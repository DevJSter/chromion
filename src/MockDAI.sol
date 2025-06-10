// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockDAI
 * @dev Mock DAI token for testing purposes
 */
contract MockDAI is ERC20 {
    constructor() ERC20("Mock DAI", "DAI") {
        // Mint 1M tokens to deployer for testing
        _mint(msg.sender, 1_000_000 * 10**18);
    }

    /**
     * @dev Mint tokens for testing - anyone can mint for demo purposes
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @dev Get 1000 DAI for testing
     */
    function faucet() external {
        _mint(msg.sender, 1000 * 10**18);
    }
}
