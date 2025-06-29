'use client';

import { useState, useEffect } from 'react';
import { useAccount, useWriteContract, useReadContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { YieldVaultABI, MockDAIABI } from '@/config/abis';
import { contractAddresses, anvil } from '@/config/wagmi';
import { ArrowDown, ArrowUp, Coins, Loader2, Banknote } from 'lucide-react';

export default function DepositWithdraw() {
  const [activeTab, setActiveTab] = useState<'deposit' | 'withdraw'>('deposit');
  const [amount, setAmount] = useState('');
  const [approvalStep, setApprovalStep] = useState<'none' | 'approving' | 'approved'>('none');
  const { address, chain } = useAccount();
  
  const currentChainId = chain?.id || anvil.id;
  const vaultAddress = contractAddresses[currentChainId as keyof typeof contractAddresses]?.yieldVault;
  const daiAddress = contractAddresses[currentChainId as keyof typeof contractAddresses]?.mockDAI;

  // Debug logging
  console.log('DepositWithdraw Debug:', {
    address,
    chainId: currentChainId,
    vaultAddress,
    daiAddress,
    isConnected: !!address
  });

  const { writeContract, data: hash, isPending } = useWriteContract();
  
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  // Read DAI balance
  const { data: daiBalance, refetch: refetchDaiBalance } = useReadContract({
    address: daiAddress,
    abi: MockDAIABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  // Read vault balance
  const { data: vaultBalance, refetch: refetchVaultBalance } = useReadContract({
    address: vaultAddress,
    abi: YieldVaultABI,
    functionName: 'getBalance',
    args: address ? [address] : undefined,
  });

  // Read DAI allowance
  const { data: allowance, refetch: refetchAllowance } = useReadContract({
    address: daiAddress,
    abi: MockDAIABI,
    functionName: 'allowance',
    args: address && vaultAddress ? [address, vaultAddress] : undefined,
  });

  useEffect(() => {
    if (isSuccess) {
      refetchDaiBalance();
      refetchVaultBalance();
      refetchAllowance();
      setAmount('');
      setApprovalStep('none');
    }
  }, [isSuccess, refetchDaiBalance, refetchVaultBalance, refetchAllowance]);

  const handleMintDAI = async () => {
    if (!daiAddress || !address) return;

    writeContract({
      address: daiAddress,
      abi: MockDAIABI,
      functionName: 'mint',
      args: [address, parseEther('1000')], // Mint 1000 DAI
    });
  };

  const handleApprove = async () => {
    if (!amount || !daiAddress || !vaultAddress) return;

    setApprovalStep('approving');
    writeContract({
      address: daiAddress,
      abi: MockDAIABI,
      functionName: 'approve',
      args: [vaultAddress, parseEther(amount)],
    });
  };

  const handleDeposit = async () => {
    if (!amount || !vaultAddress) return;

    const amountWei = parseEther(amount);
    const currentAllowance = allowance || BigInt(0);

    if (currentAllowance < amountWei) {
      await handleApprove();
      return;
    }

    writeContract({
      address: vaultAddress,
      abi: YieldVaultABI,
      functionName: 'deposit',
      args: [amountWei],
    });
  };

  const handleWithdraw = async () => {
    if (!amount || !vaultAddress) return;

    const amountWei = parseEther(amount);
    writeContract({
      address: vaultAddress,
      abi: YieldVaultABI,
      functionName: 'withdraw',
      args: [amountWei],
    });
  };

  const formatBalance = (balance: bigint | undefined) => {
    if (!balance) return '0.00';
    return parseFloat(formatEther(balance)).toFixed(2);
  };

  const maxDeposit = daiBalance ? formatEther(daiBalance) : '0';
  const maxWithdraw = vaultBalance ? formatEther(vaultBalance) : '0';

  const needsApproval = () => {
    if (!amount || !allowance) return false;
    return parseEther(amount) > allowance;
  };

  return (
    <div className="bg-white/60 dark:bg-gray-800/80 backdrop-blur-sm rounded-xl p-6 shadow-lg">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-xl font-bold text-gray-900 dark:text-white">Deposit & Withdraw</h2>
        <button
          onClick={handleMintDAI}
          disabled={isPending || isConfirming}
          className="flex items-center px-3 py-1.5 bg-blue-100 hover:bg-blue-200 dark:bg-blue-800 dark:hover:bg-blue-700 text-blue-700 dark:text-blue-300 rounded-lg text-sm font-medium transition-colors disabled:opacity-50"
        >
          {isPending || isConfirming ? (
            <Loader2 className="h-4 w-4 mr-1 animate-spin" />
          ) : (
            <Banknote className="h-4 w-4 mr-1" />
          )}
          Mint 1000 DAI
        </button>
      </div>

      {/* Tab Buttons */}
      <div className="flex bg-gray-100 dark:bg-gray-700 rounded-lg p-1 mb-6">
        <button
          onClick={() => setActiveTab('deposit')}
          className={`flex-1 flex items-center justify-center py-2 px-4 rounded-md font-medium transition-colors ${
            activeTab === 'deposit'
              ? 'bg-white dark:bg-gray-600 text-green-600 dark:text-green-400 shadow-sm'
              : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white'
          }`}
        >
          <ArrowDown className="h-4 w-4 mr-2" />
          Deposit
        </button>
        <button
          onClick={() => setActiveTab('withdraw')}
          className={`flex-1 flex items-center justify-center py-2 px-4 rounded-md font-medium transition-colors ${
            activeTab === 'withdraw'
              ? 'bg-white dark:bg-gray-600 text-red-600 dark:text-red-400 shadow-sm'
              : 'text-gray-600 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white'
          }`}
        >
          <ArrowUp className="h-4 w-4 mr-2" />
          Withdraw
        </button>
      </div>

      {/* Balance Display */}
      <div className="bg-gray-50 dark:bg-gray-700 rounded-lg p-4 mb-6">
        <div className="flex justify-between text-sm mb-2">
          <span className="text-gray-600 dark:text-gray-400">DAI Balance:</span>
          <span className="font-medium text-gray-900 dark:text-white">{formatBalance(daiBalance)} DAI</span>
        </div>
        <div className="flex justify-between text-sm">
          <span className="text-gray-600 dark:text-gray-400">Vault Balance:</span>
          <span className="font-medium text-gray-900 dark:text-white">{formatBalance(vaultBalance)} DAI</span>
        </div>
      </div>

      {/* Amount Input */}
      <div className="mb-4">
        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
          Amount to {activeTab}
        </label>
        <div className="relative">
          <input
            type="number"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
            step="0.01"
            min="0"
            className="w-full px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white placeholder-gray-500 dark:placeholder-gray-400 focus:ring-2 focus:ring-blue-500 dark:focus:ring-blue-400 focus:border-transparent"
          />
          <div className="absolute right-3 top-3 text-gray-500 dark:text-gray-400">DAI</div>
        </div>
        <div className="flex justify-between mt-2 text-sm text-gray-600 dark:text-gray-400">
          <span>Available: {activeTab === 'deposit' ? maxDeposit : maxWithdraw} DAI</span>
          <button
            onClick={() => setAmount(activeTab === 'deposit' ? maxDeposit : maxWithdraw)}
            className="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 font-medium"
          >
            Use Max
          </button>
        </div>
      </div>

      {/* Action Button */}
      <div className="space-y-3">
        {activeTab === 'deposit' && needsApproval() && (
          <button
            onClick={handleApprove}
            disabled={isPending || isConfirming || !amount}
            className="w-full bg-yellow-600 hover:bg-yellow-700 text-white font-medium py-3 px-4 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center"
          >
            {isPending || isConfirming ? (
              <Loader2 className="h-4 w-4 mr-2 animate-spin" />
            ) : null}
            {approvalStep === 'approving' ? 'Approving...' : `Approve ${amount} DAI`}
          </button>
        )}
        
        <button
          onClick={activeTab === 'deposit' ? handleDeposit : handleWithdraw}
          disabled={isPending || isConfirming || !amount || (activeTab === 'deposit' && needsApproval())}
          className={`w-full font-medium py-3 px-4 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center ${
            activeTab === 'deposit'
              ? 'bg-green-600 hover:bg-green-700 text-white'
              : 'bg-red-600 hover:bg-red-700 text-white'
          }`}
        >
          {isPending || isConfirming ? (
            <Loader2 className="h-4 w-4 mr-2 animate-spin" />
          ) : activeTab === 'deposit' ? (
            <ArrowDown className="h-4 w-4 mr-2" />
          ) : (
            <ArrowUp className="h-4 w-4 mr-2" />
          )}
          {isPending || isConfirming
            ? `${activeTab === 'deposit' ? 'Depositing' : 'Withdrawing'}...`
            : `${activeTab === 'deposit' ? 'Deposit' : 'Withdraw'} ${amount || '0'} DAI`
          }
        </button>
      </div>

      {/* Status Messages */}
      {isConfirming && (
        <div className="mt-4 p-3 bg-blue-50 dark:bg-blue-900/50 rounded-lg">
          <p className="text-blue-700 dark:text-blue-300 text-sm">Transaction pending...</p>
        </div>
      )}
      
      {isSuccess && (
        <div className="mt-4 p-3 bg-green-50 dark:bg-green-900/50 rounded-lg">
          <p className="text-green-700 dark:text-green-300 text-sm">Transaction successful!</p>
        </div>
      )}
    </div>
  );
}
