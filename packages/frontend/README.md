# Natural Gas Disruption Hook - Frontend

Interactive dashboard to visualize and test the Natural Gas Disruption Hook mechanism.

## 🚀 Features

- **Live Price Simulation** - Adjust oracle and pool prices with sliders
- **Real-time Fee Calculation** - See how fees change based on alignment and deviation
- **Bonus Visualization** - Calculate bonuses for aligned traders
- **Swap Simulator** - Test different swap scenarios
- **Interactive UI** - Beautiful gradient design with Lucide icons

## 🎮 What You Can Do

### Test the Mechanism

1. **Adjust Oracle Price** (Yellow slider) - Represents the "theoretical" price from FDC oracles
2. **Adjust Pool Price** (Green slider) - Represents current market price
3. **Watch Deviation** - See the percentage difference between oracle and pool
4. **Simulate Swaps**:
   - Enter swap amount
   - Choose Buy or Sell
   - See if you're aligned or misaligned
   - View your fee/bonus
   - Calculate net amount received

### Understanding Alignment

**When Pool > Oracle:**
- Sellers are ALIGNED (help push price down) → Get low fees + bonuses
- Buyers are MISALIGNED (push price up) → Pay high fees

**When Pool < Oracle:**
- Buyers are ALIGNED (help push price up) → Get low fees + bonuses
- Sellers are MISALIGNED (push price down) → Pay high fees

## 📊 Fee & Bonus Formulas

### Fees (Misaligned Traders)
```
baseFee = 0.3%
fee = baseFee + (deviation² × 0.5) / 100
cappedFee = min(fee, 10%)
```

### Bonuses (Aligned Traders)
```
bonus = (deviation² × 0.05)
cappedBonus = min(bonus, 5%)
```

## 🏗️ Tech Stack

- **Next.js 16.0.3** - React framework with Turbopack
- **React 19** - Latest React features
- **Tailwind CSS 4** - Utility-first styling
- **Lucide React** - Beautiful icons
- **TypeScript** - Type safety

## 🎨 Design Features

- Gradient background (slate-900 → blue-900)
- Glass-morphism cards
- Color-coded alignment states
- Responsive grid layout
- Real-time calculations
- Smooth transitions

## 🔗 Contract Addresses

Connected to local Anvil deployment:

- **Oracle**: `0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9`
- **USDC**: `0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512`
- **NATGAS**: `0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0`

## 🚦 Running

```bash
# Start development server
npm run dev

# Build for production
npm run build

# Start production server
npm start
```

Access at: **http://localhost:3000**

## 📝 Example Scenarios

### Scenario 1: Bubble (Pool too high)
```
Oracle: $100
Pool: $150 (50% too high)
Action: Sell 100 NATGAS
Result: ALIGNED
  - Fee: 0.01%
  - Bonus: 5% (capped)
  - You receive: $157.50 (above market!)
```

### Scenario 2: Crash (Pool too low)
```
Oracle: $100
Pool: $75 (25% too low)
Action: Buy 100 NATGAS
Result: ALIGNED
  - Fee: 0.01%
  - Bonus: 3.13%
  - You pay: $72.65 (below market!)
```

### Scenario 3: Fighting the Trend
```
Oracle: $100
Pool: $150 (50% too high)
Action: Buy 100 NATGAS
Result: MISALIGNED
  - Fee: 12.8% (would be capped at 10%)
  - Bonus: 0%
  - You pay: $165 (penalty!)
```

## 🎯 What Makes This Special

The frontend **perfectly visualizes the core innovation**:

1. **Visual Feedback** - Immediately see if you're helping or hurting price convergence
2. **Economic Incentives** - Watch how bonuses create profitable arbitrage
3. **Interactive Learning** - Test edge cases and understand the mechanism
4. **Real-time Math** - All calculations happen instantly as you adjust sliders

## 🚀 Next Steps

- [ ] Connect to actual Anvil contracts (read oracle price)
- [ ] Implement wallet connection (wagmi)
- [ ] Add transaction submission
- [ ] Show real balance updates
- [ ] Add charts for price history
- [ ] Deploy to testnet

---

**Built for ETHGlobal Buenos Aires 2025**
