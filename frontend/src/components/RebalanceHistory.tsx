'use client';

import { useEffect, useState } from 'react';
import { Clock, TrendingUp, TrendingDown, ArrowRightLeft } from 'lucide-react';

interface RebalanceEvent {
  id: string;
  timestamp: Date;
  fromProtocol: 'Aave' | 'Compound';
  toProtocol: 'Aave' | 'Compound';
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

  // Mock data for demonstration
  useEffect(() => {
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
      {
        id: '2',
        timestamp: new Date('2024-01-12T14:45:00Z'),
        fromProtocol: 'Aave',
        toProtocol: 'Compound',
        amount: '25,000',
        fromAPY: 3.9,
        toAPY: 4.7,
        txHash: '0xabcd...efgh'
      },
      {
        id: '3',
        timestamp: new Date('2024-01-08T09:15:00Z'),
        fromProtocol: 'Compound',
        toProtocol: 'Aave',
        amount: '75,000',
        fromAPY: 3.1,
        toAPY: 4.5,
        txHash: '0x9876...5432'
      }
    ];

    // Simulate loading delay
    setTimeout(() => {
      setRebalanceHistory(mockHistory);
      setLoading(false);
    }, 1000);
  }, [vaultAddress]);

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
      ? 'bg-blue-100 text-blue-800 px-2 py-1 rounded-full text-xs font-medium' 
      : 'bg-green-100 text-green-800 px-2 py-1 rounded-full text-xs font-medium';
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
      <div className="bg-white/60 backdrop-blur-sm rounded-xl p-6 shadow-lg">
        <div className="flex items-center gap-2 mb-4">
          <Clock className="h-5 w-5" />
          <h3 className="text-lg font-semibold">Rebalance History</h3>
        </div>
        <div className="space-y-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="animate-pulse">
              <div className="h-16 bg-gray-200 rounded-lg"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white/60 backdrop-blur-sm rounded-xl p-6 shadow-lg">
      <div className="flex items-center gap-2 mb-4">
        <Clock className="h-5 w-5" />
        <h3 className="text-lg font-semibold">Rebalance History</h3>
      </div>
      
      {rebalanceHistory.length === 0 ? (
        <div className="text-center py-8 text-gray-500">
          <ArrowRightLeft className="h-12 w-12 mx-auto mb-4 opacity-50" />
          <p>No rebalancing events yet</p>
          <p className="text-sm">The vault will automatically rebalance when better yields are available</p>
        </div>
      ) : (
        <div className="space-y-4">
          {rebalanceHistory.map((event) => (
            <div
              key={event.id}
              className="border rounded-lg p-4 hover:bg-gray-50 transition-colors"
            >
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <span className={getProtocolColor(event.fromProtocol)}>
                    {event.fromProtocol}
                  </span>
                  <ArrowRightLeft className="h-4 w-4 text-gray-400" />
                  <span className={getProtocolColor(event.toProtocol)}>
                    {event.toProtocol}
                  </span>
                </div>
                <div className="text-sm text-gray-500">
                  {formatTimestamp(event.timestamp)}
                </div>
              </div>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
                <div>
                  <span className="text-gray-600">Amount:</span>
                  <span className="font-semibold ml-1">${event.amount} DAI</span>
                </div>
                
                <div className="flex items-center gap-2">
                  <span className="text-gray-600">APY Change:</span>
                  <span className="font-semibold">
                    {event.fromAPY}% → {event.toAPY}%
                  </span>
                  {getAPYDifferenceIcon(event.fromAPY, event.toAPY)}
                </div>
                
                <div>
                  <span className="text-gray-600">Tx:</span>
                  <a
                    href={`https://etherscan.io/tx/${event.txHash}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-blue-600 hover:text-blue-800 ml-1"
                  >
                    {event.txHash.slice(0, 6)}...{event.txHash.slice(-4)}
                  </a>
                </div>
              </div>
              
              <div className="mt-2">
                <div className="text-xs text-green-600 font-medium">
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
