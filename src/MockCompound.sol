// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ILendingProtocol.sol";

/**
 * @title MockCompound
 * @dev Mock Compound lending protocol for testing
 */
contract MockCompound is ILendingProtocol {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    mapping(address => uint256) public balances;
    
    // Starting APY: 5.1%
    uint256 private currentAPY = 510;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event APYUpdated(uint256 newAPY);

    constructor(address _token) {
        token = IERC20(_token);
    }

    /**
     * @dev Deposit tokens into Mock Compound
     */
    function deposit(uint256 amount) external override {
        require(amount > 0, "Amount must be greater than 0");
        
        token.safeTransferFrom(msg.sender, address(this), amount);
        balances[msg.sender] += amount;
        
        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev Withdraw tokens from Mock Compound
     */
    function withdraw(uint256 amount) external override {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        balances[msg.sender] -= amount;
        token.safeTransfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @dev Get current APY (5.1% = 510 basis points)
     */
    function getAPY() external view override returns (uint256) {
        return currentAPY;
    }

    /**
     * @dev Get balance for the caller
     */
    function getBalance() external view override returns (uint256) {
        return balances[msg.sender];
    }

    /**
     * @dev Get protocol name
     */
    function getName() external pure override returns (string memory) {
        return "Mock Compound";
    }

    /**
     * @dev Update APY for testing (only for demo purposes)
     */
    function setAPY(uint256 newAPY) external {
        currentAPY = newAPY;
        emit APYUpdated(newAPY);
    }
}
