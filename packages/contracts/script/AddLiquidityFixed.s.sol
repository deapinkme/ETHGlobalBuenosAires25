// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPositionManager {
    function modifyLiquidities(bytes calldata unlockData, uint256 deadline) external payable;
}

contract AddLiquidityFixed is Script {
    address constant POSITION_MANAGER = 0x7C5f5A4bBd8fD63184577525326123B519429bDc;
    address constant NATGAS = 0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD;
    address constant USDC = 0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a;
    address constant HOOK = 0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Adding liquidity to V4 pool");
        console.log("Deployer:", deployer);

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(NATGAS),
            currency1: Currency.wrap(USDC),
            fee: 0,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        int24 tickLower = -60;
        int24 tickUpper = 60;
        uint256 liquidity = 1000000;
        uint128 amount0Max = 10000000000000000000;
        uint128 amount1Max = 10000000;

        bytes memory actions = hex"020808";

        bytes[] memory params = new bytes[](3);

        params[0] = abi.encode(
            poolKey,
            tickLower,
            tickUpper,
            liquidity,
            amount0Max,
            amount1Max,
            deployer,
            bytes("")
        );

        params[1] = abi.encode(Currency.wrap(NATGAS));
        params[2] = abi.encode(Currency.wrap(USDC));

        bytes memory unlockData = abi.encode(actions, params);
        uint256 deadline = block.timestamp + 3600;

        vm.startBroadcast(deployerPrivateKey);

        console.log("Approving tokens...");
        IERC20(NATGAS).approve(POSITION_MANAGER, type(uint256).max);
        IERC20(USDC).approve(POSITION_MANAGER, type(uint256).max);

        console.log("Calling modifyLiquidities...");
        IPositionManager(POSITION_MANAGER).modifyLiquidities(unlockData, deadline);

        vm.stopBroadcast();

        console.log("Liquidity added successfully!");
    }
}
