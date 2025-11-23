// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title NatGasToken
 * @notice Simple ERC20 token representing natural gas for the disruption hook demo
 */
contract NatGasToken is ERC20 {
    constructor() ERC20("Natural Gas Token", "NATGAS") {
        // Mint initial supply to deployer
        _mint(msg.sender, 1_000_000 * 10**18);
    }

    /**
     * @notice Mint additional tokens (for testing/liquidity)
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
