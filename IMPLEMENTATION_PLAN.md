# Oil Token Disruption Hook - Implementation Plan

## Project Overview
Build a Uniswap V4 hook that incentivizes price convergence through asymmetric fees + bonuses. Misaligned traders pay high fees (baked into quotes). Those fees fund bonuses for aligned traders who receive MORE than market price, creating strong arbitrage incentives.

## Core Mechanism: Fee-Funded Bonuses

**How It Works:**
1. All traders pay fees based on alignment (baked into V4 quotes)
2. Misaligned traders pay HIGH fees (2-10%)
3. Aligned traders pay LOW fees (0.1%)
4. High fees accumulate in treasury
5. Treasury pays bonuses to aligned traders immediately after swap
6. Net result: Aligned traders get ABOVE market price

**Example: Pool at $120, Oracle at $100 (20% too high)**

*Buyer (misaligned - pushes price up):*
- Quote: Pay $124.80 for 1 OIL (4% fee)
- Fee goes to treasury
- Gets exactly 1 OIL ✅

*Seller (aligned - brings price down):*
- Quote: Sell 1 OIL → receive $119.88 (0.1% fee)
- **+ Bonus from treasury: $4.80**
- **Total: $124.68** (MORE than pool price!)
- Strong incentive to sell ✅

**Gradual Curves:**
- Fee curve: 0% deviation → base fee; 50% deviation → max fee
- Bonus curve: Scales with deviation and treasury balance
- At equilibrium: base fees, no bonuses

---

## Monorepo Structure
```
ETHGlobalBuenosAires25/
├── packages/
│   ├── contracts/          # Hardhat 3
│   ├── frontend/           # Next.js
│   └── shared/
├── package.json
└── README.md
```

---

## Phase 1: Monorepo & Hardhat 3 Setup

1. **Initialize monorepo**
   - Use pnpm workspaces
   - Root package.json with workspace config

2. **Setup Hardhat 3 (packages/contracts/)**
   - Install Hardhat 3.x (bounty requirement)
   - Dependencies:
     - `@uniswap/v4-core`
     - `@uniswap/v4-periphery`
     - `@chainlink/contracts`
   - Networks: Base Sepolia, Sepolia
   - TypeScript + Viem integration

3. **Structure:**
   ```
   contracts/
   ├── contracts/
   │   ├── OilToken.sol
   │   ├── MockUSDC.sol              # Mock USDC for testing
   │   ├── DisruptionOracle.sol
   │   ├── OilDisruptionHook.sol
   │   └── libraries/
   │       ├── FeeCurve.sol
   │       └── BonusCurve.sol
   ├── test/
   ├── hardhat.config.ts
   └── package.json
   ```

---

## Phase 2: Smart Contracts

### 1. OilToken.sol
```solidity
// Standard ERC20 with minting for initial liquidity
contract OilToken is ERC20 {
    constructor() ERC20("Oil Token", "OIL") {
        _mint(msg.sender, 1_000_000 * 10**18);
    }
}
```

### 2. MockUSDC.sol
```solidity
// Mock USDC for testing (6 decimals like real USDC)
contract MockUSDC is ERC20 {
    constructor() ERC20("Mock USDC", "USDC") {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    // Faucet for testnet
    function faucet() external {
        _mint(msg.sender, 10_000 * 10**6);  // 10k USDC
    }
}
```

### 3. DisruptionOracle.sol

**State:**
```solidity
struct Disruption {
    DisruptionType eventType;
    int256 priceImpactPercent;  // +20 = +20%, -15 = -15%
    uint256 timestamp;
    bool active;
}

uint256 public basePrice;  // e.g., 100e6 (100 USDC)
Disruption public currentDisruption;
```

**Key Functions:**
```solidity
function getTheoreticalPrice() external view returns (uint256) {
    if (!currentDisruption.active) return basePrice;

    int256 adjusted = int256(basePrice) * (100 + currentDisruption.priceImpactPercent) / 100;
    return uint256(adjusted);
}

function setDisruption(DisruptionType dtype, int256 impact) external onlyOwner {
    currentDisruption = Disruption({
        eventType: dtype,
        priceImpactPercent: impact,
        timestamp: block.timestamp,
        active: true
    });
    emit DisruptionUpdated(dtype, impact);
}
```

### 4. OilDisruptionHook.sol

**Permissions:**
```solidity
function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
    return Hooks.Permissions({
        beforeSwap: true,   // Set dynamic fee
        afterSwap: true,    // Pay bonuses
        afterInitialize: true,
        // ... others false
    });
}
```

**State:**
```solidity
DisruptionOracle public immutable oracle;

// Treasury balances per pool
mapping(PoolId => uint256) public treasuryOil;
mapping(PoolId => uint256) public treasuryUSDC;

// Fee parameters
uint24 public constant ALIGNED_FEE = 100;        // 0.01%
uint24 public constant BASE_FEE = 3000;          // 0.3%
uint24 public constant MAX_MISALIGNED_FEE = 100000;  // 10%

// Bonus parameters
uint256 public constant MAX_BONUS_RATE = 500;    // 5%
uint256 public constant FEE_CURVE_MULTIPLIER = 2000;
uint256 public constant BONUS_CURVE_MULTIPLIER = 100;
```

