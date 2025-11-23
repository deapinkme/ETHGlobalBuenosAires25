// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test} from "forge-std/Test.sol";
import {FeeCurve} from "../src/libraries/FeeCurve.sol";

contract FeeCurveTest is Test {
    uint256 constant BASE_FEE = 3000;
    uint256 constant MAX_FEE = 100000;

    function test_QuadraticFeeZeroDeviation() public pure {
        uint24 fee = FeeCurve.quadraticFee(0, BASE_FEE, 2, MAX_FEE);
        assertEq(fee, BASE_FEE);
    }

    function test_QuadraticFeeSmallDeviation() public pure {
        uint24 fee = FeeCurve.quadraticFee(5, BASE_FEE, 2, MAX_FEE);
        assertEq(fee, BASE_FEE);
    }

    function test_QuadraticFeeMediumDeviation() public pure {
        uint24 fee = FeeCurve.quadraticFee(20, BASE_FEE, 2, MAX_FEE);
        uint256 expectedAdditional = uint256(20 * 20 * 2) / 10000;
        assertEq(fee, BASE_FEE + expectedAdditional);
    }

    function test_QuadraticFeeCappedAtMax() public pure {
        uint24 fee = FeeCurve.quadraticFee(500, BASE_FEE, 10000, MAX_FEE);
        assertEq(fee, MAX_FEE);
    }

    function test_QuadraticFeeIncreasesWithDeviation() public pure {
        uint24 fee1 = FeeCurve.quadraticFee(100, BASE_FEE, 10, MAX_FEE);
        uint24 fee2 = FeeCurve.quadraticFee(200, BASE_FEE, 10, MAX_FEE);
        uint24 fee3 = FeeCurve.quadraticFee(300, BASE_FEE, 10, MAX_FEE);

        assertTrue(fee2 > fee1);
        assertTrue(fee3 > fee2);
    }

    function test_LinearFeeZeroDeviation() public pure {
        uint24 fee = FeeCurve.linearFee(0, BASE_FEE, 100, MAX_FEE);
        assertEq(fee, BASE_FEE);
    }

    function test_LinearFeeProportional() public pure {
        uint24 fee = FeeCurve.linearFee(10, BASE_FEE, 100, MAX_FEE);
        assertEq(fee, BASE_FEE + 1000);
    }

    function test_LinearFeeCappedAtMax() public pure {
        uint24 fee = FeeCurve.linearFee(2000, BASE_FEE, 100, MAX_FEE);
        assertEq(fee, MAX_FEE);
    }

    function test_ExponentialFeeZeroDeviation() public pure {
        uint24 fee = FeeCurve.exponentialFee(0, BASE_FEE, 2, MAX_FEE);
        assertEq(fee, BASE_FEE);
    }

    function test_ExponentialFeeCappedAtMax() public pure {
        uint24 fee = FeeCurve.exponentialFee(100, BASE_FEE, 2, MAX_FEE);
        assertEq(fee, MAX_FEE);
    }

    function test_CapFee() public pure {
        uint24 fee = FeeCurve.capFee(150000, MAX_FEE);
        assertEq(fee, MAX_FEE);
    }

    function test_CapFeeNoChange() public pure {
        uint24 fee = FeeCurve.capFee(50000, MAX_FEE);
        assertEq(fee, 50000);
    }

    function test_QuadraticGrowthFasterThanLinear() public pure {
        uint256 deviation = 2000;

        uint24 quadratic = FeeCurve.quadraticFee(deviation, BASE_FEE, 10, MAX_FEE);
        uint24 linear = FeeCurve.linearFee(deviation, BASE_FEE, 1, MAX_FEE);

        assertTrue(quadratic > linear);
    }

    function test_RealisticFeeScenarios() public pure {
        uint24 fee5Percent = FeeCurve.quadraticFee(5, BASE_FEE, 2, MAX_FEE);
        uint24 fee10Percent = FeeCurve.quadraticFee(10, BASE_FEE, 2, MAX_FEE);
        uint24 fee20Percent = FeeCurve.quadraticFee(20, BASE_FEE, 2, MAX_FEE);

        assertTrue(fee5Percent < 4000);
        assertTrue(fee10Percent < 4000);
        assertTrue(fee20Percent < 4000);
    }
}
