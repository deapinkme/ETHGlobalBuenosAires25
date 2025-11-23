# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Natural Gas Disruption Hook - A Uniswap V4 hook implementing asymmetric fee/bonus mechanism to incentivize price convergence based on real-world natural gas prices via Flare Data Connector (FDC) oracles.

**Core Innovation:** Misaligned traders pay high fees → fees fund bonuses → aligned traders receive MORE than market price → creates profitable arbitrage for price correction.

## Monorepo Structure

```
ETHGlobalBuenosAires25/
├── packages/
│   └── contracts/          # Hardhat 3 smart contracts
│       ├── contracts/
│       │   ├── NatGasToken.sol
│       │   ├── MockUSDC.sol
│       │   ├── DisruptionOracle.sol
│       │   ├── libraries/
│       │   │   ├── FeeCurve.sol
│       │   │   └── BonusCurve.sol
│       │   └── NatGasDisruptionHook.sol (TODO)
│       ├── test/
│       ├── scripts/
│       └── hardhat.config.ts
├── IMPLEMENTATION_PLAN.md   # Full technical specification
├── NEXT_STEPS.md           # Development roadmap
└── Web2Json.sol            # FDC integration reference
```

## Development Commands

### Smart Contracts (packages/contracts/)

```bash
# Compile contracts
npx hardhat compile

# Run all tests
npx hardhat test

# Run specific test file
npx hardhat test test/unit/DisruptionOracle.test.ts

# Deploy to Base Sepolia
npx hardhat run scripts/deploy.ts --network baseSepolia

# Deploy to Sepolia
npx hardhat run scripts/deploy.ts --network sepolia

# Verify contract on Etherscan
npx hardhat verify --network baseSepolia DEPLOYED_ADDRESS constructor_args
```

### Environment Setup

Required environment variables in `packages/contracts/.env`:
```bash
PRIVATE_KEY=your_wallet_private_key
BASE_SEPOLIA_RPC=https://sepolia.base.org
SEPOLIA_RPC=https://rpc.sepolia.org
COSTON2_RPC=https://coston2-api.flare.network/ext/C/rpc
ETHERSCAN_API_KEY=your_api_key
```

## Architecture

### Contract Hierarchy

1. **NatGasToken.sol** - ERC20 token representing natural gas (NATGAS, 18 decimals)
2. **MockUSDC.sol** - Mock USDC for testing (6 decimals, includes faucet)
3. **DisruptionOracle.sol** - FDC-powered price oracle
   - Accepts FDC proofs via `updateBasePriceWithFDC(IWeb2Json.Proof calldata proof)`
   - Tracks weather disruptions (tracked but not affecting price in v1)
   - Returns theoretical price for hook calculations
4. **FeeCurve.sol** - Library for dynamic fee calculations (quadratic, linear, exponential)
5. **BonusCurve.sol** - Library for bonus rate calculations
6. **NatGasDisruptionHook.sol** (TODO) - Main Uniswap V4 hook

### Key Mechanism Flow

1. Oracle provides theoretical price (from FDC-verified external APIs)
2. Pool price diverges due to speculation
3. Hook calculates deviation percentage
4. **beforeSwap**: Sets dynamic fee based on alignment
   - Aligned traders: 0.01% fee
   - Misaligned traders: 0.3% - 10% (scales with deviation)
5. **afterSwap**: Pays bonuses to aligned traders from treasury
   - Max bonus: 5% of swap amount
   - Funded by misaligned trader fees
6. Net result: Aligned traders receive MORE than market price

### Flare Data Connector (FDC) Integration

FDC provides decentralized, verifiable off-chain data access. Key pattern from `Web2Json.sol`:

```solidity
// 1. Verify proof on-chain
function isWeb2JsonProofValid(IWeb2Json.Proof calldata proof) private view returns (bool) {
    return ContractRegistry.getFdcVerification().verifyWeb2Json(proof);
}

// 2. Decode data from proof
DataStructure memory data = abi.decode(
    proof.data.responseBody.abiEncodedData,
    (DataStructure)
);

// 3. Validate freshness and constraints
require(data.timestamp <= block.timestamp, "Future timestamp not allowed");
require(data.timestamp > block.timestamp - 1 hours, "Data too old");
```

**DisruptionOracle.sol** implements this pattern for:
- `updateBasePriceWithFDC()` - Update natural gas price from external APIs
- `setWeatherDisruptionWithFDC()` - Track weather events (v2 feature)

### Testing Strategy

Tests use Hardhat Toolbox with Viem:
```typescript
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

async function deployFixture() {
  const [owner] = await hre.viem.getWalletClients();
  const oracle = await hre.viem.deployContract("DisruptionOracle", [100_000000n]);
  return { oracle, owner };
}
```

## Uniswap V4 Hook Development

### Critical Context

- Uniswap V4 dependencies are NOT on npm
- V4 hooks primarily use Foundry, not Hardhat
- Hook addresses must be CREATE2 deployed with specific prefixes encoding permissions

### Recommended Approach

