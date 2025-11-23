// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title FeeCurve
 * @notice Library for calculating dynamic fees based on price deviation
 */
library FeeCurve {
    uint256 constant BASIS_POINTS = 10000;  // 100% = 10000 basis points

    /**
     * @notice Calculate fee using quadratic curve
     * @param deviation Price deviation as percentage (e.g., 20 for 20%)
     * @param baseFee Base fee in basis points (e.g., 3000 for 0.3%)
     * @param multiplier Curve multiplier for scaling
     * @param maxFee Maximum fee cap in basis points
     * @return fee Fee in basis points (compatible with uint24 for Uniswap V4)
     */
    function quadraticFee(
        uint256 deviation,
        uint256 baseFee,
        uint256 multiplier,
        uint256 maxFee
    ) internal pure returns (uint24) {
        // Quadratic formula: fee = baseFee + (deviation² × multiplier) / 10000
        uint256 additionalFee = (deviation * deviation * multiplier) / BASIS_POINTS;
        uint256 totalFee = baseFee + additionalFee;

        // Cap at maximum
        if (totalFee > maxFee) {
            return uint24(maxFee);
        }

        // Ensure fits in uint24 (max ~1.6M basis points = 16000%)
        require(totalFee <= type(uint24).max, "Fee exceeds uint24");

        return uint24(totalFee);
    }

    /**
     * @notice Calculate fee using linear curve
     * @param deviation Price deviation as percentage
     * @param baseFee Base fee in basis points
     * @param slope Linear slope multiplier
     * @param maxFee Maximum fee cap in basis points
     * @return fee Fee in basis points
     */
    function linearFee(
        uint256 deviation,
        uint256 baseFee,
        uint256 slope,
        uint256 maxFee
    ) internal pure returns (uint24) {
        // Linear formula: fee = baseFee + (deviation × slope)
        uint256 additionalFee = deviation * slope;
        uint256 totalFee = baseFee + additionalFee;

        // Cap at maximum
        if (totalFee > maxFee) {
            return uint24(maxFee);
        }

        require(totalFee <= type(uint24).max, "Fee exceeds uint24");

        return uint24(totalFee);
    }

    /**
     * @notice Calculate fee using exponential curve
     * @param deviation Price deviation as percentage
     * @param baseFee Base fee in basis points
     * @param exponentBase Base for exponential growth (e.g., 2 for 2^x)
     * @param maxFee Maximum fee cap in basis points
     * @return fee Fee in basis points
     */
    function exponentialFee(
        uint256 deviation,
        uint256 baseFee,
        uint256 exponentBase,
        uint256 maxFee
    ) internal pure returns (uint24) {
        // Simplified exponential: fee = baseFee × (base ^ (deviation / 10))
        // Note: This is a simplified version, production would need SafeMath for powers
        uint256 scaledDeviation = deviation / 10;
        uint256 multiplier = exponentBase ** scaledDeviation;
        uint256 totalFee = baseFee * multiplier;

        // Cap at maximum
        if (totalFee > maxFee) {
            return uint24(maxFee);
        }

        require(totalFee <= type(uint24).max, "Fee exceeds uint24");

        return uint24(totalFee);
    }

    /**
     * @notice Clamp a fee value to maximum
     * @param fee Fee to clamp
     * @param maxFee Maximum allowed fee
     * @return Clamped fee as uint24
     */
    function capFee(uint256 fee, uint256 maxFee) internal pure returns (uint24) {
        uint256 capped = fee > maxFee ? maxFee : fee;
        require(capped <= type(uint24).max, "Fee exceeds uint24");
        return uint24(capped);
    }
}
