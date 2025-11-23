# Mainnet Deployment Plan - Natural Gas Disruption Hook

**Strategy:** Full mainnet deployment with test tokens for zero liquidity risk

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                  FLARE MAINNET                               │
│  Chain ID: 14                                               │
│  RPC: https://flare-api.flare.network/ext/C/rpc            │
│                                                             │
│  ├── DisruptionOracle                                      │
│  │   ├── FDC Integration (EIA API verification)           │
│  │   ├── LayerZero V2 Endpoint: 0x1a44076...              │
│  │   └── EID: 30295                                        │
│  │                                                          │
│  └── sendPriceUpdate() →                                   │
│      ├── Encodes: (basePrice, timestamp)                   │
│      └── Sends via LayerZero to Base Mainnet              │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ LayerZero V2 Bridge
                           │ EID: 30295 → 30184
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   BASE MAINNET                               │
│  Chain ID: 8453                                             │
│  RPC: https://mainnet.base.org                              │
│                                                             │
│  ├── OracleReceiver (receives LayerZero messages)         │
│  │   └── Updates local oracle state                        │
│  │                                                          │
│  ├── NatGasToken (ERC20)                                   │
│  │   ├── Symbol: NATGAS                                    │
│  │   ├── Decimals: 18                                      │
│  │   └── Mintable for testing (NO REAL VALUE)             │
│  │                                                          │
│  ├── MockUSDC (ERC20)                                      │
│  │   ├── Symbol: USDC (but it's fake)                     │
│  │   ├── Decimals: 6                                       │
│  │   └── Faucet enabled (NO REAL VALUE)                   │
│  │                                                          │
│  ├── NatGasDisruptionHook (CREATE2 deployed)              │
│  │   ├── Address: 0x...00C0 (valid V4 address)            │
│  │   ├── Reads from OracleReceiver                        │
│  │   ├── beforeSwap: Dynamic fees (0.01% - 10%)           │
│  │   └── afterSwap: Bonus payments (up to 5%)             │
│  │                                                          │
│  └── Uniswap V4 Pool                                       │
│      ├── PoolManager: 0x498581ff718922c3f8e6a244956af099b2652b2b │
│      ├── Pair: NATGAS/MockUSDC                             │
│      ├── Hook: NatGasDisruptionHook                        │
│      ├── Initial Liquidity: Test tokens (NO REAL VALUE)    │
│      └── Fee: Dynamic via hook                             │
└─────────────────────────────────────────────────────────────┘
```

## Cost Estimate

### Deployment Costs
| Network | Contract | Gas Cost | USD Cost (Est) |
|---------|----------|----------|----------------|
| Flare Mainnet | DisruptionOracle | ~1M gas | ~$0.10 FLR |
| Base Mainnet | MockUSDC | ~1M gas | ~$0.05 ETH |
| Base Mainnet | NatGasToken | ~1M gas | ~$0.05 ETH |
| Base Mainnet | OracleReceiver | ~500k gas | ~$0.03 ETH |
| Base Mainnet | Hook (CREATE2) | ~3M gas | ~$0.15 ETH |
| Base Mainnet | Pool Init | ~500k gas | ~$0.03 ETH |
| Base Mainnet | Add Liquidity | ~300k gas | ~$0.02 ETH |

**Total Deployment:** ~$0.10 FLR + ~$0.33 ETH = **~$0.43 USD**

### Operational Costs
| Operation | Cost | Frequency |
|-----------|------|-----------|
| LayerZero bridge message | ~$0.50 | Per price update |
| FDC proof submission | Gas only | Per oracle update |
| Test swaps | ~$0.02 ETH | Per swap demo |

**Total for Demo:** ~$1-2 USD including test swaps

## Why This Works

### Zero Real Value at Risk
- NATGAS token is our custom ERC20 (worthless)
- MockUSDC is our custom ERC20 (not real USDC)
- Pool liquidity is 100% test tokens
- No real assets can be lost

### Real Infrastructure
- ✅ Real Flare Mainnet FDC verification
- ✅ Real LayerZero V2 cross-chain messaging
- ✅ Real Uniswap V4 PoolManager on Base
- ✅ Real hook integration with proper CREATE2 address
- ✅ Real on-chain execution

### Hackathon Perfect
- Judges see production-grade architecture
- No testnet limitations or downtime
- Impressive cross-chain integration
- Safe demo (can't lose real money)

## Deployment Sequence

### Phase 1: Flare Mainnet (10 minutes)

**1. Get FLR tokens**
```bash
# Buy FLR from exchange OR use faucet
# Send to your wallet: 0x9c760302031d1122b214c5869E526bFD57f04cF1
# Need: ~5 FLR for deployment (~$0.50)
```

**2. Deploy DisruptionOracle**
```bash
cd /Users/bharper/Documents/Code/ETHGlobalBuenosAires25/packages/contracts

# Update .env
export FLARE_MAINNET_RPC=https://flare-api.flare.network/ext/C/rpc
export PRIVATE_KEY=0x...

# Deploy
forge script script/DeployFlareMainnet.s.sol \
  --rpc-url $FLARE_MAINNET_RPC \
  --broadcast \
  --verify

# Save deployed address
export ORACLE_FLARE=0x...
```

**3. Configure LayerZero**
```bash
# LayerZero V2 endpoint on Flare Mainnet
export LZ_ENDPOINT_FLARE=0x1a44076050125825900e736c501f859c50fE728c
export BASE_EID=30184  # Base Mainnet endpoint ID

# Set LayerZero config on oracle
cast send $ORACLE_FLARE \
  "setLayerZeroConfig(address,uint32,address)" \
  $LZ_ENDPOINT_FLARE \
  $BASE_EID \
  0x0000000000000000000000000000000000000000 \  # Will update after Base deployment
  --rpc-url $FLARE_MAINNET_RPC \
  --private-key $PRIVATE_KEY
```

### Phase 2: Base Mainnet (25 minutes)

**1. Get ETH on Base**
```bash
# Bridge ETH to Base Mainnet
# OR buy on exchange and withdraw to Base
# Need: ~0.02 ETH for deployment (~$50-100 depending on ETH price)
```

**2. Deploy Tokens**
```bash
export BASE_MAINNET_RPC=https://mainnet.base.org

# Deploy MockUSDC and NatGasToken
forge script script/DeployTokensBase.s.sol \
  --rpc-url $BASE_MAINNET_RPC \
  --broadcast \
  --verify

export MOCK_USDC=0x...
export NATGAS_TOKEN=0x...
```

**3. Deploy OracleReceiver**
```bash
# This contract receives LayerZero messages from Flare
export LZ_ENDPOINT_BASE=0x1a44076050125825900e736c501f859c50fE728c
export FLARE_EID=30295

forge script script/DeployOracleReceiver.s.sol \
  --rpc-url $BASE_MAINNET_RPC \
  --broadcast \
  --verify

export ORACLE_RECEIVER=0x...

# Update Flare oracle with receiver address
cast send $ORACLE_FLARE \
  "setLayerZeroConfig(address,uint32,address)" \
  $LZ_ENDPOINT_FLARE \
  $BASE_EID \
  $ORACLE_RECEIVER \
  --rpc-url $FLARE_MAINNET_RPC \
  --private-key $PRIVATE_KEY
```

**4. Mine CREATE2 Salt**
```bash
export POOL_MANAGER=0x498581ff718922c3f8e6a244956af099b2652b2b

forge script script/MineHookSalt.s.sol \
  --rpc-url $BASE_MAINNET_RPC

# Output: HOOK_SALT=0x...
export HOOK_SALT=0x...
```

**5. Deploy Hook**
```bash
forge script script/DeployHookCREATE2.s.sol \
  --rpc-url $BASE_MAINNET_RPC \
  --broadcast \
  --verify

export HOOK_ADDRESS=0x...
```

**6. Initialize Pool**
```bash
forge script script/InitializePool.s.sol \
  --rpc-url $BASE_MAINNET_RPC \
  --broadcast

# Pool Key components:
# - currency0: NATGAS_TOKEN
# - currency1: MOCK_USDC
# - fee: 0 (dynamic via hook)
# - tickSpacing: 60
# - hooks: HOOK_ADDRESS
```

**7. Add Liquidity**
```bash
# Mint test tokens to yourself
cast send $NATGAS_TOKEN "mint(address,uint256)" \
  $YOUR_ADDRESS \
  1000000000000000000000 \  # 1000 NATGAS
  --rpc-url $BASE_MAINNET_RPC \
  --private-key $PRIVATE_KEY

cast send $MOCK_USDC "mint(address,uint256)" \
  $YOUR_ADDRESS \
  1000000000 \  # 1000 MockUSDC (6 decimals)
  --rpc-url $BASE_MAINNET_RPC \
  --private-key $PRIVATE_KEY

# Add liquidity to pool
forge script script/AddLiquidity.s.sol \
  --rpc-url $BASE_MAINNET_RPC \
  --broadcast
```

### Phase 3: Test Cross-Chain Bridge (5 minutes)

**1. Send Price Update from Flare**
```bash
# Update oracle price on Flare (via FDC or manual)
cast send $ORACLE_FLARE \
  "updateBasePrice(uint256)" \
  3710000 \  # $3.71 from EIA
  --rpc-url $FLARE_MAINNET_RPC \
  --private-key $PRIVATE_KEY

# Bridge price to Base via LayerZero
cast send $ORACLE_FLARE \
  "sendPriceUpdate()" \
  --value 0.01ether \  # LayerZero fee
  --rpc-url $FLARE_MAINNET_RPC \
  --private-key $PRIVATE_KEY

# Wait ~1-2 minutes for LayerZero delivery

# Check price on Base
cast call $ORACLE_RECEIVER \
  "getTheoreticalPrice()" \
  --rpc-url $BASE_MAINNET_RPC
```

### Phase 4: Frontend Integration (30 minutes)

**1. Update wagmi config**
```typescript
// packages/frontend/config/wagmi.ts
import { base } from 'wagmi/chains';

export const config = createConfig({
  chains: [base],  // Base Mainnet
  transports: {
    [base.id]: http('https://mainnet.base.org'),
  },
});
```

**2. Add contract addresses**
```typescript
// packages/frontend/config/contracts.ts
export const CONTRACTS = {
  oracleReceiver: '0x...',  // From Base deployment
  natgas: '0x...',
  mockUsdc: '0x...',
  hook: '0x...',
  poolManager: '0x498581ff718922c3f8e6a244956af099b2652b2b',
};
```

**3. Implement swap functionality**
```typescript
// Remove sliders, read real data
const { data: oraclePrice } = useReadContract({
  address: CONTRACTS.oracleReceiver,
  abi: oracleReceiverABI,
  functionName: 'getTheoreticalPrice',
});

const { data: poolPrice } = useReadContract({
  address: CONTRACTS.poolManager,
  abi: poolManagerABI,
  functionName: 'getPoolPrice',
  args: [poolKey],
});

// Execute real swaps via V4
const { writeContract } = useWriteContract();

const executeSwap = () => {
  writeContract({
    address: CONTRACTS.poolManager,
    abi: poolManagerABI,
    functionName: 'swap',
    args: [poolKey, swapParams],
  });
};
```

## Environment Variables

Add to `.env`:
```bash
# Flare Mainnet
FLARE_MAINNET_RPC=https://flare-api.flare.network/ext/C/rpc
FLARE_LZ_ENDPOINT=0x1a44076050125825900e736c501f859c50fE728c
FLARE_EID=30295

# Base Mainnet
BASE_MAINNET_RPC=https://mainnet.base.org
BASE_LZ_ENDPOINT=0x1a44076050125825900e736c501f859c50fE728c
BASE_EID=30184
BASE_POOL_MANAGER=0x498581ff718922c3f8e6a244956af099b2652b2b

# Deployed Contracts (fill after deployment)
ORACLE_FLARE=
ORACLE_RECEIVER_BASE=
NATGAS_TOKEN_BASE=
MOCK_USDC_BASE=
HOOK_BASE=
```

## Security Notes

### Safe for Demo
- ✅ Test tokens have no real value
- ✅ No real USDC in the pool
- ✅ Hook treasury can only hold test tokens
- ✅ Worst case: waste some gas fees

### Production Considerations
If this were production:
- Use real USDC (Circle's official token)
- Add extensive access controls
- Implement emergency pause
- Add withdrawal mechanisms
- Extensive auditing required

## Demo Flow

### For Hackathon Judges

**1. Show FDC Integration (Flare Mainnet)**
- Navigate to oracle on Flare explorer
- Show `updateBasePrice()` transaction with FDC proof
- Explain decentralized price verification

**2. Show LayerZero Bridge**
- Call `sendPriceUpdate()` on Flare
- Show LayerZero explorer tracking message
- Show price updated on Base within minutes

**3. Show V4 Integration (Base Mainnet)**
- Open frontend connected to Base Mainnet
- Show oracle price (from Flare, via LayerZero)
- Show pool price (from V4)
- Execute swap demonstrating:
  - High fees for misaligned trades
  - Bonuses for aligned trades
  - Real balance updates

**4. Show Hook Mechanics**
- Pool > Oracle: Sellers get bonuses
- Pool < Oracle: Buyers get bonuses
- Treasury accumulation from misaligned traders

## Scripts to Create

Need to create these deployment scripts:
- `script/DeployFlareMainnet.s.sol`
- `script/DeployTokensBase.s.sol`
- `script/DeployOracleReceiver.s.sol`
- `script/InitializePool.s.sol` (update for mainnet)
- `script/AddLiquidity.s.sol` (update for mainnet)

## Next Steps

1. **Get tokens:**
   - ~5 FLR for Flare Mainnet (~$0.50)
   - ~0.02 ETH for Base Mainnet (~$50-100)

2. **I'll create all deployment scripts**

3. **Deploy in sequence** (Flare → Base → Bridge → Pool)

4. **Test cross-chain price updates**

5. **Connect frontend**

6. **Prepare demo presentation**

---

**Ready to start? Let me know when you have the mainnet tokens and I'll begin creating the deployment scripts!**
