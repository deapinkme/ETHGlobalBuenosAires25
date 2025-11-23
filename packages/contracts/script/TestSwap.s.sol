// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";

contract TestSwap is Script {
    address constant POOL_MANAGER = 0x498581fF718922c3f8e6A244956aF099B2652b2b;
    address constant NATGAS = 0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD;
    address constant USDC = 0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a;
    address constant HOOK = 0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=================================");
        console.log("TESTING SWAP ON LIVE POOL");
        console.log("=================================");
        console.log("Deployer:", deployer);

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(NATGAS),
            currency1: Currency.wrap(USDC),
            fee: 0,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n1. Deploying PoolSwapTest helper...");
        PoolSwapTest swapRouter = new PoolSwapTest(IPoolManager(POOL_MANAGER));
        console.log("SwapRouter deployed at:", address(swapRouter));

        console.log("\n2. Checking balances...");
        uint256 natgasBalance = IERC20(NATGAS).balanceOf(deployer);
        uint256 usdcBalance = IERC20(USDC).balanceOf(deployer);
        console.log("NATGAS balance:", natgasBalance / 1e18, "tokens");
        console.log("USDC balance:", usdcBalance / 1e6, "tokens");

        console.log("\n3. Approving tokens to SwapRouter...");
        IERC20(NATGAS).approve(address(swapRouter), type(uint256).max);
        IERC20(USDC).approve(address(swapRouter), type(uint256).max);

        console.log("\n4. Executing swap: Sell 1 NATGAS for USDC");
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -1000000000000000000,
            sqrtPriceLimitX96: 4295128739
        });

        PoolSwapTest.TestSettings memory testSettings = PoolSwapTest.TestSettings({
            takeClaims: false,
            settleUsingBurn: false
        });

        swapRouter.swap(key, params, testSettings, "");

        console.log("\n5. Checking balances after swap...");
        uint256 natgasAfter = IERC20(NATGAS).balanceOf(deployer);
        uint256 usdcAfter = IERC20(USDC).balanceOf(deployer);
        console.log("NATGAS after:", natgasAfter / 1e18, "tokens");
        console.log("USDC after:", usdcAfter / 1e6, "tokens");

        console.log("\nNATGAS sold:", (natgasBalance - natgasAfter) / 1e18);
        console.log("USDC received:", (usdcAfter - usdcBalance) / 1e6);

        vm.stopBroadcast();

        console.log("\n=================================");
        console.log("SWAP COMPLETE!");
        console.log("=================================");
    }
}
