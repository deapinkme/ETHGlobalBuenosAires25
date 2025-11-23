// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

interface IPositionManager {
    enum Actions {
        INCREASE_LIQUIDITY,
        DECREASE_LIQUIDITY,
        MINT_POSITION,
        BURN_POSITION,
        SETTLE_PAIR,
        TAKE_PAIR,
        SETTLE,
        TAKE,
        CLOSE_CURRENCY,
        CLEAR_OR_TAKE,
        SWEEP
    }

    struct PoolKey {
        address currency0;
        address currency1;
        uint24 fee;
        int24 tickSpacing;
        address hooks;
    }

    function modifyLiquidities(bytes calldata unlockData, uint256 deadline) external payable;
}

contract MintPosition is Script {
    address constant POSITION_MANAGER = 0x7C5f5A4bBd8fD63184577525326123B519429bDc;
    address constant NATGAS = 0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD;
    address constant USDC = 0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a;
    address constant HOOK = 0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Minting liquidity position");
        console.log("Deployer:", deployer);

        IPositionManager.PoolKey memory poolKey = IPositionManager.PoolKey({
            currency0: NATGAS,
            currency1: USDC,
            fee: 0,
            tickSpacing: 60,
            hooks: HOOK
        });

        int24 tickLower = -887220;
        int24 tickUpper = 887220;
        uint256 liquidity = 1000000000000000000;
        uint128 amount0Max = 10000 * 10**18;
        uint128 amount1Max = 10000 * 10**6;

        bytes[] memory actions = new bytes[](3);

        actions[0] = abi.encode(IPositionManager.Actions.SETTLE_PAIR, abi.encode(NATGAS, USDC));

        actions[1] = abi.encode(
            IPositionManager.Actions.MINT_POSITION,
            abi.encode(poolKey, tickLower, tickUpper, liquidity, amount0Max, amount1Max, deployer, "")
        );

        actions[2] = abi.encode(IPositionManager.Actions.SWEEP, abi.encode(NATGAS, deployer));

        bytes memory unlockData = abi.encode(actions);
        uint256 deadline = block.timestamp + 3600;

        vm.startBroadcast(deployerPrivateKey);

        console.log("Calling modifyLiquidities...");
        IPositionManager(POSITION_MANAGER).modifyLiquidities(unlockData, deadline);

        vm.stopBroadcast();

        console.log("Position minted successfully!");
    }
}
