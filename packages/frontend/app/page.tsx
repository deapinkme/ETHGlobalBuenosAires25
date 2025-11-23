"use client";

import { useState } from "react";
import { Flame, TrendingUp, TrendingDown, DollarSign, Zap, ArrowUpDown, Wallet } from "lucide-react";
import { useAccount, useConnect, useDisconnect, useReadContract, useWriteContract, useWaitForTransactionReceipt, useSwitchChain } from "wagmi";
import { formatUnits, parseUnits } from "viem";
import { base } from "wagmi/chains";
import { CONTRACTS, POOL_ID } from "@/lib/config";
import { OracleReceiverABI, ERC20ABI, SwapRouterABI, PoolManagerABI } from "@/lib/abis";

export default function Home() {
  const { address, isConnected, chain } = useAccount();
  const { connect, connectors } = useConnect();
  const { disconnect } = useDisconnect();
  const { switchChain } = useSwitchChain();
  const [swapAmount, setSwapAmount] = useState<number>(1);
  const [isSelling, setIsSelling] = useState<boolean>(true);
  const [simulatedPoolPrice, setSimulatedPoolPrice] = useState<number>(0);

  const { writeContract: writeApprove, data: approveHash, isPending: isApproving } = useWriteContract();
  const { isLoading: isApprovingConfirm, isSuccess: isApproveSuccess } = useWaitForTransactionReceipt({
    hash: approveHash,
  });

  const { writeContract: writeSwap, data: swapHash, isPending: isSwapping } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isSwapSuccess } = useWaitForTransactionReceipt({
    hash: swapHash,
  });

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

  const poolStorageSlot = (() => {
    const poolIdBytes = POOL_ID.slice(2);
    const mappingSlot = '0000000000000000000000000000000000000000000000000000000000000006';
    const concat = poolIdBytes + mappingSlot;
    return `0x${Array.from(new Uint8Array(32).fill(0)).map((_, i) => {
      const hash = Array.from(concat.match(/.{1,2}/g) || []).map(byte => parseInt(byte, 16));
      return 0;
    }).map(() => '00').join('')}` as `0x${string}`;
  })();

  const { data: slot0Packed } = useReadContract({
    address: CONTRACTS.poolManager,
    abi: PoolManagerABI,
    functionName: 'extsload',
    args: ['0xc6a77b7e5896f3748d6af990d08f7acc5acfc2690a27bb0e7f977d988cae6fb5' as `0x${string}`],
  });

  const oraclePrice = oraclePriceRaw ? parseFloat(formatUnits(oraclePriceRaw, 6)) : 0;

  const actualPoolPrice = slot0Packed ? (() => {
    const slot0Int = BigInt(slot0Packed);
    const MASK_160 = (BigInt(1) << BigInt(160)) - BigInt(1);
    const sqrtPriceX96 = slot0Int & MASK_160;
    const Q96 = BigInt(2) ** BigInt(96);
    const sqrtPrice = Number(sqrtPriceX96) / Number(Q96);
    const priceRatio = sqrtPrice * sqrtPrice;
    return priceRatio * 1e12;
  })() : 0;
  const poolPrice = simulatedPoolPrice || oraclePrice;
  const deviation = oraclePrice > 0 ? Math.abs((poolPrice - oraclePrice) / oraclePrice * 100) : 0;
  const isAligned = poolPrice === oraclePrice ? false :
    (isSelling ? poolPrice > oraclePrice : poolPrice < oraclePrice);

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

  const hasLiquidity = true;
  const lastUpdateDate = lastUpdate ? new Date(Number(lastUpdate) * 1000) : null;
  const isWrongNetwork = isConnected && chain?.id !== base.id;

  const handleApprove = () => {
    if (!isConnected) return;
    const tokenToApprove = isSelling ? CONTRACTS.natgas : CONTRACTS.mockUsdc;
    writeApprove({
      address: tokenToApprove,
      abi: ERC20ABI,
      functionName: 'approve',
      args: [CONTRACTS.swapRouter, parseUnits('1000000', isSelling ? 18 : 6)],
    } as any);
  };

  const handleSwap = () => {
    if (!isConnected || !swapAmount) return;

    const poolKey = {
      currency0: CONTRACTS.natgas,
      currency1: CONTRACTS.mockUsdc,
      fee: 3000,
      tickSpacing: 60,
      hooks: CONTRACTS.hook,
    };

    const swapParams = {
      zeroForOne: isSelling,
      amountSpecified: isSelling
        ? -parseUnits(swapAmount.toString(), 18)
        : -parseUnits(swapAmount.toString(), 6),
      sqrtPriceLimitX96: isSelling ? 4295128739n : 1461446703485210103287273052203988822378723970342n,
    };

    writeSwap({
      address: CONTRACTS.swapRouter,
      abi: SwapRouterABI,
      functionName: 'swap',
      args: [poolKey, swapParams, '0x'],
    } as any);
  };

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
                  <div className="text-xs text-blue-300 mt-1">
                    {chain?.name || 'Unknown Network'} ({chain?.id})
                  </div>
                </div>
                {isWrongNetwork && (
                  <button
                    onClick={() => switchChain({ chainId: base.id })}
                    className="px-4 py-2 bg-orange-600 hover:bg-orange-700 text-white font-semibold rounded-lg transition-all"
                  >
                    Switch to Base Mainnet
                  </button>
                )}
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

        {isWrongNetwork && (
          <div className="mb-8 p-6 bg-red-500/20 border-2 border-red-500/50 rounded-2xl">
            <div className="flex items-center gap-3">
              <div className="text-3xl">⚠️</div>
              <div>
                <h3 className="text-xl font-bold text-white mb-1">Wrong Network</h3>
                <p className="text-blue-200">
                  You're connected to {chain?.name || 'an unsupported network'}. Please switch to Base Mainnet (Chain ID: 8453) to use this app.
                </p>
                <button
                  onClick={() => switchChain({ chainId: base.id })}
                  className="mt-3 px-4 py-2 bg-orange-600 hover:bg-orange-700 text-white font-semibold rounded-lg transition-all"
                >
                  Switch to Base Mainnet
                </button>
              </div>
            </div>
          </div>
        )}

        <div className="mb-8 p-6 bg-gradient-to-r from-blue-500/20 to-purple-500/20 border-2 border-blue-500/50 rounded-2xl">
          <div className="flex items-center gap-3">
            <div className="text-3xl">⚡</div>
            <div>
              <h3 className="text-xl font-bold text-white mb-2">How It Works</h3>
              <p className="text-blue-200 text-sm">
                This hook uses <strong>asymmetric fees</strong> to drive price convergence. When pool price deviates from oracle:
              </p>
              <div className="mt-3 grid md:grid-cols-2 gap-3 text-sm">
                <div className="flex items-start gap-2">
                  <span className="text-green-400 text-lg">✓</span>
                  <div>
                    <strong className="text-green-400">Aligned traders</strong> pay 0.01% fee and receive bonuses for helping converge
                  </div>
                </div>
                <div className="flex items-start gap-2">
                  <span className="text-red-400 text-lg">✗</span>
                  <div>
                    <strong className="text-red-400">Misaligned traders</strong> pay 0.3-10% fees that fund the bonus pool
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

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
                <div className="text-sm text-blue-200">Pool Fee</div>
                <div className="text-lg font-bold text-white">
                  0.3% (3000 basis points)
                </div>
              </div>
              <div>
                <div className="text-sm text-blue-200">Current Pool Price</div>
                <div className="text-lg font-bold text-white">
                  {actualPoolPrice > 0 ? `$${actualPoolPrice.toFixed(2)} per NATGAS` : 'Loading...'}
                </div>
                <div className="text-xs text-blue-300">
                  {actualPoolPrice > 0 && oraclePrice > 0 && (
                    <>Deviation: {Math.abs((actualPoolPrice - oraclePrice) / oraclePrice * 100).toFixed(2)}%</>
                  )}
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

          <div className="grid md:grid-cols-3 gap-6 mb-6">
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
              <label className="block text-sm font-medium text-blue-200 mb-2">
                Simulated Pool Price ${oraclePrice > 0 && `(Oracle: $${oraclePrice.toFixed(2)})`}
              </label>
              <input
                type="number"
                step="0.01"
                value={simulatedPoolPrice}
                onChange={(e) => setSimulatedPoolPrice(parseFloat(e.target.value) || 0)}
                className="w-full bg-white/5 border border-white/20 rounded-lg px-4 py-3 text-white text-lg"
                placeholder={oraclePrice.toFixed(2)}
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

          <div className="grid md:grid-cols-4 gap-4 mb-6">
            <div className="p-4 rounded-xl bg-white/5">
              <div className="text-sm text-blue-200 mb-1">Price Deviation</div>
              <div className="text-2xl font-bold text-white">
                {deviation.toFixed(2)}%
              </div>
            </div>

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

          <div className="mt-6 p-4 bg-blue-500/10 border border-blue-500/30 rounded-xl">
            <h3 className="text-lg font-bold text-white mb-2">💡 Try These Scenarios</h3>
            <div className="grid md:grid-cols-2 gap-3 text-sm">
              <button
                onClick={() => {
                  setSimulatedPoolPrice(oraclePrice * 1.1);
                  setIsSelling(true);
                }}
                className="p-3 bg-white/5 hover:bg-white/10 rounded-lg text-left transition-all"
              >
                <div className="font-semibold text-green-400">Pool Overvalued (+10%)</div>
                <div className="text-blue-200">Sell NATGAS → Get bonus!</div>
              </button>
              <button
                onClick={() => {
                  setSimulatedPoolPrice(oraclePrice * 0.9);
                  setIsSelling(false);
                }}
                className="p-3 bg-white/5 hover:bg-white/10 rounded-lg text-left transition-all"
              >
                <div className="font-semibold text-green-400">Pool Undervalued (-10%)</div>
                <div className="text-blue-200">Buy NATGAS → Get bonus!</div>
              </button>
              <button
                onClick={() => {
                  setSimulatedPoolPrice(oraclePrice * 0.9);
                  setIsSelling(true);
                }}
                className="p-3 bg-white/5 hover:bg-white/10 rounded-lg text-left transition-all"
              >
                <div className="font-semibold text-red-400">Pool Undervalued (-10%)</div>
                <div className="text-blue-200">Sell NATGAS → Pay high fee!</div>
              </button>
              <button
                onClick={() => {
                  setSimulatedPoolPrice(oraclePrice * 1.1);
                  setIsSelling(false);
                }}
                className="p-3 bg-white/5 hover:bg-white/10 rounded-lg text-left transition-all"
              >
                <div className="font-semibold text-red-400">Pool Overvalued (+10%)</div>
                <div className="text-blue-200">Buy NATGAS → Pay high fee!</div>
              </button>
            </div>
          </div>

          <div className="mt-6 p-4 bg-yellow-500/10 border border-yellow-500/30 rounded-xl">
            <h3 className="text-lg font-bold text-white mb-3">⚡ Execute Real Swap on Base Mainnet</h3>

            {!isConnected ? (
              <p className="text-blue-200 text-sm">
                Connect your wallet to execute swaps
              </p>
            ) : isWrongNetwork ? (
              <div className="p-4 bg-orange-500/20 border border-orange-500/50 rounded-lg">
                <div className="text-orange-400 font-bold mb-2">⚠️ Wrong Network</div>
                <p className="text-blue-200 text-sm mb-3">
                  Switch to Base Mainnet to execute swaps
                </p>
                <button
                  onClick={() => switchChain({ chainId: base.id })}
                  className="px-4 py-2 bg-orange-600 hover:bg-orange-700 text-white font-semibold rounded-lg transition-all"
                >
                  Switch Network
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                {isApproveSuccess && (
                  <div className="p-3 bg-green-500/20 border border-green-500/50 rounded-lg">
                    <div className="text-green-400 text-sm font-bold">✅ Approval Successful</div>
                    <a
                      href={`https://basescan.org/tx/${approveHash}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-300 hover:text-blue-200 text-xs underline"
                    >
                      View approval on BaseScan →
                    </a>
                  </div>
                )}
                {isSwapSuccess && (
                  <div className="p-3 bg-green-500/20 border border-green-500/50 rounded-lg">
                    <div className="text-green-400 text-sm font-bold">✅ Swap Successful!</div>
                    <a
                      href={`https://basescan.org/tx/${swapHash}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-blue-300 hover:text-blue-200 text-xs underline"
                    >
                      View swap on BaseScan →
                    </a>
                  </div>
                )}
                <div className="flex gap-3">
                  <button
                    onClick={handleApprove}
                    disabled={isApproving || isApprovingConfirm}
                    className="flex-1 px-4 py-3 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-semibold rounded-lg transition-all"
                  >
                    {isApproving || isApprovingConfirm ? 'Approving...' : `1. Approve ${isSelling ? 'NATGAS' : 'USDC'}`}
                  </button>
                  <button
                    onClick={handleSwap}
                    disabled={isSwapping || isConfirming}
                    className="flex-1 px-4 py-3 bg-green-600 hover:bg-green-700 disabled:bg-gray-600 disabled:cursor-not-allowed text-white font-semibold rounded-lg transition-all"
                  >
                    {isSwapping ? 'Swapping...' : isConfirming ? 'Confirming...' : `2. Swap ${swapAmount} ${isSelling ? 'NATGAS' : 'USDC'}`}
                  </button>
                </div>
                <p className="text-blue-200 text-xs">
                  Step 1: Approve token spending | Step 2: Execute swap through your hook
                </p>
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
            <div>
              <div className="text-blue-300 mb-1">Swap Router</div>
              <div className="text-white/80 break-all">{CONTRACTS.swapRouter}</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
