// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {NatGasToken} from "../src/NatGasToken.sol";

contract NatGasTokenTest is Test {
    NatGasToken public token;
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        token = new NatGasToken();
    }

    function test_InitialState() public view {
        assertEq(token.name(), "Natural Gas Token");
        assertEq(token.symbol(), "NATGAS");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 1_000_000 * 10**18);
        assertEq(token.balanceOf(address(this)), 1_000_000 * 10**18);
    }

    function test_Transfer() public {
        uint256 amount = 100 * 10**18;

        token.transfer(alice, amount);

        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(address(this)), 1_000_000 * 10**18 - amount);
    }

    function test_TransferFrom() public {
        uint256 amount = 100 * 10**18;

        token.approve(alice, amount);

        vm.prank(alice);
        token.transferFrom(address(this), bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.allowance(address(this), alice), 0);
    }

    function test_Approve() public {
        uint256 amount = 500 * 10**18;

        token.approve(alice, amount);

        assertEq(token.allowance(address(this), alice), amount);
    }

    function test_RevertTransferInsufficientBalance() public {
        uint256 tooMuch = 2_000_000 * 10**18;

        vm.expectRevert();
        token.transfer(alice, tooMuch);
    }
}
