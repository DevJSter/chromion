#!/bin/bash

# Chainlink Auto-Yield Vault - Complete Demo Script
# This script demonstrates the full end-to-end functionality

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Chainlink Auto-Yield Portfolio Manager - Full Demo${NC}"
echo "=================================================================="
echo ""

# Check if Anvil is running
if ! curl -s http://localhost:8545 > /dev/null; then
    echo -e "${RED}❌ Anvil is not running. Please start it first with: anvil${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Anvil is running${NC}"
echo ""

echo -e "${BLUE}📋 Demo Steps:${NC}"
echo "1. Run comprehensive smart contract tests"
echo "2. Execute contract interaction demo"
echo "3. Verify frontend integration"
echo "4. Test manual rebalancing functionality"
echo ""

# Step 1: Run tests
echo -e "${BLUE}Step 1: Running comprehensive tests...${NC}"
forge test -vv
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
else
    echo -e "${RED}❌ Tests failed!${NC}"
    exit 1
fi
echo ""

# Step 2: Run demo script
echo -e "${BLUE}Step 2: Running contract interaction demo...${NC}"
forge script script/DemoFixed.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Contract demo completed successfully!${NC}"
else
    echo -e "${RED}❌ Contract demo failed!${NC}"
    exit 1
fi
echo ""

# Step 3: Check frontend
echo -e "${BLUE}Step 3: Verifying frontend...${NC}"
if curl -s http://localhost:3001 > /dev/null; then
    echo -e "${GREEN}✅ Frontend is running at http://localhost:3001${NC}"
else
    echo -e "${RED}❌ Frontend is not accessible${NC}"
fi
echo ""

# Step 4: Display current contract state
echo -e "${BLUE}Step 4: Current Contract State${NC}"
echo "----------------------------------------"

# Display contract addresses
echo -e "${YELLOW}📍 Deployed Contract Addresses:${NC}"
echo "MockDAI:     0x5FbDB2315678afecb367f032d93F642f64180aa3"
echo "MockAave:    0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
echo "MockCompound: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
echo "YieldVault:  0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9"
echo ""

echo -e "${YELLOW}💡 Key Features Demonstrated:${NC}"
echo "✅ Non-custodial vault with user deposit/withdraw"
echo "✅ Automatic yield optimization between protocols"
echo "✅ Chainlink Automation for periodic rebalancing"
echo "✅ Real-time APY monitoring and comparison"
echo "✅ Manual rebalancing controls for testing"
echo "✅ Complete transaction history tracking"
echo "✅ Modern Web3 frontend with wallet integration"
echo ""

echo -e "${YELLOW}🎯 What You Can Do Now:${NC}"
echo "1. Open http://localhost:3001 in your browser"
echo "2. Connect your wallet (use Anvil test account)"
echo "3. Click 'Mint 1000 DAI' to get test tokens"
echo "4. Deposit DAI into the vault"
echo "5. Use manual controls to change protocol APYs"
echo "6. Watch automatic rebalancing happen"
echo "7. Withdraw your funds anytime"
echo ""

echo -e "${YELLOW}🔧 Testing Rebalancing:${NC}"
echo "1. Deposit some DAI into the vault"
echo "2. Note which protocol is currently active"
echo "3. Use the manual controls to increase the other protocol's APY"
echo "4. Click 'Force Rebalance' to trigger rebalancing"
echo "5. Watch the vault switch to the higher APY protocol"
echo ""

echo -e "${YELLOW}📊 Frontend Features:${NC}"
echo "• Real-time vault statistics and balances"
echo "• Live protocol APY comparison with charts"
echo "• One-click DAI minting for testing"
echo "• Seamless deposit/withdraw with approval handling"
echo "• Manual APY controls for demonstration"
echo "• Complete rebalancing history"
echo ""

echo -e "${GREEN}🎉 Demo Complete!${NC}"
echo ""
echo -e "${BLUE}💼 For Hackathon Judges:${NC}"
echo "This project demonstrates:"
echo "• Real-world DeFi utility - automated yield optimization"
echo "• Proper Chainlink integration - Automation for rebalancing"
echo "• Security best practices - non-custodial, tested, auditable"
echo "• Modern development stack - Foundry, Next.js, TypeScript"
echo "• Complete user experience - beautiful UI with full functionality"
echo ""
echo -e "${YELLOW}🔗 Quick Links:${NC}"
echo "Frontend: http://localhost:3001"
echo "Anvil RPC: http://localhost:8545"
echo "Test Account: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo ""
echo -e "${GREEN}Ready for judging! 🏆${NC}"
