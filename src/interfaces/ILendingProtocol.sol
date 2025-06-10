// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title ILendingProtocol
 * @dev Interface for lending protocols (Aave, Compound)
 */
interface ILendingProtocol {
    /**
     * @dev Deposit tokens into the lending protocol
     * @param amount Amount to deposit
     */
    function deposit(uint256 amount) external;

    /**
     * @dev Withdraw tokens from the lending protocol
     * @param amount Amount to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @dev Get current APY in basis points (e.g., 350 = 3.5%)
     */
    function getAPY() external view returns (uint256);

    /**
     * @dev Get total balance in the protocol for the vault
     */
    function getBalance() external view returns (uint256);

    /**
     * @dev Get the name of the protocol
     */
    function getName() external view returns (string memory);
}
