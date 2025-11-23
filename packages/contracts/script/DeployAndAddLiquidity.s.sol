// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LiquidityDonator} from "../src/LiquidityDonator.sol";

contract DeployAndAddLiquidity is Script {
    address constant POOL_MANAGER = 0x498581fF718922c3f8e6A244956aF099B2652b2b;

    function run() external {
        address natgas = vm.envAddress("NATGAS_TOKEN_BASE");
        address usdc = vm.envAddress("MOCK_USDC_BASE");
        address hook = vm.envAddress("HOOK_ADDRESS");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying LiquidityDonator and adding liquidity");
        console.log("Deployer:", deployer);

        Currency currency0;
        Currency currency1;

        if (uint160(usdc) < uint160(natgas)) {
            currency0 = Currency.wrap(usdc);
            currency1 = Currency.wrap(natgas);
        } else {
            currency0 = Currency.wrap(natgas);
            currency1 = Currency.wrap(usdc);
        }

        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 0,
            tickSpacing: 60,
            hooks: IHooks(hook)
        });

        uint256 amount0 = 10000 * 10**18;
        uint256 amount1 = 10000 * 10**6;

        if (Currency.unwrap(currency0) == natgas) {
            // NATGAS is currency0
        } else {
            uint256 temp = amount0;
            amount0 = amount1;
            amount1 = temp;
        }

        console.log("Liquidity amounts:");
        console.log("  currency0:", amount0);
        console.log("  currency1:", amount1);

        vm.startBroadcast(deployerPrivateKey);

        LiquidityDonator donator = new LiquidityDonator(IPoolManager(POOL_MANAGER));
        console.log("LiquidityDonator deployed at:", address(donator));

        IERC20(Currency.unwrap(currency0)).approve(address(donator), amount0);
        IERC20(Currency.unwrap(currency1)).approve(address(donator), amount1);

        donator.addLiquidity(key, amount0, amount1);

        vm.stopBroadcast();

        console.log("Liquidity added!");
        console.log("Pool now has:");
        console.log("  ", amount0 / 10**18, "NATGAS");
        console.log("  ", amount1 / 10**6, "MockUSDC");
    }
}
