'use client';

import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt, useChainId } from 'wagmi';
import { useState, useEffect } from 'react';
import { parseEther, formatEther, encodeAbiParameters } from 'viem';
import BaseERC20ABI from '@/contracts/BaseERC20.json';
import { getContractAddress } from '@/lib/contracts';

export default function ERC20TokenPage() {
  // 从环境变量获取合约地址
  const chainId = useChainId();
  const CONTRACT_ADDRESS = getContractAddress(chainId, 'BaseERC20');

  const { address, isConnected } = useAccount();
  const [recipientAddress, setRecipientAddress] = useState('');
  const [transferAmount, setTransferAmount] = useState('');
  const [spenderAddress, setSpenderAddress] = useState('');
  const [approveAmount, setApproveAmount] = useState('');
  const [errorMessage, setErrorMessage] = useState('');

  // 新增购买NFT相关状态
  const [nftMarketAddress, setNftMarketAddress] = useState('');
  const [nftTokenId, setNftTokenId] = useState('');
  const [purchaseAmount, setPurchaseAmount] = useState('');

  // 清除错误信息
  useEffect(() => {
    if (errorMessage) {
      const timer = setTimeout(() => setErrorMessage(''), 5000);
      return () => clearTimeout(timer);
    }
  }, [errorMessage]);

  // 查询余额 - 使用 useReadContract
  const {
    data: balance,
    refetch: refetchBalance,
    isLoading: isBalanceLoading
  } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: BaseERC20ABI,
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
      setRecipientAddress('');
      setTransferAmount('');
      setSpenderAddress('');
      setApproveAmount('');
      setNftMarketAddress('');
      setNftTokenId('');
      setPurchaseAmount('');
      setErrorMessage('');
      
      // 余额查询会自动重新执行，因为query.enabled依赖address
      refetchBalance();
      console.log('钱包账户已切换，余额将自动更新');
    }
  }, [address, refetchBalance]);

  // 查询代币信息 - 使用 useReadContract
  const { data: tokenName, isLoading: isNameLoading } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: BaseERC20ABI,
    functionName: 'name',
  });

  const { data: tokenSymbol, isLoading: isSymbolLoading } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: BaseERC20ABI,
    functionName: 'symbol',
  });

  const { data: decimals, isLoading: isDecimalsLoading } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: BaseERC20ABI,
    functionName: 'decimals',
  });

  // 转账功能 - 使用 useWriteContract
  const {
    writeContract: transfer,
    data: transferHash,
    isPending: isTransferLoading,
    error: transferError
  } = useWriteContract();

  const { 
    isLoading: isTransferConfirming,
    isSuccess: isTransferSuccess,
    isError: isTransferError,
    error: transferReceiptError
   } = useWaitForTransactionReceipt({
    hash: transferHash,
  });

  // 授权功能 - 使用 useWriteContract
  const {
    writeContract: approve,
    data: approveHash,
    isPending: isApproveLoading,
    error: approveError
  } = useWriteContract();

  const { 
    isLoading: isApproveConfirming,
    isSuccess: isApproveSuccess,
    isError: isApproveError,
    error: approveReceiptError
   } = useWaitForTransactionReceipt({
    hash: approveHash,
  });

  // 查询授权额度 - 使用 useReadContract
  const { data: allowance, refetch: refetchAllowance, isLoading: isAllowanceLoading } = useReadContract({
    address: CONTRACT_ADDRESS as `0x${string}`,
    abi: BaseERC20ABI,
    functionName: 'allowance',
    args: [address, spenderAddress],
    query: {
      enabled: !!address && !!spenderAddress,  // 同时依赖address和spenderAddress
    }
  });

  // 购买NFT功能 - 使用 useWriteContract
  const {
    writeContract: transferWithCallback,
    data: transferWithCallbackHash,
    isPending: isTransferWithCallbackLoading,
    error: transferWithCallbackError,
  } = useWriteContract();

  const { 
    isLoading: isTransferWithCallbackConfirming, 
    isSuccess: isTransferWithCallbackSuccess,
    isError: isTransferWithCallbackError,
    error: transferWithCallbackReceiptError
   } = useWaitForTransactionReceipt({
    hash: transferWithCallbackHash,
  });

  // 监听转账交易确认状态
  useEffect(() => {
    if (isTransferSuccess) {
      refetchBalance();
      setErrorMessage('');
    }
    if (isTransferError) {
      setErrorMessage(`转账交易确认失败: ${transferReceiptError?.message}`);
    }
  }, [isTransferSuccess, isTransferError, transferReceiptError, refetchBalance]);

  // 监听授权交易确认状态
  useEffect(() => {
    if (isApproveSuccess) {
      refetchAllowance();
      setErrorMessage('');
    }
    if (isApproveError) {
      setErrorMessage(`授权交易确认失败: ${approveReceiptError?.message}`);
    }
  }, [isApproveSuccess, isApproveError, approveReceiptError, refetchAllowance]);

  // 监听TransferWithCallback交易确认状态
  useEffect(() => {
    if (isTransferWithCallbackSuccess) {
      refetchBalance();
      setErrorMessage('');
    }
    if (isTransferWithCallbackError) {
      setErrorMessage(`TransferWithCallback交易确认失败: ${transferWithCallbackReceiptError?.message}`);
    }
  }, [isTransferWithCallbackSuccess, isTransferWithCallbackError, transferWithCallbackReceiptError, refetchBalance]);

  const handleTransfer = () => {
    if (!recipientAddress || !transferAmount) {
      setErrorMessage('请填写收款地址和转账金额');
      return;
    }

    if (!/^0x[a-fA-F0-9]{40}$/.test(recipientAddress)) {
      setErrorMessage('请输入有效的以太坊地址');
      return;
    }

    try {
      const amount = parseEther(transferAmount);
      transfer({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: BaseERC20ABI,
        functionName: 'transfer',
        args: [recipientAddress as `0x${string}`, amount],
      }, {
        onSuccess: () => {
          setErrorMessage(''); // 清除错误信息
        },
        onError: (error) => {
          setErrorMessage(`转账失败: ${error.message}`);
        }
      });
    } catch (error) {
      setErrorMessage('金额格式错误，请检查输入');
    }
  };

  const handleApprove = () => {
    if (!spenderAddress || !approveAmount) {
      setErrorMessage('请填写授权地址和授权金额');
      return;
    }

    if (!/^0x[a-fA-F0-9]{40}$/.test(spenderAddress)) {
      setErrorMessage('请输入有效的以太坊地址');
      return;
    }

    try {
      const amount = parseEther(approveAmount);
      approve({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: BaseERC20ABI,
        functionName: 'approve',
        args: [spenderAddress as `0x${string}`, amount],
      }, {
        onSuccess: () => {
          setErrorMessage(''); // 清除错误信息
        },
        onError: (error) => {
          setErrorMessage(`授权失败: ${error.message}`);
        }
      });
    } catch (error) {
      setErrorMessage('金额格式错误，请检查输入');
    }
  };

  const handleTransferWithCallback = () => {
    if (!nftMarketAddress || !purchaseAmount || !nftTokenId) {
      setErrorMessage('请填写NFT市场地址、购买金额和NFT Token ID');
      return;
    }

    if (!/^0x[a-fA-F0-9]{40}$/.test(nftMarketAddress)) {
      setErrorMessage('请输入有效的以太坊地址');
      return;
    }

    try {
      const amount = parseEther(purchaseAmount);
      // 使用ABI编码对nftTokenId进行编码
      const encodedData = encodeAbiParameters(
        [{ type: 'uint256' }], // 参数类型：uint256
        [BigInt(nftTokenId)]   // 参数值：nftTokenId转换为bigint
      );

      transferWithCallback({
        address: CONTRACT_ADDRESS as `0x${string}`,
        abi: BaseERC20ABI,
        functionName: 'transferWithCallback',
        args: [nftMarketAddress as `0x${string}`, amount, encodedData],
      }, {
        onSuccess: () => {
          setErrorMessage(''); // 清除错误信息
        },
        onError: (error) => {
          setErrorMessage(`购买NFT失败: ${error.message}`);
        }
      });
    } catch (error) {
      setErrorMessage('购买金额格式错误，请检查输入');
    }
  }

  const formattedBalance = balance ? formatEther(balance as bigint) : '0';
  const formattedAllowance = allowance ? formatEther(allowance as bigint) : '0';
  const displayName = isNameLoading ? 'Loading...' : (tokenName as string || 'ERC20 Token');
  const displaySymbol = isSymbolLoading ? 'Loading...' : (tokenSymbol as string || 'TOKEN');

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <h1 className="text-4xl font-bold text-gray-900 mb-2">
            {displayName} ({displaySymbol})
          </h1>
          <p className="text-gray-600">管理您的ERC20代币</p>
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
            {/* Token Balance Section */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">代币余额</h2>
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-3xl font-bold text-gray-900">
                    {isBalanceLoading ? '加载中...' : `${formattedBalance} ${displaySymbol}`}
                  </p>
                  <p className="text-gray-600 mt-2">您当前的余额</p>
                </div>
                <button
                  onClick={() => refetchBalance()}
                  className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-lg transition-colors"
                >
                  刷新余额
                </button>
              </div>
            </div>

            {/* Transfer Section */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">转账</h2>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    收款地址
                  </label>
                  <input
                    type="text"
                    placeholder="0x..."
                    value={recipientAddress}
                    onChange={(e) => setRecipientAddress(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    转账金额 ({displaySymbol})
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    placeholder="100"
                    value={transferAmount}
                    onChange={(e) => setTransferAmount(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <button
                  onClick={handleTransfer}
                  disabled={isTransferLoading || isTransferConfirming}
                  className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 text-white font-medium py-3 px-4 rounded-lg transition-colors"
                >
                  {isTransferLoading ? '发送中...' : isTransferConfirming ? '确认中...' : '转账'}
                </button>
              </div>
            </div>

            {/* Approve Section */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">授权</h2>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    授权地址
                  </label>
                  <input
                    type="text"
                    placeholder="0x..."
                    value={spenderAddress}
                    onChange={(e) => setSpenderAddress(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    授权金额 ({displaySymbol})
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    placeholder="100"
                    value={approveAmount}
                    onChange={(e) => setApproveAmount(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <button
                  onClick={handleApprove}
                  disabled={isApproveLoading || isApproveConfirming}
                  className="w-full bg-green-600 hover:bg-green-700 disabled:bg-green-300 text-white font-medium py-3 px-4 rounded-lg transition-colors"
                >
                  {isApproveLoading ? '授权中...' : isApproveConfirming ? '确认中...' : '授权'}
                </button>
                {/* 显示授权额度 */}
                {isAllowanceLoading ? (
                  <div className="text-sm text-gray-600">
                    查询中...
                  </div>
                ) : (
                  <div className="text-sm text-gray-600">
                    当前授权额度: {formattedAllowance ? formattedAllowance : '0'} {displaySymbol}
                  </div>
                )}
              </div>
            </div>

            {/* TransferWithCallback Section */}
            <div className="bg-white rounded-lg shadow p-6">
              <h2 className="text-2xl font-bold text-gray-900 mb-4">购买NFT</h2>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    接收地址 (NFT Market合约地址)
                  </label>
                  <input
                    type="text"
                    placeholder="0x..."
                    value={nftMarketAddress}
                    onChange={(e) => setNftMarketAddress(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    购买金额 ({displaySymbol})
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    placeholder="100"
                    value={purchaseAmount}
                    onChange={(e) => setPurchaseAmount(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    NFT Token ID
                  </label>
                  <input
                    type="number"
                    step="1"
                    placeholder="0"
                    value={nftTokenId}
                    onChange={(e) => setNftTokenId(e.target.value)}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg text-gray-900 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  />
                </div>

                <button
                  onClick={handleTransferWithCallback}
                  disabled={isTransferWithCallbackLoading || isTransferWithCallbackConfirming}
                  className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-blue-300 text-white font-medium py-3 px-4 rounded-lg transition-colors"
                >
                  {isTransferWithCallbackLoading ? '发送中...' : isTransferWithCallbackConfirming ? '确认中...' : '购买NFT'}
                </button>
              </div>
            </div>


            {/* Features Info */}
            <div className="bg-blue-50 rounded-lg p-6 border border-blue-100">
              <h3 className="text-xl font-bold text-gray-900 mb-4">功能说明</h3>
              <ul className="space-y-2 text-gray-700">
                <li className="flex items-start">
                  <span className="text-blue-600 mr-2">•</span>
                  <span><strong>查询余额:</strong> 查看您当前的ERC20代币余额</span>
                </li>
                <li className="flex items-start">
                  <span className="text-blue-600 mr-2">•</span>
                  <span><strong>转账:</strong> 将代币发送到其他地址</span>
                </li>
                <li className="flex items-start">
                  <span className="text-blue-600 mr-2">•</span>
                  <span><strong>授权:</strong> 授权其他合约使用您的代币</span>
                </li>
                <li className="flex items-start">
                  <span className="text-blue-600 mr-2">•</span>
                  <span><strong>购买NFT:</strong> 将代币发送到NFT Market合约用于购买NFT</span>
                </li>
              </ul>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}