# Cross-Chain Architecture: Natural Gas Disruption Hook

## Current Deployment Status

### What's Deployed

```
┌─────────────────────────────────────────────────────────────┐
│ Coston2 Testnet (Flare)                                     │
│ Chain ID: 114                                                │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ✅ DisruptionOracle                                         │
│     Address: 0x16AAf8F3CDfa890b2BeD67c33b4c39beaE9866aa     │
│     - FDC-powered price updates                             │
│     - Natural gas price tracking                            │
│     - Weather disruption tracking                           │
│                                                              │
│  ❌ LayerZero Endpoint V2                                    │
│     Status: NOT DEPLOYED                                     │
│     Blocker: Coston2 not yet supported by LayerZero V2      │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### What Needs to be Deployed

```
┌─────────────────────────────────────────────────────────────┐
│ Base Sepolia Testnet                                        │
│ Chain ID: 84532                                              │
│ LayerZero EID: 40245                                        │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ✅ Uniswap V4 PoolManager                                   │
│     Address: 0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408     │
│                                                              │
│  ✅ LayerZero Endpoint V2                                    │
│     Address: 0x6EDCE65403992e310A62460808c4b910D972f10f     │
│                                                              │
│  ⏳ NatGasToken (ERC20)                                      │
│     Status: TO BE DEPLOYED                                   │
│                                                              │
│  ⏳ MockUSDC (ERC20)                                         │
│     Status: TO BE DEPLOYED                                   │
│                                                              │
│  ⏳ DisruptionOracle (simplified)                            │
│     Status: TO BE DEPLOYED                                   │
│     Note: Cannot use FDC on Base Sepolia                    │
│                                                              │
│  ⏳ NatGasDisruptionHook                                     │
│     Status: TO BE DEPLOYED                                   │
│     Dependencies: PoolManager, Oracle, Tokens               │
│                                                              │
│  ⏳ NATGAS/USDC Pool                                         │
│     Status: TO BE INITIALIZED                                │
│     Hook: NatGasDisruptionHook                              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Architecture Options

### Option 1: Base Sepolia Only (RECOMMENDED FOR HACKATHON)

**Simplest path to working demo**

```
┌──────────────────────────────────────────────────────┐
│ Base Sepolia                                         │
├──────────────────────────────────────────────────────┤
│                                                       │
│  DisruptionOracle (Simplified)                       │
│  ├─ Manual price updates via owner                  │
│  ├─ No FDC integration                               │
│  └─ updateBasePrice(uint256 price) function         │
│                                                       │
│  NatGasDisruptionHook                                │
│  ├─ Reads from local oracle                         │
│  ├─ Calculates dynamic fees                         │
│  ├─ Pays bonuses from treasury                      │
│  └─ Attached to NATGAS/USDC pool                    │
│                                                       │
│  Uniswap V4 Pool                                     │
│  └─ NATGAS/USDC with hook                           │
│                                                       │
└──────────────────────────────────────────────────────┘
```

**Pros:**
- Fastest to implement
- No cross-chain complexity
- Full Uniswap V4 functionality
- Can demo core mechanism

**Cons:**
- Manual oracle updates
- No FDC showcase
- Not utilizing Coston2 deployment

**Timeline:** 1-2 days

---

### Option 2: Dual Deployment with Manual Bridge

**Showcase both FDC and V4**

```
┌─────────────────────────┐         ┌─────────────────────────┐
│ Coston2                 │         │ Base Sepolia            │
├─────────────────────────┤         ├─────────────────────────┤
│                         │         │                         │
│  DisruptionOracle       │         │  DisruptionOracle       │
│  (FDC-powered)          │         │  (Manual updates)       │
│  └─ Real gas prices ✅  │         │  └─ Owner-updated       │
│                         │         │                         │
│                         │  Manual │  NatGasDisruptionHook   │
│                         │  Update │  └─ V4 Pool Manager     │
│                         │  ──────>│                         │
│                         │         │  NATGAS/USDC Pool       │
│                         │         │  └─ Live trading ✅     │
│                         │         │                         │
└─────────────────────────┘         └─────────────────────────┘
```

**Implementation:**
1. Keep Coston2 oracle for FDC demo
2. Deploy separate oracle on Base Sepolia
3. Manually sync prices (script/bot)
4. Run hook on Base Sepolia only

**Pros:**
- Demonstrates FDC integration
- Demonstrates V4 hook
- No LayerZero dependency

**Cons:**
- Requires manual syncing
- Two separate deployments
- Not truly cross-chain

**Timeline:** 2-3 days

---

### Option 3: Wait for Coston2 LayerZero Support

**True cross-chain architecture**

```
┌─────────────────────────┐         ┌─────────────────────────┐
│ Coston2                 │         │ Base Sepolia            │
├─────────────────────────┤         ├─────────────────────────┤
│                         │         │                         │
│  DisruptionOracle       │         │  OracleReceiver         │
│  (FDC-powered)          │         │  (LayerZero)            │
│  └─ Real gas prices     │         │  └─ Bridged prices      │
│                         │         │                         │
│  LayerZeroSender        │ LayerZ  │  NatGasDisruptionHook   │
│  └─ sendPriceUpdate()   │ ──────> │  └─ Reads from receiver │
│                         │         │                         │
│                         │         │  NATGAS/USDC Pool       │
│                         │         │  └─ Live trading        │
│                         │         │                         │
└─────────────────────────┘         └─────────────────────────┘
```

