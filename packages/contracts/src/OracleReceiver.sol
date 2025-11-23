// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract OracleReceiver {
    uint256 public basePrice;
    uint256 public lastUpdateTimestamp;
    address public owner;
    address public layerZeroEndpoint;
    uint32 public sourceEid;

    event PriceUpdated(uint256 newPrice, uint256 timestamp, uint32 sourceEid);
    event LayerZeroConfigured(address endpoint, uint32 eid);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyLayerZero() {
        require(msg.sender == layerZeroEndpoint, "Only LayerZero");
        _;
    }

    constructor(uint256 _initialPrice) {
        owner = msg.sender;
        basePrice = _initialPrice;
        lastUpdateTimestamp = block.timestamp;
    }

    function setLayerZeroConfig(address _endpoint, uint32 _sourceEid) external onlyOwner {
        layerZeroEndpoint = _endpoint;
        sourceEid = _sourceEid;
        emit LayerZeroConfigured(_endpoint, _sourceEid);
    }

    function lzReceive(
        uint32 _srcEid,
        bytes32,
        uint64,
        bytes calldata _message
    ) external onlyLayerZero {
        require(_srcEid == sourceEid, "Invalid source");

        (uint256 newPrice, uint256 timestamp) = abi.decode(_message, (uint256, uint256));

        require(newPrice > 0, "Invalid price");
        require(timestamp > lastUpdateTimestamp, "Stale update");

        basePrice = newPrice;
        lastUpdateTimestamp = timestamp;

        emit PriceUpdated(newPrice, timestamp, _srcEid);
    }

    function updateBasePrice(uint256 newPrice) external onlyOwner {
        require(newPrice > 0, "Invalid price");
        basePrice = newPrice;
        lastUpdateTimestamp = block.timestamp;
        emit PriceUpdated(newPrice, block.timestamp, 0);
    }

    function getTheoreticalPrice() external view returns (uint256) {
        return basePrice;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
}
