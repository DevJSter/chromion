'use client';

import { useEffect, useState } from 'react';
import { useAccount, usePublicClient } from 'wagmi';
import { contractAddresses, anvil } from '@/config/wagmi';
import { Clock, TrendingUp, TrendingDown, ArrowRightLeft } from 'lucide-react';

interface RebalanceEvent {
  id: string;
  timestamp: Date;
  fromProtocol: string;
  toProtocol: string;
  amount: string;
  fromAPY: number;
  toAPY: number;
  txHash: string;
}

interface RebalanceHistoryProps {
  vaultAddress?: `0x${string}`;
}

export default function RebalanceHistory({ vaultAddress }: RebalanceHistoryProps) {
  const [rebalanceHistory, setRebalanceHistory] = useState<RebalanceEvent[]>([]);
  const [loading, setLoading] = useState(true);
  const { chain } = useAccount();
  const publicClient = usePublicClient();
  
  const currentChainId = chain?.id || anvil.id;
  const contractAddress = vaultAddress || contractAddresses[currentChainId as keyof typeof contractAddresses]?.yieldVault;

  // Fetch rebalance events from the blockchain
  useEffect(() => {
    const fetchRebalanceEvents = async () => {
      if (!publicClient || !contractAddress) {
        setLoading(false);
        return;
      }

      try {
        // Get logs for Rebalanced events
        const logs = await publicClient.getLogs({
          address: contractAddress,
          event: {
            type: 'event',
            name: 'Rebalanced',
            inputs: [
              { name: 'oldProtocol', type: 'address', indexed: true },
              { name: 'newProtocol', type: 'address', indexed: true },
              { name: 'amount', type: 'uint256', indexed: false },
              { name: 'oldAPY', type: 'uint256', indexed: false },
              { name: 'newAPY', type: 'uint256', indexed: false },
            ],
          },
          fromBlock: 'earliest',
          toBlock: 'latest',
        });

        const events: RebalanceEvent[] = logs.map((log, index) => ({
          id: `${log.transactionHash}-${index}`,
          timestamp: new Date(),
          fromProtocol: log.args.oldProtocol === contractAddresses[currentChainId as keyof typeof contractAddresses]?.mockAave ? 'Aave' : 'Compound',
          toProtocol: log.args.newProtocol === contractAddresses[currentChainId as keyof typeof contractAddresses]?.mockAave ? 'Aave' : 'Compound',
          amount: (Number(log.args.amount) / 1e18).toFixed(0),
          fromAPY: Number(log.args.oldAPY) / 100,
          toAPY: Number(log.args.newAPY) / 100,
          txHash: log.transactionHash,
        }));

        setRebalanceHistory(events.reverse()); // Most recent first
      } catch (error) {
        console.warn('Unable to fetch rebalance events from chain (likely CORS issue):', error);
        console.log('Falling back to demo data...');
        // Fall back to mock data for demo
        const mockHistory: RebalanceEvent[] = [
          {
            id: '1',
            timestamp: new Date('2024-01-15T10:30:00Z'),
            fromProtocol: 'Compound',
            toProtocol: 'Aave',
            amount: '50,000',
            fromAPY: 4.2,
            toAPY: 5.8,
            txHash: '0x1234...5678'
          },
        ];
        setRebalanceHistory(mockHistory);
      } finally {
        setLoading(false);
      }
    };

    fetchRebalanceEvents();
  }, [publicClient, contractAddress, currentChainId]);

  const formatTimestamp = (timestamp: Date) => {
    return new Intl.DateTimeFormat('en-US', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(timestamp);
  };

  const getProtocolColor = (protocol: string) => {
    return protocol === 'Aave' 
      ? 'bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-300 px-2 py-1 rounded-full text-xs font-medium' 
      : 'bg-green-100 dark:bg-green-900 text-green-800 dark:text-green-300 px-2 py-1 rounded-full text-xs font-medium';
  };

  const getAPYDifferenceIcon = (fromAPY: number, toAPY: number) => {
    const difference = toAPY - fromAPY;
    if (difference > 0) {
      return <TrendingUp className="h-4 w-4 text-green-600" />;
    } else {
      return <TrendingDown className="h-4 w-4 text-red-600" />;
    }
  };

  if (loading) {
    return (
      <div className="bg-white/60 dark:bg-gray-800/80 backdrop-blur-sm rounded-xl p-6 shadow-lg">
        <div className="flex items-center gap-2 mb-4">
          <Clock className="h-5 w-5 text-gray-700 dark:text-gray-300" />
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Rebalance History</h3>
        </div>
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="animate-pulse">
              <div className="h-16 bg-gray-200 dark:bg-gray-700 rounded-lg"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white/60 dark:bg-gray-800/80 backdrop-blur-sm rounded-xl p-6 shadow-lg">
      <div className="flex items-center gap-2 mb-4">
        <Clock className="h-5 w-5 text-gray-700 dark:text-gray-300" />
        <h3 className="text-lg font-semibold text-gray-900 dark:text-white">Rebalance History</h3>
      </div>
      
      {rebalanceHistory.length === 0 ? (
        <div className="text-center py-8 text-gray-500 dark:text-gray-400">
          <ArrowRightLeft className="h-12 w-12 mx-auto mb-4 opacity-50" />
          <p>No rebalancing events yet</p>
          <p className="text-sm">The vault will automatically rebalance when better yields are available</p>
        </div>
      ) : (
        <div className="space-y-4">
          {rebalanceHistory.map((event) => (
            <div
              key={event.id}
              className="border border-gray-200 dark:border-gray-600 rounded-lg p-4 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
            >
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className={getProtocolColor(event.fromProtocol)}>
                    {event.fromProtocol}
                  </span>
                  <ArrowRightLeft className="h-4 w-4 text-gray-400 dark:text-gray-500" />
                  <span className={getProtocolColor(event.toProtocol)}>
                    {event.toProtocol}
                  </span>
                </div>
                <div className="text-sm text-gray-500 dark:text-gray-400">
                  {formatTimestamp(event.timestamp)}
                </div>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                <div>
                  <span className="text-gray-600 dark:text-gray-400">Amount:</span>
                  <span className="font-semibold ml-1 text-gray-900 dark:text-white">${event.amount} DAI</span>
                </div>
                
                <div className="flex items-center gap-2">
                  <span className="text-gray-600 dark:text-gray-400">APY Change:</span>
                  <span className="font-semibold text-gray-900 dark:text-white">
                    {event.fromAPY}% → {event.toAPY}%
                  </span>
                  {getAPYDifferenceIcon(event.fromAPY, event.toAPY)}
                </div>
                
                <div>
                  <span className="text-gray-600 dark:text-gray-400">Tx:</span>
                  <a
                    href={`https://etherscan.io/tx/${event.txHash}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-600 dark:text-blue-400 hover:text-blue-800 dark:hover:text-blue-300 ml-1"
                  >
                    {event.txHash.slice(0, 6)}...{event.txHash.slice(-4)}
                  </a>
                </div>
              </div>
              
              <div className="mt-2">
                <div className="text-xs text-green-600 dark:text-green-400 font-medium">
                  Yield Improvement: +{(event.toAPY - event.fromAPY).toFixed(2)}%
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
