'use client';

import { useAccount, useReadContract } from 'wagmi';
import { formatEther } from 'viem';
import { YieldVaultABI, MockDAIABI } from '@/config/abis';
import { contractAddresses, anvil } from '@/config/wagmi';
import { DollarSign, TrendingUp, Activity, Users } from 'lucide-react';

export default function VaultStats() {
  const { address, chain } = useAccount();
  
  const currentChainId = chain?.id || anvil.id;
  const vaultAddress = contractAddresses[currentChainId as keyof typeof contractAddresses]?.yieldVault;
  const daiAddress = contractAddresses[currentChainId as keyof typeof contractAddresses]?.mockDAI;

  // Read user balance
  const { data: userBalance } = useReadContract({
    address: vaultAddress,
    abi: YieldVaultABI,
    functionName: 'getBalance',
    args: address ? [address] : undefined,
  });

  // Read total assets
  const { data: totalAssets } = useReadContract({
    address: vaultAddress,
    abi: YieldVaultABI,
    functionName: 'totalAssets',
  });

  // Read current protocol info
  const { data: protocolInfo } = useReadContract({
    address: vaultAddress,
    abi: YieldVaultABI,
    functionName: 'getCurrentProtocolInfo',
  });

  // Read protocol APYs
  const { data: protocolAPYs } = useReadContract({
    address: vaultAddress,
    abi: YieldVaultABI,
    functionName: 'getProtocolAPYs',
  });

  // Read total DAI supply (for context)
  const { data: totalDAISupply } = useReadContract({
    address: daiAddress,
    abi: MockDAIABI,
    functionName: 'totalSupply',
  });

  const formatAPY = (apy: bigint | undefined) => {
    if (!apy) return '0.00';
    return (Number(apy) / 100).toFixed(2);
  };

  const formatBalance = (balance: bigint | undefined) => {
    if (!balance) return '0.00';
    return parseFloat(formatEther(balance)).toFixed(2);
  };

  const currentProtocolName = protocolInfo?.[0] || 'Loading...';
  const currentAPY = protocolInfo?.[1];
  const aaveAPY = protocolAPYs?.[0];
  const compoundAPY = protocolAPYs?.[1];

  return (
    <div className="bg-white/60 dark:bg-gray-800/80 backdrop-blur-sm rounded-xl p-6 shadow-lg">
      <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-6">Vault Overview</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Your Balance */}
        <div className="bg-gradient-to-r from-blue-500 to-blue-600 rounded-lg p-4 text-white">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-blue-100 text-sm">Your Balance</p>
              <p className="text-2xl font-bold">{formatBalance(userBalance)}</p>
              <p className="text-blue-100 text-xs">DAI</p>
            </div>
            <DollarSign className="h-8 w-8 text-blue-200" />
          </div>
        </div>

        {/* Total Vault Assets */}
        <div className="bg-gradient-to-r from-green-500 to-green-600 rounded-lg p-4 text-white">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-green-100 text-sm">Total Assets</p>
              <p className="text-2xl font-bold">{formatBalance(totalAssets)}</p>
              <p className="text-green-100 text-xs">DAI</p>
            </div>
            <Users className="h-8 w-8 text-green-200" />
          </div>
        </div>

        {/* Current APY */}
        <div className="bg-gradient-to-r from-purple-500 to-purple-600 rounded-lg p-4 text-white">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-purple-100 text-sm">Current APY</p>
              <p className="text-2xl font-bold">{formatAPY(currentAPY)}%</p>
              <p className="text-purple-100 text-xs">{currentProtocolName}</p>
            </div>
            <TrendingUp className="h-8 w-8 text-purple-200" />
          </div>
        </div>

        {/* Active Protocol */}
        <div className="bg-gradient-to-r from-orange-500 to-orange-600 rounded-lg p-4 text-white">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-orange-100 text-sm">Active Protocol</p>
              <p className="text-lg font-bold">{currentProtocolName}</p>
              <p className="text-orange-100 text-xs">Auto-selected</p>
            </div>
            <Activity className="h-8 w-8 text-orange-200" />
          </div>
        </div>
      </div>

      {/* Protocol Comparison */}
      {aaveAPY && compoundAPY && (
        <div className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
            <div className="flex justify-between items-center">
              <span className="font-medium text-gray-900 dark:text-white">Aave APY</span>
              <span className="text-lg font-bold text-gray-900 dark:text-white">
                {formatAPY(aaveAPY)}%
              </span>
            </div>
          </div>
          <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4">
            <div className="flex justify-between items-center">
              <span className="font-medium text-gray-900 dark:text-white">Compound APY</span>
              <span className="text-lg font-bold text-gray-900 dark:text-white">
                {formatAPY(compoundAPY)}%
              </span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