**beforeSwap: Set Dynamic Fee**
```solidity
function beforeSwap(
    address,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    bytes calldata
) external override returns (bytes4, BeforeSwapDelta, uint24) {
    // Get prices
    uint256 poolPrice = getCurrentPoolPrice(key);
    uint256 theoreticalPrice = oracle.getTheoreticalPrice();

    // At equilibrium
    if (poolPrice == theoreticalPrice) {
        poolManager.updateDynamicLPFee(key, BASE_FEE);
        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    // Calculate deviation
    int256 priceDelta = int256(poolPrice) - int256(theoreticalPrice);
    uint256 deviationPercent = (abs(priceDelta) * 100) / theoreticalPrice;

    // Determine alignment
    bool isBuyingOil = params.zeroForOne;
    bool isAligned = (poolPrice > theoreticalPrice) ? !isBuyingOil : isBuyingOil;

    // Set fee
    uint24 fee = isAligned ? ALIGNED_FEE : calculateMisalignedFee(deviationPercent);
    poolManager.updateDynamicLPFee(key, fee);

    return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
}
```

**afterSwap: Collect Fees & Pay Bonuses**
```solidity
function afterSwap(
    address sender,
    PoolKey calldata key,
    IPoolManager.SwapParams calldata params,
    BalanceDelta delta,
    bytes calldata
) external override returns (bytes4, int128) {
    PoolId poolId = key.toId();

    // 1. Collect fees to treasury (V4 accumulates fees automatically)
    // Periodically claim via separate function

    // 2. Check if aligned for bonus
    uint256 poolPrice = getCurrentPoolPrice(key);
    uint256 theoreticalPrice = oracle.getTheoreticalPrice();

    if (poolPrice == theoreticalPrice) {
        return (BaseHook.afterSwap.selector, 0);
    }

    int256 priceDelta = int256(poolPrice) - int256(theoreticalPrice);
    uint256 deviationPercent = (abs(priceDelta) * 100) / theoreticalPrice;

    bool isBuyingOil = params.zeroForOne;
    bool isAligned = (poolPrice > theoreticalPrice) ? !isBuyingOil : isBuyingOil;

    // 3. Pay bonus if aligned
    if (isAligned) {
        uint256 swapAmount = uint256(abs(delta.amount0()));  // Simplified
        uint256 bonusRate = calculateBonusRate(deviationPercent);
        uint256 bonusAmount = (swapAmount * bonusRate) / 10000;

        // Determine which token to bonus
        if (poolPrice > theoreticalPrice) {
            // Seller gets USDC bonus
            if (treasuryUSDC[poolId] >= bonusAmount) {
                treasuryUSDC[poolId] -= bonusAmount;
                poolManager.take(key.currency1, sender, bonusAmount);
                emit BonusPaid(sender, bonusAmount, false);
            }
        } else {
            // Buyer gets OIL bonus
            if (treasuryOil[poolId] >= bonusAmount) {
                treasuryOil[poolId] -= bonusAmount;
                poolManager.take(key.currency0, sender, bonusAmount);
                emit BonusPaid(sender, bonusAmount, true);
            }
        }
    }

    return (BaseHook.afterSwap.selector, 0);
}
```

**Fee Curve:**
```solidity
function calculateMisalignedFee(uint256 deviationPercent) internal pure returns (uint24) {
    // Quadratic: fee = BASE + (dev² × multiplier)
    uint256 additionalFee = (deviationPercent * deviationPercent * FEE_CURVE_MULTIPLIER) / 10000;
    uint256 totalFee = BASE_FEE + additionalFee;

    return totalFee > MAX_MISALIGNED_FEE ? MAX_MISALIGNED_FEE : uint24(totalFee);
}
```

**Bonus Curve:**
```solidity
function calculateBonusRate(uint256 deviationPercent) internal pure returns (uint256) {
    if (deviationPercent == 0) return 0;

    // Quadratic scaled: bonus = dev² × multiplier
    uint256 bonus = (deviationPercent * deviationPercent * BONUS_CURVE_MULTIPLIER) / 10000;

    return bonus > MAX_BONUS_RATE ? MAX_BONUS_RATE : bonus;
}
```

**Fee Collection:**
```solidity
function claimAccumulatedFees(PoolKey calldata key) external {
    PoolId poolId = key.toId();

    // Claim fees from PoolManager
    uint256 oilFees = poolManager.collectHookFees(key.currency0);
    uint256 usdcFees = poolManager.collectHookFees(key.currency1);

    // Add to treasury
    treasuryOil[poolId] += oilFees;
    treasuryUSDC[poolId] += usdcFees;

    emit FeesCollected(oilFees, usdcFees);
}
```

### 5. Libraries

**FeeCurve.sol:**
```solidity
library FeeCurve {
    function quadraticFee(uint256 deviation, uint256 base, uint256 multiplier, uint256 max)
        internal pure returns (uint24);
}
```

