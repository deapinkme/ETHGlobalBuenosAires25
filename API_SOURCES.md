# Henry Hub Natural Gas Price API Sources

Comprehensive guide to free APIs for fetching Henry Hub natural gas prices for the Disruption Oracle.

## Quick Recommendation

**Use EIA API** - Official U.S. government source, 100% free, 50k calls/day, daily updates.

## Summary Comparison

| Source | Free? | Rate Limit | Update | Reliability | Best For |
|--------|-------|------------|--------|-------------|----------|
| **EIA API** ⭐ | ✅ Yes | 50k/day | Daily | ⭐⭐⭐⭐⭐ | **Production** |
| **FRED** | ✅ Yes | Unknown | Daily | ⭐⭐⭐⭐⭐ | Backup |
| **Alpha Vantage** | ✅ Free tier | 25/day | Daily | ⭐⭐⭐⭐ | Testing |
| **Nasdaq/Quandl** | ✅ Free tier | 50k/day | Daily | ⭐⭐⭐⭐ | Historical |

---

## 1. EIA API (RECOMMENDED) ⭐

### Overview
The U.S. Energy Information Administration is the official government source for energy statistics.

### Details
- **URL**: https://api.eia.gov/v2/natural-gas/pri/fut/data/
- **Series ID**: `RNGWHHD` (Daily Henry Hub Spot Price)
- **Authentication**: Free API key
- **Cost**: 100% FREE
- **Rate Limits**:
  - 300 calls per 10 seconds
  - 2,000 calls per 10 minutes
  - 50,000 calls per day
- **Data Format**: JSON
- **Update Frequency**: Daily (business days)
- **Historical Data**: 1997-01-07 to present

### Registration
1. Go to: https://www.eia.gov/opendata/register.php
2. Fill form (name, email, organization)
3. Receive API key instantly via email

### Example Request
```bash
curl "https://api.eia.gov/v2/natural-gas/pri/fut/data/?api_key=YOUR_API_KEY&frequency=daily&data[0]=value&facets[series][]=RNGWHHD&sort[0][column]=period&sort[0][direction]=desc&offset=0&length=1"
```

### Example Response
```json
{
  "response": {
    "data": [
      {
        "period": "2025-11-19",
        "series": "RNGWHHD",
        "value": "3.93",
        "units": "dollars per million Btu"
      }
    ]
  }
}
```

### FDC Integration
```jq
.response.data[0] | {
  price: (.value | tonumber * 1000000 | floor),
  timestamp: (.period | fromdateiso8601)
}
```

### Pros
- ✅ Official government source (most authoritative)
- ✅ Completely free
- ✅ Very generous rate limits
- ✅ Reliable infrastructure
- ✅ Clean JSON format
- ✅ Well-documented API

### Cons
- ⚠️ Updates only on business days (no weekends)
- ⚠️ Requires API key registration

### Resources
- **Documentation**: https://www.eia.gov/opendata/documentation.php
- **API Browser**: https://www.eia.gov/opendata/browser/
- **Historical Data**: https://www.eia.gov/dnav/ng/hist/rngwhhdm.htm
- **Register**: https://www.eia.gov/opendata/register.php

---

## 2. FRED (Federal Reserve Economic Data)

### Overview
Federal Reserve's economic database, sourced from EIA.

### Details
- **URL**: https://api.stlouisfed.org/fred/series/observations
- **Series IDs**:
  - `DHHNGSP` - Daily Henry Hub Spot Price
  - `MHHNGSP` - Monthly
  - `WHHNGSP` - Weekly
  - `AHHNGSP` - Annual
- **Authentication**: Free API key
- **Cost**: 100% FREE
- **Rate Limits**: Not publicly specified (generous)
- **Data Format**: JSON, XML, CSV
- **Update Frequency**: Daily (sourced from EIA)
- **Historical Data**: 1997-01-07 to present

### Registration
1. Go to: https://fred.stlouisfed.org/docs/api/api_key.html
2. Create account
3. Request API key

### Example Request
```bash
curl "https://api.stlouisfed.org/fred/series/observations?series_id=DHHNGSP&api_key=YOUR_API_KEY&file_type=json&sort_order=desc&limit=1"
```

### Example Response
```json
{
  "observations": [
    {
      "realtime_start": "2025-11-19",
      "realtime_end": "2025-11-19",
      "date": "2025-11-17",
      "value": "3.93"
    }
  ]
}
```

### FDC Integration
```jq
.observations[0] | {
  price: (.value | tonumber * 1000000 | floor),
  timestamp: (.date | fromdateiso8601)
}
```

