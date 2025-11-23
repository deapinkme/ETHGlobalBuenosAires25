// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {BonusCurve} from "../src/libraries/BonusCurve.sol";

contract BonusCurveTest is Test {
    uint256 constant MAX_BONUS = 500;
    uint256 constant MULTIPLIER = 1;

    function test_QuadraticBonusZeroDeviation() public pure {
        uint256 bonus = BonusCurve.quadraticBonus(0, MULTIPLIER, MAX_BONUS);
        assertEq(bonus, 0);
    }

    function test_QuadraticBonusSmallDeviation() public pure {
        uint256 bonus = BonusCurve.quadraticBonus(5, MULTIPLIER, MAX_BONUS);
        uint256 expected = (5 * 5 * MULTIPLIER) / 10000;
        assertEq(bonus, expected);
    }

    function test_QuadraticBonusMediumDeviation() public pure {
        uint256 bonus = BonusCurve.quadraticBonus(20, MULTIPLIER, MAX_BONUS);
        uint256 expected = (20 * 20 * MULTIPLIER) / 10000;
        assertEq(bonus, expected);
    }

    function test_QuadraticBonusCappedAtMax() public pure {
        uint256 bonus = BonusCurve.quadraticBonus(1000, 100, MAX_BONUS);
        assertEq(bonus, MAX_BONUS);
    }

    function test_QuadraticBonusIncreasesWithDeviation() public pure {
        uint256 bonus1 = BonusCurve.quadraticBonus(100, 10, MAX_BONUS);
        uint256 bonus2 = BonusCurve.quadraticBonus(200, 10, MAX_BONUS);
        uint256 bonus3 = BonusCurve.quadraticBonus(300, 10, MAX_BONUS);

        assertTrue(bonus2 > bonus1);
        assertTrue(bonus3 > bonus2);
    }

    function test_LinearBonusZeroDeviation() public pure {
        uint256 bonus = BonusCurve.linearBonus(0, 10, MAX_BONUS);
        assertEq(bonus, 0);
    }

    function test_LinearBonusProportional() public pure {
        uint256 bonus = BonusCurve.linearBonus(10, 5, MAX_BONUS);
        assertEq(bonus, 50);
    }

    function test_LinearBonusCappedAtMax() public pure {
        uint256 bonus = BonusCurve.linearBonus(1000, 10, MAX_BONUS);
        assertEq(bonus, MAX_BONUS);
    }

    function test_SqrtBonusZeroDeviation() public pure {
        uint256 bonus = BonusCurve.sqrtBonus(0, 10, MAX_BONUS);
        assertEq(bonus, 0);
    }

    function test_SqrtBonusSlowerGrowth() public pure {
        uint256 bonus16 = BonusCurve.sqrtBonus(16, 10, MAX_BONUS);
        uint256 bonus64 = BonusCurve.sqrtBonus(64, 10, MAX_BONUS);

        assertEq(bonus16, 40);
        assertEq(bonus64, 80);
    }

    function test_SqrtBonusCappedAtMax() public pure {
        uint256 bonus = BonusCurve.sqrtBonus(10000, 100, MAX_BONUS);
        assertEq(bonus, MAX_BONUS);
    }

    function test_TreasuryAdjustedBonusSufficientFunds() public pure {
        uint256 bonus = BonusCurve.treasuryAdjustedBonus(
            20,
            MULTIPLIER,
            MAX_BONUS,
            1000,
            500
        );

        uint256 idealBonus = BonusCurve.quadraticBonus(20, MULTIPLIER, MAX_BONUS);
        assertEq(bonus, idealBonus);
    }

    function test_TreasuryAdjustedBonusInsufficientFunds() public pure {
        uint256 bonus = BonusCurve.treasuryAdjustedBonus(
            20,
            MULTIPLIER,
            MAX_BONUS,
            250,
            1000
        );

        uint256 idealBonus = BonusCurve.quadraticBonus(20, MULTIPLIER, MAX_BONUS);
        uint256 expected = (idealBonus * 250) / 1000;
        assertEq(bonus, expected);
    }

    function test_TreasuryAdjustedBonusZeroTreasury() public pure {
        uint256 bonus = BonusCurve.treasuryAdjustedBonus(
            20,
            MULTIPLIER,
            MAX_BONUS,
            0,
            1000
        );

        assertEq(bonus, 0);
    }

    function test_SqrtFunction() public pure {
        assertEq(BonusCurve.sqrt(0), 0);
        assertEq(BonusCurve.sqrt(1), 1);
        assertEq(BonusCurve.sqrt(4), 2);
        assertEq(BonusCurve.sqrt(9), 3);
        assertEq(BonusCurve.sqrt(16), 4);
        assertEq(BonusCurve.sqrt(25), 5);
        assertEq(BonusCurve.sqrt(100), 10);
    }

    function test_SqrtNonPerfectSquares() public pure {
        assertEq(BonusCurve.sqrt(2), 1);
        assertEq(BonusCurve.sqrt(3), 1);
        assertEq(BonusCurve.sqrt(8), 2);
        assertEq(BonusCurve.sqrt(15), 3);
    }

    function test_RealisticBonusScenarios() public pure {
        uint256 bonus5Percent = BonusCurve.quadraticBonus(5, MULTIPLIER, MAX_BONUS);
        uint256 bonus10Percent = BonusCurve.quadraticBonus(10, MULTIPLIER, MAX_BONUS);
        uint256 bonus20Percent = BonusCurve.quadraticBonus(20, MULTIPLIER, MAX_BONUS);

        assertTrue(bonus5Percent == 0);
        assertTrue(bonus10Percent == 0);
        assertTrue(bonus20Percent == 0);
    }
}
