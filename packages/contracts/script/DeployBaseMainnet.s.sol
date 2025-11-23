// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {OracleReceiver} from "../src/OracleReceiver.sol";
import {NatGasToken} from "../src/NatGasToken.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract DeployBaseMainnet is Script {
    uint256 constant INITIAL_NATGAS_PRICE = 3_710_000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=====================================");
        console.log("Deploying to Base Mainnet");
        console.log("=====================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        console.log("\n1. Deploying OracleReceiver...");
        OracleReceiver oracleReceiver = new OracleReceiver(INITIAL_NATGAS_PRICE);
        console.log("   OracleReceiver:", address(oracleReceiver));

        console.log("\n2. Deploying NatGasToken...");
        NatGasToken natgas = new NatGasToken();
        console.log("   NatGasToken:", address(natgas));

        console.log("\n3. Deploying MockUSDC...");
        MockUSDC usdc = new MockUSDC();
        console.log("   MockUSDC:", address(usdc));

        console.log("\n=== Deployment Complete ===");
        console.log("OracleReceiver:", address(oracleReceiver));
        console.log("NatGasToken:", address(natgas));
        console.log("MockUSDC:", address(usdc));
        console.log("Initial Price: $3.71");

        console.log("\n=== Save to .env ===");
        console.log("ORACLE_RECEIVER_BASE=", address(oracleReceiver));
        console.log("NATGAS_TOKEN_BASE=", address(natgas));
        console.log("MOCK_USDC_BASE=", address(usdc));

        console.log("\n=== Next Steps ===");
        console.log("1. Configure LayerZero on both oracles");
        console.log("2. Mine CREATE2 salt for hook");
        console.log("3. Deploy hook with CREATE2");

        vm.stopBroadcast();
    }
}
