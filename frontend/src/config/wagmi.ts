import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { mainnet, polygon, optimism, arbitrum, sepolia } from 'wagmi/chains';
import { defineChain } from 'viem';

// Define local Anvil chain
export const anvil = defineChain({
  id: 31337,
  name: 'Anvil',
  nativeCurrency: {
    decimals: 18,
    name: 'Ether',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: {
      http: ['http://127.0.0.1:8545'],
    },
  },
})

export const config = getDefaultConfig({
  appName: 'Chainlink Auto-Yield Vault',
  projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'default-project-id',
  chains: [anvil, mainnet, polygon, optimism, arbitrum, sepolia],
  ssr: true, // If your dApp uses server side rendering (SSR)
});

// Contract addresses
export const contracts = {
  mockDAI: (process.env.NEXT_PUBLIC_MOCKDAI_ADDRESS || '0x5FbDB2315678afecb367f032d93F642f64180aa3') as `0x${string}`,
  mockAave: (process.env.NEXT_PUBLIC_AAVE_ADDRESS || '0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512') as `0x${string}`,
  mockCompound: (process.env.NEXT_PUBLIC_COMPOUND_ADDRESS || '0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0') as `0x${string}`,
  yieldVault: (process.env.NEXT_PUBLIC_VAULT_ADDRESS || '0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9') as `0x${string}`,
} as const;

export const contractAddresses = {
  [anvil.id]: {
    mockDAI: contracts.mockDAI,
    mockAave: contracts.mockAave,
    mockCompound: contracts.mockCompound,
    yieldVault: contracts.yieldVault,
  },
  [sepolia.id]: {
    mockDAI: '0x' as `0x${string}`,
    mockAave: '0x' as `0x${string}`,
    mockCompound: '0x' as `0x${string}`,
    yieldVault: '0x' as `0x${string}`,
  },
  // Add other networks as needed
};
