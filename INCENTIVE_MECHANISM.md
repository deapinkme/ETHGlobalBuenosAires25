# Incentive Mechanism Breakdown

Complete documentation of the fee and bonus formulas that drive price convergence in the Natural Gas Disruption Hook.

## 🎯 Overview

The incentive mechanism creates profitable arbitrage opportunities for traders who correct price misalignments, funded by fees from traders who push prices away from the oracle's theoretical price.

---

## 1. Price Deviation Calculation

First, the system determines if the pool price is misaligned with the oracle's theoretical price:

```
deviation = |pool_price - theoretical_price| / theoretical_price × 100
```

**Example:**
- Theoretical price (oracle): $3.50
- Pool price: $4.20
- Deviation: |4.20 - 3.50| / 3.50 × 100 = **20%**

---

## 2. Trader Alignment

The hook determines if a trader is **aligned** or **misaligned**:

| Pool vs Oracle | Buying NATGAS | Selling NATGAS |
|----------------|---------------|----------------|
| Pool > Oracle (too high) | ❌ **Misaligned** (pushes price higher) | ✅ **Aligned** (brings price down) |
| Pool < Oracle (too low) | ✅ **Aligned** (brings price up) | ❌ **Misaligned** (pushes price lower) |

**Logic:**
- If pool price is too high, sellers are aligned (bring price down)
- If pool price is too low, buyers are aligned (bring price up)
- Aligned traders receive bonuses
- Misaligned traders pay high fees

---

## 3. Fee Structure for Misaligned Traders

**Formula** (from `FeeCurve.sol:26`):
```solidity
fee = baseFee + (deviation² × multiplier) / 10000
```

**Parameters:**
- `baseFee` = 3000 basis points (0.3%)
- `multiplier` = 2000 (controls curve steepness)
- `maxFee` = 100000 basis points (10%)
- `BASIS_POINTS` = 10000 (100% = 10000 bp)

### Fee Examples

| Deviation | Calculation | Fee (bp) | Fee % |
|-----------|-------------|----------|-------|
| 0% | 3000 + (0² × 2000) / 10000 | 3000 | **0.3%** |
| 10% | 3000 + (10² × 2000) / 10000 | 5000 | **0.5%** |
| 20% | 3000 + (20² × 2000) / 10000 | 11000 | **1.1%** |
| 30% | 3000 + (30² × 2000) / 10000 | 21000 | **2.1%** |
| 40% | 3000 + (40² × 2000) / 10000 | 35000 | **3.5%** |
| 50% | 3000 + (50² × 2000) / 10000 | 53000 | **5.3%** |
| 60% | 3000 + (60² × 2000) / 10000 | 75000 | **7.5%** |
| 70%+ | Capped at maxFee | 100000 | **10%** |

### Key Points

- Fees grow **quadratically** (faster as deviation increases)
- Small deviations = small penalty
- Large deviations = severe penalty
- Capped at 10% to prevent extreme fees
- At equilibrium (0% deviation): everyone pays base fee of 0.3%

### Fee Curve Visualization

```
Fee %
10% |                                    _______________
    |                               ___/
 5% |                        ___/‾‾
    |                   __/‾‾
 3% |              __/‾‾
    |         __/‾‾
 1% |    __/‾‾
    | /‾‾
 0% |_________________________________________________
    0%    10%    20%    30%    40%    50%    60%+
                        Deviation
```

**Alternative Fee Curves Available:**
- `linearFee()` - Linear growth (lines 48-66)
- `exponentialFee()` - Exponential growth (lines 76-96)

---

## 4. Bonus Structure for Aligned Traders

**Formula** (from `BonusCurve.sol:29`):
```solidity
bonus = (deviation² × multiplier) / 10000
```

**Parameters:**
- `multiplier` = 100 (controls curve steepness)
- `maxBonus` = 500 basis points (5%)
- No base bonus (starts at 0)

### Bonus Examples

| Deviation | Calculation | Bonus (bp) | Bonus % |
|-----------|-------------|------------|---------|
| 0% | (0² × 100) / 10000 | 0 | **0%** |
| 10% | (10² × 100) / 10000 | 10 | **0.1%** |
| 20% | (20² × 100) / 10000 | 40 | **0.4%** |
| 30% | (30² × 100) / 10000 | 90 | **0.9%** |
| 40% | (40² × 100) / 10000 | 160 | **1.6%** |
| 50% | (50² × 100) / 10000 | 250 | **2.5%** |
| 60% | (60² × 100) / 10000 | 360 | **3.6%** |
| 70%+ | Capped at maxBonus | 500 | **5%** |

### Key Points

- Bonuses grow **quadratically** (mirrors fee curve)
- Zero deviation = zero bonus (at equilibrium)
- Maximum bonus is 5% of swap amount
- Paid immediately after swap from treasury
- Aligned traders also pay low fee (0.1% instead of base 0.3%)

