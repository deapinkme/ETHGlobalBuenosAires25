# Natural Gas Disruption Hook - Uniswap V4

A Uniswap V4 hook that creates market incentives for price convergence based on real-world oil disruption events using Chainlink oracles.

## Overview

This project implements a novel pricing mechanism where:
- **Misaligned traders** (pushing price away from theoretical) pay **high fees**
- **Aligned traders** (correcting price toward theoretical) pay **low fees** + receive **bonuses**
- Bonuses are funded by misaligned trader fees (self-sustaining)
- Creates profitable arbitrage opportunities that drive price discovery

## How It Works

### Example Scenario

**Setup:**
- Oracle theoretical price: $100 (based on real-world data)
- Pool price: $120 (speculation/FOMO)
- Deviation: 20% too high

**Trading Dynamics:**

| Trader Type | Action | Fee | Bonus | Net Result |
|------------|--------|-----|-------|------------|
| Seller (aligned) | Sells 1 OIL | 0.1% | +$4.80 | Gets $124.68 (ABOVE market!) |
| Buyer (misaligned) | Buys 1 OIL | 4% | None | Pays $124.80 (in quote) |

**Result:** Sellers are incentivized to sell, pushing price down toward $100. As price converges, incentives decrease to zero.

## Project Structure

```
ETHGlobalBuenosAires25/
├── IMPLEMENTATION_PLAN.md          # Detailed implementation plan
├── package.json                     # Root workspace config
└── packages/
    ├── contracts/                   # Smart contracts (Hardhat 3)
    │   ├── contracts/
    │   │   ├── OilToken.sol         # Oil ERC20 token
    │   │   ├── MockUSDC.sol         # Mock USDC (6 decimals)
    │   │   ├── DisruptionOracle.sol # Price oracle
    │   │   ├── OilDisruptionHook.sol # Main V4 hook (TODO)
    │   │   └── libraries/
    │   │       ├── FeeCurve.sol     # Dynamic fee calculations
    │   │       └── BonusCurve.sol   # Bonus calculations
    │   ├── test/                    # Tests
    │   ├── hardhat.config.ts
    │   └── package.json
    ├── frontend/                    # Next.js UI (TODO)
    └── shared/                      # Shared types/utils
```

## Smart Contracts

### Deployed Contracts

#### OilToken.sol
- Standard ERC20 representing oil
- 18 decimals
- Mintable for testing

#### MockUSDC.sol
- Mock USDC for testnet
- 6 decimals (like real USDC)
- Includes `faucet()` function for easy testing

#### DisruptionOracle.sol
- Tracks real-world disruption events
- Calculates theoretical price based on:
  - Base price
  - Disruption type (supply shock, demand shock, weather, sanctions)
  - Price impact percentage
- Owner-controlled (will integrate Chainlink in production)

#### Libraries

**FeeCurve.sol**
- Quadratic, linear, and exponential fee curves
- Scales fees based on price deviation
- Caps at maximum to prevent extreme fees

**BonusCurve.sol**
- Quadratic, linear, and sqrt bonus curves
- Calculates bonus rates for aligned traders
- Includes treasury-adjusted bonuses

### OilDisruptionHook.sol (In Progress)

Main Uniswap V4 hook that:
1. **beforeSwap**: Sets dynamic fee based on alignment
2. **afterSwap**: Pays bonuses to aligned traders from treasury

## Getting Started

### Prerequisites

- Node.js 18+
- npm or pnpm
- Git

### Installation

```bash
# Clone repository
git clone <repo-url>
cd ETHGlobalBuenosAires25

# Install dependencies
npm install
cd packages/contracts
npm install
```

### Compile Contracts

```bash
cd packages/contracts
npx hardhat compile
```

### Run Tests

```bash
cd packages/contracts
npx hardhat test
```

### Deploy to Testnet

```bash
# Set environment variables
export PRIVATE_KEY=your_private_key
export BASE_SEPOLIA_RPC=your_rpc_url

# Deploy
npx hardhat run scripts/deploy.ts --network baseSepolia
```

## Mechanism Details

