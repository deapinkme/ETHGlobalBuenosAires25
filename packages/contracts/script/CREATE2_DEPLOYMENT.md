# CREATE2 Deployment Guide for Uniswap V4 Hooks

## Why CREATE2 is Required

Uniswap V4 hooks use a unique address validation mechanism where **the hook's permissions are encoded in its contract address**. Specifically, the lowest 14 bits of the hook's address must match the permission flags for which hooks are enabled.

For `NatGasDisruptionHook`, we need:
- `beforeSwap: true` (bit 7)
- `afterSwap: true` (bit 6)

This means the hook address must end with specific bits: `0xC0` (binary: `11000000`).

Regular deployment gives random addresses that will fail validation with `HookAddressNotValid` error. CREATE2 deployment allows us to "mine" a salt that produces an address with the correct flags.

## Understanding Hook Address Validation

From `v4-core/src/libraries/Hooks.sol`:

```solidity
uint160 internal constant BEFORE_SWAP_FLAG = 1 << 7;  // 0x80
uint160 internal constant AFTER_SWAP_FLAG = 1 << 6;   // 0x40
```

The address validation checks:
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

## How CREATE2 Works

CREATE2 computes contract addresses deterministically:
```
address = keccak256(0xFF, deployer, salt, keccak256(creationCode))[12:]
```

By trying different salts, we can find one that produces an address with the correct lowest bits.

## Step 1: Mine a Salt

Before deploying, you need to find a valid salt. Set environment variables in `.env`:

```bash
POOL_MANAGER=0x... # Address of PoolManager contract
ORACLE=0x...       # Address of DisruptionOracle contract
```

Run the mining script:
```bash
forge script script/MineHookSalt.s.sol --rpc-url <RPC_URL>
```

This will output:
```
SUCCESS!
Hook address: 0x00000000000000000000000000000000000000C0
Salt: 0x1234...
```

The script tests up to 160,444 different salts to find a valid address.

## Step 2: Deploy with CREATE2

Add the mined salt to your `.env`:
```bash
HOOK_SALT=0x1234...  # Salt from mining step
```

Deploy the hook:
```bash
forge script script/DeployHookCREATE2.s.sol --rpc-url <RPC_URL> --broadcast
```

The script will:
1. Deploy the hook using CREATE2 with the mined salt
2. Verify the address has correct flags
3. Validate hook permissions match the address

## Step 3: Verify Deployment

You can verify the deployment succeeded by checking:

```solidity
// Address ends with correct bits
uint160 addressFlags = uint160(address(hook)) & 0x3FFF;
uint160 expectedFlags = 0xC0; // beforeSwap | afterSwap
assert(addressFlags == expectedFlags);

// Permissions validation passes
Hooks.validateHookPermissions(IHooks(address(hook)), hook.getHookPermissions());
```

## Using in Tests

Tests automatically use CREATE2 deployment via `HookMiner`:

```solidity
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

function setUp() public {
    oracle = new DisruptionOracle(ORACLE_PRICE);
    poolManager = new MockPoolManager();

    uint160 flags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);
    bytes memory constructorArgs = abi.encode(poolManager, oracle);

    (address hookAddress, bytes32 salt) = HookMiner.find(
        address(this),
        flags,
        type(NatGasDisruptionHook).creationCode,
        constructorArgs
    );

    hook = new NatGasDisruptionHook{salt: salt}(poolManager, oracle);
    require(address(hook) == hookAddress, "Hook address mismatch");
}
```

## Production Deployment

For mainnet/testnet deployment, use the CREATE2 Deployer Proxy:
```
0x4e59b44847b379578588920cA78FbF26c0B4956C
```

Update mining to use this deployer:
```solidity
address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);
HookMiner.find(CREATE2_DEPLOYER, flags, creationCode, constructorArgs);
```

## Example: Valid Hook Address

A valid hook address for beforeSwap + afterSwap might look like:
```
0x742d35Cc6634C0532925a3b844Bc9e7595f0C0C0
                                           ^^^^
                                    These bits = 0xC0
```

The last byte (`0xC0`) encodes:
- Bit 7 (0x80): beforeSwap enabled
- Bit 6 (0x40): afterSwap enabled

## Troubleshooting

**Mining takes too long / fails:**
- The script tries 160,444 salts. For certain flag combinations, valid addresses are rare.
- Consider using a dedicated mining script that runs longer or in parallel.

**HookAddressNotValid error:**
- Verify the salt was mined for the exact same constructor arguments.
- Ensure you're using the same deployer address in mining and deployment.
- Check that `getHookPermissions()` returns the flags you mined for.

**Address mismatch:**
- Constructor arguments must be identical between mining and deployment.
- Salt must be used exactly as mined.
- Ensure using the same Solidity version and compiler settings.

## References

- [Uniswap V4 Hooks.sol](https://github.com/Uniswap/v4-core/blob/main/src/libraries/Hooks.sol)
- [HookMiner.sol](https://github.com/Uniswap/v4-periphery/blob/main/src/utils/HookMiner.sol)
- [CREATE2 Deployer](https://github.com/pcaversaccio/create2deployer)
