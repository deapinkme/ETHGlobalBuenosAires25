# EIA API Setup Guide for Henry Hub Natural Gas Prices

This guide will help you set up the U.S. Energy Information Administration (EIA) API to fetch Henry Hub natural gas prices for integration with Flare Data Connector (FDC).

## Why EIA?
Zovernment's energy data authority
- **Free**: No cost, no credit card required
- **Generous Limits**: 50,000 calls/day
- **Reliable**: Government infrastructure
- **Daily Updates**: Fresh Henry Hub spot prices
- **Historical Data**: Complete archive since 1997

## Step 1: Register for API Key

### Requirements
- Email address (that's it!)
- 2 minutes of your time

### Registration Process

1. **Go to registration page**: https://www.eia.gov/opendata/register.php

2. **Fill out the form**:
   - First Name
   - Last Name
   - Email Address
   - Organization: "Personal Project" or "Blockchain Oracle"
   - Affiliation Type: Select "Private Sector" or "Other"

3. **Submit and check email**
   - API key sent instantly to your email
   - Save it somewhere safe (you'll need it for every API call)

## Step 2: Understanding the Henry Hub Endpoint

### API Base URL
```
https://api.eia.gov/v2/natural-gas/pri/fut/data/
```

### Henry Hub Series ID
```
RNGWHHD - Henry Hub Natural Gas Spot Price (Daily)
```

### Complete Endpoint for Latest Price
```bash
https://api.eia.gov/v2/natural-gas/pri/fut/data/?api_key=YOUR_API_KEY&frequency=daily&data[0]=value&facets[series][]=RNGWHHD&sort[0][column]=period&sort[0][direction]=desc&offset=0&length=1
```

**Note**: Your API key is required. The URL structure follows the EIA v2 API format with Henry Hub series filter.

### URL Parameters Explained

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `api_key` | YOUR_API_KEY | Authentication |
| `frequency` | `daily` | Daily data points |
| `data[0]` | `value` | Return price values |
| `facets[series][]` | `RNGWHHD` | Henry Hub series |
| `sort[0][column]` | `period` | Sort by date |
| `sort[0][direction]` | `desc` | Most recent first |
| `offset` | `0` | Start at first result |
| `length` | `1` | Return only 1 result |

## Step 3: Test the API

### Using cURL

```bash
curl "https://api.eia.gov/v2/natural-gas/pri/fut/data/?api_key=YOUR_API_KEY&frequency=daily&data[0]=value&facets[series][]=RNGWHHD&sort[0][column]=period&sort[0][direction]=desc&offset=0&length=1"
```

### Expected Response

```json
{
  "response": {
    "total": 7184,
    "dateFormat": "YYYY-MM-DD",
    "frequency": "daily",
    "data": [
      {
        "period": "2025-11-19",
        "series": "RNGWHHD",
        "series-description": "Henry Hub Natural Gas Spot Price",
        "value": "3.93",
        "units": "dollars per million Btu"
      }
    ],
    "facets": {}
  },
  "request": {
    "command": "/v2/natural-gas/pri/fut/data/",
    "params": {
      "frequency": "daily",
      "data": ["value"],
      "facets": {
        "series": ["RNGWHHD"]
      },
      "sort": [
        {
          "column": "period",
          "direction": "desc"
        }
      ],
      "offset": 0,
      "length": 1,
      "api_key": "xxxxxx"
    }
  },
  "apiVersion": "2.1.7"
}
```

### Using TypeScript/Node.js

```typescript
const EIA_API_KEY = 'YOUR_API_KEY';
const EIA_ENDPOINT = 'https://api.eia.gov/v2/natural-gas/pri/fut/data/';

const params = new URLSearchParams({
  api_key: EIA_API_KEY,
  frequency: 'daily',
  'data[0]': 'value',
  'facets[series][]': 'RNGWHHD',
  'sort[0][column]': 'period',
  'sort[0][direction]': 'desc',
  offset: '0',
  length: '1'
});

const response = await fetch(`${EIA_ENDPOINT}?${params}`);
const data = await response.json();

console.log('Latest Henry Hub Price:', data.response.data[0].value);
console.log('Date:', data.response.data[0].period);
```

## Step 4: Convert to DisruptionOracle Format

Your contract expects prices in USDC format (6 decimals):

```typescript
// EIA returns price as string (e.g., "3.93")
const eiaPrice = data.response.data[0].value;

// Convert to 6 decimal format
const priceInUsdc = Math.floor(parseFloat(eiaPrice) * 1_000_000);
// Result: 3930000 (represents $3.93)

// Convert date to Unix timestamp
const timestamp = new Date(data.response.data[0].period).getTime() / 1000;
```

## Step 5: JQ Transformation for FDC

Flare FDC uses JQ (JSON query language) to transform API responses. Here's the transformation for EIA:

```jq
.response.data[0] | {
  price: (.value | tonumber * 1000000 | floor),
  timestamp: (.period | fromdateiso8601)
}
```

### Explanation:
- `.response.data[0]` - Get first (most recent) data point
- `.value | tonumber` - Convert string to number
- `* 1000000 | floor` - Convert to 6 decimals, round down
- `.period | fromdateiso8601` - Convert date to Unix timestamp

### Expected Output:
```json
{
  "price": 3930000,
  "timestamp": 1732060800
}
```

This matches your `PriceData` struct:
```solidity
struct PriceData {
    uint256 price;          // 3930000 (6 decimals)
    uint256 timestamp;      // Unix timestamp
}
```

## Rate Limits

### Free Tier Limits
- **300 calls** per 10 seconds
- **2,000 calls** per 10 minutes
- **50,000 calls** per day

### Best Practices
- Cache responses (prices update daily, no need to call every second)
- Implement exponential backoff on errors
- Monitor your usage via response headers

### Rate Limit Headers
```http
X-Ratelimit-Limit-Day: 50000
X-Ratelimit-Remaining-Day: 49999
```

## Data Characteristics

### Update Frequency
- **Daily** - New prices posted each business day
- Updates typically around 3:00 PM ET
- No weekend updates (markets closed)

### Price Units
- **Dollars per million BTU** ($/MMBtu)
- Standard natural gas pricing unit
- Directly comparable to futures prices

### Historical Availability
- Data available from: **1997-01-07** to present
- Over 7,000 data points
- Continuous daily series

## Troubleshooting

### Common Errors

**Invalid API Key**
```json
{
  "error": "invalid api_key"
}
```
**Solution**: Double-check your API key

**Series Not Found**
```json
{
  "error": "invalid series"
}
```
**Solution**: Verify series ID is `RNGWHHD`

**Rate Limit Exceeded**
```json
{
  "error": "rate limit exceeded"
}
```
**Solution**: Wait and retry, implement caching

## Next Steps

1. ✅ Register for API key
2. ✅ Test endpoint with curl
3. ✅ Verify response format
4. → See `test-eia-api.ts` to test with TypeScript
5. → See `fdc-attestation-request.json` for FDC integration
6. → See `submit-fdc-proof.ts` to submit to your contract

## Additional Resources

- **EIA API Documentation**: https://www.eia.gov/opendata/documentation.php
- **API Query Browser**: https://www.eia.gov/opendata/browser/
- **Henry Hub Historical Data**: https://www.eia.gov/dnav/ng/hist/rngwhhdm.htm
- **Flare FDC Docs**: https://dev.flare.network/fdc/

## Alternative Series IDs

If you need different frequencies:

| Series ID | Description | Frequency |
|-----------|-------------|-----------|
| `RNGWHHD` | Henry Hub Spot Price | Daily |
| `RNGWHHW` | Henry Hub Spot Price | Weekly |
| `RNGWHHM` | Henry Hub Spot Price | Monthly |
| `RNGWHHA` | Henry Hub Spot Price | Annual |

For this oracle, **use `RNGWHHD`** for daily updates.
