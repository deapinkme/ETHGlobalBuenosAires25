# FDC Integration - Quick Reference Card

**One-page reference for common FDC operations**

---

## Environment Setup

```bash
cp .env.example .env
# Fill in:
# - EIA_API_KEY (get from https://www.eia.gov/opendata/register.php)
# - PRIVATE_KEY (your wallet)
# - DISRUPTION_ORACLE_ADDRESS (after deployment)
```

---

## Commands

### Test EIA API
```bash
npx ts-node scripts/fdc-integration/test-eia-api.ts
```

### Deploy to Coston2
```bash
./deploy-coston2.sh
```
**Or manually:**
```bash
forge script script/DeployCoston2.s.sol:DeployCoston2 \
  --rpc-url $COSTON2_RPC \
  --broadcast
```

### Update Oracle Price
```bash
export NEW_PRICE=4500000  # $4.50 with 6 decimals
./update-oracle-price.sh
```
**Or manually:**
```bash
forge script script/UpdateOraclePrice.s.sol:UpdateOraclePrice \
  --rpc-url $COSTON2_RPC \
  --broadcast
```

### View Oracle State
```bash
cast call $DISRUPTION_ORACLE_ADDRESS \
  "basePrice()(uint256)" \
  --rpc-url $COSTON2_RPC
```

---

## File Locations

| File | Purpose |
|------|---------|
| `FDC_SETUP_SUMMARY.md` | Complete setup overview |
| `FDC_QUICKSTART.md` | Step-by-step getting started |
| `scripts/fdc-integration/README.md` | Full FDC integration guide |
| `scripts/fdc-integration/eia-api-setup.md` | EIA API details |
| `scripts/fdc-integration/test-eia-api.ts` | Test EIA connection |
| `scripts/fdc-integration/submit-fdc-proof.ts` | FDC proof template |
| `scripts/fdc-integration/fdc-attestation-request.json` | Attestation request format |
| `script/DeployCoston2.s.sol` | Deploy to Coston2 |
| `script/UpdateOraclePrice.s.sol` | Manual price update |

---

## Price Format

**Always use 6 decimals (USDC format):**

| Human Price | Contract Value |
|-------------|----------------|
| $3.93 | 3930000 |
| $4.50 | 4500000 |
| $10.00 | 10000000 |
| $0.50 | 500000 |

**Conversion:**
```typescript
const contractValue = Math.floor(humanPrice * 1_000_000);
const humanPrice = contractValue / 1_000_000;
```

---

## Contract Functions

### Read Functions
```solidity
function basePrice() external view returns (uint256)
function getTheoreticalPrice() external view returns (uint256)
function currentDisruption() external view returns (Disruption memory)
function owner() external view returns (address)
```

### Owner Functions
```solidity
function updateBasePrice(uint256 newBasePrice) external onlyOwner
function clearDisruption() external onlyOwner
function transferOwnership(address newOwner) external onlyOwner
```

### FDC Functions
```solidity
function updateBasePriceWithFDC(IWeb2Json.Proof calldata proof) external
function setWeatherDisruptionWithFDC(IWeb2Json.Proof calldata proof) external
```

---

## Common Workflows

### Initial Setup
1. Get EIA API key
2. Test API: `npx ts-node scripts/fdc-integration/test-eia-api.ts`
3. Deploy: `./deploy-coston2.sh`
4. Test update: `./update-oracle-price.sh`

### Daily Price Update (Manual)
1. Get latest price from EIA
2. Convert to 6 decimals
3. Set `NEW_PRICE` in .env
4. Run `./update-oracle-price.sh`

### FDC Proof Submission (Future)
1. Create attestation request
2. Submit to FDC verifier
3. Wait for proof
4. Call `updateBasePriceWithFDC(proof)`

---

## Network Info

### Coston2 Testnet
- **RPC**: https://coston2-api.flare.network/ext/C/rpc
- **Chain ID**: 114
- **Explorer**: https://coston2-explorer.flare.network/
- **Faucet**: https://faucet.flare.network/

### FDC Verifier
- **URL**: https://fdc-verifiers-testnet.flare.network/
- **Docs**: https://dev.flare.network/fdc/

---

## Troubleshooting

| Error | Solution |
|-------|----------|
| "EIA_API_KEY not set" | Add to .env |
| "Insufficient funds" | Get Coston2 CFLR from faucet |
| "Invalid FDC proof" | Check proof age < 1 hour |
| "Data too old" | Submit fresh attestation |
| "No data returned" | Markets closed (weekend) |

**Full troubleshooting**: See `scripts/fdc-integration/README.md`

---

## Links

- **EIA Registration**: https://www.eia.gov/opendata/register.php
- **Coston2 Faucet**: https://faucet.flare.network/
- **FDC Docs**: https://dev.flare.network/fdc/
- **Flare Discord**: https://discord.gg/flarenetwork

---

## Contract Validation Rules

**Price Data:**
- ✓ price > 0
- ✓ timestamp ≤ block.timestamp
- ✓ timestamp > block.timestamp - 1 hour

**Weather Data:**
- ✓ severity: 0-10
- ✓ timestamp ≤ block.timestamp
- ✓ timestamp > block.timestamp - 1 hour

---

## Status

- ✅ Infrastructure complete
- ✅ Manual updates working
- ⏳ FDC attestation client setup pending

**For full details, see `FDC_SETUP_SUMMARY.md`**
