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

interface IPermit2 {
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;
}

library Actions {
    uint256 constant MINT_POSITION = 0x02;
    uint256 constant CLOSE_CURRENCY = 0x12;
}

contract AddLiquidityFinal is Script {
    address constant POSITION_MANAGER = 0x7C5f5A4bBd8fD63184577525326123B519429bDc;
    address constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    address constant NATGAS = 0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD;
    address constant USDC = 0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a;
    address constant HOOK = 0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Adding liquidity via PositionManager");
        console.log("Deployer:", deployer);

        PoolKey memory poolKey = PoolKey({
            currency0: Currency.wrap(NATGAS),
            currency1: Currency.wrap(USDC),
            fee: 0,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        int24 tickLower = -120;
        int24 tickUpper = 120;
        uint256 liquidity = 1000000;
        uint128 amount0Max = type(uint128).max;
        uint128 amount1Max = type(uint128).max;

        bytes memory mintParams = abi.encode(
            poolKey,
            tickLower,
            tickUpper,
            liquidity,
            amount0Max,
            amount1Max,
            deployer,
            bytes("")
        );

        bytes memory actions = new bytes(3);
        actions[0] = bytes1(uint8(Actions.MINT_POSITION));
        actions[1] = bytes1(uint8(Actions.CLOSE_CURRENCY));
        actions[2] = bytes1(uint8(Actions.CLOSE_CURRENCY));

        bytes[] memory params = new bytes[](3);
        params[0] = mintParams;
        params[1] = abi.encode(Currency.wrap(NATGAS));
        params[2] = abi.encode(Currency.wrap(USDC));

        bytes memory unlockData = abi.encode(actions, params);
        uint256 deadline = block.timestamp + 3600;

        vm.startBroadcast(deployerPrivateKey);

        console.log("Approving tokens to Permit2...");
        IERC20(NATGAS).approve(PERMIT2, type(uint256).max);
        IERC20(USDC).approve(PERMIT2, type(uint256).max);

        console.log("Setting Permit2 allowance for PositionManager...");
        IPermit2(PERMIT2).approve(NATGAS, POSITION_MANAGER, type(uint160).max, type(uint48).max);
        IPermit2(PERMIT2).approve(USDC, POSITION_MANAGER, type(uint160).max, type(uint48).max);

        console.log("Minting position...");
        IPositionManager(POSITION_MANAGER).modifyLiquidities(unlockData, deadline);

        vm.stopBroadcast();

        console.log("Position minted successfully!");
    }
}
