'use client';

import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, useChainId } from 'wagmi';
import { useState, useEffect } from 'react';
import MyNFTPermit from '@/contracts/MyNFTPermit.json';
import { getContractAddress } from '@/lib/contracts';

export default function NFTManagementPage() {
  // 从环境变量获取合约地址
  const chainId = useChainId();
  const CONTRACT_ADDRESS = getContractAddress(chainId, 'MyNFTPermit');

  const { address, isConnected } = useAccount();
  const [mintToAddress, setMintToAddress] = useState('');
  const [tokenURI, setTokenURI] = useState('');
  const [tokenId, setTokenId] = useState('');
  const [approveToAddress, setApproveToAddress] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  // 清除错误信息
  useEffect(() => {
    if (errorMessage) {
      const timer = setTimeout(() => setErrorMessage(''), 5000);
      return () => clearTimeout(timer);
    }
  }, [errorMessage]);
  

  // 查询NFT信息 - 使用 useReadContract
  const { data: nftName, isLoading: isNameLoading } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: MyNFTPermit,
    functionName: 'name',
  });

  const { data: nftSymbol, isLoading: isSymbolLoading } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: MyNFTPermit,
    functionName: 'symbol',
  });

  const { data: ownerBalance, refetch: refetchBalance, isLoading: isBalanceLoading } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: MyNFTPermit,
    functionName: 'balanceOf',
    args: [address],
    query: {
      enabled: !!address,
    }
  });

  // 监听钱包账户切换，重置表单状态
  useEffect(() => {
    if (address) {
      // 切换账户时重置表单状态
      setMintToAddress('');
      setTokenURI('');
      setTokenId('');
      setApproveToAddress('');
      setErrorMessage('');
      
      // 余额查询会自动重新执行，因为query.enabled依赖address
      refetchBalance();
      console.log('钱包账户已切换，余额将自动更新');
    }
  }, [address, refetchBalance]);

  // 查询特定Token的Owner - 使用 useReadContract
  const { data: tokenOwner, refetch: refetchTokenOwner, isLoading: isOwnerLoading } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: MyNFTPermit,
    functionName: 'ownerOf',
    args: [tokenId ? BigInt(tokenId) : BigInt(0)],
    query: {
      enabled: !!tokenId && !!address,
    }
  });

  // 查询授权状态 - 使用 useReadContract
  const { data: approvedAddress, refetch: refetchApproved, isLoading: isApprovedLoading } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: MyNFTPermit,
    functionName: 'getApproved',
    args: [tokenId ? BigInt(tokenId) : BigInt(0)],
    query: {
      enabled: !!tokenId && !!address,
    }
  });

  // 铸造NFT功能 - 使用 useWriteContract
  const {
    writeContract: mintNFT,
    data: mintHash,
    isPending: isMintLoading,
    error: mintError
  } = useWriteContract();

  const { 
    isLoading: isMintConfirming,
    isSuccess: isMintSuccess,
    isError: isMintError,
    error: mintConfirmError
  } = useWaitForTransactionReceipt({
    hash: mintHash,
  });

  // 授权功能 - 使用 useWriteContract
  const {
    writeContract: approveNFT,
    data: approveHash,
    isPending: isApproveLoading,
    error: approveError
  } = useWriteContract();

  const { 
    isLoading: isApproveConfirming,
    isSuccess: isApproveSuccess,
    isError: isApproveError,
    error: approveConfirmError
  } = useWaitForTransactionReceipt({
    hash: approveHash,
  });

  // 监听铸造NFT交易确认
  useEffect(() => {
    if (isMintSuccess) {
      refetchBalance();
      refetchTokenOwner();
    } else if (isMintError) {
      setErrorMessage(`铸造失败: ${mintConfirmError.message}`);
    }
  }, [isMintSuccess, isMintError, mintConfirmError, refetchBalance, refetchTokenOwner]);

  // 监听授权NFT交易确认
  useEffect(() => {
    if (isApproveSuccess) {
      refetchApproved();
    } else if (isApproveError) {
      setErrorMessage(`授权失败: ${approveConfirmError.message}`);
    }
  }, [isApproveSuccess, isApproveError, approveConfirmError, refetchApproved]);

  const handleMint = () => {
    if (!mintToAddress || !tokenURI) {
      setErrorMessage('请填写接收地址和Token URI');
      return;
    }

    if (!/^0x[a-fA-F0-9]{40}$/.test(mintToAddress)) {
      setErrorMessage('请输入有效的以太坊地址');
      return;
    }

    try {
      mintNFT({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: MyNFTPermit,
        functionName: 'mint',
        args: [mintToAddress as `0x${string}`, tokenURI],
      }, {
        onSuccess: () => {
          setErrorMessage("");
        },
        onError: (error) => {
          setErrorMessage(`铸造失败: ${error.message}`);
        }
      });
    } catch (error) {
      setErrorMessage('铸造参数错误，请检查输入');
    }
  };

  const handleApprove = () => {
    if (!approveToAddress || !tokenId) {
      setErrorMessage('请填写授权地址和Token ID');
      return;
    }

    if (!/^0x[a-fA-F0-9]{40}$/.test(approveToAddress)) {
      setErrorMessage('请输入有效的以太坊地址');
      return;
    }

    try {
      approveNFT({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: MyNFTPermit,
        functionName: 'approve',
        args: [approveToAddress as `0x${string}`, BigInt(tokenId)],
      }, {
        onSuccess: () => {
          setErrorMessage("");
        },
        onError: (error) => {
          setErrorMessage(`授权失败: ${error.message}`);
        }
      });
    } catch (error) {
      setErrorMessage('授权参数错误，请检查输入');
    }
  };

  const handleQueryOwner = () => {
    if (!tokenId) {
      setErrorMessage('请填写Token ID');
      return;
    }
    refetchTokenOwner();
  };

  const displayName = isNameLoading ? 'Loading...' : (nftName as string || 'Simple NFT');
  const displaySymbol = isSymbolLoading ? 'Loading...' : (nftSymbol as string || 'SNFT');

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">
            {displayName} ({displaySymbol})
          </h1>
          <p className="text-gray-600">管理您的NFT资产</p>
        </div>

        {/* 错误提示 */}
        {errorMessage && (
          <div className="mb-6 bg-red-50 border border-red-200 rounded-lg p-4">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                </svg>
              </div>
              <div className="ml-3">
                <p className="text-sm text-red-700">{errorMessage}</p>
              </div>
            </div>
          </div>
        )}

        {!isConnected ? (
          <div className="bg-white rounded-lg shadow p-8 text-center">
            <p className="text-gray-700 mb-4">请连接您的钱包</p>
            <p className="text-sm text-gray-500">点击右上角的"Connect Wallet"按钮</p>
          </div>
        ) : (
          <div className="space-y-8">
            {/* NFT Balance Section */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">我的NFT余额</h2>
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-3xl font-bold text-gray-900">
                    {isBalanceLoading ? '加载中...' : `${ownerBalance?.toString() || '0'} ${displaySymbol}`}
                  </p>
                  <p className="text-gray-600 mt-2">您当前拥有的NFT数量</p>
                </div>
                <button
                  onClick={() => refetchBalance()}
                  className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-lg transition-colors"
                >
                  刷新余额
                </button>
              </div>
            </div>

            {/* Mint NFT Section */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">铸造NFT</h2>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    接收地址
                  </label>
                  <input
                    type="text"
                    placeholder="0x..."
                    value={mintToAddress}
                    onChange={(e) => setMintToAddress(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Token URI
                  </label>
                  <input
                    type="text"
                    placeholder="https://example.com/token/1"
                    value={tokenURI}
                    onChange={(e) => setTokenURI(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <button
                  onClick={handleMint}
                  disabled={isMintLoading || isMintConfirming}
                  className="w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white font-medium py-3 px-4 rounded-lg transition-colors"
                >
                  {isMintLoading ? '发送中...' : isMintConfirming ? '确认中...' : '铸造NFT'}
                </button>
              </div>
            </div>

            {/* Query Owner Section */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">查询NFT Owner</h2>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Token ID
                  </label>
                  <input
                    type="number"
                    placeholder="0"
                    value={tokenId}
                    onChange={(e) => setTokenId(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div className="flex space-x-4">
                  <button
                    onClick={handleQueryOwner}
                    className="flex-1 bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-lg transition-colors"
                  >
                    查询Owner
                  </button>
                  <button
                    onClick={() => refetchApproved()}
                    className="flex-1 bg-purple-600 hover:bg-purple-700 text-white font-medium py-2 px-4 rounded-lg transition-colors"
                  >
                    查询授权状态
                  </button>
                </div>
                {tokenOwner !== undefined && tokenOwner !== null && (
                  <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                    <p className="text-green-700">
                      <strong>Owner:</strong> {typeof tokenOwner === 'string' ? tokenOwner : String(tokenOwner)}
                    </p>
                  </div>
                )}
                {approvedAddress !== undefined && approvedAddress !== null && (
                  <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
                    <p className="text-blue-700">
                      <strong>Approved Address:</strong> {typeof approvedAddress === 'string' ? approvedAddress : String(approvedAddress)}
                    </p>
                  </div>
                )}
              </div>
            </div>

            {/* Approve NFT Section */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">授权NFT</h2>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Token ID
                  </label>
                  <input
                    type="number"
                    placeholder="0"
                    value={tokenId}
                    onChange={(e) => setTokenId(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    授权地址
                  </label>
                  <input
                    type="text"
                    placeholder="0x..."
                    value={approveToAddress}
                    onChange={(e) => setApproveToAddress(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <button
                  onClick={handleApprove}
                  disabled={isApproveLoading || isApproveConfirming}
                  className="w-full bg-orange-600 hover:bg-orange-700 disabled:bg-gray-400 text-white font-medium py-3 px-4 rounded-lg transition-colors"
                >
                  {isApproveLoading ? '发送中...' : isApproveConfirming ? '确认中...' : '授权NFT'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Features Info */}
        <div className="mt-8 bg-blue-50 rounded-lg p-6 border border-blue-100">
          <h3 className="text-xl font-bold text-gray-900 mb-4">功能说明</h3>
          <ul className="space-y-2 text-gray-700">
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>铸造NFT:</strong> 创建新的NFT并指定接收地址和元数据URI</span>
            </li>
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>查询Owner:</strong> 根据Token ID查询NFT的当前所有者</span>
            </li>
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>授权NFT:</strong> 将特定NFT的转移权限授予其他地址</span>
            </li>
            <li className="flex items-start">
              <span className="text-blue-600 mr-2">•</span>
              <span><strong>查询授权状态:</strong> 查看NFT当前的授权地址</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  );
}