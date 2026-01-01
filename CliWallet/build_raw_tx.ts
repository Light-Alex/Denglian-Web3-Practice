import { createWalletClient, formatEther, http, parseEther, parseGwei, encodeFunctionData, type Hash, type TransactionReceipt } from 'viem'
import { prepareTransactionRequest } from 'viem/actions'
import { mnemonicToAccount, privateKeyToAccount, type PrivateKeyAccount } from 'viem/accounts'
import { foundry, sepolia } from 'viem/chains'
import { createPublicClient, type PublicClient, type WalletClient } from 'viem'
import BaseERC20ABI from './abis/BaseERC20.json' with { type: 'json' };
import dotenv from 'dotenv'

dotenv.config()

async function sendTransactionExample(): Promise<Hash> {
  try {
    // const privateKey = generatePrivateKey()

    // 1. 从环境变量获取私钥
    const privateKey = process.env.PRIVATE_KEY as `0x${string}`
    if (!privateKey) {
      throw new Error('请在 .env 文件中设置 PRIVATE_KEY')
    }

    // 使用助记词 推导账户
    // const account = mnemonicToAccount('xxxx xxx ') 
    // 使用私钥 推导账户
    const account: PrivateKeyAccount = privateKeyToAccount(privateKey)
    const userAddress = account.address
    console.log('账户地址:', userAddress)

    // 创建公共客户端
    const publicClient: PublicClient = createPublicClient({
      chain: sepolia,
      transport: http(process.env.RPC_URL)
    })

    // 创建钱包客户端
    const walletClient: WalletClient = createWalletClient({
      account: account,
      chain: sepolia,
      transport: http(process.env.RPC_URL)
    })

    // 检查网络状态
    const blockNumber = await publicClient.getBlockNumber()
    console.log('当前区块号:', blockNumber)

    // 获取当前 gas 价格
    const gasPrice = await publicClient.getGasPrice()
    console.log('当前 gas 价格:', parseGwei(gasPrice.toString()), 'Wei', ',', formatEther(gasPrice), 'Ether')

    // 查询余额
    const balance = await publicClient.getBalance({
      address: userAddress
    })
    console.log('账户余额: ', parseEther(balance.toString()), 'Wei', ",", formatEther(balance), 'Ether')

    // 查询nonce
    const nonce = await publicClient.getTransactionCount({
      address: userAddress
    })
    console.log('当前 Nonce:', nonce)

    // // ------------------主链币交易------------------
    // // 2. 构建交易参数
    // const txParams = {
    //   account: account,
    //   to: '0x6687e46C68C00bd1C10F8cc3Eb000B1752737e94' as `0x${string}`, // 目标地址
    //   value: parseEther('0.0000001'), // 发送金额（ETH）
    //   chainId: sepolia.id,
    //   type: 'eip1559' as const, // 使用 const 断言确保类型正确
    //   chain: sepolia, // 添加 chain 参数
      
    //   // EIP-1559 交易参数
    //   maxFeePerGas: gasPrice * 2n, // 最大总费用为当前 gas 价格的 2 倍
    //   maxPriorityFeePerGas: parseGwei('0.001'), // 最大小费
    //   gas: 21000n,   // gas limit
    //   nonce: nonce
    // }

    // // 或 自动 Gas 估算 及参数验证和补充
    // // Viem 库中的一个重要函数，它会自动填充缺失的交易参数、估算 Gas 用量、验证交易有效性
    // const preparedTx = await prepareTransactionRequest(publicClient, txParams)

    // console.log('准备后的交易参数:', {
    //   ...preparedTx,
    //   maxFeePerGas: parseGwei(preparedTx.maxFeePerGas.toString()),
    //   maxPriorityFeePerGas: parseGwei(preparedTx.maxPriorityFeePerGas.toString()),
    // })

    // // // // 方式 1：直接发送交易
    // // const txHash1 = await walletClient.sendTransaction(preparedTx)
    // // console.log('交易哈希:', txHash1)

    // // 方式 2 ： 
    // // 签名交易
    // const signedTx = await walletClient.signTransaction(preparedTx)
    // console.log('Signed Transaction:', signedTx)

    // // 发送交易  eth_sendRawTransaction
    // const txHash = await publicClient.sendRawTransaction({
    //     serializedTransaction: signedTx
    // })
    // console.log('Transaction Hash:', txHash)

    // // 等待交易确认
    // const receipt: TransactionReceipt = await publicClient.waitForTransactionReceipt({ hash: txHash })
    // console.log('交易状态:', receipt.status === 'success' ? '成功' : '失败')
    // console.log('区块号:', receipt.blockNumber)
    // console.log('Gas 使用量:', receipt.gasUsed.toString())

    // // ------------------ERC20 交易------------------
    const baseERC20Address = process.env.NEXT_PUBLIC_BASE_ERC20_ADDRESS as `0x${string}`
    if (!baseERC20Address) {
      throw new Error('请在 .env 文件中设置 NEXT_PUBLIC_BASE_ERC20_ADDRESS')
    }

    // 查询ERC20代币余额
    const balanceERC20 = await publicClient.readContract({
      address: baseERC20Address,
      abi: BaseERC20ABI,
      functionName: 'balanceOf',
      args: [userAddress]
    })
    console.log('ERC20 代币余额:', formatEther(balanceERC20 as bigint), "Ether")

    // 构造ERC20的转账交易, 调用ERC20的transfer函数
    const txParams = {
      account: account,
      to: baseERC20Address,
      value: 0n, // 发送金额（ETH）
      // 调用ERC20的transfer函数, 转账50 个代币
      data: encodeFunctionData({
        abi: BaseERC20ABI,
        functionName: 'transfer',
        args: ['0x6687e46C68C00bd1C10F8cc3Eb000B1752737e94', parseEther('50')]
      }),
      chainId: sepolia.id,
      type: 'eip1559' as const, // 使用 const 断言确保类型正确
      chain: sepolia, // 添加 chain 参数
      
      // EIP-1559 交易参数
      maxFeePerGas: gasPrice * 2n, // 最大总费用为当前 gas 价格的 2 倍
      maxPriorityFeePerGas: parseGwei('0.001'), // 最大小费
      gas: 50000n,   // gas limit
      nonce: nonce
    }

    const preparedTx = await prepareTransactionRequest(publicClient, txParams)
    console.log('准备后的交易参数:', {
      ...preparedTx,
      maxFeePerGas: parseGwei(preparedTx.maxFeePerGas.toString()),
      maxPriorityFeePerGas: parseGwei(preparedTx.maxPriorityFeePerGas.toString()),
    })

    const signedTx = await walletClient.signTransaction(preparedTx)
    console.log('签名后的交易:', signedTx)

    // 发送交易  eth_sendRawTransaction
    const txHash = await publicClient.sendRawTransaction({
        serializedTransaction: signedTx
    })
    console.log('Transaction Hash:', txHash)

    // 等待交易确认
    const receipt: TransactionReceipt = await publicClient.waitForTransactionReceipt({ hash: txHash })
    console.log('交易状态:', receipt.status === 'success' ? '成功' : '失败')
    console.log('区块号:', receipt.blockNumber)
    console.log('Gas 使用量:', receipt.gasUsed.toString())

    return txHash

  } catch (error) {
    console.error('错误:', error)
    if (error instanceof Error) {
      console.error('错误信息:', error.message)
    }
    if (error && typeof error === 'object' && 'details' in error) {
      console.error('错误详情:', error.details)
    }
    throw error
  }
}

// 执行示例
sendTransactionExample() 