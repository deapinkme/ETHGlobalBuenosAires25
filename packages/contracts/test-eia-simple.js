const fs = require('fs');
const path = require('path');

// Read .env file manually
const envPath = path.join(__dirname, '.env');
const envContent = fs.readFileSync(envPath, 'utf8');
const envLines = envContent.split('\n');

let apiKey = null;
for (const line of envLines) {
  if (line.startsWith('EIA_API_KEY=')) {
    apiKey = line.split('=')[1].trim();
    break;
  }
}

if (!apiKey) {
  console.error('❌ EIA_API_KEY not found in .env');
  process.exit(1);
}

console.log('🔑 API Key found (first 10 chars):', apiKey.substring(0, 10) + '...');

// Correct endpoint using futures data (RNGWHHD series)
const endpoint = `https://api.eia.gov/v2/natural-gas/pri/fut/data/?api_key=${apiKey}&frequency=daily&data[0]=value&facets[series][]=RNGWHHD&sort[0][column]=period&sort[0][direction]=desc&offset=0&length=1`;

console.log('\n📡 Fetching Henry Hub Natural Gas Spot Price from EIA...\n');

fetch(endpoint)
  .then(res => {
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}: ${res.statusText}`);
    }
    return res.json();
  })
  .then(data => {
    console.log('✅ API Response received!\n');

    if (data.response && data.response.data && data.response.data.length > 0) {
      const latest = data.response.data[0];
      const price = parseFloat(latest.value);
      const date = latest.period;
      const series = latest.series;

      console.log('📊 Latest Natural Gas Price (Henry Hub):');
      console.log('   Series:', series);
      console.log('   Date:', date);
      console.log('   Price: $' + price.toFixed(2) + ' per MMBtu');
      console.log('   Unit:', latest.units);

      const priceInOracle = Math.round(price * 1e6);
      console.log('\n🎯 Oracle Format (6 decimals):');
      console.log('   uint256 basePrice = ' + priceInOracle + ';');
      console.log('   (This equals $' + (priceInOracle / 1e6).toFixed(2) + ')');

      console.log('\n✨ Success! EIA API is working correctly.');
      console.log('\n📋 Next steps:');
      console.log('   1. Deploy oracle to Coston2: ./deploy-coston2.sh');
      console.log('   2. Or update existing oracle: ./update-oracle-price.sh ' + priceInOracle);
      console.log('\n🔗 FDC Integration:');
      console.log('   - This price can be verified via Flare Data Connector');
      console.log('   - See scripts/fdc-integration/README.md for details');
    } else {
      console.log('⚠️  No data returned from API');
      console.log('Full response:', JSON.stringify(data, null, 2));
    }
  })
  .catch(err => {
    console.error('\n❌ Error fetching data:', err.message);
    console.log('\n🔍 Troubleshooting:');
    console.log('   - Check your API key is valid');
    console.log('   - Verify you have internet connection');
    console.log('   - Try the API in browser: https://www.eia.gov/opendata/browser/');
    process.exit(1);
  });
