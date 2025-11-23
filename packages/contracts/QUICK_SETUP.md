# Quick Setup Guide - ETHGlobal Hackathon

Get up and running in 5 minutes!

## 1. Get Your EIA API Key (2 minutes)

1. Go to: https://www.eia.gov/opendata/register.php
2. Fill in:
   - Your name
   - Your email
   - Organization: "ETHGlobal Hackathon Team"
3. Submit form
4. Check your email for the API key

## 2. Update .env File

Open `packages/contracts/.env` and paste your API key:

```bash
EIA_API_KEY=your_actual_key_here
```

## 3. Test the API

```bash
cd packages/contracts
npx ts-node scripts/fdc-integration/test-eia-api.ts
```

You should see current Henry Hub natural gas prices!

## 4. Add Your Wallet Private Key

For deployment:

```bash
# In packages/contracts/.env
PRIVATE_KEY=your_wallet_private_key
```

⚠️ **Note**: This is fine for hackathon testnets. Remove from repo after!

## 5. Compile Contracts

```bash
npx hardhat compile
```

## 6. Deploy (Optional)

```bash
# Deploy to Coston2 (Flare testnet)
npx hardhat run scripts/deploy.ts --network coston2

# Or Base Sepolia
npx hardhat run scripts/deploy.ts --network baseSepolia
```

## That's It!

Your oracle is ready to fetch live natural gas prices from the EIA API and integrate with Flare FDC.

## Team Sharing

The `.env` file is committed to the repo for hackathon convenience. Everyone on the team can use the same API key!

---

**Questions?** Check:
- `scripts/fdc-integration/eia-api-setup.md` - Detailed EIA setup
- `API_SOURCES.md` - All API options
- `README.md` - Full project docs
