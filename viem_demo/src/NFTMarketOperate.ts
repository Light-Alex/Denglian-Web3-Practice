import {
  createPublicClient,
  createWalletClient,
  formatEther,
  getContract,
  http,
  parseEther,
  parseGwei,
  publicActions,
  parseEventLogs,
  encodeAbiParameters ,
} from "viem";
import { foundry } from "viem/chains";
import dotenv from "dotenv";

import MyToken_ABI from './abis/MyToken.json' with { type: 'json' };
import ERC721_ABI from './abis/MyERC721.json' with { type: 'json' };
import NFT_MARKET_ABI from './abis/NFTMarket.json' with { type: 'json' };


import { privateKeyToAccount } from "viem/accounts";
dotenv.config();

const MyToken_ADDRESS = "0x8A791620dd6260079BF849Dc5567aDC3F2FdC318";
const ERC721_ADDRESS = "0x610178dA211FEF7D417bC0e6FeD39F05609AD788";
const NFT_MARKET_ADDRESS = "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e";

const walletAddress1 = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
const walletAddress2 = "0x70997970C51812dc3A010C7d01b50e0d17dc79C8";

const main = async () => {

  // 创建一个公共客户端
  const publicClient = createPublicClient({
    chain: foundry,
    transport: http(process.env.RPC_URL!),
  }).extend(publicActions);

  const blockNumber = await publicClient.getBlockNumber();
  console.log(`The block number is ${blockNumber}`);

  // Get the balance of an address
  const tbalance = formatEther(await publicClient.getBalance({
    address: walletAddress1,
  }));

  console.log(`The balance of ${walletAddress1} is ${tbalance}`);

  // Get the balance of an address
  const tbalance2 = formatEther(await publicClient.getBalance({
    address: walletAddress2,
  }));

  console.log(`The balance of ${walletAddress2} is ${tbalance2}`);

  // 创建钱包客户端
  const account1 = privateKeyToAccount(
    process.env.PRIVATE_KEY1! as `0x${string}`
  );

  const walletClient1 = createWalletClient({
    account: account1,
    chain: foundry,
    transport: http(process.env.RPC_URL!),
  }).extend(publicActions);

  const account2 = privateKeyToAccount(
    process.env.PRIVATE_KEY2! as `0x${string}`
  );

  const walletClient2 = createWalletClient({
    account: account2,
    chain: foundry,
    transport: http(process.env.RPC_URL!),
  }).extend(publicActions);

  const address1 = await walletClient1.getAddresses();
  console.log(`The wallet 1 address is ${address1}`);
  const address2 = await walletClient2.getAddresses();
  console.log(`The wallet 2 address is ${address2}`);

  const myTokenContract1 = getContract({
    address: MyToken_ADDRESS,
    abi: MyToken_ABI,
    client: {
      public: publicClient,
      wallet: walletClient1,
    },
  });

  const myTokenContract2 = getContract({
    address: MyToken_ADDRESS,
    abi: MyToken_ABI,
    client: {
      public: publicClient,
      wallet: walletClient2,
    },
  });

  // 读取MyToken合约的symbol方法
  const symbol = await myTokenContract1.read.symbol([]);
  console.log(`MyToken 合约的 symbol 是 ${symbol}`);

  // 读取MyToken合约的balanceOf方法
  let balance1 = formatEther(BigInt(await myTokenContract1.read.balanceOf([
    address1.toString(),
  ]) as string));
  console.log(`${address1.toString()} balance is ${balance1} ${symbol}`);

  let balance2 = formatEther(BigInt(await myTokenContract1.read.balanceOf([
    address2.toString(),
  ]) as string));
  console.log(`${address2.toString()} balance is ${balance2} ${symbol}`);

  // wallet1向wallet2转账10000个MyToken
  const tx = await myTokenContract1.write.transfer([
    address2.toString(),
    parseEther("10000"),
  ]);
  console.log(` 调用 transfer 方法的 transaction hash is ${tx}`);

  // 等待交易被确认
  const receipt = await publicClient.waitForTransactionReceipt({ hash: tx });
  console.log(`交易状态: ${receipt.status === 'success' ? '成功' : '失败'}`);
  console.log(receipt.logs);
  // 从 receipt 中解析事件
  const transferLogs = await parseEventLogs({
    abi: MyToken_ABI,
    eventName: 'Transfer', 
    logs: receipt.logs,
  });

  // 打印转账事件详情
  for (const log of transferLogs) {
    const eventLog = log as unknown as { eventName: string; args: { from: string; to: string; value: bigint } };
    if (eventLog.eventName === 'Transfer') {
      console.log('转账事件详情:');
      console.log(`从: ${eventLog.args.from}`);
      console.log(`到: ${eventLog.args.to}`);
      console.log(`金额: ${formatEther(eventLog.args.value)}`);
    }
  }

  // 读取MyToken合约的balanceOf方法
  balance1 = formatEther(BigInt(await myTokenContract1.read.balanceOf([
    address1.toString(),
  ]) as string));
  console.log(`${address1.toString()} balance is ${balance1} ${symbol}`);

  balance2 = formatEther(BigInt(await myTokenContract1.read.balanceOf([
    address2.toString(),
  ]) as string));
  console.log(`${address2.toString()} balance is ${balance2} ${symbol}`);

  // 铸造NFT
  const erc721Contract = getContract({
    address: ERC721_ADDRESS,
    abi: ERC721_ABI,
    client: {
      public: publicClient,
      wallet: walletClient1,
    },
  });

  // 调用mint方法铸造NFT
  const tx2 = await erc721Contract.write.mint([
    address1.toString(),
    "tokenURI_0",
  ]);
  console.log(` 调用 mint 方法的 transaction hash is ${tx2}`);
  // 等待交易被确认
  const receipt2 = await publicClient.waitForTransactionReceipt({ hash: tx2 });
  console.log(`交易状态: ${receipt2.status === 'success' ? '成功' : '失败'}`);
  
  let owner = await erc721Contract.read.ownerOf([0]);
  console.log(`Token 0 的所有者是 ${owner}`);

  // // 授权NFTMarket合约调用MyToken合约的transfer方法
  // const tx3 = await myTokenContract.write.approve([
  //   NFT_MARKET_ADDRESS,
  //   parseEther("10000"),
  // ]);
  // console.log(` 调用 approve 方法的 transaction hash is ${tx3}`);
  // // 等待交易被确认
  // const receipt3 = await publicClient.waitForTransactionReceipt({ hash: tx3 });
  // console.log(`交易状态: ${receipt3.status === 'success' ? '成功' : '失败'}`);

  // 授权NFTMarket合约调用MyERC721合约的safeTransferFrom方法
  const tx4 = await erc721Contract.write.approve([
    NFT_MARKET_ADDRESS,
    0,
  ]);
  console.log(` 调用 approve 方法的 transaction hash is ${tx4}`);
  // 等待交易被确认
  const receipt4 = await publicClient.waitForTransactionReceipt({ hash: tx4 });
  console.log(`交易状态: ${receipt4.status === 'success' ? '成功' : '失败'}`);
  
  const nftMarketContract = getContract({
    address: NFT_MARKET_ADDRESS,
    abi: NFT_MARKET_ABI,
    client: {
      public: publicClient,
      wallet: walletClient1,
    },
  });

  // wallet1上架NFT 0 到NFTMarket合约
  const tx5 = await nftMarketContract.write.list([
    0,
    parseEther("5000"),
  ]);
  console.log(` 调用 list 方法的 transaction hash is ${tx5}`);
  // 等待交易被确认
  const receipt5 = await publicClient.waitForTransactionReceipt({ hash: tx5 });
  console.log(`交易状态: ${receipt5.status === 'success' ? '成功' : '失败'}`);

  // wallet2购买NFT 0
  const tx6 = await myTokenContract2.write.transferWithCallback([
    NFT_MARKET_ADDRESS,
    parseEther("5000"),
    encodeAbiParameters([{ type: 'uint256' }], [BigInt(0)]),
  ]);
  console.log(` 调用 transferWithCallback 方法的 transaction hash is ${tx6}`);
  // 等待交易被确认
  const receipt6 = await publicClient.waitForTransactionReceipt({ hash: tx6 });
  console.log(`交易状态: ${receipt6.status === 'success' ? '成功' : '失败'}`);

  // 读取MyToken合约的balanceOf方法
  balance1 = formatEther(BigInt(await myTokenContract1.read.balanceOf([
    address1.toString(),
  ]) as string));
  console.log(`${address1.toString()} balance is ${balance1} ${symbol}`);

  balance2 = formatEther(BigInt(await myTokenContract1.read.balanceOf([
    address2.toString(),
  ]) as string));
  console.log(`${address2.toString()} balance is ${balance2} ${symbol}`);

  owner = await erc721Contract.read.ownerOf([0]);
  console.log(`Token 0 的所有者是 ${owner}`);
};

main();
