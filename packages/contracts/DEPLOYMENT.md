# Deployment Guide

This guide explains how to deploy the Natural Gas Disruption Hook contracts to testnets.

## Prerequisites

1. **Foundry installed**
   ```bash
   curl -L https://foundry.paradigm.xyz | bash
   foundryup
   ```

2. **Funded wallet**
   - Get testnet ETH from faucets for Base Sepolia or Sepolia
   - Base Sepolia: https://www.coinbase.com/faucets/base-sepolia-faucet
   - Sepolia: https://sepoliafaucet.com/

3. **Environment setup**
   ```bash
   cp .env.example .env
   # Edit .env with your PRIVATE_KEY and POOL_MANAGER_ADDRESS
   ```

## Known Pool Manager Addresses

You need a deployed Uniswap V4 PoolManager. Current known testnets:

- **Base Sepolia**: TBD (check Uniswap V4 docs)
- **Sepolia**: TBD (check Uniswap V4 docs)
- **Coston2** (Flare testnet): Not applicable (use for FDC testing only)

⚠️ **Important**: If no V4 PoolManager exists on your target network, you'll need to deploy one or use a mock for testing.

## Deployment Steps

### Step 1: Deploy Core Contracts

```bash
# For Base Sepolia
forge script script/Deploy.s.sol:Deploy --rpc-url $BASE_SEPOLIA_RPC --broadcast --verify

# For Sepolia
forge script script/Deploy.s.sol:Deploy --rpc-url $SEPOLIA_RPC --broadcast --verify

# For local testing (Anvil)
anvil  # In separate terminal
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast
```

**Outputs:**
- MockUSDC address
- NatGasToken address
- DisruptionOracle address
- NatGasDisruptionHook address

Save these addresses to your `.env` file for Step 2.

### Step 2: Initial Setup

Update `.env` with deployed addresses:
```bash
NATGAS_ADDRESS=0x...
USDC_ADDRESS=0x...
ORACLE_ADDRESS=0x...
HOOK_ADDRESS=0x...
```

Run setup script:
```bash
# For Base Sepolia
forge script script/Setup.s.sol:Setup --rpc-url $BASE_SEPOLIA_RPC --broadcast

# For Sepolia
forge script script/Setup.s.sol:Setup --rpc-url $SEPOLIA_RPC --broadcast
```

This will:
- Mint 1,000,000 USDC to deployer
- Log deployer's NATGAS balance (from constructor mint)
- Approve tokens for treasury funding

### Step 3: Create Uniswap V4 Pool (Manual)

You'll need to interact with the PoolManager directly to:

1. **Initialize pool** with NATGAS/USDC pair
   - Use tick spacing appropriate for your token pair
   - Set initial sqrtPriceX96
   - Register your hook address

2. **Add initial liquidity**
   - Provide balanced NATGAS/USDC liquidity
   - Recommended: 5,000 NATGAS + 500,000 USDC (1 NATGAS = $100)

3. **Fund hook treasury**
   ```solidity
   // Call this function on NatGasDisruptionHook
   hook.fundTreasury(poolKey, 1000e18, 100000e6);
   ```

4. **Set pool price**
   ```solidity
   // Set initial pool price (in USDC with 6 decimals)
   hook.setPoolPrice(poolKey, 100_000000);  // $100.00
   ```

## Testing Deployment

### Test Oracle Update
```bash
cast call $ORACLE_ADDRESS "getTheoreticalPrice()" --rpc-url $BASE_SEPOLIA_RPC
```

Expected: `100000000` (100 USDC with 6 decimals)

### Test Token Balances
```bash
# NATGAS balance (18 decimals)
cast call $NATGAS_ADDRESS "balanceOf(address)(uint256)" $YOUR_ADDRESS --rpc-url $BASE_SEPOLIA_RPC

# USDC balance (6 decimals)
cast call $USDC_ADDRESS "balanceOf(address)(uint256)" $YOUR_ADDRESS --rpc-url $BASE_SEPOLIA_RPC
```

### Test Hook Permissions
```bash
cast call $HOOK_ADDRESS "getHookPermissions()" --rpc-url $BASE_SEPOLIA_RPC
```

Should return beforeSwap=true and afterSwap=true.

## Verification

If auto-verification fails during deployment, verify manually:

```bash
# Verify MockUSDC
forge verify-contract $USDC_ADDRESS src/MockUSDC.sol:MockUSDC \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY

# Verify NatGasToken
forge verify-contract $NATGAS_ADDRESS src/NatGasToken.sol:NatGasToken \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY

# Verify DisruptionOracle
forge verify-contract $ORACLE_ADDRESS src/DisruptionOracle.sol:DisruptionOracle \
  --constructor-args $(cast abi-encode "constructor(uint256)" 100000000) \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY

# Verify NatGasDisruptionHook
forge verify-contract $HOOK_ADDRESS src/NatGasDisruptionHook.sol:NatGasDisruptionHook \
  --constructor-args $(cast abi-encode "constructor(address,address)" $POOL_MANAGER_ADDRESS $ORACLE_ADDRESS) \
  --chain-id 84532 \
  --etherscan-api-key $BASESCAN_API_KEY
```

## Local Testing with Anvil

For rapid iteration:

```bash
# Terminal 1: Start local chain
anvil

# Terminal 2: Deploy
forge script script/Deploy.s.sol:Deploy --rpc-url http://localhost:8545 --broadcast

# Terminal 3: Run tests
forge test -vvv
```

## Network IDs

- **Base Sepolia**: 84532
- **Sepolia**: 11155111
- **Coston2**: 114 (Flare testnet)

## Troubleshooting

### "PoolManager not found"
- Ensure POOL_MANAGER_ADDRESS is set correctly in `.env`
- Verify V4 PoolManager is deployed on your target network
- Consider deploying a mock PoolManager for testing

### "Insufficient funds"
- Ensure deployer wallet has enough testnet ETH
- Gas costs typically ~0.01-0.05 ETH for full deployment

### "Hook address invalid"
- V4 hooks require CREATE2 deployment with specific prefixes
- For MVP testing, use any deployed address
- For production, implement proper CREATE2 deployment

### "Pool price not set"
- Call `setPoolPrice(poolKey, price)` before testing swaps
- Price should be in USDC format (6 decimals)

## Next Steps

After deployment:
1. Test aligned/misaligned swaps
2. Verify dynamic fee adjustment
3. Test bonus payments
4. Monitor treasury balances
5. Update oracle price with FDC proofs (on Coston2)

## Security Notes

⚠️ **Testnet Only**: These contracts are for demonstration and testing
- MockUSDC has public mint function (not for production)
- Manual pool price setter (replace with price oracle integration)
- No access control on fundTreasury (add in production)
- FDC integration not fully tested yet

## Support

- Uniswap V4 Docs: https://docs.uniswap.org/contracts/v4/overview
- Flare FDC Docs: https://dev.flare.network/fdc/overview
- Foundry Book: https://book.getfoundry.sh/
