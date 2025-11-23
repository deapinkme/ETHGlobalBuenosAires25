# Flare Data Connector (FDC) Integration Guide

Complete guide for integrating the Natural Gas Disruption Hook with Flare Data Connector to fetch real-world Henry Hub natural gas prices.

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [FDC Architecture](#fdc-architecture)
4. [Setup Instructions](#setup-instructions)
5. [Testing the Integration](#testing-the-integration)
6. [Deployment Workflow](#deployment-workflow)
7. [Troubleshooting](#troubleshooting)

---

## Overview

### What is FDC?

Flare Data Connector (FDC) is a decentralized oracle system that brings **verifiable off-chain data** onto the blockchain. Unlike traditional oracles, FDC:

- Verifies data cryptographically on-chain
- Supports arbitrary Web2 APIs
- Uses JQ transformations for flexible data extraction
- Provides Merkle proofs for data integrity

### Our Use Case

We use FDC to fetch **Henry Hub natural gas spot prices** from the U.S. Energy Information Administration (EIA) API and update our DisruptionOracle contract with verifiable price data.

**Data Flow:**
```
EIA API → FDC Verifier → Proof Generation → DisruptionOracle.updateBasePriceWithFDC()
```

---

## Quick Start

### Prerequisites

- Node.js 18+ and TypeScript
- Foundry (for Solidity deployment)
- EIA API key (free, get at https://www.eia.gov/opendata/register.php)
- Coston2 testnet wallet with some test CFLR

### 1. Get Your EIA API Key

```bash
# Visit https://www.eia.gov/opendata/register.php
# Receive key instantly via email
# Add to .env file:
echo "EIA_API_KEY=your_key_here" >> .env
```

### 2. Test EIA API Connection

```bash
cd packages/contracts
npx ts-node scripts/fdc-integration/test-eia-api.ts
```

**Expected Output:**
```
═══════════════════════════════════════════════════════
           EIA HENRY HUB NATURAL GAS PRICE
═══════════════════════════════════════════════════════

📊 RAW EIA DATA:
   Date:        2025-11-19
   Price:       3.93 dollars per million Btu
   Series:      Henry Hub Natural Gas Spot Price

🔄 CONVERTED FOR SMART CONTRACT:
   price:       3930000 (uint256)
   timestamp:   1732060800 (uint256)

✅ CONTRACT VALIDATION:
   ✓ price > 0:                     true
   ✓ timestamp <= block.timestamp:  true
   ✓ timestamp > 1 hour ago:        true
```

### 3. Deploy to Coston2

```bash
# Add PRIVATE_KEY to .env
source .env

# Deploy DisruptionOracle
forge script script/DeployCoston2.s.sol:DeployCoston2 \
  --rpc-url $COSTON2_RPC \
  --broadcast \
  --verify

# Save the deployed address to .env
echo "DISRUPTION_ORACLE_ADDRESS=0x..." >> .env
```

### 4. Submit FDC Attestation

See [FDC Attestation Workflow](#fdc-attestation-workflow) below for detailed steps.

---

## FDC Architecture

### Components

1. **Data Source**: EIA API (Henry Hub prices)
2. **FDC Verifier**: Coston2 testnet FDC infrastructure
3. **Attestation Request**: JSON specifying API endpoint, JQ transform, and ABI
4. **Proof**: Cryptographic proof of data authenticity
5. **Smart Contract**: DisruptionOracle.sol verifies and consumes proof

### Data Structure

#### EIA API Response
```json
{
  "response": {
    "data": [
      {
        "period": "2025-11-19",
        "value": "3.93",
        "units": "dollars per million Btu"
      }
    ]
  }
}
```

#### JQ Transformation
```jq
.response.data[0] | {
  price: (.value | tonumber * 1000000 | floor),
  timestamp: (.period | fromdateiso8601)
}
```

#### Output (ABI-encoded)
```solidity
struct PriceData {
    uint256 price;      // 3930000 ($3.93 with 6 decimals)
    uint256 timestamp;  // 1732060800 (Unix time)
}
```

---

## Setup Instructions

### Environment Variables

Copy `.env.example` and fill in:

```bash
# Required
EIA_API_KEY=your_eia_api_key
PRIVATE_KEY=your_wallet_private_key
COSTON2_RPC=https://coston2-api.flare.network/ext/C/rpc

# After deployment
DISRUPTION_ORACLE_ADDRESS=deployed_address
```

### Install Dependencies

```bash
# TypeScript dependencies
npm install

# Foundry dependencies
forge install
```

---

## Testing the Integration

### 1. Test EIA API Locally

```bash
npx ts-node scripts/fdc-integration/test-eia-api.ts
```

**This script:**
- Fetches latest Henry Hub price from EIA
- Converts to contract format (6 decimals)
- Validates against contract requirements
- Displays formatted output

### 2. Test JQ Transformation

```bash
# Install jq if needed
brew install jq  # macOS
apt-get install jq  # Linux

# Test the transformation
curl "https://api.eia.gov/v2/natural-gas/pri/fut/data/?api_key=$EIA_API_KEY&frequency=daily&data[0]=value&facets[series][]=RNGWHHD&sort[0][column]=period&sort[0][direction]=desc&offset=0&length=1" | \
jq '.response.data[0] | {price: (.value | tonumber * 1000000 | floor), timestamp: (.period | fromdateiso8601)}'
```

**Expected:**
```json
{
  "price": 3930000,
  "timestamp": 1732060800
}
```

### 3. Deploy to Coston2 Testnet

```bash
forge script script/DeployCoston2.s.sol:DeployCoston2 \
  --rpc-url $COSTON2_RPC \
  --broadcast
```

### 4. Manual Price Update (Testing Fallback)

Before setting up FDC, test manual updates:

```bash
# Set new price (6 decimals, e.g., $4.50)
export NEW_PRICE=4500000

forge script script/UpdateOraclePrice.s.sol:UpdateOraclePrice \
  --rpc-url $COSTON2_RPC \
  --broadcast
```

---

## FDC Attestation Workflow

### Understanding FDC Attestation

FDC uses a **request → verify → prove** workflow:

1. **Request**: Submit attestation request with API details
2. **Verify**: FDC nodes fetch data and verify independently
3. **Prove**: Generate Merkle proof of consensus
4. **Consume**: Submit proof to smart contract

### Attestation Request Format

See `fdc-attestation-request.json` for the full template:

```json
{
  "attestationType": "0x4a736f6e417069000000000000000000000000000000000000000000000000",
  "sourceId": "0x4549410000000000000000000000000000000000000000000000000000000000",
  "requestBody": {
    "url": "https://api.eia.gov/v2/natural-gas/pri/fut/data/?api_key=YOUR_KEY&...",
    "jqTransform": ".response.data[0] | {...}",
    "abi": {...}
  }
}
```

**Key Fields:**
- `attestationType`: `JsonApi` (hex-encoded)
- `sourceId`: `EIA` (hex-encoded)
- `url`: Full EIA API endpoint with your key
- `jqTransform`: Data transformation logic
- `abi`: Solidity struct ABI definition

### Submitting Attestation

**Method 1: FDC Attestation Client (Recommended)**

Flare provides an attestation client for submitting requests. See:
- https://dev.flare.network/fdc/guides/attestation-client

**Method 2: Direct API (Advanced)**

```typescript
const response = await fetch('https://fdc-verifiers-testnet.flare.network/api/attestation/request', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify(attestationRequest)
});

const proof = await response.json();
```

**Method 3: Using Our Script (Template)**

```bash
npx hardhat run scripts/fdc-integration/submit-fdc-proof.ts --network coston2
```

> **Note**: This script is a template. You'll need to integrate with Flare's actual attestation submission process.

### Retrieving Proofs

Once submitted, FDC verifiers process the request. Typical workflow:

1. Submit attestation request
2. Wait for voting round to complete (varies by network)
3. Query FDC for proof using attestation hash
4. Receive proof with Merkle data

### Calling Contract with Proof

```solidity
// In Solidity
IWeb2Json.Proof memory proof = /* fetched from FDC */;
oracle.updateBasePriceWithFDC(proof);
```

```typescript
// In TypeScript
const proof = /* fetched from FDC */;
const tx = await oracle.updateBasePriceWithFDC(proof);
await tx.wait();
```

---

## Deployment Workflow

### Production Deployment Checklist

- [ ] Register EIA API key
- [ ] Test API connection locally
- [ ] Deploy DisruptionOracle to Coston2
- [ ] Verify contract on Coston2 explorer
- [ ] Set up FDC attestation client
- [ ] Submit test attestation request
- [ ] Retrieve proof successfully
- [ ] Call `updateBasePriceWithFDC()` with proof
- [ ] Verify price updated on-chain
- [ ] Set up automated price updates (optional)

### Automated Price Updates

For production, consider automating updates:

**Option 1: Cron Job + Script**
```bash
# Run daily at 4 PM ET (after EIA update)
0 16 * * 1-5 /path/to/update-price.sh
```

**Option 2: Chainlink Automation (Cross-chain)**
- Use Chainlink Keepers to trigger updates
- Call LayerZero to send price cross-chain

**Option 3: Manual Updates**
- Owner calls `updateBasePrice()` when needed
- Fallback for FDC failures

---

## Troubleshooting

### EIA API Issues

**Error: "invalid api_key"**
- Solution: Check your EIA_API_KEY in .env
- Verify key at https://www.eia.gov/opendata/

**Error: "rate limit exceeded"**
- Solution: EIA allows 50k calls/day
- Implement caching (prices update daily)

**Error: "No data returned"**
- Solution: Markets closed (weekend)
- EIA only updates on business days

### FDC Integration Issues

**Error: "Invalid FDC proof"**
- Solution: Ensure proof is from Coston2 verifier
- Check that proof timestamp is < 1 hour old

**Error: "Data too old"**
- Solution: Contract rejects data > 1 hour old
- Submit fresh attestation request

**Error: "Future timestamp not allowed"**
- Solution: Ensure your system clock is synchronized
- Check timestamp in proof matches current time

### Contract Deployment Issues

**Error: "Insufficient funds"**
- Solution: Get Coston2 testnet CFLR from faucet
- https://faucet.flare.network/

**Error: "Invalid RPC URL"**
- Solution: Use https://coston2-api.flare.network/ext/C/rpc
- Check network connectivity

### JQ Transformation Issues

**Test JQ locally:**
```bash
echo '{"response":{"data":[{"period":"2025-11-19","value":"3.93"}]}}' | \
jq '.response.data[0] | {price: (.value | tonumber * 1000000 | floor), timestamp: (.period | fromdateiso8601)}'
```

**Common JQ errors:**
- Missing field: Check API response structure
- Type mismatch: Ensure `tonumber` before math ops
- Invalid date: Verify ISO8601 format

---

## Additional Resources

### Official Documentation

- **Flare FDC**: https://dev.flare.network/fdc/
- **FDC Attestation Guide**: https://dev.flare.network/fdc/guides/attestation-client
- **EIA API Docs**: https://www.eia.gov/opendata/documentation.php
- **JQ Manual**: https://jqlang.github.io/jq/manual/

### Contract Interfaces

- `IWeb2Json.sol`: FDC proof interface
- `IFdcVerificationExtended.sol`: Verification interface
- `DisruptionOracle.sol`: Oracle implementation

### Helper Scripts

1. `test-eia-api.ts` - Test EIA API connection
2. `submit-fdc-proof.ts` - Submit FDC proof (template)
3. `DeployCoston2.s.sol` - Deploy to Coston2
4. `UpdateOraclePrice.s.sol` - Manual price update
5. `fdc-attestation-request.json` - Request template

### Support

- **Flare Discord**: https://discord.gg/flarenetwork
- **GitHub Issues**: Report bugs in this repo
- **FDC Testnet Status**: Check Coston2 explorer

---

## Summary

This integration allows the DisruptionOracle to fetch real-world natural gas prices using Flare's decentralized oracle network. The process involves:

1. **Setup**: Get EIA API key, deploy contract
2. **Request**: Submit attestation request to FDC
3. **Verify**: FDC nodes verify data independently
4. **Prove**: Receive cryptographic proof
5. **Update**: Call contract with proof

**Benefits:**
- Decentralized (no single point of failure)
- Verifiable (cryptographic proofs)
- Flexible (any Web2 API)
- Secure (on-chain verification)

**Next Steps:**
1. Register for EIA API key
2. Test locally with `test-eia-api.ts`
3. Deploy to Coston2
4. Set up FDC attestation submission
5. Integrate with Uniswap V4 hook

---

*Last Updated: November 2025*