**BonusCurve.sol:**
```solidity
library BonusCurve {
    function quadraticBonus(uint256 deviation, uint256 multiplier, uint256 max)
        internal pure returns (uint256);
}
```

---

## Phase 3: Testing (Hardhat 3)

### Unit Tests

```typescript
describe("MockUSDC", () => {
  it("has 6 decimals");
  it("allows anyone to mint via faucet");
});

describe("DisruptionOracle", () => {
  it("calculates theoretical price correctly");
  it("handles positive/negative impacts");
});

describe("FeeCurve", () => {
  it("returns ALIGNED_FEE for aligned traders");
  it("scales misaligned fee with deviation");
  it("caps at MAX_MISALIGNED_FEE");
});

describe("BonusCurve", () => {
  it("returns 0 at 0% deviation");
  it("scales bonus with deviation");
  it("caps at MAX_BONUS_RATE");
});

describe("OilDisruptionHook", () => {
  it("identifies aligned traders correctly");
  it("sets appropriate fees");
  it("pays bonuses from treasury");
  it("handles treasury depletion gracefully");
});
```

### Integration Tests

```typescript
describe("Full Flow", () => {
  beforeEach(async () => {
    // Deploy MockUSDC and OilToken
    usdc = await deployContract("MockUSDC");
    oil = await deployContract("OilToken");

    // Mint tokens for testing
    await usdc.faucet();
    await oil.mint(deployer, parseUnits("10000", 18));
  });

  it("rewards sellers when pool too high", async () => {
    // Oracle $100, pool $120

    const initialBalance = await usdc.balanceOf(seller);
    await swap(seller, SELL_1_OIL);
    const finalBalance = await usdc.balanceOf(seller);

    // Should get ~$119.88 (quote) + ~$4.80 (bonus) = $124.68
    expect(finalBalance - initialBalance).to.be.gt(parseUnits("124", 6));
  });

  it("charges high fee to buyers when pool too high", async () => {
    // Buyer pays $124.80 (baked into quote)
    const quote = await router.quoteExactOutput(BUY_1_OIL);
    expect(quote.amountIn).to.be.closeTo(parseUnits("124.80", 6), 1000);
  });

  it("converges price via incentives", async () => {
    // Start: pool $150, oracle $100
    // Multiple sellers attracted by bonuses
    // Price moves to $100
    // Bonuses → 0
  });

  it("accumulates fees in treasury", async () => {
    // Execute misaligned swaps
    // Call claimAccumulatedFees
    // Verify treasury balances increase
  });
});
```

---

## Phase 4: Chainlink Integration

```javascript
// Chainlink Functions code
const data = await Promise.all([
  fetch(WEATHER_API),
  fetch(EIA_API),
  fetch(SANCTIONS_API)
]);

let impact = 0;

if (data[0].hurricane) impact += 25;
if (data[1].supplyDrop) impact += 15;
if (data[2].sanctions) impact += 10;

return Functions.encodeUint256(impact);
```

---

## Phase 5: Frontend (Next.js)

### Components

**Swap Widget:**
```tsx
// Selling (aligned)
<SwapWidget>
  You sell: 1 OIL
  You receive: 119.88 USDC (fee: 0.1%)
  + Bonus: ~4.80 USDC 🎁
  Total: ~124.68 USDC

  ✅ You're getting ABOVE market price!
  [Execute Swap]
</SwapWidget>

// Buying (misaligned)
<SwapWidget>
  You pay: 124.80 USDC (fee: 4%)
  You receive: 1 OIL

  ⚠️ High fee - price needs to come down
  [Execute Swap]
</SwapWidget>
```

**Dashboard:**
- Pool vs Oracle price
- Current deviation
- Fee rates for buyers/sellers
- Bonus rates
- Treasury balance

**Charts:**
- Fee curve visualization
- Bonus curve visualization
- Price convergence history

**Faucet Component (Testnet):**
- Button to mint Mock USDC
- Button to mint OIL tokens
- Display current balances

---

## Phase 6: Deployment (Base Sepolia)

```bash
1. Deploy MockUSDC
2. Deploy OilToken
3. Deploy DisruptionOracle (basePrice = 100e6)
4. Deploy OilDisruptionHook (CREATE2)
5. Initialize pool with dynamic fees + hook
6. Add liquidity (OIL/MockUSDC)
7. Fund treasury (initial capital)
8. Verify contracts
```

---

## Success Criteria

✅ **Hardhat 3** (bounty qualified)
✅ **Mock USDC** with 6 decimals + faucet
✅ **Asymmetric fees** baked into quotes
✅ **Bonuses** for aligned traders (funded by misaligned fees)
✅ **Aligned traders get ABOVE market price**
✅ **Gradual curves** for fees and bonuses
✅ **Treasury self-funding** from misaligned trader fees
✅ **Price convergence** demonstrated
✅ **Clear UX** showing fees + bonuses upfront

---

## Key Innovation

Creates **profitable arbitrage** for price correction:
- Aligned traders earn MORE than market
- Misaligned traders pay fees (but know upfront)
- Self-sustaining via fee redistribution
- Drives price toward real-world oracle value
