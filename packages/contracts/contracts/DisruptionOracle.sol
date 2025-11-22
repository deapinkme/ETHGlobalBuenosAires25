// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title DisruptionOracle
 * @notice Oracle that tracks oil price disruptions and calculates theoretical price
 * @dev In production, this would be updated via Chainlink Functions
 */
contract DisruptionOracle {
    enum DisruptionType {
        NONE,
        SUPPLY_SHOCK,
        DEMAND_SHOCK,
        WEATHER,
        SANCTIONS
    }

    struct Disruption {
        DisruptionType eventType;
        int256 priceImpactPercent;  // e.g., +20 = +20%, -15 = -15%
        uint256 timestamp;
        bool active;
    }

    // Base price in USDC (6 decimals)
    uint256 public basePrice;

    // Current active disruption
    Disruption public currentDisruption;

    // Owner can update disruptions (in production, this would be Chainlink)
    address public owner;

    event DisruptionUpdated(
        DisruptionType indexed eventType,
        int256 priceImpactPercent,
        uint256 timestamp
    );

    event DisruptionCleared(uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    constructor(uint256 _basePrice) {
        owner = msg.sender;
        basePrice = _basePrice;  // e.g., 100 * 10**6 for $100
    }

    /**
     * @notice Get the theoretical price based on current disruption
     * @return Theoretical price in USDC (6 decimals)
     */
    function getTheoreticalPrice() external view returns (uint256) {
        if (!currentDisruption.active) {
            return basePrice;
        }

        // Calculate adjusted price: basePrice * (100 + impact) / 100
        int256 adjustedPrice = int256(basePrice) * (100 + currentDisruption.priceImpactPercent) / 100;

        require(adjustedPrice > 0, "Invalid price calculation");

        return uint256(adjustedPrice);
    }

    /**
     * @notice Set a new disruption event
     * @param dtype Type of disruption
     * @param impactPercent Price impact as percentage (e.g., +20 for +20%, -15 for -15%)
     */
    function setDisruption(DisruptionType dtype, int256 impactPercent) external onlyOwner {
        require(dtype != DisruptionType.NONE, "Use clearDisruption instead");
        require(impactPercent >= -100, "Impact cannot reduce price below zero");

        currentDisruption = Disruption({
            eventType: dtype,
            priceImpactPercent: impactPercent,
            timestamp: block.timestamp,
            active: true
        });

        emit DisruptionUpdated(dtype, impactPercent, block.timestamp);
    }

    /**
     * @notice Clear current disruption
     */
    function clearDisruption() external onlyOwner {
        currentDisruption.active = false;
        emit DisruptionCleared(block.timestamp);
    }

    /**
     * @notice Update base price
     * @param newBasePrice New base price in USDC (6 decimals)
     */
    function updateBasePrice(uint256 newBasePrice) external onlyOwner {
        require(newBasePrice > 0, "Base price must be positive");
        basePrice = newBasePrice;
    }

    /**
     * @notice Transfer ownership
     * @param newOwner Address of new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}
