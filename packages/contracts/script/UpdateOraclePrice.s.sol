// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { DisruptionOracle } from "../src/DisruptionOracle.sol";

contract UpdateOraclePrice is Script {
    function run() external {
        address oracleAddress = vm.envAddress("DISRUPTION_ORACLE_ADDRESS");
        uint256 newPrice = vm.envUint("NEW_PRICE");
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        require(oracleAddress != address(0), "DISRUPTION_ORACLE_ADDRESS not set");
        require(newPrice > 0, "NEW_PRICE must be positive");

        DisruptionOracle oracle = DisruptionOracle(oracleAddress);

        console.log("Updating DisruptionOracle price:");
        console.log("Oracle Address:", oracleAddress);
        console.log("Current Price:", oracle.basePrice());
        console.log("New Price:", newPrice);

        vm.startBroadcast(deployerPrivateKey);

        oracle.updateBasePrice(newPrice);

        vm.stopBroadcast();

        console.log("Price updated successfully!");
        console.log("Verified Price:", oracle.basePrice());
    }
}
