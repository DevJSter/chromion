// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console2} from "forge-std/Script.sol";
import {MockDAI} from "../src/MockDAI.sol";
import {MockAave} from "../src/MockAave.sol";
import {MockCompound} from "../src/MockCompound.sol";
import {YieldVaultV2} from "../src/YieldVaultV2.sol";

/**
 * @title DeployV2
 * @dev Deploy the enhanced Auto-Yield Vault with real yield compounding
 */
contract DeployV2 is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Mock DAI
        console2.log("Deploying MockDAI...");
        MockDAI dai = new MockDAI();
        console2.log("MockDAI deployed at:", address(dai));

        // Deploy Mock Aave (3.5% APY)
        console2.log("Deploying MockAave...");
        MockAave aave = new MockAave(address(dai));
        console2.log("MockAave deployed at:", address(aave));

        // Deploy Mock Compound (5.1% APY)
        console2.log("Deploying MockCompound...");
        MockCompound compound = new MockCompound(address(dai));
        console2.log("MockCompound deployed at:", address(compound));

        // Deploy YieldVaultV2 (Enhanced Auto-Yield)
        console2.log("Deploying YieldVaultV2...");
        YieldVaultV2 vault = new YieldVaultV2(
            address(dai),
            address(aave),
            address(compound)
        );
        console2.log("YieldVaultV2 deployed at:", address(vault));

        vm.stopBroadcast();

        // Save addresses to .env file
        console2.log("\n=== DEPLOYMENT COMPLETE ===");
        console2.log("Add these addresses to your .env file:");
        console2.log("DAI_ADDRESS=", address(dai));
        console2.log("AAVE_ADDRESS=", address(aave));
        console2.log("COMPOUND_ADDRESS=", address(compound));
        console2.log("VAULT_V2_ADDRESS=", address(vault));
        
        console2.log("\n=== INITIAL STATE ===");
        console2.log("Aave APY:", aave.getAPY(), "basis points");
        console2.log("Compound APY:", compound.getAPY(), "basis points");
        
        (string memory protocolName, uint256 protocolAPY, uint256 protocolBalance) = vault.getCurrentProtocolInfo();
        console2.log("Active Protocol:", protocolName);
        console2.log("Protocol APY:", protocolAPY, "bp");
        console2.log("Protocol Balance:", protocolBalance / 1e18, "DAI");
    }
}