**Blockers:**
- LayerZero V2 not deployed on Coston2
- Unknown timeline for deployment

**Pros:**
- True cross-chain demo
- Full FDC + LayerZero showcase
- Production-like architecture

**Cons:**
- Blocked on external deployment
- High complexity
- Unknown timeline

**Timeline:** Unknown (requires LayerZero team)

---

### Option 4: Flare Mainnet Bridge (EXPENSIVE)

**Use Flare mainnet instead of Coston2**

```
┌─────────────────────────┐         ┌─────────────────────────┐
│ Flare Mainnet           │         │ Base Sepolia            │
│ LayerZero EID: 30295    │         │ LayerZero EID: 40245    │
├─────────────────────────┤         ├─────────────────────────┤
│                         │         │                         │
│  DisruptionOracle       │         │  OracleReceiver         │
│  (FDC-powered)          │         │  (LayerZero)            │
│  └─ Real prices ✅      │         │  └─ Bridged prices ✅   │
│                         │         │                         │
│  LayerZeroSender        │ LayerZ  │  NatGasDisruptionHook   │
│  Address: 0x1a44...     │ ──────> │  Address: 0x6EDC...     │
│                         │         │                         │
└─────────────────────────┘         └─────────────────────────┘
```

**Pros:**
- Working LayerZero integration
- Real FDC on mainnet
- Production-ready architecture

**Cons:**
- Mainnet tokens required
- Gas costs
- Mixing mainnet + testnet

**Timeline:** 2-4 days + token costs

---

## Recommended Path: Hybrid Approach

### Phase 1: Base Sepolia Demo (This Weekend)
```
Base Sepolia:
├── Deploy tokens (NATGAS, MockUSDC)
├── Deploy simplified oracle (manual updates)
├── Deploy NatGasDisruptionHook
├── Initialize V4 pool
└── Add liquidity + test swaps
```

**Goal**: Working V4 hook demo with manual oracle

### Phase 2: Add FDC Showcase (Parallel)
```
Coston2:
└── Keep existing DisruptionOracle deployment
    └── Create frontend demo showing FDC price updates
```

**Goal**: Demonstrate FDC integration separately

### Phase 3: Bridge Integration (If Time Permits)
```
Option A: Manual syncing script
Option B: Wait for Coston2 LayerZero
Option C: Flare mainnet bridge
```

**Goal**: Connect the two systems

---

## Implementation Roadmap

### Immediate (Day 1)
- [x] Find Uniswap V4 deployment addresses
- [x] Find LayerZero deployment addresses
- [ ] Deploy tokens on Base Sepolia
- [ ] Deploy simplified oracle on Base Sepolia
- [ ] Write NatGasDisruptionHook contract

### Short-term (Day 2-3)
- [ ] Deploy hook with CREATE2 (proper prefix)
- [ ] Initialize V4 pool with hook
- [ ] Add initial liquidity
- [ ] Test swap scenarios
- [ ] Build basic frontend

### Medium-term (Day 4-5)
- [ ] Contact LayerZero about Coston2 support
- [ ] OR implement manual sync script
- [ ] OR deploy on Flare mainnet
- [ ] Enhance frontend with dual-chain view

### Optional (If Time)
- [ ] Full LayerZero bridge integration
- [ ] Advanced frontend features
- [ ] Comprehensive testing suite

---

## Key Addresses Reference

### Base Sepolia (84532)
```
PoolManager:     0x05E73354cFDd6745C338b50BcFDfA3Aa6fA03408
LayerZero:       0x6EDCE65403992e310A62460808c4b910D972f10f
LayerZero EID:   40245
```

### Ethereum Sepolia (11155111)
```
PoolManager:     0xE03A1074c86CFeDd5C142C4F04F1a1536e203543
LayerZero:       0x6EDCE65403992e310A62460808c4b910D972f10f
LayerZero EID:   40161
```

### Coston2 (114)
```
DisruptionOracle: 0x16AAf8F3CDfa890b2BeD67c33b4c39beaE9866aa
LayerZero:        NOT DEPLOYED
```

### Flare Mainnet (14)
```
LayerZero:       0x1a44076050125825900e736c501f859c50fE728c
LayerZero EID:   30295
```

---

## Decision Matrix

| Option | Complexity | Timeline | FDC Demo | V4 Demo | Cross-Chain | Cost |
|--------|-----------|----------|----------|---------|-------------|------|
| Base Sepolia Only | Low | 1-2 days | ❌ | ✅ | ❌ | Free |
| Dual + Manual Sync | Medium | 2-3 days | ✅ | ✅ | Manual | Free |
| Wait for Coston2 | High | Unknown | ✅ | ✅ | ✅ | Free |
| Flare Mainnet | High | 2-4 days | ✅ | ✅ | ✅ | $$$ |

**Recommendation**: Start with **Base Sepolia Only**, then add **Dual + Manual Sync** if time permits.

---

## Next Actions

1. ✅ Document all deployment addresses
2. ✅ Analyze architecture options
3. ⏳ Deploy tokens on Base Sepolia
4. ⏳ Create simplified oracle contract
5. ⏳ Implement NatGasDisruptionHook
6. ⏳ Contact LayerZero team (parallel track)

**Question for Team**: Which architecture option should we pursue?

---

**Last Updated**: 2025-11-23
