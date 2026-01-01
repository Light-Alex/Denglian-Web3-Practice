# Deployment Summary

## Deployed Contracts (Sepolia Testnet)

### BaseERC20 (Market Token - MTK)
- **Address**: `0xFbFfF97E9E9b087c5D4DE46cA83d0103c74B17a5`
- **Etherscan**: https://sepolia.etherscan.io/address/0xFbFfF97E9E9b087c5D4DE46cA83d0103c74B17a5
- **Features**:
  - ERC20 token with extended functionality
  - `transferWithCallback()` - triggers callback on contract recipients
  - Initial supply: 1,000,000 MTK (18 decimals)

### SimpleNFT
- **Address**: `0xEd92c232914fE479e59B53b3d6bCF10f964dFa76`
- **Etherscan**: https://sepolia.etherscan.io/address/0xEd92c232914fE479e59B53b3d6bCF10f964dFa76
- **Features**:
  - Standard ERC721 NFT contract
  - Minting function for testing

### NFTMarket
- **Address**: `0xd626015EC416C466a31b5c206C6b39D9589adEd7`
- **Etherscan**: https://sepolia.etherscan.io/address/0xd626015EC416C466a31b5c206C6b39D9589adEd7
- **Features**:
  - NFT marketplace using ERC20 tokens
  - `list()` - list NFT for sale
  - `buyNFT()` - purchase with tokens
  - `tokensReceived()` - callback purchase method
  - `cancelListing()` - cancel listing

## Frontend Integration

### ABI Files Exported
- ✅ `web/contracts/BaseERC20.json`
- ✅ `web/contracts/NFTMarket.json`
- ✅ `web/contracts/SimpleNFT.json`

### Contract Addresses Configured
File: `web/lib/contracts.ts`

```typescript
export const CONTRACT_ADDRESSES = {
  sepolia: {
    BaseERC20: '0xFbFfF97E9E9b087c5D4DE46cA83d0103c74B17a5',
    NFTMarket: '0xd626015EC416C466a31b5c206C6b39D9589adEd7',
    SimpleNFT: '0xEd92c232914fE479e59B53b3d6bCF10f964dFa76',
  },
};
```

## Pages Status

### Active Pages
- ✅ **NFT Market** (`/`) - Fully functional marketplace interface
  - List NFT section
  - Browse available NFTs
  - View my listings
  - How it works guide

### Placeholder Pages (Under Development)
- ⏳ **NFT Market V2** (`/v2`) - Placeholder created
- ⏳ **Transaction History** (`/transactions`) - Placeholder created

## Next Steps for Students

### 1. Verify Contracts on Etherscan (Optional)
Visit each Etherscan link and manually verify if needed.

### 2. Test the Application
```bash
cd web
npm install
npm run dev
```

### 3. Mint Test NFTs
Use cast to mint NFTs:
```bash
cast send 0xEd92c232914fE479e59B53b3d6bCF10f964dFa76 \
  "mint(address,string)" \
  YOUR_ADDRESS \
  "https://example.com/nft/1.json" \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

### 4. Approve and List NFT
1. Connect wallet to the dApp
2. Approve NFTMarket contract to manage your NFT
3. List your NFT with a price in MTK tokens

### 5. Get MTK Tokens
The deployer has 1,000,000 MTK. You can:
- Transfer some MTK to test accounts
- Or add a faucet function to the contract

## Contract Interaction Examples

### Using Regular Purchase
```typescript
// 1. Approve tokens
await writeContract({
  address: baseERC20Address,
  abi: BaseERC20ABI,
  functionName: 'approve',
  args: [nftMarketAddress, price],
});

// 2. Buy NFT
await writeContract({
  address: nftMarketAddress,
  abi: NFTMarketABI,
  functionName: 'buyNFT',
  args: [listingId],
});
```

### Using Callback Purchase (One Transaction)
```typescript
// Encode listing ID
const data = ethers.AbiCoder.defaultAbiCoder().encode(['uint256'], [listingId]);

// Transfer with callback - automatically buys NFT
await writeContract({
  address: baseERC20Address,
  abi: BaseERC20ABI,
  functionName: 'transferWithCallback',
  args: [nftMarketAddress, price, data],
});
```

## Known Issues

- Contract verification on Etherscan encountered API errors
  - Contracts are deployed and functional
  - Can be manually verified if needed
  
## Support

For issues or questions:
1. Check Etherscan transaction logs
2. Review contract source code in `contracts/src/`
3. Check browser console for errors
