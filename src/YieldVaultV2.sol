// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import "./interfaces/ILendingProtocol.sol";

/**
 * @title YieldVaultV2
 * @dev AUTO-YIELD PORTFOLIO MANAGER with real yield compounding and Chainlink Automation
 * Features:
 * - Automatic yield accrual over time
 * - Compound growth (reinvestment of yields)
 * - Continuous yield optimization
 * - Share-based vault system
 * - Multi-frequency automation (compounding + rebalancing)
 */
contract YieldVaultV2 is ReentrancyGuard, Ownable, AutomationCompatibleInterface {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    ILendingProtocol public aave;
    ILendingProtocol public compound;
    
    // Current active protocol
    ILendingProtocol public currentProtocol;
    
    // User deposit tracking for yield calculation
    struct UserDeposit {
        uint256 principal;        // Original deposit amount
        uint256 shares;          // Vault shares owned
        uint256 depositTime;     // When user deposited
    }
    
    mapping(address => UserDeposit) public userDeposits;
    
    // Vault metrics
    uint256 public totalShares;
    uint256 public totalPrincipal;
    uint256 public totalYieldGenerated;
    uint256 public lastCompoundTime;
    
    // Auto-yield parameters
    uint256 public compoundInterval = 1 hours;     // Compound every hour
    uint256 public rebalanceThreshold = 50;       // 0.5% APY difference
    
    // Performance tracking
    uint256 public totalRebalances;
    uint256 public totalCompounds;
    uint256 public vaultStartTime;
    
    // Events
    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, uint256 amount, uint256 shares, uint256 yield);
    event Rebalanced(address indexed oldProtocol, address indexed newProtocol, uint256 amount, uint256 oldAPY, uint256 newAPY);
    event YieldCompounded(uint256 yieldAmount, uint256 newTotalAssets, uint256 compoundCount);
    event RebalanceThresholdUpdated(uint256 newThreshold);
    event CompoundIntervalUpdated(uint256 newInterval);

    constructor(
        address _token,
        address _aave,
        address _compound
    ) Ownable(msg.sender) {
        token = IERC20(_token);
        aave = ILendingProtocol(_aave);
        compound = ILendingProtocol(_compound);
        lastCompoundTime = block.timestamp;
        vaultStartTime = block.timestamp;
        
        // Start with the protocol that has higher APY
        if (aave.getAPY() >= compound.getAPY()) {
            currentProtocol = aave;
        } else {
            currentProtocol = compound;
        }
    }

    /**
     * @dev Deposit tokens into the vault and receive shares
     */
    function deposit(uint256 amount) external nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        
        // Compound existing yield before new deposit
        _compoundYield();
        
        token.safeTransferFrom(msg.sender, address(this), amount);
        
        // Calculate shares to mint (if first deposit, 1:1 ratio)
        uint256 sharesToMint;
        if (totalShares == 0) {
            sharesToMint = amount;
        } else {
            uint256 currentTotalAssets = _getTotalAssets();
            sharesToMint = (amount * totalShares) / currentTotalAssets;
        }
        
        // Update user deposit
        userDeposits[msg.sender].principal += amount;
        userDeposits[msg.sender].shares += sharesToMint;
        userDeposits[msg.sender].depositTime = block.timestamp;
        
        // Update vault totals
        totalShares += sharesToMint;
        totalPrincipal += amount;
        
        // Approve and deposit to current protocol
        token.forceApprove(address(currentProtocol), amount);
        currentProtocol.deposit(amount);
        
        emit Deposited(msg.sender, amount, sharesToMint);
    }

    /**
     * @dev Withdraw tokens from the vault (burns shares, returns principal + yield)
     */
    function withdraw(uint256 shares) external nonReentrant {
        require(shares > 0, "Shares must be greater than 0");
        require(userDeposits[msg.sender].shares >= shares, "Insufficient shares");
        
        // Compound yield before withdrawal
        _compoundYield();
        
        // Calculate withdrawal amount based on current share value
        uint256 currentTotalAssets = _getTotalAssets();
        uint256 withdrawAmount = (shares * currentTotalAssets) / totalShares;
        
        // Calculate yield earned
        uint256 principalPortion = (shares * userDeposits[msg.sender].principal) / userDeposits[msg.sender].shares;
        uint256 yieldPortion = withdrawAmount > principalPortion ? withdrawAmount - principalPortion : 0;
        
        // Update user deposit
        userDeposits[msg.sender].shares -= shares;
        userDeposits[msg.sender].principal -= principalPortion;
        
        // Update vault totals
        totalShares -= shares;
        totalPrincipal -= principalPortion;
        
        // Withdraw from current protocol
        currentProtocol.withdraw(withdrawAmount);
        
        token.safeTransfer(msg.sender, withdrawAmount);
        
        emit Withdrawn(msg.sender, withdrawAmount, shares, yieldPortion);
    }

    /**
     * @dev Withdraw all user's vault balance
     */
    function withdrawAll() external {
        uint256 userShares = userDeposits[msg.sender].shares;
        require(userShares > 0, "No balance to withdraw");
        this.withdraw(userShares);
    }

    /**
     * @dev Get user's current vault value (principal + accrued yield)
     */
    function getUserValue(address user) external view returns (uint256 principal, uint256 currentValue, uint256 yield) {
        if (userDeposits[user].shares == 0) {
            return (0, 0, 0);
        }
        
        principal = userDeposits[user].principal;
        uint256 currentTotalAssets = _getTotalAssets();
        currentValue = (userDeposits[user].shares * currentTotalAssets) / totalShares;
        yield = currentValue > principal ? currentValue - principal : 0;
    }

    /**
     * @dev Get total assets under management (including accrued yield)
     */
    function _getTotalAssets() internal view returns (uint256) {
        return currentProtocol.getBalance();
    }

    /**
     * @dev Get vault performance metrics
     */
    function getVaultMetrics() external view returns (
        uint256 totalAssets,
        uint256 totalYield,
        uint256 apy,
        uint256 rebalanceCount,
        uint256 compoundCount,
        uint256 sharePrice
    ) {
        totalAssets = _getTotalAssets();
        totalYield = totalYieldGenerated;
        apy = currentProtocol.getAPY();
        rebalanceCount = totalRebalances;
        compoundCount = totalCompounds;
        sharePrice = totalShares > 0 ? (totalAssets * 1e18) / totalShares : 1e18;
    }

    /**
     * @dev Compound accrued yield - THE CORE AUTO-YIELD FUNCTIONALITY
     */
    function _compoundYield() internal {
        // Force yield update on current protocol
        if (address(currentProtocol) == address(aave)) {
            aave.updateYield(address(this));
        } else {
            compound.updateYield(address(this));
        }
        
        uint256 currentBalance = currentProtocol.getBalance();
        if (currentBalance > totalPrincipal) {
            uint256 newYield = currentBalance - totalPrincipal;
            
            // THIS IS THE KEY: Update totalPrincipal to include compounded yield
            // This creates compound growth by treating yield as new principal
            totalPrincipal = currentBalance;
            totalYieldGenerated += newYield;
            lastCompoundTime = block.timestamp;
            totalCompounds++;
            
            emit YieldCompounded(newYield, currentBalance, totalCompounds);
        }
    }

    /**
     * @dev Manual compound yield (anyone can call)
     */
    function compoundYield() external {
        _compoundYield();
    }

    /**
     * @dev Chainlink Automation: Check if rebalance OR yield compounding is needed
     */
    function checkUpkeep(bytes calldata /* checkData */) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory performData) 
    {
        // Check if yield compounding is needed (more frequent)
        bool needsCompounding = block.timestamp >= lastCompoundTime + compoundInterval;
        
        // Check if rebalancing is needed
        bool needsRebalancing = false;
        uint256 aaveAPY = aave.getAPY();
        uint256 compoundAPY = compound.getAPY();
        
        if (address(currentProtocol) == address(aave)) {
            needsRebalancing = compoundAPY > aaveAPY + rebalanceThreshold;
        } else {
            needsRebalancing = aaveAPY > compoundAPY + rebalanceThreshold;
        }
        
        // Only perform upkeep if we have assets
        bool hasAssets = _getTotalAssets() > 0;
        
        upkeepNeeded = hasAssets && (needsCompounding || needsRebalancing);
        
        // Encode which action to perform (0 = compound, 1 = rebalance, 2 = both)
        if (needsCompounding && needsRebalancing) {
            performData = abi.encode(2); // Both
        } else if (needsRebalancing) {
            performData = abi.encode(1); // Rebalance only
        } else {
            performData = abi.encode(0); // Compound only
        }
    }

    /**
     * @dev Chainlink Automation: Perform upkeep (compound yield and/or rebalance)
     */
    function performUpkeep(bytes calldata performData) external override {
        uint256 action = abi.decode(performData, (uint256));
        
        // Always compound first if needed
        if (action == 0 || action == 2) {
            _compoundYield();
        }
        
        // Then rebalance if needed
        if (action == 1 || action == 2) {
            uint256 aaveAPY = aave.getAPY();
            uint256 compoundAPY = compound.getAPY();
            
            ILendingProtocol newProtocol;
            uint256 oldAPY;
            uint256 newAPY;
            
            if (address(currentProtocol) == address(aave) && compoundAPY > aaveAPY + rebalanceThreshold) {
                newProtocol = compound;
                oldAPY = aaveAPY;
                newAPY = compoundAPY;
                _rebalance(newProtocol, oldAPY, newAPY);
            } else if (address(currentProtocol) == address(compound) && aaveAPY > compoundAPY + rebalanceThreshold) {
                newProtocol = aave;
                oldAPY = compoundAPY;
                newAPY = aaveAPY;
                _rebalance(newProtocol, oldAPY, newAPY);
            }
        }
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
        if (totalShares == 0) return;
        
        address oldProtocolAddress = address(currentProtocol);
        
        // Withdraw all from current protocol
        uint256 amount = currentProtocol.getBalance();
        if (amount > 0) {
            currentProtocol.withdraw(amount);
            
            // Deposit into new protocol
            token.forceApprove(address(newProtocol), amount);
            newProtocol.deposit(amount);
        }
        
        currentProtocol = newProtocol;
        totalRebalances++;
        
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
     * @dev Update compound interval (owner only)
     */
    function setCompoundInterval(uint256 newInterval) external onlyOwner {
        require(newInterval >= 10 minutes, "Interval too short");
        compoundInterval = newInterval;
        emit CompoundIntervalUpdated(newInterval);
    }

    /**
     * @dev Get time until next compound
     */
    function timeUntilNextCompound() external view returns (uint256) {
        uint256 nextCompoundTime = lastCompoundTime + compoundInterval;
        return nextCompoundTime > block.timestamp ? nextCompoundTime - block.timestamp : 0;
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

    /**
     * @dev Get vault status summary
     */
    function getVaultStatus() external view returns (
        string memory currentProtocolName,
        uint256 totalAssets,
        uint256 totalYield,
        uint256 annualizedReturn,
        uint256 nextCompoundIn,
        bool shouldRebalance
    ) {
        currentProtocolName = currentProtocol.getName();
        totalAssets = _getTotalAssets();
        totalYield = totalYieldGenerated;
        
        // Calculate annualized return
        uint256 timeElapsed = block.timestamp - vaultStartTime;
        if (timeElapsed > 0 && totalPrincipal > 0) {
            annualizedReturn = (totalYield * 365 days * 10000) / (totalPrincipal * timeElapsed);
        }
        
        // Calculate time until next compound
        uint256 nextCompoundTime = lastCompoundTime + compoundInterval;
        nextCompoundIn = nextCompoundTime > block.timestamp ? nextCompoundTime - block.timestamp : 0;
        
        // Check if should rebalance
        uint256 aaveAPY = aave.getAPY();
        uint256 compoundAPY = compound.getAPY();
        if (address(currentProtocol) == address(aave)) {
            shouldRebalance = compoundAPY > aaveAPY + rebalanceThreshold;
        } else {
            shouldRebalance = aaveAPY > compoundAPY + rebalanceThreshold;
        }
    }
}