### Pros
- ✅ Official Federal Reserve source
- ✅ Free
- ✅ Multiple formats (JSON, XML, CSV)
- ✅ Simple API structure
- ✅ Same data as EIA

### Cons
- ⚠️ Data sourced from EIA (not primary source)
- ⚠️ Slightly delayed updates

### Resources
- **FRED Daily Prices**: https://fred.stlouisfed.org/series/DHHNGSP
- **FRED Monthly Prices**: https://fred.stlouisfed.org/series/MHHNGSP
- **API Documentation**: https://fred.stlouisfed.org/docs/api/

---

## 3. Alpha Vantage

### Overview
Commercial financial data provider with free tier.

### Details
- **URL**: https://www.alphavantage.co/query
- **Function**: `NATURAL_GAS`
- **Authentication**: Free API key
- **Cost**: FREE tier available
- **Rate Limits**:
  - Free: 25 requests per day
  - Premium: 75 requests/min ($49.99/month)
- **Data Format**: JSON, CSV
- **Update Frequency**: Monthly on free tier
- **Historical Data**: Limited on free tier

### Registration
1. Go to: https://www.alphavantage.co/support/#api-key
2. Enter email
3. Receive API key instantly

### Example Request
```bash
curl "https://www.alphavantage.co/query?function=NATURAL_GAS&apikey=YOUR_API_KEY"
```

### Example Response
```json
{
  "name": "Henry Hub Natural Gas Spot Price",
  "interval": "monthly",
  "unit": "dollars per million BTU",
  "data": [
    {
      "date": "2025-11-01",
      "value": "3.45"
    }
  ]
}
```

### FDC Integration
```jq
.data[0] | {
  price: (.value | tonumber * 1000000 | floor),
  timestamp: (.date | fromdateiso8601)
}
```

### Pros
- ✅ Quick setup
- ✅ No complex query parameters
- ✅ Good for testing

### Cons
- ⚠️ Only 25 calls/day on free tier
- ⚠️ Monthly data (not daily)
- ⚠️ Not suitable for production oracle

### Resources
- **Get API Key**: https://www.alphavantage.co/support/#api-key
- **Documentation**: https://www.alphavantage.co/documentation/

---

## 4. Nasdaq Data Link (formerly Quandl)

### Overview
Nasdaq-owned data platform with free datasets.

### Details
- **Dataset Code**: `CHRIS/CME_NG1` (Natural Gas Futures)
- **URL**: https://data.nasdaq.com/api/v3/datasets/CHRIS/CME_NG1/data.json
- **Authentication**: Free API key
- **Cost**: Free tier available
- **Rate Limits**:
  - Anonymous: 20 calls/day
  - Free account: 50 calls/day
  - With key: Same as EIA (50k/day)
- **Data Format**: JSON, CSV
- **Update Frequency**: Daily
- **Historical Data**: Extensive

### Registration
1. Go to: https://data.nasdaq.com/sign-up
2. Create account
3. Get API key from profile

### Example Request
```bash
curl "https://data.nasdaq.com/api/v3/datasets/CHRIS/CME_NG1/data.json?limit=1&api_key=YOUR_API_KEY"
```

### Example Response
```json
{
  "dataset_data": {
    "column_names": ["Date", "Open", "High", "Low", "Settle", "Volume"],
    "data": [
      ["2025-11-19", 3.95, 4.05, 3.90, 3.93, 125000]
    ]
  }
}
```

### FDC Integration
```jq
.dataset_data.data[0] | {
  price: (.[4] * 1000000 | floor),
  timestamp: (.[0] | fromdateiso8601)
}
```

### Pros
- ✅ Nasdaq reliability
- ✅ Good historical archive
- ✅ Futures data

### Cons
- ⚠️ Futures prices (may differ from spot)
- ⚠️ More complex data structure

### Resources
- **Documentation**: https://docs.data.nasdaq.com/
- **Browse Datasets**: https://data.nasdaq.com/search?filters=["Free"]

---

## 5. Web Scraping Options (NOT RECOMMENDED)

### Sources with Visible Prices

1. **Investing.com**: https://www.investing.com/commodities/natural-gas
2. **Yahoo Finance**: https://finance.yahoo.com/quote/NG=F/ (ticker: NG=F)
3. **Trading Economics**: https://tradingeconomics.com/commodity/natural-gas

### Tools
- **investpy** (Python): Investing.com scraper
- **yfinance** (Python): Yahoo Finance API
- **yahooquery** (Python): Another Yahoo wrapper

