# Example Valid Hook Address

## Understanding V4 Hook Addresses

In Uniswap V4, hook permissions are encoded in the contract address itself. The lowest 14 bits of the address determine which hook functions will be called.

## Required Flags for NatGasDisruptionHook

```solidity
uint160 BEFORE_SWAP_FLAG = 1 << 7;  // 0x80 (bit 7)
uint160 AFTER_SWAP_FLAG  = 1 << 6;  // 0x40 (bit 6)

// Combined: 0xC0 (binary: 11000000)
```

## Valid Address Format

### Example 1: Minimal Valid Address
```
0x00000000000000000000000000000000000000C0
                                          ^^
                                    Last byte = 0xC0
```

Binary breakdown of last 14 bits:
```
11 0000 0000 0000
^^
││
│└─ Bit 6: afterSwap = true
└── Bit 7: beforeSwap = true
```

### Example 2: Realistic Address
```
0x742d35Cc6634C0532925a3b844Bc9e7595f0C0C0
                                        ^^^^
                                  Low 2 bytes = 0xC0C0

Binary of 0xC0C0:
11 0000 1100 0000
^^
││
│└─ Bit 6: afterSwap = true
└── Bit 7: beforeSwap = true
```

Note: Only the lowest 14 bits matter. The `0xC0` pattern must appear in the masked bits.

### Example 3: From Test Deployment
When running tests, HookMiner finds addresses like:
```
Potential address: 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b0C0
                                                       ^^^^
                                                  Masked: 0x00C0
```

## Validation Code

```solidity
// Extract lowest 14 bits
uint160 addressBits = uint160(hookAddress);
uint160 mask = 0x3FFF; // 14 bits: 0011 1111 1111 1111
uint160 flags = addressBits & mask;

// For NatGasDisruptionHook, must equal 0xC0
require(flags == 0xC0, "Invalid hook address");

// Alternative: Check specific bits
require(addressBits & 0x80 != 0, "beforeSwap not enabled");
require(addressBits & 0x40 != 0, "afterSwap not enabled");
```

## How CREATE2 Finds Valid Addresses

```solidity
// Pseudo-code for mining process
for (uint256 salt = 0; salt < MAX_ITERATIONS; salt++) {
    address potential = computeCreate2Address(
        deployer,
        salt,
        creationCode
    );

    uint160 flags = uint160(potential) & 0x3FFF;

    if (flags == 0xC0) {
        // Found valid address!
        return (potential, salt);
    }
}
```

## Full Flag Mask Decoding

For any address, you can decode all 14 permission bits:

```
Bits 13-0:  0011 1111 1111 1111 (0x3FFF)

Bit 13: beforeInitialize
Bit 12: afterInitialize
Bit 11: beforeAddLiquidity
Bit 10: afterAddLiquidity
Bit  9: beforeRemoveLiquidity
Bit  8: afterRemoveLiquidity
Bit  7: beforeSwap              ← NatGasDisruptionHook
Bit  6: afterSwap               ← NatGasDisruptionHook
Bit  5: beforeDonate
Bit  4: afterDonate
Bit  3: beforeSwapReturnsDelta
Bit  2: afterSwapReturnsDelta
Bit  1: afterAddLiquidityReturnsDelta
Bit  0: afterRemoveLiquidityReturnsDelta
```

## Test Output Example

```bash
$ forge test --match-test test_GetHookPermissions -vvv

[PASS] test_GetHookPermissions()
Traces:
  Hook address: 0x...C0
  Permissions:
    beforeSwap: true   ✓
    afterSwap:  true   ✓
    (all others: false)
```

## Common Invalid Addresses

### Wrong Flags
```
0x0000000000000000000000000000000000000080  ❌ Only beforeSwap
0x0000000000000000000000000000000000000040  ❌ Only afterSwap
0x0000000000000000000000000000000000000000  ❌ No flags
0x00000000000000000000000000000000000001C0  ❌ Extra flags set
```

### Valid Addresses
```
0x00000000000000000000000000000000000000C0  ✓ Minimal
0xabc123...40C0                              ✓ Bits 6,7 set, bit 14 set
0xffffff...80C0                              ✓ Bits 6,7,15 set (high bits OK)
0x123456...0CC0                              ✓ Bits 6,7,10,11 set (extra OK if unused)
```

Wait - last one is WRONG! Let me correct:

```
0xabc123...40C0  ✓ (0x40C0 & 0x3FFF = 0x00C0)
0xffffff...80C0  ✓ (0x80C0 & 0x3FFF = 0x00C0)
0x123456...0CC0  ❌ (0x0CC0 & 0x3FFF = 0x0CC0 ≠ 0x00C0)
```

## Verification Script

```bash
# Set your hook address
export HOOK_ADDRESS=0x...

# Run validation script
forge script script/ValidateHookAddress.s.sol

# Output:
# Address flags:       0xC0
# Expected flags:      0xC0
# Address is valid:    true ✓
```

## Why This Matters

1. **Gas Efficiency**: No storage needed for permissions
2. **Immutability**: Permissions can't change after deployment
3. **Verification**: Anyone can verify permissions from address alone
4. **Security**: Prevents permission escalation attacks

## Mining Statistics

For `beforeSwap + afterSwap` (0xC0):
- Target: 1 in 16,384 addresses (14 bits = 2^14 possibilities)
- But we need specific 2 bits: ~1 in 192 addresses have ANY 2 bits set
- Expected iterations: ~100-500 on average
- Max iterations: 160,444

Most salt mining completes in under 1 second.