### Fee Structure

- **Aligned traders**: 0.01% fee
- **Misaligned traders**: 0.3% - 10% (scales with deviation)
- **At equilibrium**: 0.3% base fee for all

### Bonus Structure

- **Maximum bonus**: 5% of swap amount
- **Scales quadratically** with price deviation
- **Zero bonus** when price = theoretical
- **Treasury-funded**: From accumulated misaligned trader fees

### Price Convergence

1. Oracle updates theoretical price (e.g., $100)
2. Pool price diverges (e.g., $150 from speculation)
3. Sellers see 50% deviation → earn max bonuses
4. Arbitrageurs sell to capture bonuses
5. Pool price moves toward $100
6. Bonuses decrease as deviation shrinks
7. At $100: symmetric fees, no bonuses

## Disruption Types

The oracle supports multiple disruption types:

- **SUPPLY_SHOCK**: Production disruptions (hurricanes, refinery issues)
- **DEMAND_SHOCK**: Demand changes (recessions, seasonal shifts)
- **WEATHER**: Weather events affecting production/transport
- **SANCTIONS**: Geopolitical sanctions affecting supply

## Roadmap

### Phase 1: Core Contracts ✅
- [x] OilToken
- [x] MockUSDC
- [x] DisruptionOracle
- [x] FeeCurve library
- [x] BonusCurve library

### Phase 2: Hook Implementation (In Progress)
- [ ] Create V4 interface definitions
- [ ] Implement OilDisruptionHook
- [ ] beforeSwap: Dynamic fee logic
- [ ] afterSwap: Bonus distribution

### Phase 3: Testing
- [ ] Unit tests for all contracts
- [ ] Integration tests
- [ ] Fee curve validation
- [ ] Price convergence simulation

### Phase 4: Chainlink Integration
- [ ] Chainlink Functions for data fetching
- [ ] Automated oracle updates
- [ ] Real-world API integration

### Phase 5: Frontend
- [ ] Next.js setup
- [ ] Swap interface with fee/bonus preview
- [ ] Price dashboard
- [ ] Disruption timeline
- [ ] Treasury balance display

### Phase 6: Deployment
- [ ] Deploy to Base Sepolia
- [ ] Initialize pool
- [ ] Add liquidity
- [ ] Create demo scenarios

## Configuration

### Environment Variables

```bash
# .env file
PRIVATE_KEY=your_wallet_private_key
BASE_SEPOLIA_RPC=https://sepolia.base.org
SEPOLIA_RPC=https://rpc.sepolia.org
ETHERSCAN_API_KEY=your_api_key
```

### Oracle Configuration

```solidity
// Default base price: $100
basePrice = 100 * 10**6  // 100 USDC (6 decimals)

// Example disruption
oracle.setDisruption(
    DisruptionType.SUPPLY_SHOCK,
    25  // +25% price impact
);
// Theoretical price now: $125
```

## Testing Scenarios

### Scenario 1: Supply Disruption
```
Oracle: $100 → $130 (+30% impact)
Pool: $100
Expected: Buyers get bonuses, sellers pay fees
Result: Price rises to $130
```

### Scenario 2: Speculation Bubble
```
Oracle: $100
Pool: $180 (degen pump)
Expected: Sellers get massive bonuses, buyers pay high fees
Result: Price crashes to $100
```

### Scenario 3: Demand Collapse
```
Oracle: $100 → $70 (-30% impact)
Pool: $100
Expected: Sellers get bonuses, buyers pay fees
Result: Price falls to $70
```

## Tech Stack

- **Smart Contracts**: Solidity 0.8.24
- **Development**: Hardhat 3
- **Testing**: Hardhat + Viem
- **Frontend**: Next.js 14, wagmi, viem
- **Oracle**: Chainlink Functions
- **DEX**: Uniswap V4

## Contributing

This is a hackathon project for ETHGlobal Buenos Aires 2025.

## License

MIT

## Acknowledgments

- Uniswap V4 for the hooks architecture
- Chainlink for oracle infrastructure
- ETHGlobal for the hackathon opportunity
