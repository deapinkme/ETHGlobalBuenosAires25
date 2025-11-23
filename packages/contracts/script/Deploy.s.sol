// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {NatGasToken} from "../src/NatGasToken.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {DisruptionOracle} from "../src/DisruptionOracle.sol";
import {NatGasDisruptionHook} from "../src/NatGasDisruptionHook.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";

contract Deploy is Script {
    uint256 constant INITIAL_NATGAS_PRICE = 100 * 10**6;

    NatGasToken public natGas;
    MockUSDC public usdc;
    DisruptionOracle public oracle;
    NatGasDisruptionHook public hook;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address poolManager = vm.envAddress("POOL_MANAGER_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying contracts...");
        console.log("Deployer:", vm.addr(deployerPrivateKey));
        console.log("Pool Manager:", poolManager);

        usdc = new MockUSDC();
        console.log("MockUSDC deployed at:", address(usdc));

        natGas = new NatGasToken();
        console.log("NatGasToken deployed at:", address(natGas));

        oracle = new DisruptionOracle(INITIAL_NATGAS_PRICE);
        console.log("DisruptionOracle deployed at:", address(oracle));
        console.log("Initial price set to:", INITIAL_NATGAS_PRICE);

        hook = new NatGasDisruptionHook(IPoolManager(poolManager), oracle);
        console.log("NatGasDisruptionHook deployed at:", address(hook));

        console.log("\n=== Deployment Summary ===");
        console.log("MockUSDC:", address(usdc));
        console.log("NatGasToken:", address(natGas));
        console.log("DisruptionOracle:", address(oracle));
        console.log("NatGasDisruptionHook:", address(hook));
        console.log("========================\n");

        vm.stopBroadcast();
    }
}