### Bonus Curve Visualization

```
Bonus %
 5% |                                    _______________
    |                               ___/
    |                        ___/‾‾
 3% |                   __/‾‾
    |              __/‾‾
 2% |         __/‾‾
    |    __/‾‾
 1% | /‾‾
 0% |_________________________________________________
    0%    10%    20%    30%    40%    50%    60%+
                        Deviation
```

**Alternative Bonus Curves Available:**
- `linearBonus()` - Linear growth (lines 42-56)
- `sqrtBonus()` - Square root growth, slower (lines 65-80)
- `treasuryAdjustedBonus()` - Adjusts for treasury availability (lines 91-107)

---

## 5. Treasury Mechanism

### How Treasury is Funded

1. Misaligned traders pay fees when they swap
2. Fees accumulate in the hook contract
3. Hook periodically claims fees from Uniswap V4 PoolManager
4. Fees are added to treasury balances (separate for NATGAS and USDC)

### How Treasury Pays Bonuses

```solidity
// From treasuryAdjustedBonus (BonusCurve.sol:91-107)
idealBonus = (deviation² × multiplier) / 10000

if (treasuryBalance < bonusAmount) {
    // Reduce bonus proportionally if treasury low
    actualBonus = (idealBonus × treasuryBalance) / bonusAmount
} else {
    actualBonus = idealBonus
}
```

### Self-Sustaining Model

- High fees from misaligned → funds treasury
- Treasury pays bonuses to aligned → incentivizes price correction
- As price corrects, deviation decreases → fees and bonuses both decrease
- At equilibrium: symmetric fees, no bonuses, treasury grows

### Treasury Balance Formula

```
Treasury Growth = Fees Collected - Bonuses Paid

When pool misaligned:
  Fees Collected (high) > Bonuses Paid (moderate)
  Net: Treasury grows

When pool near equilibrium:
  Fees Collected (low) ≈ Bonuses Paid (low)
  Net: Treasury stable or grows slowly
```

---

## 6. Complete Trading Example

### Scenario Setup

- **Oracle (FDC)**: $3.50 (theoretical price)
- **Pool**: $4.20 (current market price)
- **Deviation**: 20% (pool too high)

### Misaligned Buyer (Pushes Price Higher)

**Trade:** Buys 100 NATGAS

```
Base quote: 100 NATGAS × $4.20 = $420.00
Fee (20% deviation): 1.1% (11000 bp)
Final cost: $420.00 × 1.011 = $424.62

Result:
- Trader pays: $424.62 in USDC
- Trader receives: 100 NATGAS
- Treasury receives: $4.62 in USDC fees
```

### Aligned Seller (Brings Price Down)

**Trade:** Sells 100 NATGAS

```
Base quote: 100 NATGAS × $4.20 = $420.00
Fee (aligned): 0.1% (100 bp)
Bonus (20% deviation): 0.4% (40 bp)

After fee: $420.00 × 0.999 = $419.58
Bonus payment: $420.00 × 0.004 = $1.68 (from treasury)
Total received: $419.58 + $1.68 = $421.26

Result:
- Trader pays: 100 NATGAS
- Trader receives: $421.26 in USDC (MORE than pool price!)
- Treasury pays: $1.68 in USDC bonus
```

### Treasury Impact

```
Collected: $4.62 from buyer
Paid: $1.68 to seller
Net gain: $2.94 (grows treasury for future bonuses)
```

### Arbitrage Profit

Aligned seller gets **$421.26** for tokens worth **$420.00** at pool price:
- **Profit: $1.26 per 100 NATGAS**
- **Profit margin: 0.3%**

This profit is **guaranteed** and **risk-free** when correcting price misalignments!

---

## 7. Why This Creates Strong Incentives

### For Aligned Traders

✅ Earn **ABOVE market price** when correcting mispricing
✅ Larger deviation = larger bonus (up to 5%)
✅ Creates profitable arbitrage opportunity
✅ Pay lower fees (0.1% vs 0.3% base)

**Example:** Sell at $4.20 pool, receive $4.21+ with bonus

### Against Misaligned Traders

❌ Pay **BELOW market price** when pushing price wrong direction
❌ Larger deviation = higher fees (up to 10%)
❌ Makes speculation expensive
❌ Pay high fees on top of base fee

**Example:** Buy at $4.20 pool, pay $4.24+ with fees

### Price Convergence Dynamics

```
High deviation (50%)
  → Massive bonuses (2.5-5%)
  → Arbitrageurs swarm
  → Price corrects rapidly

Medium deviation (20%)
  → Good bonuses (0.4%)
  → Some arbitrage activity
  → Price moves steadily

Low deviation (5%)
  → Small bonuses (0.025%)
  → Minor correction
  → Price stabilizes

Zero deviation (0%)
  → No bonuses
  → Equilibrium reached
  → Symmetric 0.3% fees for all
```

