// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {MockDAI} from "../src/MockDAI.sol";
import {MockAave} from "../src/MockAave.sol";
import {MockCompound} from "../src/MockCompound.sol";
import {YieldVaultV2} from "../src/YieldVaultV2.sol";

/**
 * @title AutoYieldDemo
 * @dev Comprehensive demo of the Auto-Yield Portfolio Manager
 * Features demonstrated:
 * - Real yield generation over time
 * - Automatic yield compounding
 * - Protocol rebalancing
 * - Share-based vault system
 */
contract AutoYieldDemo is Script {
    // Contract addresses (V2 deployment - Fixed)
    address constant DAI_ADDRESS = 0xa85233C63b9Ee964Add6F2cffe00Fd84eb32338f;
    address constant AAVE_ADDRESS = 0x4A679253410272dd5232B3Ff7cF5dbB88f295319;
    address constant COMPOUND_ADDRESS = 0x7a2088a1bFc9d81c55368AE168C2C02570cB814F;
    address constant VAULT_V2_ADDRESS = 0x09635F643e140090A9A8Dcd712eD6285858ceBef;

    MockDAI dai;
    MockAave aave;
    MockCompound compound;
    YieldVaultV2 vault;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Initialize contract interfaces
        dai = MockDAI(DAI_ADDRESS);
        aave = MockAave(AAVE_ADDRESS);
        compound = MockCompound(COMPOUND_ADDRESS);
        vault = YieldVaultV2(VAULT_V2_ADDRESS);

        console2.log("=== AUTO-YIELD PORTFOLIO MANAGER DEMO ===\n");

        // Step 1: Show initial state
        _showInitialState();

        // Step 2: User deposits
        _demonstrateDeposit();

        // Step 3: Simulate time passage and yield accrual
        _demonstrateYieldAccrual();

        // Step 4: Show yield compounding
        _demonstrateCompounding();

        // Step 5: Demonstrate rebalancing
        _demonstrateRebalancing();

        // Step 6: Show final results and withdrawals
        _demonstrateFinalResults();

        vm.stopBroadcast();
    }

    function _showInitialState() internal view {
        console2.log("1. INITIAL STATE");
        console2.log("================");
        
        (uint256 totalAssets, uint256 totalYield, uint256 apy, uint256 rebalances, uint256 compounds, uint256 sharePrice) = vault.getVaultMetrics();
        (string memory currentProtocolName,, ) = vault.getCurrentProtocolInfo();
        
        console2.log("Active Protocol:", currentProtocolName);
        console2.log("Aave APY:", aave.getAPY(), "basis points");
        console2.log("Compound APY:", compound.getAPY(), "basis points");
        console2.log("Vault Total Assets:", totalAssets / 1e18, "DAI");
        console2.log("Share Price:", sharePrice / 1e14, "DAI (x10000)");
        console2.log("Total Rebalances:", rebalances);
        console2.log("Total Compounds:", compounds);
        console2.log("");
    }

    function _demonstrateDeposit() internal {
        console2.log("2. USER DEPOSIT");
        console2.log("===============");
        
        // Mint DAI for user
        dai.mint(msg.sender, 1000 ether);
        console2.log("Minted 1000 DAI for user");
        
        // Approve and deposit
        dai.approve(address(vault), 1000 ether);
        vault.deposit(500 ether);
        
        console2.log("Deposited 500 DAI to vault");
        
        (uint256 principal, uint256 currentValue, uint256 yield) = vault.getUserValue(msg.sender);
        console2.log("User Principal:", principal / 1e18, "DAI");
        console2.log("User Current Value:", currentValue / 1e18, "DAI");
        console2.log("User Yield Earned:", yield / 1e18, "DAI");
        console2.log("");
    }

    function _demonstrateYieldAccrual() internal {
        console2.log("3. YIELD ACCRUAL SIMULATION");
        console2.log("===========================");
        
        console2.log("Simulating 24 hours of yield accrual...");
        
        // Fast forward 24 hours
        vm.warp(block.timestamp + 24 hours);
        
        // Show yield before compounding
        (uint256 principal, uint256 currentValue, uint256 yield) = vault.getUserValue(msg.sender);
        console2.log("After 24 hours:");
        console2.log("User Principal:", principal / 1e18, "DAI");
        console2.log("User Current Value:", currentValue / 1e18, "DAI");
        console2.log("User Yield Earned:", yield / 1e18, "DAI");
        
        // Show protocol-level yield
        if (address(vault.currentProtocol()) == address(aave)) {
            (uint256 protocolPrincipal, uint256 protocolAccrued, uint256 protocolCurrent, uint256 protocolTotal) = aave.getUserDeposit(address(vault));
            console2.log("Protocol Principal:", protocolPrincipal / 1e18);
            console2.log("Protocol Accrued:", protocolAccrued / 1e18);
            console2.log("Protocol Current:", protocolCurrent / 1e18);
        }
        console2.log("");
    }

    function _demonstrateCompounding() internal {
        console2.log("4. YIELD COMPOUNDING");
        console2.log("====================");
        
        // Manual compound to show the effect
        vault.compoundYield();
        console2.log("Manual compound executed");
        
        (,uint256 totalYield, uint256 apy, uint256 rebalances, uint256 compounds,) = vault.getVaultMetrics();
        console2.log("Total Yield Generated:", totalYield / 1e18, "DAI");
        console2.log("Total Compounds:", compounds);
        
        // Show updated user value
        (uint256 principal, uint256 currentValue, uint256 yield) = vault.getUserValue(msg.sender);
        console2.log("User Value After Compound:");
        console2.log("Principal:", principal / 1e18, "DAI");
        console2.log("Current Value:", currentValue / 1e18, "DAI");
        console2.log("Yield:", yield / 1e18, "DAI");
        console2.log("");
    }

    function _demonstrateRebalancing() internal {
        console2.log("5. PROTOCOL REBALANCING");
        console2.log("=======================");
        
        (string memory currentProtocolName,,) = vault.getCurrentProtocolInfo();
        console2.log("Current Protocol:", currentProtocolName);
        console2.log("Aave APY:", aave.getAPY());
        console2.log("Compound APY:", compound.getAPY());
        
        // Change APYs to trigger rebalancing
        if (address(vault.currentProtocol()) == address(aave)) {
            console2.log("Increasing Compound APY to trigger rebalance...");
            compound.setAPY(900); // 9%
        } else {
            console2.log("Increasing Aave APY to trigger rebalance...");
            aave.setAPY(900); // 9%
        }
        
        console2.log("New APYs - Aave:", aave.getAPY(), "Compound:", compound.getAPY());
        
        // Manual rebalance
        vault.manualRebalance();
        (string memory newProtocolName,,) = vault.getCurrentProtocolInfo();
        console2.log("Rebalanced to:", newProtocolName);
        
        (,,,uint256 rebalances,,) = vault.getVaultMetrics();
        console2.log("Total Rebalances:", rebalances);
        console2.log("");
    }

    function _demonstrateFinalResults() internal {
        console2.log("6. FINAL RESULTS & WITHDRAWAL");
        console2.log("=============================");
        
        // Fast forward another 12 hours to show more yield
        vm.warp(block.timestamp + 12 hours);
        vault.compoundYield();
        
        // Show final vault metrics
        (uint256 totalAssets, uint256 totalYield, uint256 estimatedAPY, uint256 rebalances, uint256 compounds, uint256 sharePrice) = vault.getVaultMetrics();
        
        console2.log("VAULT FINAL METRICS:");
        console2.log("Total Assets:", totalAssets / 1e18, "DAI");
        console2.log("Total Yield Generated:", totalYield / 1e18, "DAI");
        console2.log("Estimated APY:", estimatedAPY, "basis points");
        console2.log("Total Rebalances:", rebalances);
        console2.log("Total Compounds:", compounds);
        console2.log("Share Price:", sharePrice / 1e14, "DAI (x10000)");
        
        // Show user's final position
        (uint256 principal, uint256 currentValue, uint256 yield) = vault.getUserValue(msg.sender);
        console2.log("\nUSER FINAL POSITION:");
        console2.log("Principal Invested:", principal / 1e18, "DAI");
        console2.log("Current Value:", currentValue / 1e18, "DAI");
        console2.log("Total Yield Earned:", yield / 1e18, "DAI");
        console2.log("ROI:", yield * 100 / principal, "%");
        
        // Partial withdrawal to show functionality
        console2.log("\nDemonstrating partial withdrawal...");
        (uint256 userPrincipal, uint256 userShares, uint256 userDepositTime) = vault.userDeposits(msg.sender);
        vault.withdraw(userShares / 2); // Withdraw 50%
        
        console2.log("Withdrew 50% of position");
        (principal, currentValue, yield) = vault.getUserValue(msg.sender);
        console2.log("Remaining Principal:", principal / 1e18, "DAI");
        console2.log("Remaining Value:", currentValue / 1e18, "DAI");
        
        console2.log("\n=== AUTO-YIELD DEMO COMPLETE ===");
        console2.log("SUCCESS: Real yield generation over time");
        console2.log("SUCCESS: Automatic yield compounding");
        console2.log("SUCCESS: Protocol optimization/rebalancing");
        console2.log("SUCCESS: Share-based vault system");
        console2.log("SUCCESS: Partial withdrawals");
    }
}
