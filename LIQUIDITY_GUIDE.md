# How to Add Liquidity to Uniswap V4 Pool

## Pool Details

- **Pool ID:** `0x4e5e918bd31b3ab25ac6b401452b635771c15f30fa6e4cdbb4838cc61ee06805`
- **Pool Manager:** `0x498581fF718922c3f8e6A244956aF099B2652b2b`
- **Position Manager:** `0x7c5f5a4bbd8fd63184577525326123b519429bdc`
- **Currency0 (NATGAS):** `0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD` (18 decimals)
- **Currency1 (MockUSDC):** `0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a` (6 decimals)
- **Hook:** `0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0`
- **Fee Tier:** 0 (dynamic via hook)
- **Tick Spacing:** 60

---

## Option 1: Uniswap V4 SDK (Recommended)

### Installation

```bash
npm install @uniswap/v4-sdk viem
```

### Code Example

```typescript
import { Position, Pool } from '@uniswap/v4-sdk';
import { Token } from '@uniswap/sdk-core';
import { createWalletClient, http, parseUnits } from 'viem';
import { base } from 'viem/chains';
import { privateKeyToAccount } from 'viem/accounts';

const NATGAS_TOKEN = new Token(
  8453, // Base chain ID
  '0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD',
  18,
  'NATGAS',
  'Natural Gas Token'
);

const USDC_TOKEN = new Token(
  8453,
  '0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a',
  6,
  'USDC',
  'Mock USDC'
);

// Create position for full range liquidity
const position = Position.fromAmounts({
  pool: /* your pool instance */,
  tickLower: -887220, // Min tick for tick spacing 60
  tickUpper: 887220,  // Max tick for tick spacing 60
  amount0: parseUnits('10000', 18), // 10,000 NATGAS
  amount1: parseUnits('10000', 6),  // 10,000 USDC
  useFullPrecision: true,
});

// Then call PositionManager.mint() with position parameters
```

**Full Guide:** https://docs.uniswap.org/sdk/v4/guides/liquidity/position-minting

---

## Option 2: Direct Contract Interaction (Advanced)

### Step 1: Approve Tokens

```bash
cd packages/contracts
source .env

# Approve NATGAS to PositionManager
~/.foundry/bin/cast send 0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD \
  "approve(address,uint256)" \
  0x7c5f5a4bbd8fd63184577525326123b519429bdc \
  10000000000000000000000 \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY

# Approve USDC to PositionManager
~/.foundry/bin/cast send 0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a \
  "approve(address,uint256)" \
  0x7c5f5a4bbd8fd63184577525326123b519429bdc \
  10000000000 \
  --rpc-url https://mainnet.base.org \
  --private-key $PRIVATE_KEY
```

### Step 2: Call PositionManager.mint()

You need to encode the mint call with proper parameters. The PositionManager expects:

```solidity
struct MintParams {
    PoolKey poolKey;
    int24 tickLower;
    int24 tickUpper;
    uint256 liquidity;
    uint256 amount0Max;
    uint256 amount1Max;
    address recipient;
    bytes hookData;
}
```

**Issue:** Calculating `liquidity` requires the V4 SDK's SqrtPriceMath library. It's not a simple conversion from token amounts.

---

## Option 3: Use Uniswap Interface (When Available)

Uniswap V4 interface might not support custom hooks yet, but you can check:
- https://app.uniswap.org/pools

---

## Why Is This Complex?

Uniswap V4 uses **concentrated liquidity**:

1. **Liquidity ≠ Token Amounts**
   - The `liquidity` parameter is calculated using: `L = sqrt(x * y)`
   - Depends on current pool price and tick range
   - Requires complex fixed-point math (Q64.96)

2. **Tick Math**
   - Prices are stored as ticks: `price = 1.0001^tick`
   - Valid tick range: -887220 to 887220 (for tick spacing 60)
   - Each tick represents ~0.01% price movement

3. **Settlement**
   - V4 uses "flash accounting" - deltas must be settled in callback
   - Can't just transfer tokens directly

---

## Recommended Approach for Your Demo

### Quick Test with Minimal Liquidity

Use the Uniswap V4 SDK in a Node.js script:

```bash
# Install dependencies
npm install --save @uniswap/v4-sdk @uniswap/sdk-core viem

# Create add-liquidity.ts
```

```typescript
import { Position } from '@uniswap/v4-sdk';
import { Token, CurrencyAmount } from '@uniswap/sdk-core';

// Define your pool and position
// Use Position.fromAmounts() to calculate liquidity
// Call PositionManager.mint() via viem

// Full example:
// https://docs.uniswap.org/sdk/v4/guides/liquidity/position-minting
```

### Alternative: Frontend Integration

Add a "Add Liquidity" button to your frontend:

```typescript
// In your Next.js frontend
import { useWriteContract } from 'wagmi';

const { writeContract } = useWriteContract();

async function addLiquidity() {
  // Use @uniswap/v4-sdk to calculate parameters
  // Call PositionManager.mint() via wagmi
}
```

---

## Quick Win: Minimal Liquidity for Testing

If you just want to enable swaps for your demo:

1. **Install V4 SDK**: `npm install @uniswap/v4-sdk @uniswap/sdk-core`
2. **Run script**: Use `add-liquidity-sdk.js` (provided)
3. **Add $100 of each token**: Enough to test the mechanism
4. **Full range**: tickLower = -887220, tickUpper = 887220

---

## Resources

- **Uniswap V4 SDK Docs**: https://docs.uniswap.org/sdk/v4/guides/liquidity/position-minting
- **Position Manager Guide**: https://docs.uniswap.org/contracts/v4/guides/position-manager
- **PositionManager Contract**: https://basescan.org/address/0x7c5f5a4bbd8fd63184577525326123b519429bdc
- **V4 Periphery Source**: https://github.com/Uniswap/v4-periphery

---

## Summary

**Easiest:** Use @uniswap/v4-sdk to calculate liquidity and call PositionManager.mint()

**Manual:** Requires understanding SqrtPriceMath, tick calculations, and flash accounting

**For Demo:** Add minimal liquidity ($100-$1000 of each token) via SDK to enable testing

The complexity is why we documented "Pool needs liquidity via SDK" - it's not a limitation of your deployment, it's how V4 works! 🚀
