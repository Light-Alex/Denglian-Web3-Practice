'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { WagmiProvider } from 'wagmi';
import { config } from '@/lib/wagmi';
import { createAppKit } from '@reown/appkit/react';
import { sepolia } from '@reown/appkit/networks';
import { WagmiAdapter } from '@reown/appkit-adapter-wagmi';

// const queryClient = new QueryClient();
// 创建更稳定的 QueryClient
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 5 * 60 * 1000, // 5分钟
    },
  },
});

// Get projectId from environment
const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'YOUR_PROJECT_ID';

// Create Wagmi adapter
const wagmiAdapter = new WagmiAdapter({
  networks: [sepolia],
  projectId,
  ssr: true,
});

// Create AppKit modal
createAppKit({
  adapters: [wagmiAdapter],
  networks: [sepolia],
  projectId,
  metadata: {
    name: 'NFT Market',
    description: 'NFT Marketplace using ERC20 tokens',
    url: 'https://nftmarket.example.com',
    icons: ['https://nftmarket.example.com/logo.png'],
  },
  features: {
    analytics: true,
  },
});

export function Web3Provider({ children }: { children: React.ReactNode }) {
  return (
    // <WagmiProvider config={config}>
    <WagmiProvider config={wagmiAdapter.wagmiConfig}>
      <QueryClientProvider client={queryClient}>
        {children}
      </QueryClientProvider>
    </WagmiProvider>
  );
}
