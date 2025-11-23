/**
 * Submit FDC Proof to DisruptionOracle Contract
 *
 * This script creates an FDC attestation request for Henry Hub prices,
 * retrieves the proof from the FDC verifier, and submits it to the
 * DisruptionOracle contract to update the base price.
 *
 * Usage:
 *   1. Deploy DisruptionOracle to Coston2 testnet
 *   2. Set environment variables (see .env.example)
 *   3. Run: npx hardhat run scripts/fdc-integration/submit-fdc-proof.ts --network coston2
 */

import { ethers } from 'hardhat';
import { config } from 'dotenv';

config();

// Configuration
const FDC_VERIFIER_URL = 'https://fdc-verifiers-testnet.flare.network';
const EIA_API_KEY = process.env.EIA_API_KEY;
const DISRUPTION_ORACLE_ADDRESS = process.env.DISRUPTION_ORACLE_ADDRESS;

// Attestation type and source ID (hex-encoded, zero-padded to 32 bytes)
const ATTESTATION_TYPE_JSONAPI = '0x4a736f6e417069000000000000000000000000000000000000000000000000'; // 'JsonApi'
const SOURCE_ID_EIA = '0x4549410000000000000000000000000000000000000000000000000000000000'; // 'EIA'

interface AttestationRequest {
  attestationType: string;
  sourceId: string;
  requestBody: {
    url: string;
    jqTransform: string;
    abi: {
      components: Array<{
        internalType: string;
        name: string;
        type: string;
      }>;
      internalType: string;
      name: string;
      type: string;
    };
  };
}

interface FDCProof {
  data: {
    attestationType: string;
    sourceId: string;
    votingRound: number;
    lowestUsedTimestamp: number;
    requestBody: {
      url: string;
      postprocessJQ: string;
    };
    responseBody: {
      abiEncodedData: string;
    };
  };
  merkleProof: string[];
}

/**
 * Create FDC attestation request for EIA Henry Hub price
 */
function createAttestationRequest(): AttestationRequest {
  if (!EIA_API_KEY) {
    throw new Error('EIA_API_KEY environment variable not set');
  }

  // EIA API URL for latest Henry Hub daily price
  const eiaUrl = `https://api.eia.gov/v2/natural-gas/pri/fut/data/?api_key=${EIA_API_KEY}&frequency=daily&data[0]=value&facets[series][]=RNGWHHD&sort[0][column]=period&sort[0][direction]=desc&offset=0&length=1`;

  // JQ transformation to convert EIA response to PriceData format
  const jqTransform = '.response.data[0] | {price: (.value | tonumber * 1000000 | floor), timestamp: (.period | fromdateiso8601)}';

  // ABI for PriceData struct
  const abi = {
    components: [
      {
        internalType: 'uint256',
        name: 'price',
        type: 'uint256'
      },
      {
        internalType: 'uint256',
        name: 'timestamp',
        type: 'uint256'
      }
    ],
    internalType: 'struct DisruptionOracle.PriceData',
    name: '',
    type: 'tuple'
  };

  return {
    attestationType: ATTESTATION_TYPE_JSONAPI,
    sourceId: SOURCE_ID_EIA,
    requestBody: {
      url: eiaUrl,
      jqTransform,
      abi
    }
  };
}

/**
 * Submit attestation request to FDC verifier
 */
async function submitAttestationRequest(request: AttestationRequest): Promise<FDCProof> {
  console.log('📤 Submitting attestation request to FDC verifier...');
  console.log(`   Verifier: ${FDC_VERIFIER_URL}`);
  console.log(`   Attestation Type: JsonApi`);
  console.log(`   Source: EIA Henry Hub`);
  console.log();

  // Note: This is a placeholder implementation
  // The actual FDC API endpoints and authentication may differ
  // Refer to Flare documentation for the exact implementation

  const response = await fetch(`${FDC_VERIFIER_URL}/api/attestation/request`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(request)
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`FDC verifier request failed: ${response.status} ${response.statusText}\n${errorText}`);
  }

  const proof = await response.json() as FDCProof;
  console.log('✅ Attestation proof received');
  console.log();

  return proof;
}

