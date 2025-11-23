"use client";

import { useState } from "react";
import { Flame, TrendingUp, TrendingDown, DollarSign, Zap, ArrowUpDown, Wallet } from "lucide-react";
import { useAccount, useConnect, useDisconnect, useReadContract } from "wagmi";
import { formatUnits } from "viem";
import { CONTRACTS, POOL_ID } from "@/lib/config";
import { OracleReceiverABI, PoolManagerABI } from "@/lib/abis";

export default function Home() {
  const { address, isConnected } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const [swapAmount, setSwapAmount] = useState<number>(100);
  const [isSelling, setIsSelling] = useState<boolean>(true);

  const { data: oraclePriceRaw } = useReadContract({
    address: CONTRACTS.oracleReceiver,
    abi: OracleReceiverABI,
    functionName: 'getTheoreticalPrice',
  });

  const { data: lastUpdate } = useReadContract({
    address: CONTRACTS.oracleReceiver,
    abi: OracleReceiverABI,
    functionName: 'lastUpdateTimestamp',
  });

  const { data: poolLiquidity } = useReadContract({
    address: CONTRACTS.poolManager,
    abi: PoolManagerABI,
    functionName: 'getLiquidity',
    args: [POOL_ID],
  });

  const oraclePrice = oraclePriceRaw ? parseFloat(formatUnits(oraclePriceRaw, 6)) : 0;
  const poolPrice = oraclePrice;
  const deviation = 0;
  const isAligned = isSelling ? poolPrice > oraclePrice : poolPrice < oraclePrice;

  const calculateFee = () => {
    if (isAligned) return 0.01;
    const dev = parseFloat(deviation.toString());
    const baseFee = 0.3;
    const multiplier = 0.5;
    const fee = baseFee + (dev * dev * multiplier) / 100;
    return Math.min(fee, 10);
  };

  const calculateBonus = () => {
    if (!isAligned) return 0;
    const dev = parseFloat(deviation.toString());
    const maxBonus = 5;
    const bonus = (dev * dev * 0.05);
    return Math.min(bonus, maxBonus);
  };

  const fee = calculateFee();
  const bonus = calculateBonus();
  const netAmount = isAligned
    ? swapAmount + (swapAmount * bonus) / 100
    : swapAmount - (swapAmount * fee) / 100;

  const hasLiquidity = poolLiquidity && poolLiquidity > 0n;
  const lastUpdateDate = lastUpdate ? new Date(Number(lastUpdate) * 1000) : null;

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900">
      <div className="container mx-auto px-4 py-8">
        <header className="text-center mb-8">
          <div className="flex items-center justify-center gap-3 mb-4">
            <Flame className="w-12 h-12 text-orange-500" />
            <h1 className="text-5xl font-bold text-white">Natural Gas Hook</h1>
          </div>
          <p className="text-xl text-blue-200 mb-6">Asymmetric fees drive price convergence</p>

          <div className="flex justify-center">
            {!isConnected ? (
              <button
                onClick={() => connectors[0] && connect({ connector: connectors[0] })}
                className="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg flex items-center gap-2 transition-all"
              >
                <Wallet className="w-5 h-5" />
                Connect Wallet
              </button>
            ) : (
              <div className="flex items-center gap-4">
                <div className="px-4 py-2 bg-white/10 rounded-lg border border-white/20">
                  <span className="text-blue-200 text-sm">Connected: </span>
                  <span className="text-white font-mono">{address?.slice(0, 6)}...{address?.slice(-4)}</span>
                </div>
                <button
                  onClick={() => disconnect()}
                  className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white font-semibold rounded-lg transition-all"
                >
                  Disconnect
                </button>
              </div>
            )}
          </div>
        </header>

        {!hasLiquidity && (
          <div className="mb-8 p-6 bg-yellow-500/20 border-2 border-yellow-500/50 rounded-2xl">
            <div className="flex items-center gap-3">
              <div className="text-3xl">⚠️</div>
              <div>
                <h3 className="text-xl font-bold text-white mb-1">Pool Has No Liquidity</h3>
                <p className="text-blue-200">The pool is initialized but needs liquidity before swaps can execute. Add liquidity via the Uniswap V4 SDK to enable trading.</p>
              </div>
            </div>
          </div>
        )}

        <div className="grid md:grid-cols-2 gap-6 mb-8">
          <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 border border-white/20">
            <div className="flex items-center gap-3 mb-4">
              <Zap className="w-6 h-6 text-yellow-400" />
              <h2 className="text-2xl font-bold text-white">Oracle Price</h2>
            </div>
            {oraclePrice > 0 ? (
              <>
                <div className="text-5xl font-bold text-yellow-400 mb-2">${oraclePrice.toFixed(2)}</div>
                <p className="text-sm text-blue-200">Theoretical price from FDC oracles</p>
                {lastUpdateDate && (
                  <p className="text-xs text-blue-300 mt-2">
                    Last updated: {lastUpdateDate.toLocaleString()}
                  </p>
                )}
              </>
            ) : (
              <div className="text-2xl text-blue-200">Loading...</div>
            )}
          </div>

          <div className="bg-white/10 backdrop-blur-lg rounded-2xl p-6 border border-white/20">
            <div className="flex items-center gap-3 mb-4">
              <DollarSign className="w-6 h-6 text-green-400" />
              <h2 className="text-2xl font-bold text-white">Pool Status</h2>
            </div>
            <div className="space-y-3">
              <div>
                <div className="text-sm text-blue-200">Pool ID</div>
                <div className="text-xs font-mono text-white/80 break-all">{POOL_ID}</div>
              </div>
              <div>
                <div className="text-sm text-blue-200">Liquidity</div>
                <div className="text-2xl font-bold text-white">
                  {poolLiquidity !== undefined ? poolLiquidity.toString() : 'Loading...'}
                </div>
              </div>
              <div>
                <div className="text-sm text-blue-200">Status</div>
                <div className={`text-lg font-semibold ${hasLiquidity ? 'text-green-400' : 'text-red-400'}`}>
                  {hasLiquidity ? '✅ Active' : '❌ No Liquidity'}
                </div>
              </div>
            </div>
          </div>
        </div>

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

          <div className="grid md:grid-cols-3 gap-4 mb-6">
            <div className="p-4 rounded-xl bg-white/5">
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
                +${((swapAmount * bonus) / 100).toFixed(2)} bonus for helping price converge!
              </div>
            )}
          </div>
        </div>

        <div className="mt-8 bg-white/5 rounded-xl p-6 border border-white/10">
          <h3 className="text-xl font-bold text-white mb-4">Contract Addresses (Base Mainnet)</h3>
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-4 text-sm font-mono">
            <div>
              <div className="text-blue-300 mb-1">Oracle Receiver</div>
              <div className="text-white/80 break-all">{CONTRACTS.oracleReceiver}</div>
            </div>
            <div>
              <div className="text-blue-300 mb-1">MockUSDC</div>
              <div className="text-white/80 break-all">{CONTRACTS.mockUsdc}</div>
            </div>
            <div>
              <div className="text-blue-300 mb-1">NATGAS</div>
              <div className="text-white/80 break-all">{CONTRACTS.natgas}</div>
            </div>
            <div>
              <div className="text-blue-300 mb-1">Hook</div>
              <div className="text-white/80 break-all">{CONTRACTS.hook}</div>
            </div>
            <div>
              <div className="text-blue-300 mb-1">Pool Manager</div>
              <div className="text-white/80 break-all">{CONTRACTS.poolManager}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
