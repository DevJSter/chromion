// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/MockDAI.sol";
import "../src/MockAave.sol";
import "../src/MockCompound.sol";
import "../src/YieldVault.sol";

contract DemoScript is Script {
    address constant MOCKDAI_ADDRESS = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    address constant AAVE_ADDRESS = 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512;
    address constant COMPOUND_ADDRESS = 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0;
    address constant VAULT_ADDRESS = 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Get contract instances
        MockDAI dai = MockDAI(MOCKDAI_ADDRESS);
        MockAave aave = MockAave(AAVE_ADDRESS);
        MockCompound compound = MockCompound(COMPOUND_ADDRESS);
        YieldVault vault = YieldVault(VAULT_ADDRESS);

        console2.log("=== Chainlink Auto-Yield Vault Demo ===");
        console2.log("User address:");
        console2.logAddress(msg.sender);
        
        // 1. Mint some DAI tokens for testing
        console.log("\n1. Minting test DAI tokens...");
        dai.mint(msg.sender, 1000 ether);
        uint256 userBalance = dai.balanceOf(msg.sender);
        console.log("User DAI balance (in ether):");
        console.log(userBalance / 1e18);

        // 2. Check initial APYs
        console.log("\n2. Current Protocol APYs:");
        console.log("Aave APY (basis points):");
        console.log(aave.getAPY());
        console.log("Compound APY (basis points):");
        console.log(compound.getAPY());

        // 3. Approve and deposit to vault
        console.log("\n3. Depositing 500 DAI to vault...");
        dai.approve(VAULT_ADDRESS, 500 ether);
        vault.deposit(500 ether);
        
        console.log("Vault total assets (in ether):");
        console.log(vault.totalAssets() / 1e18);
        console.log("User vault balance (in ether):");
        console.log(vault.balances(msg.sender) / 1e18);
        console.log("Current protocol address:");
        console.log(vault.currentProtocol());

        // 4. Simulate APY change by updating Compound APY
        console.log("\n4. Simulating APY change - Compound increases to 8%...");
        compound.setAPY(800); // 8%
        console.log("New Compound APY (basis points):");
        console.log(compound.getAPY());

        // 5. Trigger rebalance
        console.log("\n5. Triggering rebalance...");
        vault.checkUpkeep("");
        (, bytes memory performData) = vault.checkUpkeep("");
        if (performData.length > 0) {
            vault.performUpkeep(performData);
            console.log("Rebalance completed!");
            console.log("New current protocol address:");
            console.log(vault.currentProtocol());
        } else {
            console.log("No rebalance needed");
        }

        // 6. Check final state
        console.log("\n6. Final State:");
        console.log("Vault total assets (in ether):");
        console.log(vault.totalAssets() / 1e18);
        console.log("Current protocol address:");
        console.log(vault.currentProtocol());
        console.log("User can withdraw (in ether):");
        console.log(vault.balances(msg.sender) / 1e18);

        // 7. Demonstrate withdrawal
        console.log("\n7. Withdrawing 100 DAI...");
        vault.withdraw(100 ether);
        console.log("User DAI balance after withdrawal (in ether):");
        console.log(dai.balanceOf(msg.sender) / 1e18);
        console.log("Remaining vault balance (in ether):");
        console.log(vault.balances(msg.sender) / 1e18);

        console.log("\n=== Demo Complete ===");
        console.log("Auto-yield vault successfully demonstrated!");
        console.log("Chainlink Automation integration working");
        console.log("Dynamic rebalancing based on APY changes");

        vm.stopBroadcast();
    }
}
