// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {NatGasDisruptionHook} from "../src/NatGasDisruptionHook.sol";
import {DisruptionOracle} from "../src/DisruptionOracle.sol";

contract DeployHookCREATE2 is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    function run() public returns (NatGasDisruptionHook) {
        address poolManager = vm.envOr("POOL_MANAGER", address(0));
        address oracle = vm.envOr("ORACLE", address(0));
        bytes32 salt = vm.envOr("HOOK_SALT", bytes32(0));

        require(poolManager != address(0), "POOL_MANAGER not set");
        require(oracle != address(0), "ORACLE not set");
        require(salt != bytes32(0), "HOOK_SALT not set");

        console.log("Deploying NatGasDisruptionHook with CREATE2");
        console.log("  poolManager:", poolManager);
        console.log("  oracle:", oracle);
        console.log("  salt: 0x%x", uint256(salt));
        console.log("");

        vm.startBroadcast();
        NatGasDisruptionHook hook = new NatGasDisruptionHook{salt: salt}(
            IPoolManager(poolManager),
            DisruptionOracle(oracle)
        );
        vm.stopBroadcast();

        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        );

        uint160 addressFlags = uint160(address(hook)) & Hooks.ALL_HOOK_MASK;

        console.log("SUCCESS!");
        console.log("Hook deployed to:", address(hook));
        console.log("Address flags: 0x%x", addressFlags);
        console.log("Required flags: 0x%x", flags);
        console.log("Flags match:", addressFlags == flags);
        console.log("");

        require(addressFlags == flags, "Hook address does not have correct flags");

        Hooks.validateHookPermissions(IHooks(address(hook)), hook.getHookPermissions());
        console.log("Hook permissions validated successfully!");

        return hook;
    }
}
