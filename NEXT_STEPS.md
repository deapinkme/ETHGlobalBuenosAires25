# Next Steps - Oil Disruption Hook

## Current Status ✅

### Completed
- [x] Monorepo structure setup
- [x] Hardhat 3 configured (packages/contracts)
- [x] Dependencies installed (@openzeppelin/contracts, @chainlink/contracts, viem)
- [x] OilToken.sol implemented
- [x] MockUSDC.sol implemented (6 decimals + faucet)
- [x] DisruptionOracle.sol implemented
- [x] FeeCurve.sol library implemented
- [x] BonusCurve.sol library implemented
- [x] IMPLEMENTATION_PLAN.md created
- [x] README.md created

### File Structure
```
ETHGlobalBuenosAires25/
├── IMPLEMENTATION_PLAN.md       ✅ Complete technical plan
├── README.md                     ✅ Project overview
├── NEXT_STEPS.md                ← You are here
├── package.json                  ✅ Workspace config
└── packages/
    └── contracts/
        ├── contracts/
        │   ├── OilToken.sol         ✅
        │   ├── MockUSDC.sol         ✅
        │   ├── DisruptionOracle.sol ✅
        │   └── libraries/
        │       ├── FeeCurve.sol     ✅
        │       └── BonusCurve.sol   ✅
        ├── hardhat.config.ts         ✅
        ├── package.json              ✅
        └── tsconfig.json             ✅
```

---

## Immediate Next Steps 🎯

### Step 1: Verify Compilation

First, test that existing contracts compile:

```bash
cd packages/contracts
npx hardhat compile
```

**Expected result:** All 5 contracts should compile successfully.

**If errors occur:** Check OpenZeppelin import versions.

---

### Step 2: Add Uniswap V4 Dependencies ⚠️ CRITICAL

The hook contract requires Uniswap V4 core libraries. However, V4 is not yet on npm. You have two options:

#### Option A: Use Foundry/Forge (Recommended for V4 hooks)

V4 hooks are primarily developed with Foundry. To integrate:

```bash
# Install Foundry if not already installed
curl -L https://foundry.paradigm.xyz | bash
foundryup

# In packages/contracts, initialize Forge
forge init --force

# Add V4 dependencies
forge install uniswap/v4-core
forge install uniswap/v4-periphery
```

Then you can use Hardhat + Foundry together (dual setup).

#### Option B: Use V4 Template Repository

Clone the official V4 template as reference:

```bash
# In a separate directory
git clone https://github.com/uniswapfoundation/v4-template.git
cd v4-template

# Copy necessary interfaces and dependencies to your project
```

**Recommended:** Go with **Option A** for this hackathon. It's the standard V4 development path.

---

### Step 3: Create Uniswap V4 Interface Definitions

Before implementing the hook, you need these V4 interfaces:

**Create: `packages/contracts/contracts/interfaces/IPoolManager.sol`**

Minimal interface needed:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IPoolManager {
    // Add minimal interface definitions needed for hook
    // Reference: v4-core/src/interfaces/IPoolManager.sol
}
```

**Create: `packages/contracts/contracts/base/BaseHook.sol`**

Base hook implementation:
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Reference: v4-periphery/src/base/hooks/BaseHook.sol
abstract contract BaseHook {
    // Minimal base hook implementation
}
```

**Where to find these:**
- V4 Core: https://github.com/Uniswap/v4-core
- V4 Periphery: https://github.com/Uniswap/v4-periphery

---

### Step 4: Implement OilDisruptionHook.sol

**File:** `packages/contracts/contracts/OilDisruptionHook.sol`

Key sections to implement:

```solidity
// 1. Imports
import "./interfaces/IPoolManager.sol";
import "./base/BaseHook.sol";
import "./DisruptionOracle.sol";
import "./libraries/FeeCurve.sol";
import "./libraries/BonusCurve.sol";

// 2. State variables
DisruptionOracle public immutable oracle;
mapping(PoolId => uint256) public treasuryOil;
mapping(PoolId => uint256) public treasuryUSDC;

// 3. Constants
uint24 public constant ALIGNED_FEE = 100;        // 0.01%
uint24 public constant BASE_FEE = 3000;          // 0.3%
uint24 public constant MAX_MISALIGNED_FEE = 100000;  // 10%
uint256 public constant MAX_BONUS_RATE = 500;    // 5%

// 4. Hook permissions
function getHookPermissions() public pure override returns (Hooks.Permissions memory);

// 5. beforeSwap: Set dynamic fee
function beforeSwap(...) external override returns (...);

// 6. afterSwap: Pay bonuses
function afterSwap(...) external override returns (...);

// 7. Helper functions
function getCurrentPoolPrice(PoolKey calldata key) internal view returns (uint256);
function calculateMisalignedFee(uint256 deviationPercent) internal pure returns (uint24);
function calculateBonusRate(uint256 deviationPercent) internal pure returns (uint256);
```

