// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {SwapRouter} from "../src/SwapRouter.sol";

contract DeploySwapRouter is Script {
    address constant POOL_MANAGER = 0x498581fF718922c3f8e6A244956aF099B2652b2b;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying SwapRouter...");
        console.log("Deployer:", deployer);

        vm.startBroadcast(deployerPrivateKey);

        SwapRouter swapRouter = new SwapRouter(IPoolManager(POOL_MANAGER));

        vm.stopBroadcast();

        console.log("\n=================================");
        console.log("SwapRouter deployed at:", address(swapRouter));
        console.log("=================================");
    }
}
