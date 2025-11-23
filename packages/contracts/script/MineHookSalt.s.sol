// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {NatGasDisruptionHook} from "../src/NatGasDisruptionHook.sol";
import {DisruptionOracle} from "../src/DisruptionOracle.sol";

contract MineHookSalt is Script {
    address constant CREATE2_DEPLOYER = address(0x4e59b44847b379578588920cA78FbF26c0B4956C);

    function run() public {
        address poolManager = vm.envOr("POOL_MANAGER", address(0));
        address oracle = vm.envOr("ORACLE", address(0));

        require(poolManager != address(0), "POOL_MANAGER not set");
        require(oracle != address(0), "ORACLE not set");

        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG
        );

        bytes memory constructorArgs = abi.encode(IPoolManager(poolManager), DisruptionOracle(oracle));

        console.log("Mining salt for hook with flags:");
        console.log("  beforeSwap: true");
        console.log("  afterSwap: true");
        console.log("  Required flag bits: 0x%x", flags);
        console.log("");
        console.log("Constructor args:");
        console.log("  poolManager:", poolManager);
        console.log("  oracle:", oracle);
        console.log("");

        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(NatGasDisruptionHook).creationCode, constructorArgs);

        console.log("SUCCESS!");
        console.log("Hook address:", hookAddress);
        console.log("Salt: 0x%x", uint256(salt));
        console.log("");
        console.log("To deploy with this salt, run:");
        console.log("  forge script script/DeployHookCREATE2.s.sol --rpc-url <RPC> --broadcast");
        console.log("");
        console.log("Add to .env:");
        console.log("  HOOK_SALT=%s", vm.toString(salt));
    }
}