**Reference:** See IMPLEMENTATION_PLAN.md Phase 2, section 4 for full pseudocode.

---

### Step 5: Write Unit Tests

**Create:** `packages/contracts/test/unit/`

Test files needed:
1. **OilToken.test.ts**
2. **MockUSDC.test.ts**
3. **DisruptionOracle.test.ts**
4. **FeeCurve.test.ts**
5. **BonusCurve.test.ts**

Example test structure:

```typescript
// test/unit/DisruptionOracle.test.ts
import { loadFixture } from "@nomicfoundation/hardhat-toolbox-viem/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("DisruptionOracle", function () {
  async function deployFixture() {
    const [owner, otherAccount] = await hre.viem.getWalletClients();
    const oracle = await hre.viem.deployContract("DisruptionOracle", [100_000000n]); // $100
    return { oracle, owner, otherAccount };
  }

  it("Should return base price when no disruption", async function () {
    const { oracle } = await loadFixture(deployFixture);
    expect(await oracle.read.getTheoreticalPrice()).to.equal(100_000000n);
  });

  it("Should calculate +20% impact correctly", async function () {
    const { oracle } = await loadFixture(deployFixture);
    await oracle.write.setDisruption([1, 20n]); // SUPPLY_SHOCK, +20%
    expect(await oracle.read.getTheoreticalPrice()).to.equal(120_000000n);
  });

  // Add more tests...
});
```

Run tests:
```bash
npx hardhat test
```

---

### Step 6: Write Integration Tests

**Create:** `packages/contracts/test/integration/FullFlow.test.ts`

This requires:
1. Deploy full V4 PoolManager (or mock)
2. Initialize pool with hook
3. Add liquidity
4. Simulate swaps
5. Verify fee/bonus behavior

**Note:** Integration tests are complex for V4 hooks. Consider using Foundry for this.

---

### Step 7: Create Deployment Scripts

**Create:** `packages/contracts/scripts/deploy.ts`

```typescript
import hre from "hardhat";

async function main() {
  console.log("Deploying Oil Disruption Hook...");

  // 1. Deploy MockUSDC
  const usdc = await hre.viem.deployContract("MockUSDC");
  console.log(`MockUSDC deployed to ${usdc.address}`);

  // 2. Deploy OilToken
  const oil = await hre.viem.deployContract("OilToken");
  console.log(`OilToken deployed to ${oil.address}`);

  // 3. Deploy DisruptionOracle
  const basePrice = 100_000000n; // $100
  const oracle = await hre.viem.deployContract("DisruptionOracle", [basePrice]);
  console.log(`DisruptionOracle deployed to ${oracle.address}`);

  // 4. Deploy OilDisruptionHook
  // const hook = await hre.viem.deployContract("OilDisruptionHook", [
  //   poolManagerAddress,
  //   oracle.address
  // ]);
  // console.log(`OilDisruptionHook deployed to ${hook.address}`);

  // 5. Verify contracts
  console.log("\nVerifying contracts...");
  // Add verification logic
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

---

### Step 8: Setup Frontend (Next.js)

**Create:** `packages/frontend/`

```bash
cd packages
npx create-next-app@latest frontend --typescript --tailwind --app --no-src-dir
cd frontend
npm install wagmi viem @tanstack/react-query
```

Key components to build:
1. **Swap Widget** - Shows fee/bonus preview
2. **Price Dashboard** - Pool vs Oracle price
3. **Disruption Feed** - Timeline of events
4. **Faucet Component** - Mint test tokens

---

## Critical Decisions Needed 🤔

### Decision 1: Hardhat vs Foundry for Hook Development

**Current:** Hardhat 3 setup ✅
**Issue:** V4 hooks are primarily Foundry-based
**Options:**
- A) Add Foundry alongside Hardhat (hybrid approach)
- B) Migrate fully to Foundry
- C) Continue with Hardhat and manually port V4 interfaces

**Recommendation:** Add Foundry for hook development, keep Hardhat for deployment scripts.

### Decision 2: Testnet Choice

**Options:**
- Base Sepolia (recommended - L2, cheap, Uniswap support)
- Sepolia (Ethereum testnet)
- Arbitrum Sepolia

**Recommendation:** Base Sepolia for lower gas costs.

### Decision 3: Mock V4 vs Real V4 Deployment

For hackathon purposes:
- **Option A:** Deploy to real V4 testnet pools
- **Option B:** Create simplified mock PoolManager for demo

**Recommendation:** Start with mock for faster development, migrate to real V4 if time permits.

---

## Development Workflow 🔄

### Daily Development Loop

1. **Morning:** Pick next contract/feature
2. **Implement:** Write contract/test
3. **Test:** `npx hardhat test`
4. **Commit:** Git commit progress
5. **Document:** Update this file with blockers

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/hook-implementation

# Commit frequently
git add .
git commit -m "feat: implement beforeSwap logic"

# Push to remote
git push origin feature/hook-implementation
```

