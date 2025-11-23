// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {MockUSDC} from "../src/MockUSDC.sol";

contract MockUSDCTest is Test {
    MockUSDC public usdc;
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        usdc = new MockUSDC();
    }

    function test_InitialState() public view {
        assertEq(usdc.name(), "Mock USDC");
        assertEq(usdc.symbol(), "USDC");
        assertEq(usdc.decimals(), 6);
        assertEq(usdc.totalSupply(), 0);
    }

    function test_Faucet() public {
        vm.prank(alice);
        usdc.faucet();

        assertEq(usdc.balanceOf(alice), 10_000 * 10**6);
    }

    function test_FaucetMultipleTimes() public {
        vm.startPrank(alice);

        usdc.faucet();
        assertEq(usdc.balanceOf(alice), 10_000 * 10**6);

        usdc.faucet();
        assertEq(usdc.balanceOf(alice), 20_000 * 10**6);

        vm.stopPrank();
    }

    function test_Mint() public {
        uint256 amount = 1_000 * 10**6;

        usdc.mint(address(this), amount);

        assertEq(usdc.balanceOf(address(this)), amount);
    }

    function test_Transfer() public {
        uint256 mintAmount = 10_000 * 10**6;
        uint256 transferAmount = 500 * 10**6;

        usdc.mint(address(this), mintAmount);
        usdc.transfer(alice, transferAmount);

        assertEq(usdc.balanceOf(alice), transferAmount);
        assertEq(usdc.balanceOf(address(this)), mintAmount - transferAmount);
    }

    function test_Approve() public {
        uint256 amount = 100 * 10**6;

        usdc.approve(alice, amount);

        assertEq(usdc.allowance(address(this), alice), amount);
    }

    function test_TransferFrom() public {
        uint256 mintAmount = 10_000 * 10**6;
        uint256 transferAmount = 250 * 10**6;

        usdc.mint(address(this), mintAmount);
        usdc.approve(alice, transferAmount);

        vm.prank(alice);
        usdc.transferFrom(address(this), bob, transferAmount);

        assertEq(usdc.balanceOf(bob), transferAmount);
        assertEq(usdc.allowance(address(this), alice), 0);
    }

    function test_DecimalsAre6() public view {
        assertEq(usdc.decimals(), 6);
        uint256 oneUSDC = 1 * 10**6;
        assertEq(oneUSDC, 1_000_000);
    }
}
