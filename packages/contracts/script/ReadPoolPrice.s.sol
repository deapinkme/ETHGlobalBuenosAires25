// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

interface IPoolManager {
    function pools(bytes32 id) external view returns (
        uint160 sqrtPriceX96,
        int24 tick,
        uint24 protocolFee,
        uint24 lpFee
    );
}

contract ReadPoolPrice is Script {
    address constant POOL_MANAGER = 0x498581fF718922c3f8e6A244956aF099B2652b2b;
    bytes32 constant POOL_ID = 0xee3563ab546dddd4c9b8c4db4721077d62d363bfeabf0a98b5ed786e0ff2a7be;

    function run() external view {
        console.log("Reading pool price for pool:", uint256(POOL_ID));

        (uint160 sqrtPriceX96, int24 tick, uint24 protocolFee, uint24 lpFee) =
            IPoolManager(POOL_MANAGER).pools(POOL_ID);

        console.log("sqrtPriceX96:", sqrtPriceX96);
        console.log("tick:", uint256(int256(tick)));
        console.log("protocolFee:", protocolFee);
        console.log("lpFee:", lpFee);

        uint256 sqrtPrice = uint256(sqrtPriceX96);
        uint256 price = (sqrtPrice * sqrtPrice * 1e6) / (2**192);

        console.log("Calculated price (USDC per NATGAS with decimals):", price);
    }
}
