require('dotenv').config();

const apiKey = process.env.EIA_API_KEY;

if (!apiKey) {
  console.error('❌ EIA_API_KEY not found in .env');
  process.exit(1);
}

console.log('🔑 API Key found (first 10 chars):', apiKey.substring(0, 10) + '...');

const endpoint = `https://api.eia.gov/v2/natural-gas/pri/spot/data/?api_key=${apiKey}&frequency=daily&data[0]=value&facets[area][]=SHG&sort[0][column]=period&sort[0][direction]=desc&offset=0&length=1`;

console.log('\n📡 Fetching Henry Hub Natural Gas Spot Price...\n');

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
      const price = latest.value;
      const date = latest.period;

      console.log('📊 Latest Natural Gas Price:');
      console.log('   Date:', date);
      console.log('   Price: $' + price.toFixed(2) + ' per MMBtu');
      console.log('   Price (6 decimals):', Math.round(price * 1e6), '(for oracle)');

      console.log('\n🎯 Oracle Format:');
      console.log('   uint256 basePrice =', Math.round(price * 1e6) + ';');

      console.log('\n✨ Success! EIA API is working correctly.');
    } else {
      console.log('⚠️  No data returned from API');
      console.log('Full response:', JSON.stringify(data, null, 2));
    }
  })
  .catch(err => {
    console.error('❌ Error fetching data:', err.message);
    process.exit(1);
  });
