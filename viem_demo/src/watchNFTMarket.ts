import {
    createPublicClient,
    formatEther,
    getContract,
    http,
    publicActions,
    webSocket,
    type Log,
} from "viem";
import { foundry } from "viem/chains";
import dotenv from "dotenv";
import NFT_MARKET_ABI from './abis/NFTMarket.json' with { type: 'json' };

dotenv.config();

const NFT_MARKET_ADDRESS = "0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e";

const main = async () => {
    // 创建公共客户端
    const publicClient = createPublicClient({
        chain: foundry,
        transport: webSocket(process.env.RPC_URL!),
        // transport: http(process.env.RPC_URL!),
    }).extend(publicActions);

    console.log('开始监听 NFTMarket 事件...');

    // 监听NFT List事件
    const unwatch_list = publicClient.watchEvent({
        address: NFT_MARKET_ADDRESS,
        event: {
            type: 'event',
            name: 'NFTListed',
            inputs: [
                { type: 'address', name: 'seller'},
                { type: 'uint256', name: 'tokenId'},
                { type: 'uint256', name: 'price'}
            ]
        },
        onLogs: (logs) => {
            logs.forEach((log) => {
                if (log.args.price !== undefined) {
                        console.log('\n检测到新的NFT List事件:');
                        console.log(`合约地址: ${log.address}`);
                        console.log(`Seller: ${log.args.seller}`);
                        console.log(`Token ID: ${log.args.tokenId}`);
                        console.log(`Price: ${formatEther(log.args.price)}`);
                        console.log(`交易哈希: ${log.transactionHash}`);
                        console.log(`区块号: ${log.blockNumber}`);
                }
            });
        }
    });

    // 监听NFT Buy事件
    const unwatch_buy = publicClient.watchEvent({
        address: NFT_MARKET_ADDRESS,
        event: {
            type: 'event',
            name: 'NFTPurchased',
            inputs: [
                { type: 'address', name: 'buyer'},
                { type: 'uint256', name: 'tokenId'},
                { type: 'uint256', name: 'price'}
            ]
        },
        onLogs: (logs) => {
            logs.forEach((log) => {
                if (log.args.price !== undefined) {
                        console.log('\n检测到新的NFTPurchased事件:');
                        console.log(`合约地址: ${log.address}`);
                        console.log(`Buyer: ${log.args.buyer}`);
                        console.log(`Token ID: ${log.args.tokenId}`);
                        console.log(`Price: ${formatEther(log.args.price)}`);
                        console.log(`交易哈希: ${log.transactionHash}`);
                        console.log(`区块号: ${log.blockNumber}`);
                }
            });
        }
    });

    // 保持程序运行
    process.on('SIGINT', () => {
        console.log('\n停止监听...');
        unwatch_list();
        unwatch_buy();
        process.exit();
    });
};

main().catch((error) => {
    console.error('发生错误:', error);
    process.exit(1);
}); 