// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPositionManager {
    struct PoolKey {
        address currency0;
        address currency1;
        uint24 fee;
        int24 tickSpacing;
        address hooks;
    }

    function modifyLiquidities(bytes calldata unlockData, uint256 deadline) external payable;
}

contract AddLiquiditySimple is Script {
    address constant POSITION_MANAGER = 0x7c5f5a4bbd8fd63184577525326123b519429bdc;
    address constant NATGAS = 0x4aA1dF02688241e4c665D4837a7c201CddF9F3CD;
    address constant USDC = 0xbB9d7298273dFEbe2706aafb06d7f1c10E8B356a;
    address constant HOOK = 0xC3CEe78d0825b24C684355de4e6FbD51F0b940c0;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Adding liquidity to V4 pool");
        console.log("Deployer:", deployer);

        uint256 natgasAmount = 10000 * 10**18;
        uint256 usdcAmount = 10000 * 10**6;

        vm.startBroadcast(deployerPrivateKey);

        console.log("Approving NATGAS to PositionManager...");
        IERC20(NATGAS).approve(POSITION_MANAGER, natgasAmount);

        console.log("Approving USDC to PositionManager...");
        IERC20(USDC).approve(POSITION_MANAGER, usdcAmount);

        console.log("Token approvals complete!");
        console.log("");
        console.log("NEXT STEP: Use the Uniswap V4 Position Manager UI or SDK");
        console.log("Position Manager: https://basescan.org/address/" , POSITION_MANAGER);
        console.log("");
        console.log("Approved amounts:");
        console.log("  NATGAS: 10,000 tokens");
        console.log("  USDC: 10,000 tokens");
        console.log("");
        console.log("To complete, call PositionManager.modifyLiquidities() with:");
        console.log("  - Pool Key (NATGAS/USDC, fee=0, tickSpacing=60, hook)");
        console.log("  - Tick range: -887220 to 887220 (full range)");
        console.log("  - Liquidity amount (requires SDK calculation)");

        vm.stopBroadcast();
    }
}
