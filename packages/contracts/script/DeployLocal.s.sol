// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {NatGasToken} from "../src/NatGasToken.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {DisruptionOracle} from "../src/DisruptionOracle.sol";
import {NatGasDisruptionHook} from "../src/NatGasDisruptionHook.sol";
import {MockPoolManager} from "../test/mocks/MockPoolManager.sol";

contract DeployLocal is Script {
    uint256 constant INITIAL_NATGAS_PRICE = 100 * 10**6;

    function run() external {
        uint256 deployerPrivateKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

        vm.startBroadcast(deployerPrivateKey);

        address deployer = vm.addr(deployerPrivateKey);
        console.log("\n=== Local Deployment Starting ===");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        MockPoolManager poolManager = new MockPoolManager();
        console.log("MockPoolManager deployed at:", address(poolManager));

        MockUSDC usdc = new MockUSDC();
        console.log("MockUSDC deployed at:", address(usdc));

        NatGasToken natGas = new NatGasToken();
        console.log("NatGasToken deployed at:", address(natGas));

        DisruptionOracle oracle = new DisruptionOracle(INITIAL_NATGAS_PRICE);
        console.log("DisruptionOracle deployed at:", address(oracle));
        console.log("  - Initial price: $100.00 (100000000 with 6 decimals)");

        console.log("\nNote: Skipping NatGasDisruptionHook deployment (requires CREATE2)");
        console.log("  - Hook implementation is complete");
        console.log("  - CREATE2 deployment needed for V4 compatibility");
        console.log("  - All other contracts ready for testing!");

        console.log("\n=== Testing Setup ===");
        console.log("Minting test tokens to deployer...");

        usdc.faucet();
        console.log("  - USDC balance:", usdc.balanceOf(deployer) / 10**6, "USDC");

        natGas.mint(deployer, 1000 * 10**18);
        console.log("  - NATGAS balance:", natGas.balanceOf(deployer) / 10**18, "NATGAS");

        console.log("\n=== Quick Test Commands ===");
        console.log("Update oracle price:");
        console.log("  cast send", address(oracle), "\"updateBasePrice(uint256)\" 150000000 --private-key $PRIVATE_KEY");
        console.log("\nCheck theoretical price:");
        console.log("  cast call", address(oracle), "\"getTheoreticalPrice()\"");
        console.log("\nTransfer NATGAS:");
        console.log("  cast send", address(natGas), "\"transfer(address,uint256)\" <recipient> 1000000000000000000 --private-key $PRIVATE_KEY");

        console.log("\n=== Deployment Summary ===");
        console.log("MockPoolManager:", address(poolManager));
        console.log("MockUSDC:", address(usdc));
        console.log("NatGasToken:", address(natGas));
        console.log("DisruptionOracle:", address(oracle));
        console.log("========================\n");

        vm.stopBroadcast();
    }
}
