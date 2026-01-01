'use client';

import { http, createConfig } from 'wagmi';
import { sepolia } from 'wagmi/chains';
import { walletConnect, injected, coinbaseWallet, metaMask } from 'wagmi/connectors';

/**
 * Wagmi Configuration for AppKit
 *
 * Student Guide for Replacement:
 * 1. Get your WalletConnect projectId from https://cloud.walletconnect.com/
 * 2. Add it to .env.local file as NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID
 * 3. To support other chains, add them to the chains array
 */

const projectId = process.env.NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID || 'YOUR_PROJECT_ID';

export const config = createConfig({
  chains: [sepolia],
  connectors: [
    walletConnect({ projectId, showQrModal: false }),
    // metaMask(),
    injected({ shimDisconnect: true}),
    coinbaseWallet({
      appName: 'NFT Market',
      appLogoUrl: 'https://nftmarket.example.com/logo.png',
    }),
  ],
  transports: {
    [sepolia.id]: http(),
  },
  ssr: true,
});
