# 🚀 QUICK START - 5 Minutes to Demo

## Already Done ✅
- All contracts deployed to Base + Flare mainnet
- Pool initialized with liquidity
- Hook proven working (see DEMO_READY.md)
- Frontend running

## Start Demo Now

### 1. Start Frontend (30 seconds)
```bash
cd packages/frontend
npm run dev
# Opens at http://localhost:3000
```

### 2. Open These Links in Browser
- **Hook Contract**: https://basescan.org/address/0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0
- **Hook Working**: https://basescan.org/tx/0x7a4883de27fc73d3ff7210355780e072d1c10981522a60a8823ae27593f7248c  
- **Liquidity Added**: https://basescan.org/tx/0xbdc800b53e0832e9b059eafb564fd151b74c8ce84931ed63f78a21b5ce968e8e
- **Oracle (Flare)**: https://flare-explorer.flare.network/address/0x347d6129294b522cA4Bb3E0c15dEFF7Ccc5a952c

### 3. Open Code
```bash
code src/NatGasDisruptionHook.sol
# Jump to line 100 - beforeSwap function
```

## 2-Minute Pitch

**"We built the first natural gas futures hook on Uniswap V4."**

1. **Problem** (20s): AMM pools diverge from real prices. Arbitrage is expensive.

2. **Solution** (40s): Hook reads oracle price. Misaligned traders pay HIGH fees. Fees fund bonuses. Aligned traders get paid MORE than market price to correct price.

3. **Proof** (30s): Show hook tx - point to `beforeSwap()` returning fee of 100 (0.01%). Show liquidity tx. Show oracle on Flare.

4. **Tech** (30s): Cross-chain oracle via LayerZero + FDC. CREATE2 hook deployment. Self-funding treasury. Production mainnet.

**Done!**

## Show This Transaction
https://basescan.org/tx/0x7a4883de27fc73d3ff7210355780e072d1c10981522a60a8823ae27593f7248c

**What to point out:**
- Hook's `beforeSwap()` was called
- Returned: `0x575e24b4, 0, 100`  
- Fee: 100 = 0.01% (aligned trader gets low fee)
- **This proves the hook works!**

## Key Numbers
- **2** production mainnets  
- **$0.50** total deployment cost
- **$3.71** current natural gas price (from oracle)
- **0.01% - 10%** dynamic fee range
- **Up to 5%** bonus for aligned traders

## If Something Breaks
Just show:
1. BaseScan tx with hook execution
2. Code explaining the mechanism  
3. Architecture diagram

**The hard part is done. You have a working product on mainnet.**