### Why NOT to Use

❌ **Legal Issues**: Violates Terms of Service
❌ **IP Bans**: Risk of being blocked
❌ **Unreliable**: Sites change structure
❌ **Not Oracle-Safe**: Not suitable for production
❌ **Rate Limiting**: Aggressive anti-scraping

**Recommendation**: Always use official APIs instead of scraping.

---

## 6. GitHub Open Source Projects

Community-built wrappers and datasets:

### A. leabstrait/gas-prices-data
- **URL**: https://github.com/leabstrait/gas-prices-data
- **Features**: EIA API implementation + HTML scraper
- **License**: Check repository

### B. datasets/natural-gas
- **URL**: https://github.com/datasets/natural-gas
- **Features**: Python data pipeline
- **License**: Open Data Commons

### C. MattScheffler/HenryHub
- **URL**: https://github.com/MattScheffler/HenryHub
- **Features**: Analysis functions
- **Language**: R

### D. attaradev/hh-natural-gas-prices
- **URL**: https://github.com/attaradev/hh-natural-gas-prices
- **Features**: EIA extraction scripts
- **Format**: CSV

**Note**: These are wrappers around official sources (mainly EIA). Good for learning, but use official APIs for production.

---

## Implementation Recommendations

### For Production Oracle
1. **Primary**: EIA API (most reliable)
2. **Backup**: FRED API (same data, different endpoint)
3. **Fallback**: Manual owner update if both fail

### For Development/Testing
- **Alpha Vantage**: Quick setup, good for proof-of-concept
- **EIA with caching**: Test with real API, cache responses

### For Historical Analysis
- **Nasdaq Data Link**: Best historical archive
- **EIA**: Official historical data

---

## FDC Integration Guide

### Required Components

1. **API Key**: Get from chosen provider (EIA recommended)
2. **API Endpoint**: Full URL with parameters
3. **JQ Transformation**: Convert JSON to PriceData format
4. **ABI Definition**: Struct definition for encoding

### Example FDC Request (EIA)

```json
{
  "attestationType": "0x4a736f6e417069000000000000000000000000000000000000000000000000",
  "sourceId": "0x4549410000000000000000000000000000000000000000000000000000000000",
  "requestBody": {
    "url": "https://api.eia.gov/v2/natural-gas/pri/fut/data/?api_key=YOUR_KEY&...",
    "jqTransform": ".response.data[0] | {price: (.value | tonumber * 1000000 | floor), timestamp: (.period | fromdateiso8601)}",
    "abi": {
      "components": [
        {"internalType": "uint256", "name": "price", "type": "uint256"},
        {"internalType": "uint256", "name": "timestamp", "type": "uint256"}
      ],
      "internalType": "struct DisruptionOracle.PriceData",
      "type": "tuple"
    }
  }
}
```

### Testing Workflow

1. ✅ Test API endpoint directly (curl/Postman)
2. ✅ Verify JSON response structure
3. ✅ Test JQ transformation locally
4. ✅ Submit to FDC verifier on Coston2
5. ✅ Retrieve proof
6. ✅ Call contract with proof

---

## Backup Strategy

Implement multi-source fallback:

```typescript
async function fetchPrice() {
  try {
    // Try EIA first
    return await fetchEIA();
  } catch {
    try {
      // Fall back to FRED
      return await fetchFRED();
    } catch {
      // Manual owner update as last resort
      throw new Error('All APIs failed');
    }
  }
}
```

---

## Cost Analysis

| Provider | Free Calls/Day | Enough for Oracle? | Cost if Exceeding |
|----------|----------------|-------------------|-------------------|
| EIA | 50,000 | ✅ Yes | N/A (always free) |
| FRED | Unlimited? | ✅ Yes | N/A (always free) |
| Alpha Vantage | 25 | ❌ No | $49.99/month |
| Nasdaq | 50 | ⚠️ Maybe | Premium required |

**Recommendation**: EIA's 50k/day is more than sufficient for an oracle that updates once per day.

---

## Summary

✅ **Best Choice**: EIA API
✅ **Backup**: FRED API
✅ **For Testing**: Alpha Vantage
❌ **Avoid**: Web scraping

### Quick Start
1. Register for EIA API key: https://www.eia.gov/opendata/register.php
2. Use series ID: `RNGWHHD`
3. See `scripts/fdc-integration/` for implementation examples
4. Integrate with Flare FDC for decentralized oracle

**All sources are free, but EIA is the gold standard for natural gas price data.**
