# Quick Deploy Guide - CREATE2 Hook Deployment

## Prerequisites

1. Foundry installed
2. Deployed PoolManager contract
3. Deployed DisruptionOracle contract
4. Private key with ETH for gas

## Step 1: Configure Environment

Create/update `.env` file:

```bash
# Required for mining and deployment
POOL_MANAGER=0x...              # Your PoolManager address
ORACLE=0x...                    # Your DisruptionOracle address
PRIVATE_KEY=0x...               # Your deployer private key

# Network RPCs
BASE_SEPOLIA_RPC=https://sepolia.base.org
SEPOLIA_RPC=https://rpc.sepolia.org
```

## Step 2: Mine Salt

```bash
# Dry run to find salt
forge script script/MineHookSalt.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC

# Example output:
# Hook address: 0x00000000000000000000000000000000000000C0
# Salt: 0x0000000000000000000000000000000000000000000000000000000000000042
```

## Step 3: Save Salt

Add the mined salt to `.env`:

```bash
HOOK_SALT=0x0000000000000000000000000000000000000000000000000000000000000042
```

## Step 4: Deploy Hook

```bash
# Deploy with broadcast
forge script script/DeployHookCREATE2.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --verify

# Successful output:
# Hook deployed to: 0x...
# Address flags: 0xC0
# Required flags: 0xC0
# Flags match: true
# Hook permissions validated successfully!
```

## Step 5: Verify (Optional)

```bash
# Validate the deployed address
export HOOK_ADDRESS=0x...  # Address from step 4
forge script script/ValidateHookAddress.s.sol
```

## Testing Locally

Run the test suite (uses automatic CREATE2 deployment):

```bash
forge test --match-contract NatGasDisruptionHookTest -vv
```

## One-Liner Deployment

After setting up `.env`:

```bash
# Mine and deploy in sequence
forge script script/MineHookSalt.s.sol --rpc-url $BASE_SEPOLIA_RPC && \
export HOOK_SALT=$(forge script script/MineHookSalt.s.sol --rpc-url $BASE_SEPOLIA_RPC 2>&1 | grep -oP "Salt: \K0x[0-9a-fA-F]+") && \
echo "Using salt: $HOOK_SALT" && \
forge script script/DeployHookCREATE2.s.sol --rpc-url $BASE_SEPOLIA_RPC --broadcast
```

## Important Notes

1. **Same Salt = Same Address**: The salt must be mined with the exact same constructor arguments you'll use in deployment.

2. **Different Networks Need Same Deployer**: To get the same address on multiple chains, use the CREATE2 Deployer Proxy (`0x4e59b44847b379578588920cA78FbF26c0B4956C`).

3. **Constructor Changes Require Re-mining**: Any change to constructor parameters requires mining a new salt.

4. **Mining Can Take Time**: The script tries up to 160,444 salts. For beforeSwap + afterSwap, it typically finds a match quickly.

## Troubleshooting

**Error: "POOL_MANAGER not set"**
- Add `POOL_MANAGER=0x...` to `.env`

**Error: "could not find salt"**
- Very rare for beforeSwap + afterSwap flags
- Try running the script again
- If persistent, check constructor arguments are correct

**Error: "Hook address mismatch"**
- Constructor args in mining don't match deployment
- Verify `POOL_MANAGER` and `ORACLE` are identical in both steps

**Error: "HookAddressNotValid"**
- The deployed address doesn't have correct flags
- Re-mine the salt
- Ensure using the mined salt in deployment

## Example Full Workflow

```bash
# 1. Set environment
export POOL_MANAGER=0x1234567890123456789012345678901234567890
export ORACLE=0xabcdefabcdefabcdefabcdefabcdefabcdefabcd
export BASE_SEPOLIA_RPC=https://sepolia.base.org

# 2. Mine salt
forge script script/MineHookSalt.s.sol --rpc-url $BASE_SEPOLIA_RPC

# Output:
# SUCCESS!
# Hook address: 0x00000000000000000000000000000000000000C0
# Salt: 0x0000000000000000000000000000000000000000000000000000000000000042

# 3. Save salt to .env
export HOOK_SALT=0x0000000000000000000000000000000000000000000000000000000000000042

# 4. Deploy
forge script script/DeployHookCREATE2.s.sol \
  --rpc-url $BASE_SEPOLIA_RPC \
  --broadcast \
  --private-key $PRIVATE_KEY

# Output:
# SUCCESS!
# Hook deployed to: 0x00000000000000000000000000000000000000C0
# Flags match: true
# Hook permissions validated successfully!
```

## Next Steps After Deployment

1. Initialize Uniswap V4 pool with the hook
2. Add initial liquidity to the pool
3. Fund the hook's treasury via `fundTreasury()`
4. Update oracle prices via `updatePriceFromOracle()`

See `DEPLOYMENT.md` for complete pool initialization steps.