Add Foundry alongside Hardhat (hybrid setup):
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# In packages/contracts
forge init --force
forge install uniswap/v4-core
forge install uniswap/v4-periphery
```

### Hook Requirements (NatGasDisruptionHook.sol)

Must implement:
1. `getHookPermissions()` - Return `beforeSwap: true, afterSwap: true`
2. `beforeSwap()` - Calculate deviation, set dynamic fee via `poolManager.updateDynamicLPFee()`
3. `afterSwap()` - Check alignment, pay bonuses from treasury via `poolManager.take()`
4. Treasury management: `treasuryOil[poolId]` and `treasuryUSDC[poolId]` mappings

Key constants:
```solidity
uint24 public constant ALIGNED_FEE = 100;        // 0.01%
uint24 public constant BASE_FEE = 3000;          // 0.3%
uint24 public constant MAX_MISALIGNED_FEE = 100000;  // 10%
uint256 public constant MAX_BONUS_RATE = 500;    // 5%
```

## Token Decimals (CRITICAL)

- **NATGAS**: 18 decimals (standard ERC20)
- **MockUSDC**: 6 decimals (matches real USDC)
- **Oracle prices**: 6 decimals (USDC format, e.g., 100_000000 = $100.00)

Always handle decimal conversions when calculating fees/bonuses across token pairs.

## Development Workflow

1. **Adding new features**:
   - Check IMPLEMENTATION_PLAN.md for spec details
   - Check NEXT_STEPS.md for current blockers
   - Write contract code
   - Write unit tests
   - Compile: `npx hardhat compile`
   - Test: `npx hardhat test`

2. **Testing FDC integration**:
   - Reference `Web2Json.sol` for proof structure
   - Deploy to Coston2 testnet for FDC verification
   - Use `abiSignaturePriceData()` and `abiSignatureWeatherData()` helpers for ABI generation

3. **Deployment order**:
   ```bash
   1. Deploy MockUSDC
   2. Deploy NatGasToken
   3. Deploy DisruptionOracle (constructor: basePrice in 6 decimals)
   4. Deploy NatGasDisruptionHook (CREATE2 with correct prefix)
   5. Initialize V4 pool with hook
   6. Add initial liquidity
   7. Fund hook treasury
   ```

## Common Patterns

### Fee Calculation
```solidity
uint256 deviationPercent = (abs(poolPrice - theoreticalPrice) * 100) / theoreticalPrice;
uint24 fee = FeeCurve.quadraticFee(deviationPercent, BASE_FEE, MULTIPLIER, MAX_FEE);
```

### Alignment Detection
```solidity
bool isBuyingNatGas = params.zeroForOne;
bool isAligned = (poolPrice > theoreticalPrice) ? !isBuyingNatGas : isBuyingNatGas;
```

### Bonus Payment
```solidity
uint256 bonusRate = BonusCurve.quadraticBonus(deviationPercent, MULTIPLIER, MAX_BONUS);
uint256 bonusAmount = (swapAmount * bonusRate) / 10000;

if (treasury[poolId] >= bonusAmount) {
    treasury[poolId] -= bonusAmount;
    poolManager.take(currency, trader, bonusAmount);
}
```

## Key Dependencies

- `@openzeppelin/contracts ^5.0.0` - ERC20, Ownable
- `@flarenetwork/flare-periphery-contracts ^0.1.38` - FDC integration
- `@nomicfoundation/hardhat-toolbox-viem ^3.0.0` - Testing framework
- `viem ^2.0.0` - Ethereum interactions

## Important Notes

1. **V1 Scope**: Disruptions are tracked but do NOT affect price calculation yet
   - `getTheoreticalPrice()` returns `basePrice` only
   - Weather/supply/demand disruptions are infrastructure for v2

2. **FDC Proofs**: Must be < 1 hour old, timestamps cannot be in future

3. **Treasury Self-Funding**: Bonuses paid from misaligned trader fees
   - If treasury depleted, aligned traders still get low fees but no bonus
   - System gracefully degrades to standard AMM

4. **Hardhat Version**: Uses Hardhat 2.x (not 3.x despite README stating Hardhat 3)
   - Check `packages/contracts/package.json`: `"hardhat": "^2.22.0"`

5. **Solidity Version**: 0.8.25 with optimizer enabled, viaIR: true

## Testing Scenarios

From README.md, key scenarios to validate:
1. Pool > Oracle: Sellers rewarded, buyers penalized
2. Pool < Oracle: Buyers rewarded, sellers penalized
3. Pool = Oracle: Symmetric base fees, no bonuses
4. Price convergence via multiple aligned swaps
5. Treasury accumulation from misaligned fees
6. FDC proof verification and price updates

## Reference Documentation

- [Uniswap V4 Docs](https://docs.uniswap.org/contracts/v4/overview)
- [Flare FDC Docs](https://dev.flare.network/fdc/overview)
- [Hardhat Docs](https://hardhat.org/docs)
- See IMPLEMENTATION_PLAN.md for complete technical spec
- See NEXT_STEPS.md for current development status
