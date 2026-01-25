import { http, createConfig } from 'wagmi'
import { sepolia, mainnet } from 'wagmi/chains'
import { injected } from 'wagmi/connectors'
import { walletConnect } from 'wagmi/connectors' // WalletConnect 已禁用

// 自定义 Anvil 本地链
const anvil = {
  id: 31337,
  name: 'Anvil',
  nativeCurrency: {
    decimals: 18,
    name: 'Ether',
    symbol: 'ETH',
  },
  rpcUrls: {
    default: {
      http: [process.env.NEXT_PUBLIC_RPC_URL_ANVIL || 'http://127.0.0.1:8545'],
    },
    public: {
      http: [process.env.NEXT_PUBLIC_RPC_URL_ANVIL || 'http://127.0.0.1:8545'],
    },
  },
  testnet: true,
}

// Wagmi 配置（WalletConnect 已禁用以避免控制台错误）
export const config = createConfig({
  chains: [sepolia, anvil, mainnet],
  connectors: [
    injected(), // MetaMask, Coinbase Wallet, etc.
    // WalletConnect 已禁用 - 如需启用，请配置有效的 PROJECT_ID 并取消注释：
    walletConnect({
      projectId: process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID,
      showQrModal: true,
      qrModalOptions: {
        themeMode: 'light',
      },
      disableProviderPing: true,
    }),
  ],
  transports: {
    [sepolia.id]: http(process.env.NEXT_PUBLIC_RPC_URL_SEPOLIA),
    [anvil.id]: http(process.env.NEXT_PUBLIC_RPC_URL_ANVIL || 'http://127.0.0.1:8545'),
    [mainnet.id]: http(),
  },
  ssr: true,
})
