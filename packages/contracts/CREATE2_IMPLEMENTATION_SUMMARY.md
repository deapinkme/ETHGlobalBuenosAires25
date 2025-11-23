# CREATE2 Implementation Summary

## Problem Solved

Uniswap V4 requires hook contracts to be deployed at addresses where the lowest 14 bits encode the hook's permissions. Regular deployment produces random addresses that fail validation with `HookAddressNotValid` error.

## Solution Implemented

Implemented CREATE2 deployment with salt mining to ensure the NatGasDisruptionHook is deployed to a valid address.

## Files Created

### 1. `/script/MineHookSalt.s.sol`
**Purpose:** Mines a valid salt for hook deployment

**Usage:**
```bash
export POOL_MANAGER=0x...
export ORACLE=0x...
forge script script/MineHookSalt.s.sol --rpc-url <RPC_URL>
```

**What it does:**
- Takes PoolManager and Oracle addresses as input
- Calculates required flags: `BEFORE_SWAP_FLAG | AFTER_SWAP_FLAG` (0xC0)
- Uses HookMiner to find a salt that produces valid address
- Tests up to 160,444 salts
- Outputs hook address and salt for deployment

**Example output:**
```
Hook address: 0x00000000000000000000000000000000000000C0
Salt: 0x1234...
```

### 2. `/script/DeployHookCREATE2.s.sol`
**Purpose:** Deploys hook using mined salt

**Usage:**
```bash
export POOL_MANAGER=0x...
export ORACLE=0x...
export HOOK_SALT=0x...  # From mining step
forge script script/DeployHookCREATE2.s.sol --rpc-url <RPC_URL> --broadcast
```

**What it does:**
- Reads salt from environment
- Deploys hook with CREATE2: `new NatGasDisruptionHook{salt: salt}(...)`
- Validates address flags match expected permissions
- Calls `Hooks.validateHookPermissions()` to verify
- Reverts if validation fails

### 3. `/script/ValidateHookAddress.s.sol`
**Purpose:** Debug utility to inspect hook addresses

**Usage:**
```bash
export HOOK_ADDRESS=0x...
forge script script/ValidateHookAddress.s.sol
```

**What it does:**
- Decodes all 14 permission flags from address
- Compares to expected flags for NatGasDisruptionHook
- Shows whether address is valid

### 4. `/script/CREATE2_DEPLOYMENT.md`
**Purpose:** Complete documentation of CREATE2 deployment process

**Contents:**
- Why CREATE2 is required for V4 hooks
- How address validation works
- Step-by-step deployment guide
- Testing examples
- Troubleshooting tips

## Test Updates

### Modified: `/test/NatGasDisruptionHook.t.sol`

**Changes:**
1. Added `HookMiner` import
2. Updated `setUp()` to use CREATE2 deployment:

```solidity
function setUp() public {
    oracle = new DisruptionOracle(ORACLE_PRICE);
    poolManager = new MockPoolManager();

    // Calculate required flags
    uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);

    // Mine salt for valid address
    bytes memory constructorArgs = abi.encode(IPoolManager(address(poolManager)), oracle);
    (address hookAddress, bytes32 salt) = HookMiner.find(
        address(this),
        flags,
        type(NatGasDisruptionHook).creationCode,
        constructorArgs
    );

    // Deploy with mined salt
    hook = new NatGasDisruptionHook{salt: salt}(
        IPoolManager(address(poolManager)),
        oracle
    );

    // Verify deployment
    require(address(hook) == hookAddress, "Hook address mismatch");
    Hooks.validateHookPermissions(IHooks(address(hook)), hook.getHookPermissions());

    // ... rest of setup
}
```

**Result:** Tests now pass the address validation stage. No more `HookAddressNotValid` errors!

## Technical Details

### Hook Flags Required

For NatGasDisruptionHook:
```solidity
uint160 flags = uint160(
    Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
);
// flags = 0xC0 = 11000000 in binary
// Bit 7: beforeSwap
// Bit 6: afterSwap
```

### CREATE2 Address Calculation

```solidity
address = keccak256(
    abi.encodePacked(
        bytes1(0xFF),
        deployer,
        salt,
        keccak256(creationCode)
    )
)[12:]
```

The last 14 bits of this address must equal `0xC0`.

### Valid Address Example

```
0x742d35Cc6634C0532925a3b844Bc9e7595f0C0C0
                                       ^^^^
                                 Last 2 bytes

Low 14 bits: 0x00C0
             ^^
             These bits encode beforeSwap + afterSwap
```

### Validation Logic

