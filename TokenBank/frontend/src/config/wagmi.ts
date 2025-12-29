import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { mainnet, sepolia, localhost } from 'wagmi/chains';
import { defineChain } from 'viem';

// 自定义 anvil 链配置
const anvil = defineChain({
  id: 31_337, // anvil 默认链 ID 31337
  name: 'Anvil Local',
  network: 'anvil',
  nativeCurrency: {
    decimals: 18,
    name: 'Ether',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: {
      http: ['http://localhost:8545'],
    },
    public: {
      http: ['http://localhost:8545'],
    },
  },
});


export const config = getDefaultConfig({
  appName: 'TokenBank DApp',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || 'YOUR_PROJECT_ID',
  chains: [mainnet, sepolia, localhost, anvil],
  ssr: true,
});
