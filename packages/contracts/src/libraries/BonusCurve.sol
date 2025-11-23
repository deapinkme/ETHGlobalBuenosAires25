// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title BonusCurve
 * @notice Library for calculating bonus rates based on price deviation
 */
library BonusCurve {
    uint256 constant BASIS_POINTS = 10000;  // 100% = 10000 basis points

    /**
     * @notice Calculate bonus using quadratic curve
     * @param deviation Price deviation as percentage (e.g., 20 for 20%)
     * @param multiplier Curve multiplier for scaling
     * @param maxBonus Maximum bonus rate in basis points (e.g., 500 for 5%)
     * @return bonus Bonus rate in basis points
     */
    function quadraticBonus(
        uint256 deviation,
        uint256 multiplier,
        uint256 maxBonus
    ) internal pure returns (uint256) {
        // Zero deviation = zero bonus
        if (deviation == 0) {
            return 0;
        }

        // Quadratic formula: bonus = (deviation² × multiplier) / 10000
        uint256 bonus = (deviation * deviation * multiplier) / BASIS_POINTS;

        // Cap at maximum
        return bonus > maxBonus ? maxBonus : bonus;
    }

    /**
     * @notice Calculate bonus using linear curve
     * @param deviation Price deviation as percentage
     * @param slope Linear slope multiplier
     * @param maxBonus Maximum bonus rate in basis points
     * @return bonus Bonus rate in basis points
     */
    function linearBonus(
        uint256 deviation,
        uint256 slope,
        uint256 maxBonus
    ) internal pure returns (uint256) {
        if (deviation == 0) {
            return 0;
        }

        // Linear formula: bonus = deviation × slope
        uint256 bonus = deviation * slope;

        // Cap at maximum
        return bonus > maxBonus ? maxBonus : bonus;
    }

    /**
     * @notice Calculate bonus using square root curve (slower growth)
     * @param deviation Price deviation as percentage
     * @param multiplier Curve multiplier
     * @param maxBonus Maximum bonus rate in basis points
     * @return bonus Bonus rate in basis points
     */
    function sqrtBonus(
        uint256 deviation,
        uint256 multiplier,
        uint256 maxBonus
    ) internal pure returns (uint256) {
        if (deviation == 0) {
            return 0;
        }

        // Square root formula: bonus = sqrt(deviation) × multiplier
        uint256 sqrtDev = sqrt(deviation);
        uint256 bonus = sqrtDev * multiplier;

        // Cap at maximum
        return bonus > maxBonus ? maxBonus : bonus;
    }

    /**
     * @notice Calculate bonus with treasury balance consideration
     * @param deviation Price deviation as percentage
     * @param multiplier Curve multiplier
     * @param maxBonus Maximum bonus rate
     * @param treasuryBalance Available treasury balance
     * @param requiredAmount Amount needed for full bonus
     * @return bonus Adjusted bonus rate based on treasury availability
     */
    function treasuryAdjustedBonus(
        uint256 deviation,
        uint256 multiplier,
        uint256 maxBonus,
        uint256 treasuryBalance,
        uint256 requiredAmount
    ) internal pure returns (uint256) {
        // Calculate ideal bonus
        uint256 idealBonus = quadraticBonus(deviation, multiplier, maxBonus);

        // If insufficient treasury, reduce bonus proportionally
        if (treasuryBalance < requiredAmount) {
            return (idealBonus * treasuryBalance) / requiredAmount;
        }

        return idealBonus;
    }

    /**
     * @notice Simple integer square root using Babylonian method
     * @param x Number to find square root of
     * @return y Square root of x
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;

        uint256 z = (x + 1) / 2;
        y = x;

        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}