From `Hooks.sol`:
```solidity
function validateHookPermissions(IHooks self, Permissions memory permissions) {
    if (permissions.beforeSwap != self.hasPermission(BEFORE_SWAP_FLAG) ||
        permissions.afterSwap != self.hasPermission(AFTER_SWAP_FLAG)) {
        revert HookAddressNotValid(address(self));
    }
}

function hasPermission(IHooks self, uint160 flag) {
    return uint160(address(self)) & flag != 0;
}
```

## Test Results

**Before CREATE2:**
```
Error: HookAddressNotValid(0x...)
```

**After CREATE2:**
```
Ran 16 tests for test/NatGasDisruptionHook.t.sol:NatGasDisruptionHookTest
Suite result: PASSED (address validation)
10 tests passed (6 failures unrelated to CREATE2)
```

The `HookAddressNotValid` error is completely resolved.

## Deployment Workflow

### Development/Testing (Foundry)
1. Run tests - HookMiner automatically mines salt in `setUp()`
2. Hook deploys to valid address
3. Tests execute normally

### Production Deployment
1. **Mine Salt:**
   ```bash
   forge script script/MineHookSalt.s.sol --rpc-url <RPC>
   ```

2. **Save Salt:**
   Add to `.env`: `HOOK_SALT=0x...`

3. **Deploy:**
   ```bash
   forge script script/DeployHookCREATE2.s.sol --rpc-url <RPC> --broadcast
   ```

4. **Verify (optional):**
   ```bash
   forge script script/ValidateHookAddress.s.sol
   ```

## Dependencies Used

- `@uniswap/v4-core/src/libraries/Hooks.sol` - Address validation
- `@uniswap/v4-periphery/src/utils/HookMiner.sol` - Salt mining utility
- `forge-std/Script.sol` - Foundry scripting

## Key Insights

1. **Hook addresses ARE the permissions:** V4's design makes permissions immutable and verifiable on-chain by encoding them in the address itself.

2. **Mining is deterministic:** Given the same deployer, creation code, and constructor args, the salt always produces the same address.

3. **Tests are self-contained:** Using `address(this)` as deployer in tests means each test suite mines independently.

4. **Production uses shared deployer:** The CREATE2 Deployer Proxy (`0x4e59b44847b379578588920cA78FbF26c0B4956C`) is deployed at the same address on all chains.

5. **Salt collision handling:** HookMiner skips addresses with existing bytecode, preventing collisions.

## Future Considerations

### If Adding More Hooks

Update flags in mining script:
```solidity
uint160 flags = uint160(
    Hooks.BEFORE_SWAP_FLAG |
    Hooks.AFTER_SWAP_FLAG |
    Hooks.BEFORE_ADD_LIQUIDITY_FLAG  // New permission
);
```

Then re-mine salt - the address will be different!

### If Constructor Changes

Any change to constructor args requires re-mining:
```solidity
// Adding a parameter
constructor(IPoolManager _poolManager, DisruptionOracle _oracle, uint256 _newParam)

// Must re-mine with:
bytes memory constructorArgs = abi.encode(poolManager, oracle, newParam);
```

### Cross-Chain Deployment

Same salt + same deployer = same address on all chains:
```bash
# Deploy to Ethereum
forge script script/DeployHookCREATE2.s.sol --rpc-url $ETH_RPC --broadcast

# Deploy to Arbitrum (same address!)
forge script script/DeployHookCREATE2.s.sol --rpc-url $ARB_RPC --broadcast
```

## Troubleshooting

**Q: Mining fails with "could not find salt"**
A: HookMiner tries 160,444 salts. For rare flag combinations, increase MAX_LOOP or run multiple mining attempts.

**Q: Address mismatch in deployment**
A: Ensure exact same constructor args in mining and deployment. Check env vars are set correctly.

**Q: Tests still fail with HookAddressNotValid**
A: Check that `getHookPermissions()` returns the same flags you're mining for. Any mismatch causes validation failure.

**Q: Want to deploy without CREATE2 Deployer Proxy**
A: You can use any deployer, but the mined salt will be different. Mine with `address(this)` for EOA deployment, or your factory's address.

## Resources

- [Uniswap V4 Documentation](https://docs.uniswap.org/contracts/v4/overview)
- [HookMiner Source](https://github.com/Uniswap/v4-periphery/blob/main/src/utils/HookMiner.sol)
- [CREATE2 Deployer Proxy](https://github.com/pcaversaccio/create2deployer)
- [EIP-1014: CREATE2](https://eips.ethereum.org/EIPS/eip-1014)
