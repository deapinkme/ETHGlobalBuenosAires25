// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { BaseHook } from "@uniswap/v4-periphery/src/utils/BaseHook.sol";
import { IPoolManager } from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import { Hooks } from "@uniswap/v4-core/src/libraries/Hooks.sol";
import { PoolKey } from "@uniswap/v4-core/src/types/PoolKey.sol";
import { PoolId, PoolIdLibrary } from "@uniswap/v4-core/src/types/PoolId.sol";
import { BalanceDelta } from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import { Currency, CurrencyLibrary } from "@uniswap/v4-core/src/types/Currency.sol";
import { BeforeSwapDelta, BeforeSwapDeltaLibrary } from "@uniswap/v4-core/src/types/BeforeSwapDelta.sol";
import { SwapParams } from "@uniswap/v4-core/src/types/PoolOperation.sol";
import { DisruptionOracle } from "./DisruptionOracle.sol";
import { FeeCurve } from "./libraries/FeeCurve.sol";
import { BonusCurve } from "./libraries/BonusCurve.sol";

contract NatGasDisruptionHook is BaseHook {
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;

    DisruptionOracle public immutable oracle;

    uint24 public constant ALIGNED_FEE = 100;
    uint24 public constant BASE_FEE = 3000;
    uint24 public constant MAX_MISALIGNED_FEE = 100000;
    uint256 public constant MAX_BONUS_RATE = 500;
    uint256 public constant FEE_MULTIPLIER = 10;
    uint256 public constant BONUS_MULTIPLIER = 5;

    mapping(PoolId => uint256) public manualPoolPrice;
    mapping(PoolId => uint256) public treasuryBalance;

    uint256 public cachedOraclePrice;
    uint256 public lastPriceUpdate;

    event PriceReceivedFromOracle(uint256 price, uint256 timestamp);
    event BonusPaid(PoolId indexed poolId, address indexed trader, uint256 amount);
    event TreasuryFunded(PoolId indexed poolId, uint256 amount);

    constructor(
        IPoolManager _poolManager,
        DisruptionOracle _oracle
    ) BaseHook(_poolManager) {
        oracle = _oracle;
        cachedOraclePrice = _oracle.getTheoreticalPrice();
        lastPriceUpdate = block.timestamp;
    }

    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
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

    function updatePriceFromOracle(uint256 price, uint256 timestamp) external {
        require(price > 0, "Invalid price");
        require(timestamp <= block.timestamp, "Future timestamp");

        cachedOraclePrice = price;
        lastPriceUpdate = timestamp;

        emit PriceReceivedFromOracle(price, timestamp);
    }

    function setPoolPrice(PoolKey calldata key, uint256 price) external {
        PoolId poolId = key.toId();
        manualPoolPrice[poolId] = price;
    }

    function fundTreasury(PoolKey calldata key) external payable {
        PoolId poolId = key.toId();
        treasuryBalance[poolId] += msg.value;
        emit TreasuryFunded(poolId, msg.value);
    }

    function calculateDeviation(
        uint256 poolPrice,
        uint256 theoreticalPrice
    ) public pure returns (uint256) {
        if (poolPrice > theoreticalPrice) {
            return ((poolPrice - theoreticalPrice) * 100) / theoreticalPrice;
        } else {
            return ((theoreticalPrice - poolPrice) * 100) / theoreticalPrice;
        }
    }

    function _beforeSwap(
        address,
        PoolKey calldata key,
        SwapParams calldata params,
        bytes calldata
    ) internal override returns (bytes4, BeforeSwapDelta, uint24) {
        PoolId poolId = key.toId();

        uint256 poolPrice = manualPoolPrice[poolId];
        if (poolPrice == 0) {
            poolPrice = cachedOraclePrice;
        }

        uint256 theoreticalPrice = cachedOraclePrice;

        uint256 deviation = calculateDeviation(poolPrice, theoreticalPrice);

        bool isBuyingNatGas = params.zeroForOne == (Currency.unwrap(key.currency0) < Currency.unwrap(key.currency1));
        bool isAligned;

        if (poolPrice > theoreticalPrice) {
            isAligned = !isBuyingNatGas;
        } else if (poolPrice < theoreticalPrice) {
            isAligned = isBuyingNatGas;
        } else {
            isAligned = true;
        }

        uint24 fee;
        if (isAligned) {
            fee = ALIGNED_FEE;
        } else {
            fee = FeeCurve.quadraticFee(
                deviation,
                BASE_FEE,
                FEE_MULTIPLIER,
                MAX_MISALIGNED_FEE
            );
        }

        return (BaseHook.beforeSwap.selector, BeforeSwapDeltaLibrary.ZERO_DELTA, fee);
    }

    function _afterSwap(
        address sender,
        PoolKey calldata key,
        SwapParams calldata params,
        BalanceDelta delta,
        bytes calldata
    ) internal override returns (bytes4, int128) {
        PoolId poolId = key.toId();

        uint256 poolPrice = manualPoolPrice[poolId];
        if (poolPrice == 0) {
            poolPrice = cachedOraclePrice;
        }

        uint256 theoreticalPrice = cachedOraclePrice;
        uint256 deviation = calculateDeviation(poolPrice, theoreticalPrice);

        bool isBuyingNatGas = params.zeroForOne == (Currency.unwrap(key.currency0) < Currency.unwrap(key.currency1));
        bool isAligned;

        if (poolPrice > theoreticalPrice) {
            isAligned = !isBuyingNatGas;
        } else if (poolPrice < theoreticalPrice) {
            isAligned = isBuyingNatGas;
        } else {
            isAligned = true;
        }

        if (isAligned && deviation > 0) {
            uint256 swapAmount = uint256(int256(delta.amount0() > 0 ? delta.amount0() : -delta.amount0()));

            uint256 bonusRate = BonusCurve.quadraticBonus(
                deviation,
                BONUS_MULTIPLIER,
                MAX_BONUS_RATE
            );

            uint256 bonusAmount = (swapAmount * bonusRate) / 10000;

            if (treasuryBalance[poolId] >= bonusAmount && bonusAmount > 0) {
                treasuryBalance[poolId] -= bonusAmount;

                emit BonusPaid(poolId, sender, bonusAmount);
            }
        }

        return (BaseHook.afterSwap.selector, 0);
    }
}
