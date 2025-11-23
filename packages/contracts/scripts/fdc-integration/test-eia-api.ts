/**
 * Test script for EIA Henry Hub Natural Gas API
 *
 * This script fetches the latest Henry Hub natural gas price from the EIA API
 * and converts it to the format expected by the DisruptionOracle contract.
 *
 * Usage:
 *   1. Set your EIA_API_KEY environment variable
 *   2. Run: npx ts-node scripts/fdc-integration/test-eia-api.ts
 */

import { config } from 'dotenv';

config();

// EIA API Configuration
const EIA_API_KEY = process.env.EIA_API_KEY;
const EIA_BASE_URL = 'https://api.eia.gov/v2/natural-gas/pri/fut/data/';
const HENRY_HUB_SERIES = 'RNGWHHD'; // Daily Henry Hub Natural Gas Spot Price

// Type definitions
interface EIADataPoint {
  period: string;           // "2025-11-19"
  series: string;           // "RNGWHHD"
  'series-description': string;
  value: string;            // "3.93"
  units: string;            // "dollars per million Btu"
}

interface EIAResponse {
  response: {
    total: number;
    dateFormat: string;
    frequency: string;
    data: EIADataPoint[];
    facets: Record<string, unknown>;
  };
  request: {
    command: string;
    params: Record<string, unknown>;
  };
  apiVersion: string;
}

interface PriceData {
  price: bigint;           // Price in 6 decimals (e.g., 3930000 for $3.93)
  timestamp: bigint;       // Unix timestamp
  priceFormatted: string;  // Human-readable price (e.g., "$3.93")
  date: string;            // ISO date (e.g., "2025-11-19")
}

/**
 * Fetch the latest Henry Hub price from EIA API
 */
async function fetchHenryHubPrice(): Promise<EIAResponse> {
  if (!EIA_API_KEY) {
    throw new Error(
      'EIA_API_KEY environment variable not set. ' +
      'Get your key at https://www.eia.gov/opendata/register.php'
    );
  }

  // Build query parameters
  const params = new URLSearchParams({
    api_key: EIA_API_KEY,
    frequency: 'daily',
    'data[0]': 'value',
    'facets[series][]': HENRY_HUB_SERIES,
    'sort[0][column]': 'period',
    'sort[0][direction]': 'desc',
    offset: '0',
    length: '1'  // Get only the most recent data point
  });

  const url = `${EIA_BASE_URL}?${params}`;

  console.log('Fetching Henry Hub price from EIA...');
  console.log(`URL: ${url.replace(EIA_API_KEY, 'YOUR_API_KEY')}\n`);

  const response = await fetch(url);

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`EIA API request failed: ${response.status} ${response.statusText}\n${errorText}`);
  }

  const data = await response.json() as EIAResponse;

  // Check if we got data
  if (!data.response.data || data.response.data.length === 0) {
    throw new Error('No data returned from EIA API');
  }

  return data;
}

/**
 * Convert EIA response to DisruptionOracle PriceData format
 */
function convertToPriceData(eiaData: EIADataPoint): PriceData {
  // Parse the price string to number
  const priceUsd = parseFloat(eiaData.value);

  if (isNaN(priceUsd) || priceUsd <= 0) {
    throw new Error(`Invalid price value: ${eiaData.value}`);
  }

  // Convert to 6 decimal format (USDC format)
  // Example: 3.93 -> 3930000
  const priceInDecimals = BigInt(Math.floor(priceUsd * 1_000_000));

  // Convert date to Unix timestamp
  const date = new Date(eiaData.period);
  const timestamp = BigInt(Math.floor(date.getTime() / 1000));

  return {
    price: priceInDecimals,
    timestamp: timestamp,
    priceFormatted: `$${priceUsd.toFixed(2)}`,
    date: eiaData.period
  };
}

/**
 * Display price data in a formatted table
 */
function displayPriceData(data: EIADataPoint, priceData: PriceData): void {
  console.log('═══════════════════════════════════════════════════════');
  console.log('           EIA HENRY HUB NATURAL GAS PRICE            ');
  console.log('═══════════════════════════════════════════════════════');
  console.log();

  console.log('📊 RAW EIA DATA:');
  console.log(`   Date:        ${data.period}`);
  console.log(`   Price:       ${data.value} ${data.units}`);
  console.log(`   Series:      ${data['series-description']}`);
  console.log();

  console.log('🔄 CONVERTED FOR SMART CONTRACT:');
  console.log(`   price:       ${priceData.price} (uint256)`);
  console.log(`   timestamp:   ${priceData.timestamp} (uint256)`);
  console.log();

  console.log('💡 HUMAN-READABLE:');
  console.log(`   Price:       ${priceData.priceFormatted} per MMBtu`);
  console.log(`   Date:        ${priceData.date}`);
  console.log(`   Timestamp:   ${new Date(Number(priceData.timestamp) * 1000).toISOString()}`);
  console.log();

  console.log('📝 SOLIDITY STRUCT FORMAT:');
  console.log('   struct PriceData {');
  console.log(`     uint256 price;      // ${priceData.price}`);
  console.log(`     uint256 timestamp;  // ${priceData.timestamp}`);
  console.log('   }');
  console.log();

  console.log('✅ CONTRACT VALIDATION:');
  console.log(`   ✓ price > 0:                     ${priceData.price > 0n}`);
  console.log(`   ✓ timestamp <= block.timestamp:  ${priceData.timestamp <= BigInt(Math.floor(Date.now() / 1000))}`);

  const oneHourAgo = BigInt(Math.floor(Date.now() / 1000) - 3600);
  console.log(`   ✓ timestamp > 1 hour ago:        ${priceData.timestamp > oneHourAgo}`);
  console.log();

  console.log('═══════════════════════════════════════════════════════');
}

/**
 * Main execution
 */
async function main() {
  try {
    // Fetch data from EIA
    const eiaResponse = await fetchHenryHubPrice();
    const latestData = eiaResponse.response.data[0];

    // Convert to contract format
    const priceData = convertToPriceData(latestData);

    // Display results
    displayPriceData(latestData, priceData);

    // Show API info
    console.log('📡 API INFORMATION:');
    console.log(`   Total data points: ${eiaResponse.response.total}`);
    console.log(`   Frequency:         ${eiaResponse.response.frequency}`);
    console.log(`   API Version:       ${eiaResponse.apiVersion}`);
    console.log();

    console.log('🔗 NEXT STEPS:');
    console.log('   1. Use this data to create FDC attestation request');
    console.log('   2. Submit to FDC verifier on Coston2');
    console.log('   3. Call DisruptionOracle.updateBasePriceWithFDC(proof)');
    console.log();

  } catch (error) {
    console.error('❌ Error:', error instanceof Error ? error.message : error);
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  main();
}

// Export for use in other scripts
export { fetchHenryHubPrice, convertToPriceData, type PriceData, type EIAResponse };
