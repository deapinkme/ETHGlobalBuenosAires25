// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";

contract ValidateHookAddress is Script {
    function run() public view {
        address hookAddress = vm.envOr("HOOK_ADDRESS", address(0));
        require(hookAddress != address(0), "HOOK_ADDRESS not set");

        console.log("Validating hook address:", hookAddress);
        console.log("");

        uint160 addressBits = uint160(hookAddress);
        uint160 flags = addressBits & Hooks.ALL_HOOK_MASK;

        console.log("Full address:       0x%x", addressBits);
        console.log("Flag mask (14 bits): 0x%x", Hooks.ALL_HOOK_MASK);
        console.log("Address flags:       0x%x", flags);
        console.log("");

        console.log("Decoded permissions:");
        console.log("  beforeInitialize:              ", (flags & Hooks.BEFORE_INITIALIZE_FLAG) != 0);
        console.log("  afterInitialize:               ", (flags & Hooks.AFTER_INITIALIZE_FLAG) != 0);
        console.log("  beforeAddLiquidity:            ", (flags & Hooks.BEFORE_ADD_LIQUIDITY_FLAG) != 0);
        console.log("  afterAddLiquidity:             ", (flags & Hooks.AFTER_ADD_LIQUIDITY_FLAG) != 0);
        console.log("  beforeRemoveLiquidity:         ", (flags & Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG) != 0);
        console.log("  afterRemoveLiquidity:          ", (flags & Hooks.AFTER_REMOVE_LIQUIDITY_FLAG) != 0);
        console.log("  beforeSwap:                    ", (flags & Hooks.BEFORE_SWAP_FLAG) != 0);
        console.log("  afterSwap:                     ", (flags & Hooks.AFTER_SWAP_FLAG) != 0);
        console.log("  beforeDonate:                  ", (flags & Hooks.BEFORE_DONATE_FLAG) != 0);
        console.log("  afterDonate:                   ", (flags & Hooks.AFTER_DONATE_FLAG) != 0);
        console.log("  beforeSwapReturnsDelta:        ", (flags & Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG) != 0);
        console.log("  afterSwapReturnsDelta:         ", (flags & Hooks.AFTER_SWAP_RETURNS_DELTA_FLAG) != 0);
        console.log("  afterAddLiquidityReturnsDelta: ", (flags & Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG) != 0);
        console.log("  afterRemoveLiquidityReturnsDelta:", (flags & Hooks.AFTER_REMOVE_LIQUIDITY_RETURNS_DELTA_FLAG) != 0);
        console.log("");

        uint160 expectedFlags = uint160(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);
        bool isValid = flags == expectedFlags;

        console.log("Expected flags (beforeSwap + afterSwap): 0x%x", expectedFlags);
        console.log("Address is valid for NatGasDisruptionHook:", isValid);
        console.log("");

        if (isValid) {
            console.log("SUCCESS: This address can be used for NatGasDisruptionHook!");
        } else {
            console.log("FAILURE: This address has incorrect flags.");
            console.log("To fix: Mine a new salt with the correct flags.");
        }
    }
}
