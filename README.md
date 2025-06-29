# Chainlink Auto-Yield Portfolio Manager

**STATUS: COMPLETE & READY FOR DEMO**

A non-custodial smart vault that automatically reallocates user funds between lending protocols (Aave and Compound) to optimize yield, powered by Chainlink Automation and Data Feeds.

## Quick Start

```bash
# 1. Start Anvil
anvil

# 2. Deploy contracts (new terminal)
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast

# 3. Start frontend (new terminal)
cd frontend && npm install && npm run dev

# 4. Open http://localhost:3000
```

## Features Complete

- Smart Contracts: YieldVault with Chainlink Automation
- Frontend: Modern Next.js app with Web3 integration  
- Testing: 13/13 tests passing
- Demo: Full functionality demonstration
- Documentation: Complete project guide

## Live Demo

- Contracts: Deployed on local Anvil at addresses in `.env`
- Frontend: http://localhost:3000
- Demo Script: `./demo.sh` for full walkthrough

---

You're building a Chainlink-powered Auto-Yield Portfolio Manager. This is a non-custodial smart vault that reallocates user funds into different yield sources automatically based on conditions like APY, time, or price movement.

---

## 1. Feature Breakdown (MVP Scope)

### Core User Flow

1. User deposits ETH or stablecoins (for example, DAI).
2. The vault allocates funds to the protocol with the highest yield (Aave or Compound).
3. Chainlink Automation monitors APY and other conditions.
4. When another protocol offers a better yield, the vault rebalances user funds.

---

### MVP Features

| Feature                  | Description                                                             |
| ------------------------ | ----------------------------------------------------------------------- |
| Deposit/Withdraw         | Users can stake and unstake their tokens into the vault.                |
| Yield Allocation         | Vault chooses between Aave and Compound based on APY.                   |
| Chainlink Automation     | Runs a check every X blocks to decide if a rebalance is needed.         |
| Chainlink Data Feeds     | Fetch APY or interest rate feeds (mocked if real ones are unavailable). |
| Rebalancer Logic         | Withdraw from old protocol and deposit into new one automatically.      |
| UI Dashboard             | Show current vault status, yields, rebalance events, and more.          |

---

## 2. Chainlink Integration Plan

### Tools You'll Use

| Tool                     | Purpose                                                            |
| ------------------------ | ------------------------------------------------------------------ |
| Automation               | Automate yield checking and protocol switching.                    |
| Data Feeds               | APY or interest rate data (or mock from a price feed for demo).    |
| Functions (optional)     | Pull custom yield data or external DEX/APR APIs (for example, DefiLlama). |

### Example Automation Flow

Every 6 hours, a Chainlink Keeper checks:

- Aave DAI yield = 3.5%
- Compound DAI yield = 5.1%
- Switch to Compound if the difference is greater than 1%

---

## 3. Smart Contract Boilerplate (Vault Skeleton)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ILendingProtocol {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getAPY() external view returns (uint256);
}

