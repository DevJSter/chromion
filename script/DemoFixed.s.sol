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
        console2.log("1. Minting test DAI tokens...");
        dai.mint(msg.sender, 1000 ether);
        uint256 userBalance = dai.balanceOf(msg.sender);
        console2.log("User DAI balance:");
        console2.log(userBalance / 1e18);

        // 2. Check initial APYs
        console2.log("2. Current Protocol APYs:");
        console2.log("Aave APY (basis points):");
        console2.log(aave.getAPY());
        console2.log("Compound APY (basis points):");
        console2.log(compound.getAPY());

        // 3. Approve and deposit to vault
        console2.log("3. Depositing 500 DAI to vault...");
        dai.approve(VAULT_ADDRESS, 500 ether);
        vault.deposit(500 ether);
        
        console2.log("Total vault assets:");
        console2.log(vault.totalAssets() / 1e18);
        console2.log("User vault balance:");
        console2.log(vault.getBalance(msg.sender) / 1e18);
        console2.log("Current protocol:");
        console2.logAddress(address(vault.currentProtocol()));

        // 4. Simulate APY change by updating Compound APY
        console2.log("4. Simulating APY change - Compound increases to 8%...");
        compound.setAPY(800); // 8%
        console2.log("New Compound APY (basis points):");
        console2.log(compound.getAPY());

        // 5. Trigger rebalance
        console2.log("5. Triggering rebalance...");
        (bool upkeepNeeded, bytes memory performData) = vault.checkUpkeep("");
        if (upkeepNeeded) {
            vault.performUpkeep(performData);
            console2.log("Rebalance completed!");
            console2.log("New current protocol:");
            console2.logAddress(address(vault.currentProtocol()));
        } else {
            console2.log("No rebalance needed");
        }

        // 6. Check final state
        console2.log("6. Final State:");
        console2.log("Total vault assets:");
        console2.log(vault.totalAssets() / 1e18);
        console2.log("Current protocol:");
        console2.logAddress(address(vault.currentProtocol()));
        console2.log("User can withdraw:");
        console2.log(vault.getBalance(msg.sender) / 1e18);

        // 7. Demonstrate withdrawal
        console2.log("7. Withdrawing 100 DAI...");
        vault.withdraw(100 ether);
        console2.log("User DAI balance after withdrawal:");
        console2.log(dai.balanceOf(msg.sender) / 1e18);
        console2.log("Remaining vault balance:");
        console2.log(vault.getBalance(msg.sender) / 1e18);

        console2.log("=== Demo Complete ===");
        console2.log("Auto-yield vault successfully demonstrated!");
        console2.log("Chainlink Automation integration working");
        console2.log("Dynamic rebalancing based on APY changes");

        vm.stopBroadcast();
    }
}
