// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/MockDAI.sol";
import "../src/MockAave.sol";
import "../src/MockCompound.sol";
import "../src/YieldVault.sol";

contract DeployScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy Mock DAI
        MockDAI dai = new MockDAI();
        console.log("MockDAI deployed at:", address(dai));

        // Deploy Mock Lending Protocols
        MockAave aave = new MockAave(address(dai));
        console.log("MockAave deployed at:", address(aave));

        MockCompound compound = new MockCompound(address(dai));
        console.log("MockCompound deployed at:", address(compound));

        // Deploy Yield Vault
        YieldVault vault = new YieldVault(
            address(dai),
            address(aave),
            address(compound)
        );
        console.log("YieldVault deployed at:", address(vault));

        // Output deployment info
        console.log("\n=== Deployment Summary ===");
        console.log("MockDAI:", address(dai));
        console.log("MockAave:", address(aave));
        console.log("MockCompound:", address(compound));
        console.log("YieldVault:", address(vault));
        
        // Output initial APYs
        console.log("\n=== Initial APYs ===");
        console.log("Aave APY:", aave.getAPY(), "basis points");
        console.log("Compound APY:", compound.getAPY(), "basis points");

        vm.stopBroadcast();
    }
}
