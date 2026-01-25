import { NextResponse } from 'next/server'
import { createPublicClient, http } from 'viem'
import { sepolia } from 'viem/chains'
import { MEME_FACTORY_ABI, MEME_TOKEN_ABI } from '@/lib/abis/memeFactory'
import { PROTOCOL_ADDRESSES } from '@/lib/constants/addresses'

// 创建公共客户端
const publicClient = createPublicClient({
  chain: sepolia,
  transport: http(),
})

export async function GET(request, { params }) {
  try {
    const { address } = params
    const factoryAddress = PROTOCOL_ADDRESSES[sepolia.id]?.MEME_FACTORY

    // 从工厂合约读取 meme 信息
    const memeInfo = await publicClient.readContract({
      address: factoryAddress,
      abi: MEME_FACTORY_ABI,
      functionName: 'memes',
      args: [address],
    })

    // 从代币合约读取剩余供应量
    const remainingSupply = await publicClient.readContract({
      address: address,
      abi: MEME_TOKEN_ABI,
      functionName: 'remainingSupply',
    })

    // 组装响应数据
    const data = {
      tokenAddress: memeInfo[0],
      creator: memeInfo[1],
      symbol: memeInfo[2],
      totalSupply: memeInfo[3].toString(),
      perMint: memeInfo[4].toString(),
      price: memeInfo[5].toString(),
      totalMinted: memeInfo[6].toString(),
      exists: memeInfo[7],
      remainingSupply: remainingSupply.toString(),
    }

    return NextResponse.json(data)
  } catch (error) {
    console.error('Error fetching meme info:', error)
    return NextResponse.json(
      { error: 'Failed to fetch meme info', details: error.message },
      { status: 500 }
    )
  }
}
