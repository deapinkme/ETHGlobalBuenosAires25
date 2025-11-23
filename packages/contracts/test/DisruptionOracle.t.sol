// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {DisruptionOracle} from "../src/DisruptionOracle.sol";

contract DisruptionOracleTest is Test {
    DisruptionOracle public oracle;
    address public alice = address(0x1);

    uint256 constant INITIAL_PRICE = 100 * 10**6;

    function setUp() public {
        oracle = new DisruptionOracle(INITIAL_PRICE);
    }

    function test_InitialState() public view {
        assertEq(oracle.basePrice(), INITIAL_PRICE);
        assertEq(oracle.owner(), address(this));
        assertEq(oracle.WEATHER_IMPACT_MULTIPLIER(), 5);
    }

    function test_GetTheoreticalPriceReturnsBasePrice() public view {
        uint256 price = oracle.getTheoreticalPrice();
        assertEq(price, INITIAL_PRICE);
    }

    function test_UpdateBasePriceAsOwner() public {
        uint256 newPrice = 150 * 10**6;

        vm.expectEmit(true, true, true, true);
        emit DisruptionOracle.BasePriceUpdated(newPrice, block.timestamp);

        oracle.updateBasePrice(newPrice);

        assertEq(oracle.basePrice(), newPrice);
        assertEq(oracle.getTheoreticalPrice(), newPrice);
    }

    function test_RevertUpdateBasePriceNotOwner() public {
        uint256 newPrice = 150 * 10**6;

        vm.prank(alice);
        vm.expectRevert("Only owner can call");
        oracle.updateBasePrice(newPrice);
    }

    function test_RevertUpdateBasePriceZero() public {
        vm.expectRevert("Base price must be positive");
        oracle.updateBasePrice(0);
    }

    function test_ClearDisruptionAsOwner() public {
        vm.expectEmit(true, true, true, true);
        emit DisruptionOracle.DisruptionCleared(block.timestamp);

        oracle.clearDisruption();

        (
            DisruptionOracle.DisruptionType eventType,
            int256 priceImpactPercent,
            uint256 timestamp,
            bool active
        ) = oracle.currentDisruption();

        assertEq(uint256(eventType), 0);
        assertEq(priceImpactPercent, 0);
        assertEq(timestamp, 0);
        assertFalse(active);
    }

    function test_RevertClearDisruptionNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Only owner can call");
        oracle.clearDisruption();
    }

    function test_TransferOwnership() public {
        oracle.transferOwnership(alice);

        assertEq(oracle.owner(), alice);
    }

    function test_RevertTransferOwnershipZeroAddress() public {
        vm.expectRevert("Invalid address");
        oracle.transferOwnership(address(0));
    }

    function test_RevertTransferOwnershipNotOwner() public {
        vm.prank(alice);
        vm.expectRevert("Only owner can call");
        oracle.transferOwnership(alice);
    }

    function test_NewOwnerCanUpdatePrice() public {
        oracle.transferOwnership(alice);

        uint256 newPrice = 200 * 10**6;

        vm.prank(alice);
        oracle.updateBasePrice(newPrice);

        assertEq(oracle.basePrice(), newPrice);
    }

    function test_PriceDecimalsAre6() public view {
        assertEq(oracle.basePrice(), 100_000000);

        uint256 oneHundredDollars = 100 * 10**6;
        assertEq(oneHundredDollars, 100_000000);
    }
}