contract YieldVault {
    address public owner;
    address public token; // e.g., DAI
    address public currentProtocol;
    mapping(address => uint256) public balances;

    ILendingProtocol public aave;
    ILendingProtocol public compound;

    constructor(address _token, address _aave, address _compound) {
        owner = msg.sender;
        token = _token;
        aave = ILendingProtocol(_aave);
        compound = ILendingProtocol(_compound);
    }

    function deposit(uint256 amount) external {
        // Transfer tokens and track balance
    }

    function withdraw(uint256 amount) external {
        // Withdraw from protocol and return to user
    }

    function rebalance() external {
        // Called by Chainlink Automation
        uint256 aaveAPY = aave.getAPY();
        uint256 compoundAPY = compound.getAPY();

        if (compoundAPY > aaveAPY + 100) {
            // Withdraw from Aave and deposit to Compound
            currentProtocol = address(compound);
        } else if (aaveAPY > compoundAPY + 100) {
            // Withdraw from Compound and deposit to Aave
            currentProtocol = address(aave);
        }
    }
}
```

Add access control, reentrancy guard, and real token logic for production. This is a clean MVP.

---

## 4. Frontend Idea (Tailwind and Ethers.js)

### Pages/Components

1. Dashboard

   - Current vault value
   - Current protocol (Aave or Compound)
   - Estimated APY
   - Rebalance logs

2. Deposit/Withdraw

   - Simple form to stake or unstake tokens

3. Yield Comparison Graph

   - (Optional) Chart of past APYs (mock or real)

---

### Stack

| Component            | Tech                           |
| -------------------- | ------------------------------ |
| UI                   | TailwindCSS and React          |
| Wallet               | RainbowKit / Wagmi / Ethers.js |
| Chainlink Automation | Register upkeep job            |
| Charting             | Chart.js or Recharts (for APY) |

---

### DEX Integration: Needed?

Not directly at MVP, but:

- You’ll need token swaps if the vault supports yield in multiple tokens.
- For example, if yield on Compound is in cDAI, and you want to switch to ETH, a DEX call is required (Uniswap or 1inch).
- You can mock this step to keep things simple for the hackathon — assume all vaults use DAI.

---

## Optional Power-Ups (for judging bonus)

- Chainlink Functions to fetch live APYs from DefiLlama or APIs.
- UI leaderboard: Top users based on ROI
- Add NFT vault access (only holders can use it)

---

Would you like me to scaffold the contract with proper token logic and mock lending protocol interfaces? Or generate a React/Tailwind UI shell you can plug into?

Here’s a clear, high-level overview of your Chainlink hackathon project:

---

# Project: Auto-Yield Vault

A smart contract vault that automatically reallocates user funds between lending protocols (like Aave and Compound) to optimize yield, powered by Chainlink Automation and Data Feeds.

---

## Concept Summary

| Aspect           | Description                                                                                                              |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------ |
| Problem          | DeFi users must manually chase yield, which is inefficient and error-prone.                                              |
| Solution         | A non-custodial smart vault that uses Chainlink to monitor yields and auto-switch funds to the most profitable protocol. |
| Target Users     | DeFi investors who want passive optimized returns.                                                                       |

---

## Architecture Overview

```
+-----------------------------+
|       User Interface        |
| (React + Tailwind + Ethers) |
+-------------+---------------+
              |
              v
+-----------------------------+
|     Auto-Yield Vault SC     | ←→ Users deposit/withdraw
|  (Holds funds + logic)      |
+-------------+---------------+
              |
              v
+-----------------------------+        +-----------------------------+
|   Lending Protocol A        |        |   Lending Protocol B        |
|   (e.g. Aave, real or mock) |        |   (e.g. Compound, real or mock) |
+-----------------------------+        +-----------------------------+
              ^
              |
+-------------+---------------+
|  Chainlink Automation Job   | ← checks APYs every N blocks
+-------------+---------------+
              |
+-----------------------------+
|  Chainlink Data Feed or     |
|  MockAPY Oracle             |
+-----------------------------+
```

---

## Chainlink Usage

| Tool                      | Purpose                                                             |
| ------------------------- | ------------------------------------------------------------------- |
| Automation                | Calls `rebalance()` on the vault every few hours.                   |
| Data Feeds / Mock APY     | Feeds current yields from Aave/Compound (or mocked).                |
| (Optional) Functions      | Pull live APYs from APIs like DeFi Llama, if you want extra credit. |

---

## Technical Stack

### Smart Contracts

- ERC20-based Vault (Solidity)
- Mock Lending Contracts (Aave, Compound clones)
- Rebalance logic based on `getAPY()`

### Frontend

- React and Tailwind
- Wallet connection (Wagmi and Ethers.js)
- Dashboard: deposit/withdraw, current APY, active protocol
- Optional: APY chart, vault history

---

## Hackathon Features (MVP)

| Feature                            | Status                                |
| ---------------------------------- | ------------------------------------- |
| Deposit/withdraw UI                | Yes                                   |
| Yield simulation                   | Use mock lending pools with fixed APY |
| Chainlink Automation integration   | For periodic rebalancing              |
| Data Feed or mock APY input        | Used to trigger strategy switch       |
| Clear UX                           | Show current protocol and APY to user |

---

## Demo Plan

- Deploy mock Aave and Compound contracts with different APY values
- Show funds being moved from one protocol to another
- Use Chainlink Automation to trigger `rebalance()` on testnet (Sepolia/Optimism Sepolia)
- Use test tokens (DAI) for user deposits
- Frontend shows vault state updating in real-time

---

## Judge-Winning Angles

- Real-world use case: Users want this today.
- Chainlink native: Clean integration with Automation and Feeds.
- Solo-friendly: Smart scope, yet looks impressive.
- Bonus potential: Add AI suggestions, NFTs, leaderboard, or Telegram alerts later.

---

Let me know which part you want to build next:

- Vault contract with mock protocol hooks?
- Mock lending contracts with fixed APYs?
- Frontend starter template?
- Chainlink Automation example?

Just say the word and I’ll scaffold it.