/**
 * Update DisruptionOracle with FDC proof
 */
async function updateOraclePrice(proof: FDCProof): Promise<void> {
  if (!DISRUPTION_ORACLE_ADDRESS) {
    throw new Error('DISRUPTION_ORACLE_ADDRESS environment variable not set');
  }

  console.log('🔗 Connecting to DisruptionOracle contract...');
  console.log(`   Address: ${DISRUPTION_ORACLE_ADDRESS}`);

  // Get contract instance
  const DisruptionOracle = await ethers.getContractFactory('DisruptionOracle');
  const oracle = DisruptionOracle.attach(DISRUPTION_ORACLE_ADDRESS);

  // Get signer
  const [signer] = await ethers.getSigners();
  console.log(`   Signer: ${signer.address}`);
  console.log();

  // Decode the price data from the proof to display it
  const abiCoder = new ethers.AbiCoder();
  const decodedData = abiCoder.decode(
    ['tuple(uint256 price, uint256 timestamp)'],
    proof.data.responseBody.abiEncodedData
  );
  const priceData = decodedData[0];

  console.log('📊 Price Data from FDC Proof:');
  console.log(`   Price:     ${priceData.price} (${ethers.formatUnits(priceData.price, 6)} USD)`);
  console.log(`   Timestamp: ${priceData.timestamp} (${new Date(Number(priceData.timestamp) * 1000).toISOString()})`);
  console.log();

  // Call updateBasePriceWithFDC
  console.log('📝 Submitting transaction to update base price...');

  const tx = await oracle.updateBasePriceWithFDC(proof);
  console.log(`   Transaction hash: ${tx.hash}`);

  console.log('⏳ Waiting for confirmation...');
  const receipt = await tx.wait();

  console.log(`✅ Transaction confirmed in block ${receipt.blockNumber}`);
  console.log();

  // Get updated base price
  const newBasePrice = await oracle.basePrice();
  console.log('📈 Oracle Updated:');
  console.log(`   New Base Price: ${newBasePrice} (${ethers.formatUnits(newBasePrice, 6)} USD)`);
  console.log();
}

/**
 * Main execution
 */
async function main() {
  console.log('═══════════════════════════════════════════════════════');
  console.log('         FDC PROOF SUBMISSION TO DISRUPTION ORACLE     ');
  console.log('═══════════════════════════════════════════════════════');
  console.log();

  try {
    // Step 1: Create attestation request
    console.log('STEP 1: Creating FDC attestation request');
    const request = createAttestationRequest();
    console.log('✓ Request created');
    console.log();

    // Step 2: Submit to FDC verifier (NOTE: This is a placeholder)
    console.log('STEP 2: Submitting to FDC verifier');
    console.log();
    console.log('⚠️  NOTE: FDC integration requires additional setup:');
    console.log('   1. The FDC verifier API endpoints are not fully documented');
    console.log('   2. You may need to use Flare\'s attestation client');
    console.log('   3. Refer to https://dev.flare.network/fdc/ for latest docs');
    console.log('   4. For now, this script shows the structure needed');
    console.log();
    console.log('📋 Your attestation request:');
    console.log(JSON.stringify(request, null, 2));
    console.log();

    // In production, you would:
    // const proof = await submitAttestationRequest(request);
    // await updateOraclePrice(proof);

    console.log('🔗 NEXT STEPS FOR PRODUCTION:');
    console.log('   1. Set up FDC attestation client from Flare');
    console.log('   2. Deploy DisruptionOracle to Coston2');
    console.log('   3. Set DISRUPTION_ORACLE_ADDRESS in .env');
    console.log('   4. Submit attestation request via FDC client');
    console.log('   5. Retrieve proof and call updateBasePriceWithFDC()');
    console.log();

    console.log('💡 FOR TESTING:');
    console.log('   You can also manually update the price using:');
    console.log('   oracle.updateBasePrice(price) // owner-only function');
    console.log();

  } catch (error) {
    console.error('❌ Error:', error instanceof Error ? error.message : error);
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

// Export for use in other scripts
export { createAttestationRequest, submitAttestationRequest, updateOraclePrice };
