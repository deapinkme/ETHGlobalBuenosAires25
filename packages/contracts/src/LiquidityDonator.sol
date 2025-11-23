// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IUnlockCallback} from "@uniswap/v4-core/src/interfaces/callback/IUnlockCallback.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta, toBalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {ModifyLiquidityParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";

contract LiquidityDonator is IUnlockCallback {
    using CurrencyLibrary for Currency;

    IPoolManager public immutable poolManager;

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }

    function addLiquidity(
        PoolKey calldata key,
        uint256 amount0,
        uint256 amount1
    ) external {
        IERC20(Currency.unwrap(key.currency0)).transferFrom(msg.sender, address(this), amount0);
        IERC20(Currency.unwrap(key.currency1)).transferFrom(msg.sender, address(this), amount1);

        poolManager.unlock(abi.encode(key, amount0, amount1, msg.sender));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        require(msg.sender == address(poolManager), "Only pool manager");

        (PoolKey memory key, uint256 amount0, uint256 amount1, address sender) = abi.decode(
            data,
            (PoolKey, uint256, uint256, address)
        );

        int24 tickLower = TickMath.minUsableTick(key.tickSpacing);
        int24 tickUpper = TickMath.maxUsableTick(key.tickSpacing);

        int256 liquidityDelta = 1000000;

        (BalanceDelta delta, ) = poolManager.modifyLiquidity(
            key,
            ModifyLiquidityParams({
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: liquidityDelta,
                salt: bytes32(uint256(uint160(sender)))
            }),
            ""
        );

        if (delta.amount0() < 0) {
            IERC20(Currency.unwrap(key.currency0)).transfer(address(poolManager), uint256(int256(-delta.amount0())));
            poolManager.sync(key.currency0);
        }
        if (delta.amount1() < 0) {
            IERC20(Currency.unwrap(key.currency1)).transfer(address(poolManager), uint256(int256(-delta.amount1())));
            poolManager.sync(key.currency1);
        }

        return "";
    }
}