---

## 8. Key Design Principles

### 1. Quadratic Growth
- Small deviations = gentle incentives
- Large deviations = strong incentives
- Prevents overreaction to noise
- Scales naturally with market stress

### 2. Caps
- Maximum 10% fee prevents predatory pricing
- Maximum 5% bonus prevents treasury depletion
- Protects both traders and protocol

### 3. Symmetry
- Both fees and bonuses use same curve shape
- Ensures balanced incentives
- Natural equilibrium at 0% deviation

### 4. Self-Funding
- Misaligned traders pay for aligned trader bonuses
- No external subsidy needed
- Sustainable long-term

### 5. Gradual Curves
- Smooth transitions prevent gaming
- No sudden jumps in fees/bonuses
- Manipulation-resistant

### 6. Profitable Arbitrage
- Aligned traders **guaranteed** profit
- Net positive after fees and bonuses
- Economic incentive to correct price

---

## 9. Mathematical Properties

### Fee-to-Bonus Ratio

```
Fee multiplier: 2000
Bonus multiplier: 100
Ratio: 20:1

At any deviation:
  Fee collected ≈ 20 × Bonus paid

This ensures treasury grows over time
```

### Convergence Speed

```
High deviation → High bonuses → Fast convergence
Low deviation → Low bonuses → Slow convergence
Zero deviation → No bonuses → Stable equilibrium
```

### Nash Equilibrium

At equilibrium (pool price = theoretical price):
- Deviation = 0%
- Fee = 0.3% for all traders
- Bonus = 0% for all traders
- No incentive to trade unless fundamentals change

---

## 10. Code References

### Fee Formulas
- **File:** `packages/contracts/contracts/libraries/FeeCurve.sol`
- **Quadratic:** Lines 19-38
- **Linear:** Lines 48-66
- **Exponential:** Lines 76-96

### Bonus Formulas
- **File:** `packages/contracts/contracts/libraries/BonusCurve.sol`
- **Quadratic:** Lines 18-33
- **Linear:** Lines 42-56
- **Square Root:** Lines 65-80
- **Treasury Adjusted:** Lines 91-107

### Constants
```solidity
// Fee parameters
uint24 public constant ALIGNED_FEE = 100;        // 0.01%
uint24 public constant BASE_FEE = 3000;          // 0.3%
uint24 public constant MAX_MISALIGNED_FEE = 100000;  // 10%

// Bonus parameters
uint256 public constant MAX_BONUS_RATE = 500;    // 5%
uint256 public constant FEE_CURVE_MULTIPLIER = 2000;
uint256 public constant BONUS_CURVE_MULTIPLIER = 100;
```

---

## 11. Example Scenarios

### Scenario 1: Small Deviation (5%)

**Setup:** Pool at $3.675, Oracle at $3.50

```
Misaligned buyer:
- Fee: 0.35% (3500 bp)
- Pays: $3.675 × 1.0035 = $3.688

Aligned seller:
- Fee: 0.1%
- Bonus: 0.025%
- Receives: $3.675 × 0.999 + $3.675 × 0.00025 = $3.675
- Net: Approximately break-even with small profit

Treasury: Small net gain
```

### Scenario 2: Medium Deviation (30%)

**Setup:** Pool at $4.55, Oracle at $3.50

```
Misaligned buyer:
- Fee: 2.1% (21000 bp)
- Pays: $4.55 × 1.021 = $4.646

Aligned seller:
- Fee: 0.1%
- Bonus: 0.9%
- Receives: $4.55 × 0.999 + $4.55 × 0.009 = $4.586
- Net: $0.036 profit per NATGAS (0.79% profit margin)

Treasury: Moderate net gain
```

### Scenario 3: Large Deviation (60%)

**Setup:** Pool at $5.60, Oracle at $3.50

```
Misaligned buyer:
- Fee: 7.5% (capped near max)
- Pays: $5.60 × 1.075 = $6.02

Aligned seller:
- Fee: 0.1%
- Bonus: 3.6%
- Receives: $5.60 × 0.999 + $5.60 × 0.036 = $5.797
- Net: $0.197 profit per NATGAS (3.5% profit margin)

Treasury: Large net gain, enables future bonuses
```

---

## 12. Summary

The incentive mechanism creates a **self-reinforcing system** where:

1. **Price misalignments create arbitrage opportunities**
2. **Aligned traders earn risk-free profits**
3. **Misaligned traders fund the bonuses via fees**
4. **Treasury grows during high volatility**
5. **Price naturally converges to oracle value**
6. **System stabilizes at equilibrium**

This design ensures that the market **automatically** corrects price deviations through economic incentives rather than forced mechanisms.
