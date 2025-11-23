// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { DisruptionOracle } from "../src/DisruptionOracle.sol";

contract DeployCoston2 is Script {
    uint256 constant INITIAL_BASE_PRICE = 3_930_000; // $3.93 with 6 decimals

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        DisruptionOracle oracle = new DisruptionOracle(INITIAL_BASE_PRICE);

        console.log("DisruptionOracle deployed to Coston2:");
        console.log("Address:", address(oracle));
        console.log("Initial Base Price:", oracle.basePrice());
        console.log("Owner:", oracle.owner());
        console.log();
        console.log("Save this address to your .env file:");
        console.log("DISRUPTION_ORACLE_ADDRESS=%s", address(oracle));

        vm.stopBroadcast();
    }
}
