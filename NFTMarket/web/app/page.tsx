'use client';

import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, usePublicClient, useChainId } from 'wagmi';
import { useState, useEffect } from 'react';
import { parseEther, formatEther } from 'viem';
import NFTMarketABI from '@/contracts/NFTMarket.json';
import SimpleNFTABI from '@/contracts/SimpleNFT.json';
import { getContractAddress } from '@/lib/contracts';

interface Listing {
  listingId: number;
  seller: string;
  nftContract: string;
  tokenId: bigint;
  price: bigint;
  active: boolean;
}

interface NFTMetadata {
  image?: string;
  title?: string;
  description?: string;
}

export default function NFTMarketPage() {
  // 从环境变量获取合约地址
  const chainId = useChainId();
  const CONTRACT_ADDRESS = getContractAddress(chainId, 'NFTMarket') as `0x${string}`;

  const { address, isConnected } = useAccount();
  const publicClient = usePublicClient();
  const [nftContractAddress, setNftContractAddress] = useState('');
  const [tokenId, setTokenId] = useState('');
  const [price, setPrice] = useState('');
  const [errorMessage, setErrorMessage] = useState('');
  const [successMessage, setSuccessMessage] = useState('');

  // 获取所有上架列表
  const [listings, setListings] = useState<Listing[]>([]);
  const [myListings, setMyListings] = useState<Listing[]>([]);
  const [nftMetadata, setNftMetadata] = useState<{ [key: string]: NFTMetadata }>({});

  // // 在组件顶部添加状态管理
  // const [buyingStates, setBuyingStates] = useState<Record<number, boolean>>({});

  // 获取总上架数量
  const { data: listingCounter, refetch: refetchListingCounter } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: NFTMarketABI,
    functionName: 'listingCounter',
  });

  // 列出NFT交易
  const { writeContract: list, data: listHash } = useWriteContract();
  const { isLoading: isListing, isSuccess: listSuccess } = useWaitForTransactionReceipt({
    hash: listHash,
  });

  // 购买NFT交易
  const { writeContract: buyNFT, data: buyHash } = useWriteContract();
  const { isLoading: isBuying, isSuccess: buySuccess } = useWaitForTransactionReceipt({
    hash: buyHash,
  });

  // 取消上架交易
  const { writeContract: cancelListing, data: cancelHash } = useWriteContract();
  const { isLoading: isCanceling, isSuccess: cancelSuccess } = useWaitForTransactionReceipt({
    hash: cancelHash,
  });

  // 清除消息
  useEffect(() => {
    if (errorMessage || successMessage) {
      const timer = setTimeout(() => {
        setErrorMessage('');
        setSuccessMessage('');
      }, 5000);
      return () => clearTimeout(timer);
    }
  }, [errorMessage, successMessage]);

  // 获取NFT元数据
  const fetchNFTMetadata = async (nftContract: string, tokenId: bigint) => {
    const key = `${nftContract}-${tokenId}`;

    // 如果已经获取过元数据，直接返回
    if (nftMetadata[key]) {
      return nftMetadata[key];
    }

    try {
      // 获取tokenURI
      const tokenURI = await publicClient?.readContract({
        address: nftContract as `0x${string}`,
        abi: SimpleNFTABI,
        functionName: 'tokenURI',
        args: [tokenId],
      });

      if (!tokenURI) {
        return null;
      }

      // 处理IPFS地址
      let metadataUrl = tokenURI as string;
      if (metadataUrl.startsWith('ipfs://')) {
        metadataUrl = `https://ipfs.io/ipfs/${metadataUrl.replace('ipfs://', '')}`;
      }

      // 获取元数据
      const response = await fetch(metadataUrl);
      if (!response.ok) {
        throw new Error('Failed to fetch NFT metadata');
      }

      const metadata: NFTMetadata = await response.json();

      // 处理元数据中的IPFS图片地址
      if (metadata.image && metadata.image.startsWith('ipfs://')) {
        metadata.image = `https://ipfs.io/ipfs/${metadata.image.replace('ipfs://', '')}`;
      }

      // 更新状态
      setNftMetadata(prev => ({
        ...prev,
        [key]: metadata
      }));

      return metadata;
    } catch (error) {
      console.error(`Error fetching metadata for ${nftContract} token ${tokenId}:`, error);
      return null;
    }
  };

  // 加载所有上架列表
  useEffect(() => {
    const loadListings = async () => {
      refetchListingCounter();
      if (!listingCounter || !publicClient) return;

      const totalListings = Number(listingCounter);
      const activeListings: Listing[] = [];
      const myActiveListings: Listing[] = [];

      for (let i = 0; i <= totalListings; i++) {
        try {
          const listingData = await publicClient.readContract({
            address: CONTRACT_ADDRESS,
            abi: NFTMarketABI,
            functionName: 'getListing',
            args: [BigInt(i)],
          });

          // 将返回的数据转换为Listing接口
          const listing = listingData as unknown as Listing;

          if (listing.active) {
            activeListings.push(listing);
            if (listing.seller.toLowerCase() === address?.toLowerCase()) {
              myActiveListings.push(listing);
            }

            // 异步获取NFT元数据
            fetchNFTMetadata(listing.nftContract, listing.tokenId);
          }
        } catch (error) {
          console.error(`Error loading listing ${i}:`, error);
        }
      }

      setListings(activeListings);
      setMyListings(myActiveListings);
    };

    loadListings();
  }, [listingCounter, address, listSuccess, buySuccess, cancelSuccess, publicClient]);

  // 处理列出NFT
  const handleListNFT = async () => {
    if (!nftContractAddress || !tokenId || !price) {
      setErrorMessage('Please fill in all fields');
      return;
    }

    if (!nftContractAddress.startsWith('0x') || nftContractAddress.length !== 42) {
      setErrorMessage('Invalid NFT contract address');
      return;
    }

    try {
      list({
        address: CONTRACT_ADDRESS,
        abi: NFTMarketABI,
        functionName: 'list',
        args: [
          nftContractAddress as `0x${string}`,
          BigInt(tokenId),
          parseEther(price)
        ],
      });
      setSuccessMessage('Listing NFT...');
    } catch (error) {
      setErrorMessage('Failed to list NFT');
      console.error(error);
    }
  };

  // 处理购买NFT
  const handleBuyNFT = async (listingId: bigint) => {
    try {
      buyNFT({
        address: CONTRACT_ADDRESS,
        abi: NFTMarketABI,
        functionName: 'buyNFT',
        args: [listingId],
      });
      setSuccessMessage('Buying NFT...');
    } catch (error) {
      setErrorMessage('Failed to buy NFT');
      console.error(error);
    }
  };

  // 处理取消上架
  const handleCancelListing = async (listingId: bigint) => {
    try {
      cancelListing({
        address: CONTRACT_ADDRESS,
        abi: NFTMarketABI,
        functionName: 'cancelListing',
        args: [listingId],
      });
      setSuccessMessage('Canceling listing...');
    } catch (error) {
      setErrorMessage('Failed to cancel listing');
      console.error(error);
    }
  };

  // 获取NFT图片URL
  const getNFTImage = (listing: Listing) => {
    const key = `${listing.nftContract}-${listing.tokenId}`;
    const metadata = nftMetadata[key];

    if (metadata?.image) {
      return metadata.image;
    }

    return null;
  };

  // 获取NFT名称
  const getNFTTitle = (listing: Listing) => {
    const key = `${listing.nftContract}-${listing.tokenId}`;
    const metadata = nftMetadata[key];

    if (metadata?.title) {
      return metadata.title;
    }

    return `NFT #${Number(listing.tokenId)}`;
  };

  // 获取NFT描述
  const getNFTDescription = (listing: Listing) => {
    const key = `${listing.nftContract}-${listing.tokenId}`;
    const metadata = nftMetadata[key];

    if (metadata?.description) {
      return metadata.description;
    }

    return `An NFT #${Number(listing.tokenId)}`;
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">NFT Market</h1>
          <p className="text-gray-600">Trade NFTs using ERC20 tokens</p>
        </div>

        {/* 错误和成功消息 */}
        {errorMessage && (
          <div className="mb-4 p-4 bg-red-100 border border-red-400 text-red-700 rounded">
            {errorMessage}
          </div>
        )}
        {successMessage && (
          <div className="mb-4 p-4 bg-green-100 border border-green-400 text-green-700 rounded">
            {successMessage}
          </div>
        )}

        {!isConnected ? (
          <div className="bg-white rounded-lg shadow p-8 text-center">
            <p className="text-gray-700 mb-4">Please connect your wallet</p>
            <p className="text-sm text-gray-500">Click the &quot;Connect Wallet&quot; button in the top right corner</p>
          </div>
        ) : (
          <div className="space-y-8">
            {/* List NFT Section */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">List NFT</h2>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    NFT Contract Address
                  </label>
                  <input
                    type="text"
                    value={nftContractAddress}
                    onChange={(e) => setNftContractAddress(e.target.value)}
                    placeholder="0x..."
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Token ID
                  </label>
                  <input
                    type="number"
                    value={tokenId}
                    onChange={(e) => setTokenId(e.target.value)}
                    placeholder="0"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Price (Tokens)
                  </label>
                  <input
                    type="number"
                    value={price}
                    onChange={(e) => setPrice(e.target.value)}
                    step="0.01"
                    placeholder="100"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <button
                  onClick={handleListNFT}
                  disabled={isListing}
                  className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 text-white font-medium py-3 px-4 rounded-lg transition-colors"
                >
                  {isListing ? 'Listing...' : 'List NFT'}
                </button>
              </div>
            </div>

            {/* Market Listings */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">Available NFTs ({listings.length})</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {listings.length > 0 ? (
                  listings.map((listing, index) => {
                    const imageUrl = getNFTImage(listing);
                    const nftName = getNFTTitle(listing);
                    const nftDescription = getNFTDescription(listing);
                    const sellerAddress = listing.seller;
                    const formattedSellerAddress = sellerAddress ? `${sellerAddress.slice(0, 6)}...${sellerAddress.slice(-4)}` : 'Unknown';

                    return (
                      <div key={index} className="border border-gray-200 rounded-lg overflow-hidden hover:shadow-lg transition-shadow">
                        <div className="aspect-square bg-gray-100 flex items-center justify-center">
                          {imageUrl ? (
                            <img
                              src={imageUrl}
                              alt={nftName}
                              className="w-full h-full object-cover"
                              onError={(e) => {
                                // 图片加载失败时显示占位符
                                e.currentTarget.style.display = 'none';
                                e.currentTarget.nextElementSibling?.classList.remove('hidden');
                              }}
                            />
                          ) : (
                            <span className="text-gray-400">Loading...</span>
                          )}
                          {!imageUrl && (
                            <span className="text-gray-400">NFT #{Number(listing.tokenId)}</span>
                          )}
                        </div>
                        <div className="p-4">
                          <h3 className="text-lg font-semibold text-gray-900 mb-2">
                            {nftName}
                          </h3>
                          <p className="text-gray-600 text-sm mb-1">
                            Description: {nftDescription}
                          </p>
                          <p className="text-gray-600 text-sm mb-1">
                            Contract: {listing.nftContract.slice(0, 6)}...{listing.nftContract.slice(-4)}
                          </p>
                          <p className="text-gray-600 text-sm mb-1">
                            Seller: {formattedSellerAddress}
                          </p>
                          <p className="text-gray-600 text-sm mb-4">
                            Price: {formatEther(listing.price)} MTK
                          </p>
                          <button
                            onClick={() => handleBuyNFT(BigInt(listing.listingId))}
                            disabled={isBuying}
                            className="w-full bg-green-600 hover:bg-green-700 disabled:bg-green-300 text-white font-medium py-2 px-4 rounded-lg transition-colors"
                          >
                            {isBuying ? 'Buying...' : 'Buy NFT'}
                          </button>
                        </div>
                      </div>
                    );
                  })
                ) : (
                  <div className="col-span-full text-center py-12">
                    <p className="text-gray-500">No NFTs listed yet</p>
                  </div>
                )}
              </div>
            </div>

            {/* My Listings */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">My Listings ({myListings.length})</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {myListings.length > 0 ? (
                  myListings.map((listing, index) => {
                    const imageUrl = getNFTImage(listing);
                    const nftName = getNFTTitle(listing);
                    const nftDescription = getNFTDescription(listing);
                    const sellerAddress = listing.seller;
                    const formattedSellerAddress = sellerAddress ? `${sellerAddress.slice(0, 6)}...${sellerAddress.slice(-4)}` : 'Unknown';

                    return (
                      <div key={index} className="border border-gray-200 rounded-lg overflow-hidden">
                        <div className="aspect-square bg-gray-100 flex items-center justify-center">
                          {imageUrl ? (
                            <img
                              src={imageUrl}
                              alt={nftName}
                              className="w-full h-full object-cover"
                              onError={(e) => {
                                // 图片加载失败时显示占位符
                                e.currentTarget.style.display = 'none';
                                e.currentTarget.nextElementSibling?.classList.remove('hidden');
                              }}
                            />
                          ) : (
                            <span className="text-gray-400">Loading...</span>
                          )}
                          {!imageUrl && (
                            <span className="text-gray-400">NFT #{Number(listing.tokenId)}</span>
                          )}
                        </div>
                        <div className="p-4">
                          <h3 className="text-lg font-semibold text-gray-900 mb-2">
                            {nftName}
                          </h3>
                          <p className="text-gray-600 text-sm mb-1">
                            Description: {nftDescription}
                          </p>
                          <p className="text-gray-600 text-sm mb-1">
                            Contract: {listing.nftContract.slice(0, 6)}...{listing.nftContract.slice(-4)}
                          </p>
                          <p className="text-gray-600 text-sm mb-1">
                            Seller: {formattedSellerAddress}
                          </p>
                          <p className="text-gray-600 text-sm mb-4">
                            Price: {formatEther(listing.price)} MTK
                          </p>
                          <button
                            onClick={() => handleCancelListing(BigInt(listing.listingId))}
                            disabled={isCanceling}
                            className="w-full bg-red-600 hover:bg-red-700 disabled:bg-red-300 text-white font-medium py-2 px-4 rounded-lg transition-colors"
                          >
                            {isCanceling ? 'Canceling...' : 'Cancel Listing'}
                          </button>
                        </div>
                      </div>
                    );
                  })
                ) : (
                  <div className="col-span-full text-center py-12">
                    <p className="text-gray-500">You have no active listings</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        {/* Features Info */}
        <div className="mt-8 bg-blue-50 rounded-lg p-6 border border-blue-100">
          <h3 className="text-xl font-bold text-gray-900 mb-4">How It Works</h3>
          <ul className="space-y-2 text-gray-700">
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>List NFT:</strong> Set a price in ERC20 tokens and list your NFT for sale</span>
            </li>
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>Buy NFT:</strong> Purchase NFTs by transferring ERC20 tokens</span>
            </li>
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>Callback Purchase:</strong> Use transferWithCallback for automatic NFT purchase</span>
            </li>
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>Cancel Listing:</strong> Remove your NFT from the market anytime</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
}
