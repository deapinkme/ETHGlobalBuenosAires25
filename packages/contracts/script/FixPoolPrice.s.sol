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

contract FixPoolPrice is Script {
    address constant POOL_MANAGER = 0x498581fF718922c3f8e6A244956aF099B2652b2b;
    address constant NATGAS = 0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD;
    address constant USDC = 0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a;
    address constant HOOK = 0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("==================================");
        console.log("FIXING POOL PRICE");
        console.log("==================================");
        console.log("Target: 1 NATGAS = $3.71 USDC");
        console.log("Current: Pool is at 1:1 (wrong!)");
        console.log("");

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(NATGAS),
            currency1: Currency.wrap(USDC),
            fee: 0,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        vm.startBroadcast(deployerPrivateKey);

        PoolSwapTest swapRouter = new PoolSwapTest(IPoolManager(POOL_MANAGER));
        console.log("SwapRouter deployed:", address(swapRouter));

        console.log("\nMinting tokens for price correction...");
        IERC20(NATGAS).approve(address(swapRouter), type(uint256).max);
        IERC20(USDC).approve(address(swapRouter), type(uint256).max);

        console.log("\nExecuting large USDC->NATGAS swap to push price down");
        console.log("This will sell USDC to buy NATGAS, decreasing NATGAS price");

        SwapParams memory params = SwapParams({
            zeroForOne: false,
            amountSpecified: -10000000000,
            sqrtPriceLimitX96: 152604218284700732489728
        });

        PoolSwapTest.TestSettings memory testSettings = PoolSwapTest.TestSettings({
            takeClaims: false,
            settleUsingBurn: false
        });

        swapRouter.swap(key, params, testSettings, "");

        console.log("\nPrice correction complete!");
        console.log("Pool should now be near $3.71");

        vm.stopBroadcast();
    }
}
