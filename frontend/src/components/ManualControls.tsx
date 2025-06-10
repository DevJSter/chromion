'use client';

import { useState } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { YieldVaultABI, MockAaveABI, MockCompoundABI } from '@/config/abis';
import { contractAddresses, anvil } from '@/config/wagmi';
import { RefreshCw, Settings, TrendingUp, Loader2 } from 'lucide-react';

export default function ManualControls() {
  const [newAPY, setNewAPY] = useState('');
  const [protocol, setProtocol] = useState<'aave' | 'compound'>('compound');
  const { chain } = useAccount();
  
  const currentChainId = chain?.id || anvil.id;
  const vaultAddress = contractAddresses[currentChainId as keyof typeof contractAddresses]?.yieldVault;
  const aaveAddress = contractAddresses[currentChainId as keyof typeof contractAddresses]?.mockAave;
  const compoundAddress = contractAddresses[currentChainId as keyof typeof contractAddresses]?.mockCompound;

  const { writeContract, data: hash, isPending } = useWriteContract();
  
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  const handleSetAPY = async () => {
    if (!newAPY || !aaveAddress || !compoundAddress) return;

    const targetAddress = protocol === 'aave' ? aaveAddress : compoundAddress;
    const targetABI = protocol === 'aave' ? MockAaveABI : MockCompoundABI;
    
    // Convert APY percentage to basis points (multiply by 100)
    const apyInBasisPoints = BigInt(Math.round(parseFloat(newAPY) * 100));

    writeContract({
      address: targetAddress,
      abi: targetABI,
      functionName: 'setAPY',
      args: [apyInBasisPoints],
    });
  };

  const handleManualRebalance = async () => {
    if (!vaultAddress) return;

    writeContract({
      address: vaultAddress,
      abi: YieldVaultABI,
      functionName: 'manualRebalance',
    });
  };

  return (
    <div className="bg-white/60 backdrop-blur-sm rounded-xl p-6 shadow-lg">
      <div className="flex items-center gap-2 mb-6">
        <Settings className="h-5 w-5" />
        <h3 className="text-lg font-semibold">Manual Controls</h3>
      </div>

      {/* APY Control */}
      <div className="space-y-4 mb-6">
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Simulate APY Change
          </label>
          <div className="flex gap-2">
            <select
              value={protocol}
              onChange={(e) => setProtocol(e.target.value as 'aave' | 'compound')}
              className="px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="aave">Aave</option>
              <option value="compound">Compound</option>
            </select>
            <input
              type="number"
              value={newAPY}
              onChange={(e) => setNewAPY(e.target.value)}
              placeholder="APY %"
              step="0.1"
              min="0"
              max="20"
              className="flex-1 px-3 py-2 border border-gray-200 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            />
            <button
              onClick={handleSetAPY}
              disabled={isPending || isConfirming || !newAPY}
              className="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center"
            >
              {isPending || isConfirming ? (
                <Loader2 className="h-4 w-4 animate-spin" />
              ) : (
                <TrendingUp className="h-4 w-4" />
              )}
            </button>
          </div>
          <p className="text-xs text-gray-500 mt-1">
            Set new APY for {protocol} to trigger rebalancing
          </p>
        </div>
      </div>

      {/* Manual Rebalance */}
      <div className="space-y-4">
        <button
          onClick={handleManualRebalance}
          disabled={isPending || isConfirming}
          className="w-full bg-green-600 hover:bg-green-700 text-white font-medium py-3 px-4 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center gap-2"
        >
          {isPending || isConfirming ? (
            <Loader2 className="h-4 w-4 animate-spin" />
          ) : (
            <RefreshCw className="h-4 w-4" />
          )}
          Force Rebalance Now
        </button>
        <p className="text-xs text-gray-500 text-center">
          Manually trigger rebalancing check and execution
        </p>
      </div>

      {/* Status Messages */}
      {isConfirming && (
        <div className="mt-4 p-3 bg-blue-50 rounded-lg">
          <p className="text-blue-700 text-sm">Transaction pending...</p>
        </div>
      )}
      
      {isSuccess && (
        <div className="mt-4 p-3 bg-green-50 rounded-lg">
          <p className="text-green-700 text-sm">Transaction successful!</p>
        </div>
      )}
    </div>
  );
}
