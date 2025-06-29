import { NextRequest, NextResponse } from 'next/server';

const RPC_URL = process.env.NEXT_PUBLIC_RPC_URL || 'http://127.0.0.1:9650/ext/bc/xg9tvYxLBvPfLcduRadCDomHJicwsZnxZuxPPvLEUzy259e4X/rpc';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    
    const response = await fetch(RPC_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    });

    if (!response.ok) {
      throw new Error(`RPC request failed: ${response.status}`);
    }

    const data = await response.json();
    
    return NextResponse.json(data, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      },
    });
  } catch (error) {
    console.error('RPC proxy error:', error);
    return NextResponse.json(
      { error: 'RPC request failed' },
      { status: 500 }
    );
  }
}

export async function OPTIONS() {
  return new NextResponse(null, {
    status: 200,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
