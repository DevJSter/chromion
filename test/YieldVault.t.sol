// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MockDAI.sol";
import "../src/MockAave.sol";
import "../src/MockCompound.sol";
import "../src/YieldVault.sol";

contract YieldVaultTest is Test {
    MockDAI public dai;
    MockAave public aave;
    MockCompound public compound;
    YieldVault public vault;
    
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    uint256 public constant INITIAL_BALANCE = 10000 * 10**18; // 10,000 DAI

    function setUp() public {
        // Deploy contracts
        dai = new MockDAI();
        aave = new MockAave(address(dai));
        compound = new MockCompound(address(dai));
        vault = new YieldVault(address(dai), address(aave), address(compound));
        
        // Setup user balances
        dai.mint(user1, INITIAL_BALANCE);
        dai.mint(user2, INITIAL_BALANCE);
        
        // Approve vault for users
        vm.prank(user1);
        dai.approve(address(vault), type(uint256).max);
        
        vm.prank(user2);
        dai.approve(address(vault), type(uint256).max);
    }

    function testInitialState() public {
        // Compound has higher APY (510 vs 350), so should be selected initially
        (string memory name, uint256 apy, uint256 balance) = vault.getCurrentProtocolInfo();
        assertEq(name, "Mock Compound");
        assertEq(apy, 510);
        assertEq(balance, 0);
        
        assertEq(vault.totalAssets(), 0);
        assertEq(vault.rebalanceThreshold(), 100);
    }

    function testDeposit() public {
        uint256 depositAmount = 1000 * 10**18; // 1,000 DAI
        
        vm.prank(user1);
        vault.deposit(depositAmount);
        
        assertEq(vault.getBalance(user1), depositAmount);
        assertEq(vault.totalAssets(), depositAmount);
        assertEq(dai.balanceOf(user1), INITIAL_BALANCE - depositAmount);
        
        // Check that funds are in Compound (current protocol)
        // We need to check the vault's balance in compound, not call getBalance directly
        (, , uint256 protocolBalance) = vault.getCurrentProtocolInfo();
        assertEq(protocolBalance, depositAmount);
    }

    function testWithdraw() public {
        uint256 depositAmount = 1000 * 10**18;
        uint256 withdrawAmount = 400 * 10**18;
        
        // Deposit first
        vm.prank(user1);
        vault.deposit(depositAmount);
        
        // Then withdraw
        vm.prank(user1);
        vault.withdraw(withdrawAmount);
        
        assertEq(vault.getBalance(user1), depositAmount - withdrawAmount);
        assertEq(vault.totalAssets(), depositAmount - withdrawAmount);
        assertEq(dai.balanceOf(user1), INITIAL_BALANCE - depositAmount + withdrawAmount);
    }

    function test_RevertWhen_WithdrawMoreThanBalance() public {
        uint256 depositAmount = 1000 * 10**18;
        uint256 withdrawAmount = 1500 * 10**18; // More than deposited
        
        vm.prank(user1);
        vault.deposit(depositAmount);
        
        vm.prank(user1);
        vm.expectRevert("Insufficient balance");
        vault.withdraw(withdrawAmount); // Should fail
    }

    function testCheckUpkeepNoRebalanceNeeded() public {
        // Compound APY (510) > Aave APY (350) + threshold (100) = 450
        // So no rebalance needed as we're already in Compound
        (bool upkeepNeeded,) = vault.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function testCheckUpkeepRebalanceNeeded() public {
        // First deposit to have assets
        vm.prank(user1);
        vault.deposit(1000 * 10**18);
        
        // Increase Aave APY to trigger rebalance
        aave.setAPY(700); // 7% > 5.1% + 1% = 6.1%
        
        (bool upkeepNeeded,) = vault.checkUpkeep("");
        assertTrue(upkeepNeeded);
    }

    function testPerformUpkeep() public {
        uint256 depositAmount = 1000 * 10**18;
        
        // Deposit to Compound (current protocol)
        vm.prank(user1);
        vault.deposit(depositAmount);
        
        // Verify initially in Compound
        (string memory name,,) = vault.getCurrentProtocolInfo();
        assertEq(name, "Mock Compound");
        
        // Check vault has deposited correctly by checking vault's own balance
        vm.prank(address(vault));
        assertEq(compound.getBalance(), depositAmount);
        vm.prank(address(vault));
        assertEq(aave.getBalance(), 0);
        
        // Increase Aave APY to trigger rebalance
        aave.setAPY(700); // 7%
        
        // Perform upkeep (rebalance)
        vault.performUpkeep("");
        
        // Verify now in Aave
        (name,,) = vault.getCurrentProtocolInfo();
        assertEq(name, "Mock Aave");
        vm.prank(address(vault));
        assertEq(aave.getBalance(), depositAmount);
        vm.prank(address(vault));
        assertEq(compound.getBalance(), 0);
    }

    function testManualRebalance() public {
        uint256 depositAmount = 1000 * 10**18;
        
        vm.prank(user1);
        vault.deposit(depositAmount);
        
        // Increase Aave APY
        aave.setAPY(600);
        
        // Manual rebalance by owner
        vault.manualRebalance();
        
        // Should now be in Aave
        (string memory name,,) = vault.getCurrentProtocolInfo();
        assertEq(name, "Mock Aave");
    }

    function testGetProtocolAPYs() public {
        (uint256 aaveAPY, uint256 compoundAPY) = vault.getProtocolAPYs();
        assertEq(aaveAPY, 350);
        assertEq(compoundAPY, 510);
    }

    function testSetRebalanceThreshold() public {
        vault.setRebalanceThreshold(200); // 2%
        assertEq(vault.rebalanceThreshold(), 200);
    }

    function test_RevertWhen_SetRebalanceThresholdTooHigh() public {
        vm.expectRevert("Threshold too high");
        vault.setRebalanceThreshold(1100); // 11% - should fail
    }

    function testMultipleUsers() public {
        uint256 amount1 = 1000 * 10**18;
        uint256 amount2 = 2000 * 10**18;
        
        // User1 deposits
        vm.prank(user1);
        vault.deposit(amount1);
        
        // User2 deposits
        vm.prank(user2);
        vault.deposit(amount2);
        
        assertEq(vault.getBalance(user1), amount1);
        assertEq(vault.getBalance(user2), amount2);
        assertEq(vault.totalAssets(), amount1 + amount2);
    }

    function testEventEmissions() public {
        uint256 amount = 1000 * 10**18;
        
        // Test Deposited event
        vm.expectEmit(true, false, false, true);
        emit Deposited(user1, amount);
        
        vm.prank(user1);
        vault.deposit(amount);
        
        // Test Withdrawn event
        vm.expectEmit(true, false, false, true);
        emit Withdrawn(user1, amount);
        
        vm.prank(user1);
        vault.withdraw(amount);
    }

    // Events to match contract events
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
}
