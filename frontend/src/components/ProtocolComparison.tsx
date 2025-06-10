'use client';

import { useReadContract } from 'wagmi';
import { YieldVaultABI } from '@/config/abis';
import { contractAddresses } from '@/config/wagmi';
import { sepolia } from 'wagmi/chains';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Cell } from 'recharts';
import { TrendingUp, Activity } from 'lucide-react';
import { useAccount } from 'wagmi';

export default function ProtocolComparison() {
  const { chain } = useAccount();
  const currentChainId = chain?.id || sepolia.id;
  const vaultAddress = contractAddresses[currentChainId]?.yieldVault;

  // Read protocol APYs
  const { data: protocolAPYs } = useReadContract({
    address: vaultAddress,
    abi: YieldVaultABI,
    functionName: 'getProtocolAPYs',
  });

  // Read current protocol info
  const { data: protocolInfo } = useReadContract({
    address: vaultAddress,
    abi: YieldVaultABI,
    functionName: 'getCurrentProtocolInfo',
  });

  const formatAPY = (apy: bigint | undefined) => {
    if (!apy) return 0;
    return Number(apy) / 100;
  };

  const aaveAPY = formatAPY(protocolAPYs?.[0]);
  const compoundAPY = formatAPY(protocolAPYs?.[1]);
  const currentProtocolName = protocolInfo?.[0] || '';

  const chartData = [
    {
      name: 'Aave',
      apy: aaveAPY,
      isActive: currentProtocolName.includes('Aave')
    },
    {
      name: 'Compound',
      apy: compoundAPY,
      isActive: currentProtocolName.includes('Compound')
    },
  ];

  const getBarColor = (isActive: boolean) => {
    return isActive ? '#3B82F6' : '#94A3B8';
  };

  return (
    <div className="bg-white/60 backdrop-blur-sm rounded-xl p-6 shadow-lg">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-xl font-bold text-gray-900">Protocol Comparison</h2>
        <TrendingUp className="h-6 w-6 text-blue-600" />
      </div>

      {/* Chart */}
      <div className="h-64 mb-6">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart data={chartData} margin={{ top: 20, right: 30, left: 20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#E5E7EB" />
            <XAxis 
              dataKey="name" 
              tick={{ fontSize: 12 }}
              stroke="#6B7280"
            />
            <YAxis 
              tick={{ fontSize: 12 }}
              stroke="#6B7280"
              label={{ value: 'APY (%)', angle: -90, position: 'insideLeft' }}
            />
            <Tooltip 
              formatter={(value: number) => [`${value.toFixed(2)}%`, 'APY']}
              labelStyle={{ color: '#374151' }}
              contentStyle={{ 
                backgroundColor: 'rgba(255, 255, 255, 0.95)',
                border: '1px solid #E5E7EB',
                borderRadius: '8px'
              }}
            />
            <Bar dataKey="apy" radius={[4, 4, 0, 0]}>
              {chartData.map((entry, index) => (
                <Cell key={`cell-${index}`} fill={getBarColor(entry.isActive)} />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Protocol Details */}
      <div className="space-y-3">
        {chartData.map((protocol) => (
          <div
            key={protocol.name}
            className={`flex items-center justify-between p-3 rounded-lg border-2 transition-colors ${
              protocol.isActive
                ? 'border-blue-200 bg-blue-50'
                : 'border-gray-200 bg-gray-50'
            }`}
          >
            <div className="flex items-center">
              <div className={`w-3 h-3 rounded-full mr-3 ${
                protocol.isActive ? 'bg-blue-600' : 'bg-gray-400'
              }`} />
              <span className="font-medium text-gray-900">{protocol.name}</span>
              {protocol.isActive && (
                <div className="ml-2 flex items-center text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded-full">
                  <Activity className="h-3 w-3 mr-1" />
                  Active
                </div>
              )}
            </div>
            <div className="text-right">
              <span className="text-lg font-bold text-gray-900">
                {protocol.apy.toFixed(2)}%
              </span>
              <p className="text-xs text-gray-600">APY</p>
            </div>
          </div>
        ))}
      </div>

      {/* Rebalance Info */}
      <div className="mt-6 p-4 bg-gradient-to-r from-blue-50 to-indigo-50 rounded-lg border border-blue-200">
        <div className="flex items-start">
          <Activity className="h-5 w-5 text-blue-600 mr-3 mt-0.5" />
          <div>
            <h4 className="font-medium text-blue-900 mb-1">
              Automatic Rebalancing
            </h4>
            <p className="text-sm text-blue-700">
              The vault automatically moves funds to the protocol with the highest APY 
              when the difference exceeds 1%. Powered by Chainlink Automation.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}
