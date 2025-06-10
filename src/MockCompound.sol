// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/ILendingProtocol.sol";
import "./MockDAI.sol";

/**
 * @title MockCompound
 * @dev Mock Compound lending protocol with REAL yield generation
 */
contract MockCompound is ILendingProtocol {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    
    struct UserDeposit {
        uint256 principal;      // Original deposit amount
        uint256 lastUpdateTime; // Last time yield was calculated
        uint256 accruedYield;   // Accumulated yield so far
    }
    
    mapping(address => UserDeposit) public deposits;
    
    // Starting APY: 5.1% (510 basis points)
    uint256 private currentAPY = 510;
    
    // Total deposits for calculating protocol metrics
    uint256 public totalDeposited;
    uint256 public totalYieldGenerated;
    
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 principal, uint256 yield);
    event YieldAccrued(address indexed user, uint256 yieldAmount);
    event APYUpdated(uint256 newAPY);

    constructor(address _token) {
        token = IERC20(_token);
    }

    /**
     * @dev Deposit tokens and start earning yield
     */
    function deposit(uint256 amount) external override {
        require(amount > 0, "Amount must be greater than 0");
        
        // Update existing yield before new deposit
        _updateYield(msg.sender);
        
        token.safeTransferFrom(msg.sender, address(this), amount);
        deposits[msg.sender].principal += amount;
        deposits[msg.sender].lastUpdateTime = block.timestamp;
        totalDeposited += amount;
        
        emit Deposit(msg.sender, amount);
    }

    /**
     * @dev Withdraw principal + accrued yield
     */
    function withdraw(uint256 amount) external override {
        require(amount > 0, "Amount must be greater than 0");
        
        // Update yield before withdrawal
        _updateYield(msg.sender);
        
        uint256 totalBalance = deposits[msg.sender].principal + deposits[msg.sender].accruedYield;
        require(totalBalance >= amount, "Insufficient balance");
        
        uint256 principalToWithdraw;
        uint256 yieldToWithdraw;
        
        // First withdraw from yield, then from principal
        if (amount <= deposits[msg.sender].accruedYield) {
            yieldToWithdraw = amount;
            deposits[msg.sender].accruedYield -= amount;
        } else {
            yieldToWithdraw = deposits[msg.sender].accruedYield;
            principalToWithdraw = amount - yieldToWithdraw;
            deposits[msg.sender].accruedYield = 0;
            deposits[msg.sender].principal -= principalToWithdraw;
            totalDeposited -= principalToWithdraw;
        }
        
        // Mint yield tokens if needed (mock lending protocol behavior)
        if (yieldToWithdraw > 0) {
            // In a real protocol, this would be from protocol reserves
            // For demo purposes, we mint the yield tokens
            MockDAI(address(token)).mint(address(this), yieldToWithdraw);
        }
        
        token.safeTransfer(msg.sender, amount);
        
        emit Withdraw(msg.sender, principalToWithdraw, yieldToWithdraw);
    }

    /**
     * @dev Update yield based on time elapsed and APY
     */
    function _updateYield(address user) internal {
        UserDeposit storage userDeposit = deposits[user];
        
        if (userDeposit.principal == 0 || userDeposit.lastUpdateTime == 0) {
            return;
        }
        
        uint256 timeElapsed = block.timestamp - userDeposit.lastUpdateTime;
        if (timeElapsed == 0) {
            return;
        }
        
        // Calculate yield: principal * APY * timeElapsed / (365 days * 10000)
        // APY is in basis points (510 = 5.1%)
        uint256 yieldEarned = (userDeposit.principal * currentAPY * timeElapsed) / (365 days * 10000);
        
        userDeposit.accruedYield += yieldEarned;
        userDeposit.lastUpdateTime = block.timestamp;
        totalYieldGenerated += yieldEarned;
        
        if (yieldEarned > 0) {
            emit YieldAccrued(user, yieldEarned);
        }
    }

    /**
     * @dev Get current APY (5.1% = 510 basis points)
     */
    function getAPY() external view override returns (uint256) {
        return currentAPY;
    }

    /**
     * @dev Get balance for the vault (msg.sender) - includes principal + accrued yield
     */
    function getBalance() external view override returns (uint256) {
        // Calculate current yield without updating state
        uint256 currentYield = _calculateCurrentYield(msg.sender);
        return deposits[msg.sender].principal + deposits[msg.sender].accruedYield + currentYield;
    }

    /**
     * @dev Calculate current yield without updating state
     */
    function _calculateCurrentYield(address user) internal view returns (uint256) {
        UserDeposit memory userDeposit = deposits[user];
        
        if (userDeposit.principal == 0 || userDeposit.lastUpdateTime == 0) {
            return 0;
        }
        
        uint256 timeElapsed = block.timestamp - userDeposit.lastUpdateTime;
        if (timeElapsed == 0) {
            return 0;
        }
        
        return (userDeposit.principal * currentAPY * timeElapsed) / (365 days * 10000);
    }

    /**
     * @dev Get detailed user deposit info
     */
    function getUserDeposit(address user) external view returns (uint256 principal, uint256 accruedYield, uint256 currentYield, uint256 totalBalance) {
        UserDeposit memory userDeposit = deposits[user];
        uint256 pendingYield = _calculateCurrentYield(user);
        
        return (
            userDeposit.principal,
            userDeposit.accruedYield,
            pendingYield,
            userDeposit.principal + userDeposit.accruedYield + pendingYield
        );
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

    /**
     * @dev Force yield update for a user (useful for testing and automation)
     */
    function updateYield(address user) external {
        _updateYield(user);
    }
}
