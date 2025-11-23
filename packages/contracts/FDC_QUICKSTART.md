# FDC Integration Quick Start

**Goal**: Get your DisruptionOracle updating with real Henry Hub prices via Flare Data Connector.

**Time Required**: 15-20 minutes

---

## Step 1: Get EIA API Key (2 minutes)

1. Visit: https://www.eia.gov/opendata/register.php
2. Fill out the form (name, email, organization)
3. Check your email for the API key
4. Add to `.env`:

```bash
echo "EIA_API_KEY=your_key_here" >> .env
```

---

## Step 2: Test API Connection (1 minute)

```bash
cd packages/contracts
npx ts-node scripts/fdc-integration/test-eia-api.ts
```

**Expected**: You should see current Henry Hub price formatted for the contract.

---

## Step 3: Get Coston2 Testnet Tokens (2 minutes)

1. Visit: https://faucet.flare.network/
2. Select "Coston2 Testnet"
3. Enter your wallet address
4. Request test CFLR

**Add to .env:**
```bash
echo "PRIVATE_KEY=your_private_key" >> .env
```

---

## Step 4: Deploy to Coston2 (2 minutes)

```bash
source .env

forge script script/DeployCoston2.s.sol:DeployCoston2 \
  --rpc-url $COSTON2_RPC \
  --broadcast
```

**Save the deployed address:**
```bash
echo "DISRUPTION_ORACLE_ADDRESS=0x..." >> .env
```

---

## Step 5: Test Manual Update (1 minute)

Before FDC integration, test the fallback manual update:

```bash
# Update to $4.50 (4500000 with 6 decimals)
export NEW_PRICE=4500000

forge script script/UpdateOraclePrice.s.sol:UpdateOraclePrice \
  --rpc-url $COSTON2_RPC \
  --broadcast
```

**Verify on Coston2 Explorer:**
- Visit: https://coston2-explorer.flare.network/
- Search for your oracle address
- Check `basePrice` value updated

---

## Step 6: FDC Integration (In Progress)

### Current Status

The infrastructure is ready:
- ✅ EIA API connection tested
- ✅ Oracle contract deployed
- ✅ Attestation request template created
- ⏳ FDC proof submission (needs Flare attestation client)

### What You Need

To complete FDC integration, you need to:

1. **Set up FDC Attestation Client**
   - Follow: https://dev.flare.network/fdc/guides/attestation-client
   - Install Flare's attestation submission tool

2. **Submit Attestation Request**
   - Use the template in `scripts/fdc-integration/fdc-attestation-request.json`
   - Replace `YOUR_API_KEY` with your EIA key
   - Submit to FDC verifier

3. **Retrieve Proof**
   - Wait for voting round completion
   - Query FDC for proof using attestation hash

4. **Update Contract**
   - Call `oracle.updateBasePriceWithFDC(proof)`
   - Verify price updated on-chain

### Temporary Workaround

Until FDC integration is complete, use manual updates:

```bash
# Fetch latest price
LATEST_PRICE=$(npx ts-node -e "
import { fetchHenryHubPrice } from './scripts/fdc-integration/test-eia-api.ts';
const data = await fetchHenryHubPrice();
console.log(Math.floor(parseFloat(data.response.data[0].value) * 1_000_000));
")

# Update oracle
export NEW_PRICE=$LATEST_PRICE
forge script script/UpdateOraclePrice.s.sol:UpdateOraclePrice \
  --rpc-url $COSTON2_RPC \
  --broadcast
```

---

## Current File Structure

```
packages/contracts/
├── script/
│   ├── DeployCoston2.s.sol          ✅ Deploy to Coston2
│   ├── UpdateOraclePrice.s.sol      ✅ Manual price update
│   └── Deploy.s.sol                    (existing)
├── scripts/fdc-integration/
│   ├── README.md                    ✅ Complete guide
│   ├── test-eia-api.ts             ✅ Test EIA API
│   ├── submit-fdc-proof.ts         ✅ Template (needs FDC client)
│   ├── fdc-attestation-request.json ✅ Request template
│   └── eia-api-setup.md            ✅ EIA setup guide
└── src/
    └── DisruptionOracle.sol         ✅ FDC-ready contract
```

---

## Testing Checklist

- [ ] EIA API key obtained
- [ ] EIA API tested successfully
- [ ] Coston2 testnet tokens received
- [ ] DisruptionOracle deployed to Coston2
- [ ] Manual price update tested
- [ ] Contract verified on Coston2 explorer
- [ ] FDC attestation client set up (pending)
- [ ] FDC proof submitted and retrieved (pending)
- [ ] `updateBasePriceWithFDC()` called successfully (pending)

---

## Next Steps

### For Development (Now)

Use manual updates while developing other components:
1. Hook implementation
2. Pool setup
3. Frontend integration

### For Production (Later)

Complete FDC integration:
1. Set up Flare attestation client
2. Automate attestation submissions
3. Handle proof retrieval and contract updates
4. Implement error handling and fallbacks

---

## Resources

- **Full Guide**: `scripts/fdc-integration/README.md`
- **EIA Setup**: `scripts/fdc-integration/eia-api-setup.md`
- **FDC Docs**: https://dev.flare.network/fdc/
- **EIA API**: https://www.eia.gov/opendata/documentation.php
- **Coston2 Explorer**: https://coston2-explorer.flare.network/

---

## Support

**Questions?**
- Check `scripts/fdc-integration/README.md` for detailed troubleshooting
- Visit Flare Discord: https://discord.gg/flarenetwork
- Open GitHub issue for bugs

---

**Status**: Infrastructure ready, FDC submission pending Flare attestation client setup.

**Estimated Completion**: 1-2 hours additional work for full FDC automation.
