// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {NatGasToken} from "../src/NatGasToken.sol";
import {MockUSDC} from "../src/MockUSDC.sol";
import {DisruptionOracle} from "../src/DisruptionOracle.sol";
import {NatGasDisruptionHook} from "../src/NatGasDisruptionHook.sol";

contract Setup is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        address natGasAddress = vm.envAddress("NATGAS_ADDRESS");
        address usdcAddress = vm.envAddress("USDC_ADDRESS");
        address oracleAddress = vm.envAddress("ORACLE_ADDRESS");
        address hookAddress = vm.envAddress("HOOK_ADDRESS");

        vm.startBroadcast(deployerPrivateKey);

        NatGasToken natGas = NatGasToken(natGasAddress);
        MockUSDC usdc = MockUSDC(usdcAddress);
        DisruptionOracle oracle = DisruptionOracle(oracleAddress);
        NatGasDisruptionHook hook = NatGasDisruptionHook(hookAddress);

        console.log("\n=== Initial Setup ===");
        console.log("Deployer:", deployer);

        uint256 usdcAmount = 1_000_000 * 10**6;

        console.log("\nMinting tokens to deployer...");
        usdc.mint(deployer, usdcAmount);
        console.log("Minted USDC:", usdcAmount / 10**6, "USDC");
        console.log("Deployer NATGAS balance:", natGas.balanceOf(deployer) / 10**18, "NATGAS");
        console.log("Deployer USDC balance:", usdc.balanceOf(deployer) / 10**6, "USDC");

        uint256 treasuryNatGas = 1_000 * 10**18;
        uint256 treasuryUSDC = 100_000 * 10**6;

        console.log("\nApproving tokens for treasury funding...");
        natGas.approve(address(hook), treasuryNatGas);
        usdc.approve(address(hook), treasuryUSDC);

        console.log("\n=== Setup Complete ===");
        console.log("Ready to create pool and fund treasury");
        console.log("Oracle price:", oracle.getTheoreticalPrice() / 10**6, "USDC");
        console.log("====================\n");

        vm.stopBroadcast();
    }
}
