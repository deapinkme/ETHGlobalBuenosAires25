// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

contract DeployCorrectPool is Script {
    using PoolIdLibrary for PoolKey;

    address constant POOL_MANAGER = 0x498581fF718922c3f8e6A244956aF099B2652b2b;
    address constant NATGAS = 0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD;
    address constant USDC = 0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a;
    address constant HOOK = 0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("=====================================");
        console.log("Deploying CORRECTED Pool");
        console.log("=====================================");
        console.log("Target: 1 NATGAS = $3.71 USDC");
        console.log("");

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(NATGAS),
            currency1: Currency.wrap(USDC),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        uint160 sqrtPriceX96 = 152604218284700732489728;

        console.log("Pool Configuration:");
        console.log("  currency0 (NATGAS):", NATGAS);
        console.log("  currency1 (USDC):", USDC);
        console.log("  sqrtPriceX96:", sqrtPriceX96);
        console.log("  This sets: 1 NATGAS = $3.71 USDC");
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        IPoolManager(POOL_MANAGER).initialize(key, sqrtPriceX96);

        vm.stopBroadcast();

        PoolId poolId = key.toId();
        console.log("=====================================");
        console.log("NEW Pool Initialized!");
        console.log("Pool ID:");
        console.logBytes32(PoolId.unwrap(poolId));
        console.log("=====================================");
    }
}
