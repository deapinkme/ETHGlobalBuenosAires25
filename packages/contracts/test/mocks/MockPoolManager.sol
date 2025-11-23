// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";

contract MockPoolManager {
    uint24 public lastFeeSet;
    Currency public lastTakeCurrency;
    address public lastTakeRecipient;
    uint256 public lastTakeAmount;

    function updateDynamicLPFee(PoolKey calldata, uint24 newFee) external {
        lastFeeSet = newFee;
    }

    function take(Currency currency, address to, uint256 amount) external {
        lastTakeCurrency = currency;
        lastTakeRecipient = to;
        lastTakeAmount = amount;
    }
}
