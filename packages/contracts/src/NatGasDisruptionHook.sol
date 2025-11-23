// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {BeforeSwapDelta, BeforeSwapDeltaLibrary} from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {DisruptionOracle} from "./DisruptionOracle.sol";
import {FeeCurve} from "./libraries/FeeCurve.sol";
import {BonusCurve} from "./libraries/BonusCurve.sol";

contract NatGasDisruptionHook is IHooks {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using BeforeSwapDeltaLibrary for BeforeSwapDelta;

    IPoolManager public immutable poolManager;
    DisruptionOracle public immutable oracle;

    uint24 public constant ALIGNED_FEE = 100;
    uint24 public constant BASE_FEE = 3000;
    uint24 public constant MAX_MISALIGNED_FEE = 100000;
    uint256 public constant MAX_BONUS_RATE = 500;
    uint256 public constant FEE_MULTIPLIER = 2;
    uint256 public constant BONUS_MULTIPLIER = 1;

    mapping(PoolId => uint256) public treasuryToken0;
    mapping(PoolId => uint256) public treasuryToken1;
    mapping(PoolId => uint256) public manualPoolPrice;

    event DynamicFeeSet(PoolId indexed poolId, uint24 fee, uint256 deviation);
    event BonusPaid(PoolId indexed poolId, address indexed trader, uint256 amount, bool isToken0);

    error NotPoolManager();
    error HookNotImplemented();

    modifier onlyPoolManager() {
        if (msg.sender != address(poolManager)) revert NotPoolManager();
        _;
    }

    constructor(IPoolManager _poolManager, DisruptionOracle _oracle) {
        poolManager = _poolManager;
        oracle = _oracle;
    }

    function getHookPermissions() public pure returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: false,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: true,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: false,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    function beforeInitialize(address, PoolKey calldata, uint160) external pure returns (bytes4) {
        revert HookNotImplemented();
    }

    function afterInitialize(address, PoolKey calldata, uint160, int24) external pure returns (bytes4) {
        revert HookNotImplemented();
    }

    function beforeAddLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function beforeRemoveLiquidity(address, PoolKey calldata, IPoolManager.ModifyLiquidityParams calldata, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function afterAddLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function afterRemoveLiquidity(
        address,
        PoolKey calldata,
        IPoolManager.ModifyLiquidityParams calldata,
        BalanceDelta,
        BalanceDelta,
        bytes calldata
    ) external pure returns (bytes4, BalanceDelta) {
        revert HookNotImplemented();
    }

    function beforeDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function afterDonate(address, PoolKey calldata, uint256, uint256, bytes calldata)
        external
        pure
        returns (bytes4)
    {
        revert HookNotImplemented();
    }

    function setPoolPrice(PoolKey calldata key, uint256 price) external {
        PoolId poolId = key.toId();
        manualPoolPrice[poolId] = price;
    }

    function beforeSwap(
        address,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        bytes calldata
    ) external onlyPoolManager returns (bytes4, BeforeSwapDelta, uint24) {
        PoolId poolId = key.toId();

        uint256 theoreticalPrice = oracle.getTheoreticalPrice();
        uint256 poolPrice = manualPoolPrice[poolId];

        require(poolPrice > 0, "Pool price not set");

        uint256 deviation = calculateDeviation(poolPrice, theoreticalPrice);

        bool isBuyingToken0 = params.zeroForOne;
        bool isAligned = checkAlignment(poolPrice, theoreticalPrice, isBuyingToken0);

        uint24 fee;
        if (isAligned) {
            fee = ALIGNED_FEE;
        } else {
            fee = FeeCurve.quadraticFee(deviation, BASE_FEE, FEE_MULTIPLIER, MAX_MISALIGNED_FEE);
        }

        poolManager.updateDynamicLPFee(key, fee);

        emit DynamicFeeSet(poolId, fee, deviation);

        return (IHooks.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, 0);
    }

    function afterSwap(
        address sender,
        PoolKey calldata key,
        IPoolManager.SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) external onlyPoolManager returns (bytes4, int128) {
        PoolId poolId = key.toId();

        uint256 theoreticalPrice = oracle.getTheoreticalPrice();
        uint256 poolPrice = manualPoolPrice[poolId];

        if (poolPrice == 0) {
            return (IHooks.afterSwap.selector, 0);
        }

        uint256 deviation = calculateDeviation(poolPrice, theoreticalPrice);

        bool isBuyingToken0 = params.zeroForOne;
        bool isAligned = checkAlignment(poolPrice, theoreticalPrice, isBuyingToken0);

        if (isAligned && deviation > 0) {
            uint256 bonusRate = BonusCurve.quadraticBonus(deviation, BONUS_MULTIPLIER, MAX_BONUS_RATE);

            int128 swapAmount = isBuyingToken0 ? delta.amount1() : delta.amount0();
            uint256 absSwapAmount = swapAmount < 0 ? uint256(uint128(-swapAmount)) : uint256(uint128(swapAmount));

            uint256 bonusAmount = (absSwapAmount * bonusRate) / 10000;

            if (isBuyingToken0) {
                if (treasuryToken0[poolId] >= bonusAmount && bonusAmount > 0) {
                    treasuryToken0[poolId] -= bonusAmount;
                    poolManager.take(key.currency0, sender, bonusAmount);
                    emit BonusPaid(poolId, sender, bonusAmount, true);
                }
            } else {
                if (treasuryToken1[poolId] >= bonusAmount && bonusAmount > 0) {
                    treasuryToken1[poolId] -= bonusAmount;
                    poolManager.take(key.currency1, sender, bonusAmount);
                    emit BonusPaid(poolId, sender, bonusAmount, false);
                }
            }
        }

        return (IHooks.afterSwap.selector, 0);
    }

    function calculateDeviation(uint256 poolPrice, uint256 theoreticalPrice) public pure returns (uint256) {
        if (theoreticalPrice == 0) return 0;

        uint256 diff = poolPrice > theoreticalPrice
            ? poolPrice - theoreticalPrice
            : theoreticalPrice - poolPrice;

        return (diff * 100) / theoreticalPrice;
    }

    function checkAlignment(
        uint256 poolPrice,
        uint256 theoreticalPrice,
        bool isBuyingToken0
    ) public pure returns (bool) {
        if (poolPrice == theoreticalPrice) return true;

        bool poolAboveTheoretical = poolPrice > theoreticalPrice;

        if (poolAboveTheoretical) {
            return !isBuyingToken0;
        } else {
            return isBuyingToken0;
        }
    }

    function fundTreasury(PoolKey calldata key, uint256 amount0, uint256 amount1) external {
        PoolId poolId = key.toId();
        treasuryToken0[poolId] += amount0;
        treasuryToken1[poolId] += amount1;
    }
}
