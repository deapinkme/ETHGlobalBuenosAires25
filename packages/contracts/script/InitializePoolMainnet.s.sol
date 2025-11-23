// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";

contract InitializePoolMainnet is Script {
    using PoolIdLibrary for PoolKey;

    address constant POOL_MANAGER = 0x498581fF718922c3f8e6A244956aF099B2652b2b;

    function run() external {
        address natgas = vm.envAddress("NATGAS_TOKEN_BASE");
        address usdc = vm.envAddress("MOCK_USDC_BASE");
        address hook = vm.envAddress("HOOK_ADDRESS");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("=====================================");
        console.log("Initializing V4 Pool on Base Mainnet");
        console.log("=====================================");
        console.log("PoolManager:", POOL_MANAGER);
        console.log("NATGAS:", natgas);
        console.log("MockUSDC:", usdc);
        console.log("Hook:", hook);

        Currency currency0;
        Currency currency1;

        if (uint160(usdc) < uint160(natgas)) {
            currency0 = Currency.wrap(usdc);
            currency1 = Currency.wrap(natgas);
            console.log("\nToken order: USDC (currency0) / NATGAS (currency1)");
        } else {
            currency0 = Currency.wrap(natgas);
            currency1 = Currency.wrap(usdc);
            console.log("\nToken order: NATGAS (currency0) / USDC (currency1)");
        }

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 0,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });

        uint160 sqrtPriceX96 = 79228162514264337593543950336;

        console.log("\nPool Key:");
        console.log("  currency0:", Currency.unwrap(key.currency0));
        console.log("  currency1:", Currency.unwrap(key.currency1));
        console.log("  fee:", key.fee);
        console.log("  tickSpacing:", key.tickSpacing);
        console.log("  hooks:", address(key.hooks));
        console.log("  sqrtPriceX96:", sqrtPriceX96, "(1:1 price)");

        vm.startBroadcast(deployerPrivateKey);

        IPoolManager(POOL_MANAGER).initialize(key, sqrtPriceX96);

        vm.stopBroadcast();

        PoolId poolId = key.toId();
        console.log("\nPool initialized!");
        console.log("Pool ID:");
        console.logBytes32(PoolId.unwrap(poolId));

        console.log("\nNext: Add liquidity with script/AddLiquidityMainnet.s.sol");
    }
}