---

## Blockers & Solutions 🚧

### Blocker 1: Uniswap V4 Dependencies Not on npm

**Solution:**
```bash
# Option 1: Use Foundry
forge install uniswap/v4-core

# Option 2: Manual vendor
mkdir -p contracts/vendor
# Copy interfaces from v4-core repo
```

### Blocker 2: Pool Price Calculation Complex

**Solution:** Use simplified price oracle for demo:
```solidity
// Instead of complex TWAP/sqrt price:
function getCurrentPoolPrice(PoolKey calldata key) internal view returns (uint256) {
    // For demo: use last swap price or manual setter
    return manualPoolPrice;
}
```

### Blocker 3: CREATE2 Address Requirements

V4 hooks must be deployed to specific addresses encoding their permissions.

**Solution:** Use Foundry's create2 helpers or v4-template deployment scripts.

---

## Quick Reference 📚

### Important Files

| File | Purpose | Status |
|------|---------|--------|
| `IMPLEMENTATION_PLAN.md` | Full technical spec | ✅ Complete |
| `README.md` | Project overview | ✅ Complete |
| `NEXT_STEPS.md` | This file | ✅ You are here |
| `packages/contracts/contracts/OilDisruptionHook.sol` | Main hook | ❌ TODO |
| `packages/contracts/test/` | Tests | ❌ TODO |
| `packages/frontend/` | UI | ❌ TODO |

### Useful Commands

```bash
# Compile contracts
cd packages/contracts && npx hardhat compile

# Run tests
npx hardhat test

# Run specific test
npx hardhat test test/unit/DisruptionOracle.test.ts

# Deploy to testnet
npx hardhat run scripts/deploy.ts --network baseSepolia

# Verify contract
npx hardhat verify --network baseSepolia DEPLOYED_ADDRESS constructor_args

# Start frontend
cd packages/frontend && npm run dev
```

### Key Documentation Links

- [Uniswap V4 Docs](https://docs.uniswap.org/contracts/v4/overview)
- [V4 Hooks Guide](https://docs.uniswap.org/contracts/v4/guides/hooks/your-first-hook)
- [Hardhat Docs](https://hardhat.org/docs)
- [Wagmi Docs](https://wagmi.sh/)
- [Viem Docs](https://viem.sh/)

---

## Estimated Time Breakdown ⏱️

| Task | Time Estimate | Priority |
|------|---------------|----------|
| Setup V4 dependencies | 2-3 hours | 🔴 High |
| Implement OilDisruptionHook | 4-6 hours | 🔴 High |
| Write unit tests | 3-4 hours | 🟡 Medium |
| Write integration tests | 4-5 hours | 🟢 Low |
| Build frontend | 6-8 hours | 🟡 Medium |
| Deploy & test on testnet | 2-3 hours | 🟡 Medium |
| Create demo scenarios | 2-3 hours | 🟡 Medium |
| Documentation & pitch | 2-3 hours | 🟡 Medium |
| **Total** | **25-35 hours** | |

---

## When You Return 🔄

### Quickstart Checklist

1. [ ] Pull latest code: `git pull origin main`
2. [ ] Check dependencies: `cd packages/contracts && npm install`
3. [ ] Compile contracts: `npx hardhat compile`
4. [ ] Review this file for next task
5. [ ] Pick one task from "Immediate Next Steps"
6. [ ] Update todos in this file as you progress

### First Task Recommendation

**Start here:** Complete Step 2 (Add Uniswap V4 Dependencies) using Foundry.

This unblocks all hook development.

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Add to project
cd packages/contracts
forge init --force
forge install uniswap/v4-core
forge install uniswap/v4-periphery
```

---

## Questions? 🤔

Refer to:
1. **IMPLEMENTATION_PLAN.md** - Technical details
2. **README.md** - Project overview
3. **Uniswap V4 docs** - Hook architecture
4. **ETHGlobal Discord** - Community support

---

## Success Criteria for Hackathon ✨

### Minimum Viable Demo (MVP)
- [x] Core contracts implemented
- [ ] Hook contract working (even if simplified)
- [ ] Deployed to testnet
- [ ] Basic frontend showing:
  - Pool price vs Oracle price
  - Fee preview
  - One successful swap with bonus
- [ ] 3-minute pitch ready

### Stretch Goals
- [ ] Full Chainlink integration
- [ ] Multiple disruption scenarios
- [ ] Advanced fee curves
- [ ] Treasury dashboard
- [ ] Price convergence chart

---

**Last Updated:** 2025-11-22

**Next Action:** Add Uniswap V4 dependencies (Step 2)

Good luck! 🚀
