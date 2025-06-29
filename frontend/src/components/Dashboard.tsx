'use client';

import { useState } from 'react';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { useAccount } from 'wagmi';
import VaultStats from './VaultStats';
import DepositWithdraw from './DepositWithdraw';
import ProtocolComparison from './ProtocolComparison';
import RebalanceHistory from './RebalanceHistory';
import ManualControls from './ManualControls';
import { ThemeToggle } from './ThemeToggle';
import { Zap, TrendingUp, Shield, Activity } from 'lucide-react';

export default function Dashboard() {
  const { isConnected } = useAccount();

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-gray-800">
      {/* Header */}
      <header className="bg-white/80 dark:bg-gray-900/80 backdrop-blur-md border-b border-white/20 dark:border-gray-700/20 sticky top-0 z-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <Zap className="h-8 w-8 text-blue-600 mr-3" />
              <h1 className="text-xl font-bold text-gray-900 dark:text-white">
                Chainlink Auto-Yield Vault
              </h1>
            </div>
            <div className="flex items-center gap-4">
              <ThemeToggle />
              <ConnectButton />
            </div>
          </div>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {!isConnected ? (
          <div className="text-center py-12">
            <div className="bg-white/60 dark:bg-gray-800/80 backdrop-blur-sm rounded-2xl p-8 shadow-lg max-w-md mx-auto">
              <div className="w-16 h-16 bg-blue-100 dark:bg-blue-900 rounded-full flex items-center justify-center mx-auto mb-4">
                <Shield className="h-8 w-8 text-blue-600 dark:text-blue-400" />
              </div>
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                Connect Your Wallet
              </h2>
              <p className="text-gray-600 dark:text-gray-300 mb-6">
                Connect your wallet to start earning optimized yields with our
                Chainlink-powered auto-rebalancing vault.
              </p>
              <div className="flex justify-center">
                <ConnectButton />
              </div>
            </div>
          </div>
        ) : (
          <div className="space-y-8">
            {/* Feature Cards */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
              <div className="bg-white/60 dark:bg-gray-800/80 backdrop-blur-sm rounded-xl p-6 shadow-lg">
                <div className="flex items-center">
                  <TrendingUp className="h-10 w-10 text-green-600 mr-4" />
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                      Auto-Optimization
                    </h3>
                    <p className="text-gray-600 dark:text-gray-300 text-sm">
                      Automatically rebalances to highest yield
                    </p>
                  </div>
                </div>
              </div>
              
              <div className="bg-white/60 dark:bg-gray-800/80 backdrop-blur-sm rounded-xl p-6 shadow-lg">
                <div className="flex items-center">
                  <Activity className="h-10 w-10 text-blue-600 mr-4" />
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                      Chainlink Powered
                    </h3>
                    <p className="text-gray-600 dark:text-gray-300 text-sm">
                      Reliable automation & data feeds
                    </p>
                  </div>
                </div>
              </div>
              
              <div className="bg-white/60 dark:bg-gray-800/80 backdrop-blur-sm rounded-xl p-6 shadow-lg">
                <div className="flex items-center">
                  <Shield className="h-10 w-10 text-purple-600 mr-4" />
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                      Non-Custodial
                    </h3>
                    <p className="text-gray-600 dark:text-gray-300 text-sm">
                      You always control your funds
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Main Dashboard Grid */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
              {/* Left Column - Stats and Deposit/Withdraw */}
              <div className="lg:col-span-2 space-y-6">
                <VaultStats />
                <DepositWithdraw />
              </div>
              
              {/* Right Column - Protocol Comparison and Controls */}
              <div className="space-y-6">
                <ProtocolComparison />
                <ManualControls />
                <RebalanceHistory />
              </div>
            </div>
          </div>
        )}
      </main>
    </div>
  );
}
