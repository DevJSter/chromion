// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";
import "./interfaces/ILendingProtocol.sol";

/**
 * @title YieldVault
 * @dev Auto-rebalancing yield vault powered by Chainlink Automation
 */
contract YieldVault is ReentrancyGuard, Ownable, AutomationCompatibleInterface {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    ILendingProtocol public aave;
    ILendingProtocol public compound;
    
    // Current active protocol
    ILendingProtocol public currentProtocol;
    
    // User balances in the vault
    mapping(address => uint256) public balances;
    
    // Total assets in the vault
    uint256 public totalAssets;
    
    // Minimum APY difference to trigger rebalance (in basis points)
    uint256 public rebalanceThreshold = 100; // 1%
    
    // Events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Rebalanced(address indexed oldProtocol, address indexed newProtocol, uint256 amount, uint256 oldAPY, uint256 newAPY);
    event RebalanceThresholdUpdated(uint256 newThreshold);

    constructor(
        address _token,
        address _aave,
        address _compound
    ) {
        token = IERC20(_token);
        aave = ILendingProtocol(_aave);
        compound = ILendingProtocol(_compound);
        
        // Start with the protocol that has higher APY
        if (aave.getAPY() >= compound.getAPY()) {
            currentProtocol = aave;
        } else {
            currentProtocol = compound;
        }
    }

    /**
     * @dev Deposit tokens into the vault
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        token.safeTransferFrom(msg.sender, address(this), amount);
        
        // Approve and deposit to current protocol
        token.safeApprove(address(currentProtocol), amount);
        currentProtocol.deposit(amount);
        
        balances[msg.sender] += amount;
        totalAssets += amount;
        
        emit Deposited(msg.sender, amount);
    }

    /**
     * @dev Withdraw tokens from the vault
     */
    function withdraw(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= amount, "Insufficient balance");
        
        // Withdraw from current protocol
        currentProtocol.withdraw(amount);
        
        balances[msg.sender] -= amount;
        totalAssets -= amount;
        
        token.safeTransfer(msg.sender, amount);
        
        emit Withdrawn(msg.sender, amount);
    }

    /**
     * @dev Get user's vault balance
     */
    function getBalance(address user) external view returns (uint256) {
        return balances[user];
    }

    /**
     * @dev Get current protocol info
     */
    function getCurrentProtocolInfo() external view returns (
        string memory name,
        uint256 apy,
        uint256 balance
    ) {
        return (
            currentProtocol.getName(),
            currentProtocol.getAPY(),
            currentProtocol.getBalance()
        );
    }

    /**
     * @dev Get both protocols' APYs
     */
    function getProtocolAPYs() external view returns (uint256 aaveAPY, uint256 compoundAPY) {
        return (aave.getAPY(), compound.getAPY());
    }

    /**
     * @dev Chainlink Automation: Check if rebalance is needed
     */
    function checkUpkeep(bytes calldata /* checkData */) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory /* performData */) 
    {
        uint256 aaveAPY = aave.getAPY();
        uint256 compoundAPY = compound.getAPY();
        
        if (address(currentProtocol) == address(aave)) {
            // Currently in Aave, check if Compound is significantly better
            upkeepNeeded = compoundAPY > aaveAPY + rebalanceThreshold;
        } else {
            // Currently in Compound, check if Aave is significantly better
            upkeepNeeded = aaveAPY > compoundAPY + rebalanceThreshold;
        }
        
        // Only rebalance if we have assets
        upkeepNeeded = upkeepNeeded && totalAssets > 0;
    }

    /**
     * @dev Chainlink Automation: Perform rebalance
     */
    function performUpkeep(bytes calldata /* performData */) external override {
        uint256 aaveAPY = aave.getAPY();
        uint256 compoundAPY = compound.getAPY();
        
        ILendingProtocol newProtocol;
        uint256 oldAPY;
        uint256 newAPY;
        
        if (address(currentProtocol) == address(aave) && compoundAPY > aaveAPY + rebalanceThreshold) {
            newProtocol = compound;
            oldAPY = aaveAPY;
            newAPY = compoundAPY;
        } else if (address(currentProtocol) == address(compound) && aaveAPY > compoundAPY + rebalanceThreshold) {
            newProtocol = aave;
            oldAPY = compoundAPY;
            newAPY = aaveAPY;
        } else {
            return; // No rebalance needed
        }
        
        _rebalance(newProtocol, oldAPY, newAPY);
    }

    /**
     * @dev Manual rebalance (owner only, for emergency)
     */
    function manualRebalance() external onlyOwner {
        uint256 aaveAPY = aave.getAPY();
        uint256 compoundAPY = compound.getAPY();
        
        ILendingProtocol newProtocol = aaveAPY >= compoundAPY ? aave : compound;
        
        if (address(newProtocol) != address(currentProtocol)) {
            _rebalance(newProtocol, currentProtocol.getAPY(), newProtocol.getAPY());
        }
    }

    /**
     * @dev Internal rebalance function
     */
    function _rebalance(ILendingProtocol newProtocol, uint256 oldAPY, uint256 newAPY) internal {
        if (totalAssets == 0) return;
        
        address oldProtocolAddress = address(currentProtocol);
        
        // Withdraw all from current protocol
        uint256 amount = currentProtocol.getBalance();
        if (amount > 0) {
            currentProtocol.withdraw(amount);
            
            // Deposit into new protocol
            token.safeApprove(address(newProtocol), amount);
            newProtocol.deposit(amount);
        }
        
        currentProtocol = newProtocol;
        
        emit Rebalanced(oldProtocolAddress, address(newProtocol), amount, oldAPY, newAPY);
    }

    /**
     * @dev Update rebalance threshold (owner only)
     */
    function setRebalanceThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold <= 1000, "Threshold too high"); // Max 10%
        rebalanceThreshold = newThreshold;
        emit RebalanceThresholdUpdated(newThreshold);
    }

    /**
     * @dev Emergency withdraw (owner only)
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 amount = currentProtocol.getBalance();
        if (amount > 0) {
            currentProtocol.withdraw(amount);
        }
    }
}
