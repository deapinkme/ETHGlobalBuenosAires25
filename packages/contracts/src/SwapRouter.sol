// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SwapRouter {
    using CurrencyLibrary for Currency;
    using SafeERC20 for IERC20;

    IPoolManager public immutable poolManager;

    struct SwapCallbackData {
        PoolKey key;
        SwapParams params;
        address sender;
    }

    constructor(IPoolManager _poolManager) {
        poolManager = _poolManager;
    }

    function swap(
        PoolKey memory key,
        SwapParams memory params,
        bytes memory hookData
    ) external returns (BalanceDelta delta) {
        SwapCallbackData memory data = SwapCallbackData({
            key: key,
            params: params,
            sender: msg.sender
        });

        delta = abi.decode(
            poolManager.unlock(abi.encode(data, hookData)),
            (BalanceDelta)
        );
    }

    function unlockCallback(bytes calldata rawData) external returns (bytes memory) {
        require(msg.sender == address(poolManager), "Only pool manager");

        (SwapCallbackData memory data, bytes memory hookData) = abi.decode(
            rawData,
            (SwapCallbackData, bytes)
        );

        BalanceDelta delta = poolManager.swap(data.key, data.params, hookData);

        if (data.params.zeroForOne) {
            if (delta.amount0() < 0) {
                IERC20(Currency.unwrap(data.key.currency0)).safeTransferFrom(
                    data.sender,
                    address(poolManager),
                    uint256(uint128(-delta.amount0()))
                );
                poolManager.settle();
            }
            if (delta.amount1() > 0) {
                poolManager.take(
                    data.key.currency1,
                    data.sender,
                    uint256(uint128(delta.amount1()))
                );
            }
        } else {
            if (delta.amount1() < 0) {
                IERC20(Currency.unwrap(data.key.currency1)).safeTransferFrom(
                    data.sender,
                    address(poolManager),
                    uint256(uint128(-delta.amount1()))
                );
                poolManager.settle();
            }
            if (delta.amount0() > 0) {
                poolManager.take(
                    data.key.currency0,
                    data.sender,
                    uint256(uint128(delta.amount0()))
                );
            }
        }

        return abi.encode(delta);
    }
}
