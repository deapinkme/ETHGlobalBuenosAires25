// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {DisruptionOracle} from "../src/DisruptionOracle.sol";

contract DeployFlareMainnet is Script {
    uint256 constant INITIAL_NATGAS_PRICE = 3_710_000;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=====================================");
        console.log("Deploying to Flare Mainnet");
        console.log("=====================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);

        vm.startBroadcast(deployerPrivateKey);

        DisruptionOracle oracle = new DisruptionOracle(INITIAL_NATGAS_PRICE);

        console.log("\n=== Deployment Complete ===");
        console.log("DisruptionOracle:", address(oracle));
        console.log("Initial Price: $3.71 (", INITIAL_NATGAS_PRICE, ")");
        console.log("Owner:", oracle.owner());

        console.log("\n=== Save to .env ===");
        console.log("ORACLE_FLARE=", address(oracle));

        console.log("\n=== Next Steps ===");
        console.log("1. Save oracle address to .env");
        console.log("2. Deploy OracleReceiver to Base Mainnet");
        console.log("3. Configure LayerZero bridge");

        vm.stopBroadcast();
    }
}
