"use client";

import { useState, useEffect } from "react";
import { Flame, TrendingUp, TrendingDown, DollarSign, Zap, ArrowUpDown } from "lucide-react";

const CONTRACTS = {
  oracle: "0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9",
  usdc: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
  natgas: "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0",
};

export default function Home() {
  const [oraclePrice, setOraclePrice] = useState<number>(100);
  const [poolPrice, setPoolPrice] = useState<number>(120);
  const [swapAmount, setSwapAmount] = useState<number>(100);
  const [isSelling, setIsSelling] = useState<boolean>(true);

  const deviation = ((Math.abs(poolPrice - oraclePrice) / oraclePrice) * 100).toFixed(2);
  const isAligned = isSelling ? poolPrice > oraclePrice : poolPrice < oraclePrice;

  const calculateFee = () => {
    if (isAligned) return 0.01;
    const dev = parseFloat(deviation);
    const baseFee = 0.3;
    const multiplier = 0.5;
    const fee = baseFee + (dev * dev * multiplier) / 100;
    return Math.min(fee, 10);
  };

  const calculateBonus = () => {
    if (!isAligned) return 0;
    const dev = parseFloat(deviation);
    const maxBonus = 5;
    const bonus = (dev * dev * 0.05);
    return Math.min(bonus, maxBonus);
  };

  const fee = calculateFee();
  const bonus = calculateBonus();
  const netAmount = isAligned
    ? swapAmount + (swapAmount * bonus) / 100
    : swapAmount - (swapAmount * fee) / 100;

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <header className="text-center mb-12">
          <div className="flex items-center justify-center gap-3 mb-4">
            <Flame className="w-12 h-12 text-orange-500" />
            <h1 className="text-5xl font-bold text-white">Natural Gas Hook</h1>
          </div>
          <p className="text-xl text-blue-200">Asymmetric fees drive price convergence</p>
        </header>

        {/* Main Grid */}
        <div className="grid md:grid-cols-2 gap-6 mb-8">
          {/* Oracle Price */}
          <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 border border-white/20">
            <div className="flex items-center gap-3 mb-4">
              <Zap className="w-6 h-6 text-yellow-400" />
              <h2 className="text-2xl font-bold text-white">Oracle Price</h2>
            </div>
            <div className="text-5xl font-bold text-yellow-400 mb-4">${oraclePrice.toFixed(2)}</div>
            <input
              type="range"
              min="50"
              max="300"
              value={oraclePrice}
              onChange={(e) => setOraclePrice(parseFloat(e.target.value))}
              className="w-full h-2 bg-white/20 rounded-lg appearance-none cursor-pointer"
            />
            <p className="text-sm text-blue-200 mt-2">Theoretical price from FDC oracles</p>
          </div>

          {/* Pool Price */}
          <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 border border-white/20">
            <div className="flex items-center gap-3 mb-4">
              <DollarSign className="w-6 h-6 text-green-400" />
              <h2 className="text-2xl font-bold text-white">Pool Price</h2>
            </div>
            <div className="text-5xl font-bold text-green-400 mb-4">${poolPrice.toFixed(2)}</div>
            <input
              type="range"
              min="50"
              max="300"
              value={poolPrice}
              onChange={(e) => setPoolPrice(parseFloat(e.target.value))}
              className="w-full h-2 bg-white/20 rounded-lg appearance-none cursor-pointer"
            />
            <p className="text-sm text-blue-200 mt-2">Current market price</p>
          </div>
        </div>

        {/* Deviation Alert */}
        <div className={`mb-8 p-6 rounded-2xl border-2 ${
          poolPrice > oraclePrice
            ? 'bg-red-500/20 border-red-500/50'
            : poolPrice < oraclePrice
            ? 'bg-blue-500/20 border-blue-500/50'
            : 'bg-green-500/20 border-green-500/50'
        }`}>
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              {poolPrice > oraclePrice ? (
                <TrendingUp className="w-8 h-8 text-red-400" />
              ) : poolPrice < oraclePrice ? (
                <TrendingDown className="w-8 h-8 text-blue-400" />
              ) : (
                <ArrowUpDown className="w-8 h-8 text-green-400" />
              )}
              <div>
                <h3 className="text-2xl font-bold text-white">
                  {deviation}% Deviation
                </h3>
                <p className="text-blue-200">
                  {poolPrice > oraclePrice
                    ? "Pool price is HIGH - Sellers get bonuses!"
                    : poolPrice < oraclePrice
                    ? "Pool price is LOW - Buyers get bonuses!"
                    : "Perfect equilibrium"}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Swap Simulator */}
        <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-8 border border-white/20">
          <h2 className="text-3xl font-bold text-white mb-6">Swap Simulator</h2>

          <div className="grid md:grid-cols-2 gap-6 mb-6">
            <div>
              <label className="block text-sm font-medium text-blue-200 mb-2">Swap Amount</label>
              <input
                type="number"
                value={swapAmount}
                onChange={(e) => setSwapAmount(parseFloat(e.target.value) || 0)}
                className="w-full bg-white/5 border border-white/20 rounded-lg px-4 py-3 text-white text-lg"
                placeholder="Amount"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-blue-200 mb-2">Direction</label>
              <div className="flex gap-2">
                <button
                  onClick={() => setIsSelling(true)}
                  className={`flex-1 px-4 py-3 rounded-lg font-semibold transition-all ${
                    isSelling
                      ? "bg-red-500 text-white"
                      : "bg-white/5 text-blue-200 hover:bg-white/10"
                  }`}
                >
                  Sell NATGAS
                </button>
                <button
                  onClick={() => setIsSelling(false)}
                  className={`flex-1 px-4 py-3 rounded-lg font-semibold transition-all ${
                    !isSelling
                      ? "bg-green-500 text-white"
                      : "bg-white/5 text-blue-200 hover:bg-white/10"
                  }`}
                >
                  Buy NATGAS
                </button>
              </div>
            </div>
          </div>

          {/* Results */}
          <div className="grid md:grid-cols-3 gap-4 mb-6">
            <div className={`p-4 rounded-xl ${
              isAligned ? 'bg-green-500/20' : 'bg-red-500/20'
            }`}>
              <div className="text-sm text-blue-200 mb-1">Alignment</div>
              <div className="text-2xl font-bold text-white">
                {isAligned ? "✅ Aligned" : "❌ Misaligned"}
              </div>
            </div>

            <div className="p-4 rounded-xl bg-white/5">
              <div className="text-sm text-blue-200 mb-1">Fee</div>
              <div className="text-2xl font-bold text-white">
                {fee.toFixed(2)}%
              </div>
            </div>

            <div className="p-4 rounded-xl bg-white/5">
              <div className="text-sm text-blue-200 mb-1">Bonus</div>
              <div className="text-2xl font-bold text-white">
                {bonus.toFixed(2)}%
              </div>
            </div>
          </div>

          <div className="bg-gradient-to-r from-blue-500/20 to-purple-500/20 rounded-xl p-6 border border-white/20">
            <div className="flex items-center justify-between mb-4">
              <span className="text-lg text-blue-200">You send:</span>
              <span className="text-2xl font-bold text-white">{swapAmount.toFixed(2)} {isSelling ? 'NATGAS' : 'USDC'}</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-lg text-blue-200">You receive:</span>
              <span className="text-3xl font-bold text-green-400">
                {netAmount.toFixed(2)} {isSelling ? 'USDC' : 'NATGAS'}
              </span>
            </div>
            {isAligned && bonus > 0 && (
              <div className="mt-4 text-center text-green-400 font-semibold">
                🎉 +${((swapAmount * bonus) / 100).toFixed(2)} bonus for helping price converge!
              </div>
            )}
          </div>
        </div>

        {/* Contract Addresses */}
        <div className="mt-8 bg-white/5 rounded-xl p-6 border border-white/10">
          <h3 className="text-xl font-bold text-white mb-4">Contract Addresses (Anvil)</h3>
          <div className="grid md:grid-cols-3 gap-4 text-sm font-mono">
            <div>
              <div className="text-blue-300 mb-1">Oracle</div>
              <div className="text-white/80">{CONTRACTS.oracle}</div>
            </div>
            <div>
              <div className="text-blue-300 mb-1">USDC</div>
              <div className="text-white/80">{CONTRACTS.usdc}</div>
            </div>
            <div>
              <div className="text-blue-300 mb-1">NATGAS</div>
              <div className="text-white/80">{CONTRACTS.natgas}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
