// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { ContractRegistry } from "@flarenetwork/flare-periphery-contracts/coston2/ContractRegistry.sol";
import { IWeb2Json } from "./interfaces/flare/IWeb2Json.sol";
import { IFdcVerificationExtended } from "./interfaces/flare/IFdcVerificationExtended.sol";

contract DisruptionOracle {
    // Disruption types - all tracked for future iterations, currently not affecting price
    enum DisruptionType {
        NONE,
        SUPPLY_SHOCK,      // Future: Natural gas supply disruptions
        DEMAND_SHOCK,      // Future: Demand spikes or crashes
        WEATHER,           // Future: Weather events affecting natural gas production
        SANCTIONS          // Future: Geopolitical sanctions
    }

    struct Disruption {
        DisruptionType eventType;
        int256 priceImpactPercent;  // e.g., +20 = +20%, -15 = -15%
        uint256 timestamp;
        bool active;
    }

    // Data structures for FDC attestations
    struct PriceData {
        uint256 price;          // Natural gas price in USDC (6 decimals)
        uint256 timestamp;
    }

    struct WeatherData {
        string eventDescription;  // e.g., "Hurricane in Gulf of Mexico"
        int256 severity;         // Scale 1-10, affects price impact
        uint256 timestamp;
    }

    uint256 public basePrice;
    Disruption public currentDisruption;
    address public owner;

    address public layerZeroEndpoint;
    address public destinationOracle;
    uint32 public destinationEid;

    int256 public constant WEATHER_IMPACT_MULTIPLIER = 5;

    event DisruptionUpdated(
        DisruptionType indexed eventType,
        int256 priceImpactPercent,
        uint256 timestamp
    );
    event DisruptionCleared(uint256 timestamp);
    event BasePriceUpdated(uint256 newPrice, uint256 timestamp);
    event PriceSentCrossChain(uint32 indexed dstEid, uint256 price, uint256 timestamp);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    constructor(uint256 _basePrice) {
        owner = msg.sender;
        basePrice = _basePrice;
    }

    /**
     * @notice Get the theoretical price based on current disruption
     * @return Theoretical price in USDC (6 decimals)
     * @dev Currently returns basePrice only. All disruption types (SUPPLY_SHOCK, DEMAND_SHOCK,
     *      WEATHER, SANCTIONS) are tracked but don't affect price in initial iteration.
     */
    function getTheoreticalPrice() external view returns (uint256) {
        // For initial iteration, all disruptions are tracked but don't affect price
        return basePrice;

        // TODO: Uncomment for future iteration with all disruption types
        // if (!currentDisruption.active) {
        //     return basePrice;
        // }
        //
        // // Calculate adjusted price: basePrice * (100 + impact) / 100
        // int256 adjustedPrice = int256(basePrice) * (100 + currentDisruption.priceImpactPercent) / 100;
        //
        // require(adjustedPrice > 0, "Invalid price calculation");
        //
        // return uint256(adjustedPrice);
    }

    /**
     * @notice Update base price using FDC price attestation
     * @param proof FDC Web2Json proof containing price data
     */
    function updateBasePriceWithFDC(IWeb2Json.Proof calldata proof) external {
        require(isWeb2JsonProofValid(proof), "Invalid FDC proof");

        PriceData memory priceData = abi.decode(
            proof.data.responseBody.abiEncodedData,
            (PriceData)
        );

        require(priceData.price > 0, "Base price must be positive");
        require(priceData.timestamp <= block.timestamp, "Future timestamp not allowed");
        require(priceData.timestamp > block.timestamp - 1 hours, "Price data too old");

        basePrice = priceData.price;
        emit BasePriceUpdated(priceData.price, priceData.timestamp);
    }

    /**
     * @notice Set weather disruption using FDC weather attestation
     * @param proof FDC Web2Json proof containing weather data
     * @dev For future iteration - currently tracks disruptions but doesn't affect price
     */
    function setWeatherDisruptionWithFDC(IWeb2Json.Proof calldata proof) external {
        require(isWeb2JsonProofValid(proof), "Invalid FDC proof");

        WeatherData memory weatherData = abi.decode(
            proof.data.responseBody.abiEncodedData,
            (WeatherData)
        );

        require(weatherData.severity >= 0 && weatherData.severity <= 10, "Severity must be 0-10");
        require(weatherData.timestamp <= block.timestamp, "Future timestamp not allowed");
        require(weatherData.timestamp > block.timestamp - 1 hours, "Weather data too old");

        // Calculate impact based on severity
        int256 impactPercent = weatherData.severity * WEATHER_IMPACT_MULTIPLIER;

        currentDisruption = Disruption({
            eventType: DisruptionType.WEATHER,
            priceImpactPercent: impactPercent,
            timestamp: weatherData.timestamp,
            active: true
        });

        emit DisruptionUpdated(DisruptionType.WEATHER, impactPercent, weatherData.timestamp);
    }

    /**
     * @notice Clear current disruption (emergency only)
     */
    function clearDisruption() external onlyOwner {
        currentDisruption.active = false;
        emit DisruptionCleared(block.timestamp);
    }

    /**
     * @notice Emergency: Update base price manually (owner only)
     * @param newBasePrice New base price in USDC (6 decimals)
     */
    function updateBasePrice(uint256 newBasePrice) external onlyOwner {
        require(newBasePrice > 0, "Base price must be positive");
        basePrice = newBasePrice;
        emit BasePriceUpdated(newBasePrice, block.timestamp);
    }

    function setLayerZeroConfig(
        address _endpoint,
        uint32 _dstEid,
        address _dstOracle
    ) external onlyOwner {
        layerZeroEndpoint = _endpoint;
        destinationEid = _dstEid;
        destinationOracle = _dstOracle;
    }

    function sendPriceUpdate() external payable {
        require(layerZeroEndpoint != address(0), "LayerZero not configured");
        require(destinationEid != 0, "Destination not set");

        bytes memory payload = abi.encode(basePrice, block.timestamp);

        emit PriceSentCrossChain(destinationEid, basePrice, block.timestamp);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }

    function abiSignaturePriceData(PriceData calldata data) external pure {}
    function abiSignatureWeatherData(WeatherData calldata data) external pure {}

    /**
     * @notice Verify FDC Web2Json proof
     * @param proof The FDC proof to verify
     * @return bool True if proof is valid
     */
    function isWeb2JsonProofValid(IWeb2Json.Proof calldata proof) private view returns (bool) {
        return IFdcVerificationExtended(address(ContractRegistry.getFdcVerification())).verifyWeb2Json(proof);
    }
}
