/**
 * Contract Address Configuration
 *
 * Student Replacement Guide:
 * 1. After deploying contracts, fill in the addresses in the corresponding fields
 * 2. Ensure addresses are in correct format (42-character hex string starting with 0x)
 * 3. You can configure different addresses for different networks
 */

export const CONTRACT_ADDRESSES = {
  // Sepolia Testnet Addresses
  sepolia: {
    BaseERC20: process.env.NEXT_PUBLIC_BASE_ERC20_ADDRESS || '0xFbFfF97E9E9b087c5D4DE46cA83d0103c74B17a5',
    NFTMarket: process.env.NEXT_PUBLIC_NFT_MARKET_ADDRESS || '0xd626015EC416C466a31b5c206C6b39D9589adEd7',
    SimpleNFT: process.env.NEXT_PUBLIC_SIMPLE_NFT_ADDRESS || '0xEd92c232914fE479e59B53b3d6bCF10f964dFa76',
  },

  // You can add other networks here
  // mainnet: {
  //   BaseERC20: '',
  //   NFTMarket: '',
  //   SimpleNFT: '',
  // },
} as const;

/**
 * Get contract address for current network
 * @param chainId Chain ID
 * @param contractName Contract name
 * @returns Contract address
 */
export function getContractAddress(
  chainId: number,
  contractName: 'BaseERC20' | 'NFTMarket' | 'SimpleNFT'
): string {
  // Sepolia chainId = 11155111
  if (chainId === 11155111) {
    return CONTRACT_ADDRESSES.sepolia[contractName];
  }

  throw new Error(`Unsupported chain ID: ${chainId}`);
}

/**
 * Validate if address is valid
 */
export function isValidAddress(address: string): boolean {
  return /^0x[a-fA-F0-9]{40}$/.test(address);
}
