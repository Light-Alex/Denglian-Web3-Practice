'use client';

import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, usePublicClient, useChainId, useSignTypedData } from 'wagmi';
import { useState, useEffect } from 'react';
import { parseEther, formatEther } from 'viem';
import NFTMarketPermitABI from '@/contracts/NFTMarketPermit.json';
import MyNFTPermitABI from '@/contracts/MyNFTPermit.json';
import MyTokenPermitABI from '@/contracts/MyTokenPermit.json';
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
  const NFT_CONTRACT_ADDRESS = getContractAddress(chainId, 'MyNFTPermit') as `0x${string}`;
  const TOKEN_CONTRACT_ADDRESS = getContractAddress(chainId, 'MyTokenPermit') as `0x${string}`;

  const { address, isConnected, chain } = useAccount();
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

  // 添加一个状态来控制是否允许自动执行list
  const [allowAutoList, setAllowAutoList] = useState(false);

  // 添加一个状态来控制是否允许自动执行permitBuy
  const [allowAutoPermitBuy, setAllowAutoPermitBuy] = useState(false);

  // // 在组件顶部添加状态管理
  // const [buyingStates, setBuyingStates] = useState<Record<number, boolean>>({});

  // Sign typed data for erc20 permit
  const { signTypedData: tokenSignTypedData, data: tokenSignature, isPending: isTokenSigning } = useSignTypedData();
  const [erc20PermitSignature, setERC20PermitSignature] = useState<{
    listingId: bigint;
    deadline: number;
    amount: bigint;
    signature: `0x${string}`;
  } | null>(null);

  // 白名单相关状态
  const [whitelistBuyerAddress, setWhitelistBuyerAddress] = useState('');
  const [whitelistListingId, setWhitelistListingId] = useState('');
  const [whitelistSignature, setWhitelistSignature] = useState<`0x${string}` | null>(null);
  const [isGeneratingWhitelist, setIsGeneratingWhitelist] = useState(false);
  const { signTypedData: whitelistSignTypedData, data: whitelistSig, isPending: isWhitelistSigning } = useSignTypedData();

  // NFT Permit签名相关状态
  const [nftPermitSignature, setNftPermitSignature] = useState<`0x${string}` | null>(null);
  const [nftPermitDeadline, setNftPermitDeadline] = useState(0);
  const [isGeneratingNftPermit, setIsGeneratingNftPermit] = useState(false);
  const { signTypedData: nftSignTypedData, data: nftSignature, isPending: isNftSigning } = useSignTypedData();

  // 买家手动输入的卖家NFT Permit签名和deadline
  const [sellerNftPermitSignature, setSellerNftPermitSignature] = useState<string>('');
  const [sellerNftPermitDeadline, setSellerNftPermitDeadline] = useState<string>('');
  const [deployerWhitelistSignature, setDeployerWhitelistSignature] = useState<string>('');

  // 获取总上架数量
  const { data: listingCounter, refetch: refetchListingCounter } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: NFTMarketPermitABI,
    functionName: 'listingCounter',
  });

  // Read nonce for token permit
  const { data: tokenNonce, refetch: refetchTokenNonce } = useReadContract({
    address: TOKEN_CONTRACT_ADDRESS ? (TOKEN_CONTRACT_ADDRESS as `0x${string}`) : undefined,
    abi: MyTokenPermitABI,
    functionName: 'nonces',
    args: address ? [address] : undefined,
  });

  // Read nonce for nft permit
  const { data: nftNonce, refetch: refetchNftNonce } = useReadContract({
    address: nftContractAddress ? (nftContractAddress as `0x${string}`) : undefined,
    abi: MyNFTPermitABI,
    functionName: 'nonces',
    args: tokenId ? [tokenId] : undefined,
  });

  // 当nftContractAddress变化时重新读取nonce
  useEffect(() => {
    if (!!nftContractAddress || !!address) {
      refetchNftNonce();
    }
  }, [nftContractAddress, address, refetchNftNonce]);

  // 获取白名单签名者地址
  const { data: whitelistSignerAddress } = useReadContract({
    address: CONTRACT_ADDRESS,
    abi: NFTMarketPermitABI,
    functionName: 'whitelistSigner',
  }) as { data: string | undefined };

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

  // 购买NFT Permit交易
  const { writeContract: permitBuy, data: permitBuyHash } = useWriteContract();
  const { isLoading: isPermitBuying, isSuccess: permitBuySuccess } = useWaitForTransactionReceipt({
    hash: permitBuyHash,
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
        setERC20PermitSignature(null); // Clear signature state
        setWhitelistSignature(null); // Clear whitelist signature state
        setNftPermitSignature(null); // Clear nft permit signature state
      }, 60000);
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
        abi: MyNFTPermitABI,
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
            abi: NFTMarketPermitABI,
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

    setERC20PermitSignature(null); // Clear signature state
    setWhitelistSignature(null); // Clear whitelist signature state
    setNftPermitSignature(null); // Clear nft permit signature state
    loadListings();
  }, [listingCounter, address, listSuccess, buySuccess, permitBuySuccess, cancelSuccess, publicClient]);

  // 当NFT Permit签名完成时处理
  useEffect(() => {
    if (nftSignature) {
      setNftPermitSignature(nftSignature);
      setIsGeneratingNftPermit(false);
      setSuccessMessage('NFT Permit signature generated successfully!');
      refetchNftNonce();
    }
  }, [nftSignature]);

  // 当白名单签名完成时处理
  useEffect(() => {
    if (whitelistSig) {
      setWhitelistSignature(whitelistSig);
      setIsGeneratingWhitelist(false);
      setSuccessMessage('Whitelist signature generated successfully!');
    }
  }, [whitelistSig]);

  // 当ERC20 Permit签名完成时处理 - 添加nonce更新
  useEffect(() => {
    if (tokenSignature) {
      // 更新token nonce
      refetchTokenNonce();
    }
  }, [tokenSignature]);

  // When signature is received, call permitBuy
  useEffect(() => {
    if (allowAutoPermitBuy && tokenSignature && erc20PermitSignature && sellerNftPermitSignature && sellerNftPermitDeadline && deployerWhitelistSignature) {
      const { listingId, deadline, amount } = erc20PermitSignature;

      // Extract v, r, s from signature
      const sig = tokenSignature.slice(2); // Remove 0x
      const r = `0x${sig.slice(0, 64)}` as `0x${string}`;  // 提取签名的前 64 个字符(0-63)作为 r 值, 重新添加 "0x" 前缀
      const s = `0x${sig.slice(64, 128)}` as `0x${string}`; // 提取签名的 64-128 个字符(64-127)作为 s 值, 重新添加 "0x" 前缀
      const v = parseInt(sig.slice(128, 130), 16); // 提取签名的最后 2 个字符(128-129)作为 v 值, 将十六进制字符串转换为十进制数字

      console.log('Listing ID:', listingId);
      console.log('Address:', address);
      console.log('Deadline:', deadline);
      console.log('Amount:', amount);
      console.log('v:', v);
      console.log('r:', r);
      console.log('s:', s);
      console.log('Seller NFT Permit Deadline:', sellerNftPermitDeadline);
      console.log('Seller NFT Permit Signature:', sellerNftPermitSignature);
      console.log('Deployer Whitelist Signature:', deployerWhitelistSignature);

      permitBuy({
        address: CONTRACT_ADDRESS,
        abi: NFTMarketPermitABI,
        functionName: 'permitBuy',
        args: [listingId, address, BigInt(deadline), v, r, s, BigInt(sellerNftPermitDeadline), sellerNftPermitSignature, deployerWhitelistSignature],
      });

      setAllowAutoPermitBuy(false); // 执行完成后重置状态
    }
  }, [allowAutoPermitBuy, tokenSignature, erc20PermitSignature, sellerNftPermitSignature, sellerNftPermitDeadline, deployerWhitelistSignature, permitBuy]);

  // When NFT Permit signature is received, call list
  useEffect(() => {
    if (allowAutoList && nftSignature && nftPermitSignature && nftContractAddress && tokenId && price && nftPermitDeadline) {
      try {
        console.log('NFT Signature:', nftSignature);
        console.log('NFT Permit Signature:', nftPermitSignature);
        console.log('NFT Contract Address:', nftContractAddress);
        console.log('Token ID:', tokenId);
        console.log('Price:', price);
        console.log('Deadline:', nftPermitDeadline);

        list({
          address: CONTRACT_ADDRESS,
          abi: NFTMarketPermitABI,
          functionName: 'list',
          args: [
            nftContractAddress as `0x${string}`,
            BigInt(tokenId),
            parseEther(price),
            BigInt(nftPermitDeadline),
            nftPermitSignature,
          ],
        });

        setSuccessMessage('Listing NFT...');
        setAllowAutoList(false); // 执行完成后重置状态
      } catch (error) {
        setErrorMessage('Failed to list NFT');
        setAllowAutoList(false); // 出错时重置状态
        console.error('List NFT error details:', {
          error,
          nftSignature,
          nftPermitSignature,
          nftContractAddress,
          tokenId,
          price,
          nftPermitDeadline
        });
      }
    }
  }, [allowAutoList, nftSignature, nftPermitSignature, nftContractAddress, tokenId, price, list]);

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

    // 验证nftNonce是否已加载
    if (nftNonce === undefined) {
      setErrorMessage('Loading NFT nonce, please wait...');
      await refetchNftNonce();
      return;
    }

    setAllowAutoList(true);
    await handleGenerateNftPermit(nftContractAddress, BigInt(tokenId));
  };

  // 处理购买NFT
  const handleBuyNFT = async (listingId: bigint) => {
    try {
      buyNFT({
        address: CONTRACT_ADDRESS,
        abi: NFTMarketPermitABI,
        functionName: 'buyNFT',
        args: [listingId],
      });
      setSuccessMessage('Buying NFT...');
    } catch (error) {
      setErrorMessage('Failed to buy NFT');
      console.error(error);
    }
  };

  // 处理购买NFT Permit
  const handlePermitBuyNFT = async (listingId: bigint, price: string) => {
    if (!address || !chain) return;

    // 验证买家是否输入了必要的签名信息
    if (!sellerNftPermitSignature || !sellerNftPermitDeadline || !deployerWhitelistSignature) {
      setErrorMessage('please input seller NFT Permit signature, deadline, and deployer whitelist signature');
      return;
    }

    // 验证签名格式
    if (!sellerNftPermitSignature.startsWith('0x') || sellerNftPermitSignature.length !== 132) {
      setErrorMessage('NFT Permit signature format is incorrect, it should be a 0x-prefixed 132-character hex string');
      return;
    }

    if (!deployerWhitelistSignature.startsWith('0x') || deployerWhitelistSignature.length !== 132) {
      setErrorMessage('Deployer whitelist signature format is incorrect, it should be a 0x-prefixed 132-character hex string');
      return;
    }

    const deadline = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    // Store deadline and amount for later use
    setERC20PermitSignature({
      listingId,
      deadline,
      amount: BigInt(price),
      signature: '0x' as `0x${string}`, // Will be updated when signature is received
    });

    // EIP-2612 Permit type data
    const domain = {
      name: 'MyTokenPermit',
      version: '1',
      chainId: chain.id,
      verifyingContract: TOKEN_CONTRACT_ADDRESS,
    };

    await refetchTokenNonce();

    const types = {
      Permit: [
        { name: 'owner', type: 'address' },
        { name: 'spender', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'nonce', type: 'uint256' },
        { name: 'deadline', type: 'uint256' },
      ],
    };

    const message = {
      owner: address,
      spender: CONTRACT_ADDRESS,
      value: BigInt(price),
      nonce: tokenNonce || BigInt(0),
      deadline: BigInt(deadline),
    };

    tokenSignTypedData({
      domain,
      types,
      primaryType: 'Permit',
      message,
    });
    setAllowAutoPermitBuy(true); // 执行完成后重置状态
  };

  // 处理生成NFT Permit签名
  const handleGenerateNftPermit = async (nftContract: string, tokenId: bigint) => {
    if (!address || !chain) return;

    const deadline = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    setNftPermitDeadline(deadline);

    try {
      // EIP-721 Permit type data
      const domain = {
        name: 'ERC721 Permit NFT',
        version: '1',
        chainId: chain.id,
        verifyingContract: nftContract as `0x${string}`,
      };

      const types = {
        Permit: [
          { name: 'spender', type: 'address' },
          { name: 'tokenId', type: 'uint256' },
          { name: 'nonce', type: 'uint256' },
          { name: 'deadline', type: 'uint256' },
        ],
      };

      await refetchNftNonce();

      const message = {
        spender: CONTRACT_ADDRESS,
        tokenId: tokenId,
        nonce: nftNonce || BigInt(0),
        deadline: BigInt(deadline),
      };

      console.log('Spender Address:', CONTRACT_ADDRESS);
      console.log('Token ID:', tokenId);
      console.log('Nonce:', nftNonce || BigInt(0));
      console.log('Deadline:', BigInt(deadline));

      nftSignTypedData({
        domain,
        types,
        primaryType: 'Permit',
        message,
      });
      setIsGeneratingNftPermit(true);
    } catch (error) {
      console.info(error);
      setErrorMessage('Failed to generate NFT Permit signature');
      setIsGeneratingNftPermit(false);
    }
  };

  // 处理生成白名单签名
  const handleGenerateWhitelistSignature = async (buyerAddress: string, listingId: bigint) => {
    if (!address || !chain) return;

    setIsGeneratingWhitelist(true);

    try {
      // Whitelist type data
      const domain = {
        name: 'NFTMarket',
        version: '1.0.0',
        chainId: chain.id,
        verifyingContract: CONTRACT_ADDRESS,
      };

      const types = {
        Whitelist: [
          { name: 'buyer', type: 'address' },
          { name: 'listingId', type: 'uint256' },
        ],
      };

      const message = {
        buyer: buyerAddress,
        listingId: listingId,
      };

      console.log('Buyer Address:', buyerAddress);
      console.log('Listing ID:', listingId);

      whitelistSignTypedData({
        domain,
        types,
        primaryType: 'Whitelist',
        message,
      });
    } catch (error) {
      setErrorMessage('Failed to generate whitelist signature');
      setIsGeneratingWhitelist(false);
    }
  };

  // 处理取消上架
  const handleCancelListing = async (listingId: bigint) => {
    try {
      cancelListing({
        address: CONTRACT_ADDRESS,
        abi: NFTMarketPermitABI,
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
            {/*Whitelist Signature Section - 仅当当前地址为白名单签名者时显示 */}
            {whitelistSignerAddress && address &&
              whitelistSignerAddress.toLowerCase() === address.toLowerCase() && (
                <div className="bg-white rounded-lg shadow p-6">
                  <h2 className="text-2xl font-bold text-gray-900 mb-4">Generate Whitelist Signature</h2>
                  <div className="space-y-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Buyer Address
                      </label>
                      <input
                        type="text"
                        value={whitelistBuyerAddress}
                        onChange={(e) => setWhitelistBuyerAddress(e.target.value)}
                        placeholder="0x..."
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Listing ID
                      </label>
                      <input
                        type="number"
                        value={whitelistListingId}
                        onChange={(e) => setWhitelistListingId(e.target.value)}
                        placeholder="0"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      />
                    </div>
                    <button
                      onClick={() => handleGenerateWhitelistSignature(whitelistBuyerAddress, BigInt(whitelistListingId || '0'))}
                      disabled={isGeneratingWhitelist || !whitelistBuyerAddress || !whitelistListingId}
                      className="w-full bg-purple-600 hover:bg-purple-700 disabled:bg-purple-300 text-white font-medium py-3 px-4 rounded-lg transition-colors"
                    >
                      {isGeneratingWhitelist ? 'Generating...' : 'Generate Whitelist Signature'}
                    </button>
                    {whitelistSignature && (
                      <div className="mt-4 p-3 bg-green-50 border border-green-200 rounded">
                        <p className="text-sm text-green-800 break-all">
                          <strong>Whitelist Signature:</strong> {whitelistSignature}
                        </p>
                      </div>
                    )}
                  </div>
                </div>
              )}

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
                {/* <button
                  onClick={() => handleGenerateNftPermit(BigInt(0), nftContractAddress, BigInt(tokenId || '0'))}
                  disabled={isGeneratingNftPermit || !nftContractAddress || !tokenId}
                  className="w-full bg-orange-600 hover:bg-orange-700 disabled:bg-orange-300 text-white font-medium py-3 px-4 rounded-lg transition-colors"
                >
                  {isGeneratingNftPermit ? 'Generating...' : 'Generate NFT Permit Signature'}
                </button> */}
                {nftPermitSignature && (
                  <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded">
                    <p className="text-sm text-blue-800 break-all">
                      <strong>NFT Permit Signature:</strong> {nftPermitSignature}
                    </p>
                    <p className="text-sm text-blue-800 break-all">
                      <strong>NFT Permit Deadline:</strong> {nftPermitDeadline}
                    </p>
                  </div>
                )}
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
                            Listing ID: {Number(listing.listingId)}
                          </p>
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

                          {/* 买家手动输入卖家NFT Permit签名和deadline */}
                          <div className="space-y-2 mb-4">
                            <div>
                              <label className="block text-xs font-medium text-gray-700 mb-1">
                                Seller's NFT Permit Signature
                              </label>
                              <input
                                type="text"
                                value={sellerNftPermitSignature}
                                onChange={(e) => setSellerNftPermitSignature(e.target.value)}
                                placeholder="0x..."
                                className="w-full px-2 py-1 border border-gray-300 rounded text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-transparent"
                              />
                            </div>
                            <div>
                              <label className="block text-xs font-medium text-gray-700 mb-1">
                                Seller's NFT Permit Deadline
                              </label>
                              <input
                                type="number"
                                value={sellerNftPermitDeadline}
                                onChange={(e) => setSellerNftPermitDeadline(e.target.value)}
                                placeholder="Unix时间戳"
                                className="w-full px-2 py-1 border border-gray-300 rounded text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-transparent"
                              />
                            </div>
                            <div>
                              <label className="block text-xs font-medium text-gray-700 mb-1">
                                Deployer Whitelist Signature
                              </label>
                              <input
                                type="text"
                                value={deployerWhitelistSignature}
                                onChange={(e) => setDeployerWhitelistSignature(e.target.value)}
                                placeholder="0x..."
                                className="w-full px-2 py-1 border border-gray-300 rounded text-sm text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-1 focus:ring-blue-500 focus:border-transparent"
                              />
                            </div>
                          </div>

                          <button
                            onClick={() => handlePermitBuyNFT(BigInt(listing.listingId), listing.price.toString())}
                            disabled={isPermitBuying || !sellerNftPermitSignature || !sellerNftPermitDeadline || !deployerWhitelistSignature}
                            className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 text-white font-medium py-2 px-4 rounded-lg transition-colors"
                          >
                            {isBuying ? 'Permit Buying...' : 'Permit Buy NFT'}
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
                            Listing ID: {Number(listing.listingId)}
                          </p>
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
                            className="w-full bg-red-600 hover:bg-red-700 disabled:bg-red-300 text-white font-medium py-2 px-4 rounded-lg transition-colors mb-3"
                          >
                            {isCanceling ? 'Canceling...' : 'Cancel Listing'}
                          </button>
                          <button
                            onClick={() => handleGenerateNftPermit(
                              listing.nftContract,
                              listing.tokenId
                            )}
                            disabled={isGeneratingNftPermit}
                            className="w-full bg-orange-600 hover:bg-orange-700 disabled:bg-orange-300 text-white font-medium py-2 px-4 rounded-lg transition-colors"
                          >
                            {isGeneratingNftPermit ? 'Generating...' : 'Generate NFT Permit'}
                          </button>
                          {nftPermitSignature && (
                            <div className="mt-4 p-3 bg-blue-50 border border-blue-200 rounded">
                              <p className="text-sm text-blue-800 break-all">
                                <strong>NFT Permit Signature:</strong> {nftPermitSignature}
                              </p>
                              <p className="text-sm text-blue-800 break-all">
                                <strong>NFT Permit Deadline:</strong> {nftPermitDeadline}
                              </p>
                            </div>
                          )}
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
              <span><strong>Permit Buy NFT (Advanced):</strong> Use EIP-2612 and EIP-721 Permit standards for gasless transactions</span>
            </li>
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>NFT Permit Signature:</strong> Sellers generate offline signatures to authorize NFT transfers</span>
            </li>
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>Token Permit Signature:</strong> Buyers generate offline signatures to authorize token spending</span>
            </li>
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>Whitelist Signature:</strong> Contract deployer provides offline signatures for buyer verification</span>
            </li>
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>Cancel Listing:</strong> Remove your NFT from the market anytime</span>
            </li>
          </ul>

          <div className="mt-4 p-4 bg-white rounded border border-blue-200">
            <h4 className="font-bold text-gray-900 mb-2">Permit Buy NFT Process:</h4>
            <ol className="space-y-2 text-sm text-gray-700">
              <li>1. Seller generates NFT Permit signature and deadline</li>
              <li>2. Contract deployer generates whitelist signature for buyer</li>
              <li>3. Buyer inputs seller's NFT Permit signature, deadline, and deployer's whitelist signature</li>
              <li>4. Buyer generates token Permit signature for payment authorization</li>
              <li>5. All signatures are verified in a single transaction for gas efficiency</li>
            </ol>
          </div>
        </div>
      </div>
    </div>
  );
}
