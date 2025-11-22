// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title OilToken
 * @notice Simple ERC20 token representing oil for the disruption hook demo
 */
contract OilToken is ERC20 {
    constructor() ERC20("Oil Token", "OIL") {
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
