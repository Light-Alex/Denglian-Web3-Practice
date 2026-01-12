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
} from "viem";
import { sepolia } from "viem/chains";
import dotenv from "dotenv";

import ERC20_ABI from './abis/MyERC20.json' with { type: 'json' };
import { privateKeyToAccount } from "viem/accounts";
dotenv.config();

const ERC20_ADDRESS = "0xC3310c7E1CA7a494D494C6B55BedADD19C6D4fc8";

const main = async () => {
    // 创建一个公共客户端
    const publicClient = createPublicClient({
        chain: sepolia,
        transport: http(process.env.SEPOLIA_RPC_URL!),
    }).extend(publicActions);

    const blockNumber = await publicClient.getBlockNumber();
    console.log(`The block number is ${blockNumber}`);

    // 创建钱包客户端
    const account1 = privateKeyToAccount(
        process.env.SEPOLIA_PRIVATE_KEY1! as `0x${string}`
    );

    const walletClient1 = createWalletClient({
        account: account1,
        chain: sepolia,
        transport: http(process.env.SEPOLIA_RPC_URL!),
    }).extend(publicActions);

    const address1 = await walletClient1.getAddresses();
    console.log(`The wallet1 address is ${address1}`);

    // 创建钱包客户端
    const account2 = privateKeyToAccount(
        process.env.SEPOLIA_PRIVATE_KEY2! as `0x${string}`
    );

    const walletClient2 = createWalletClient({
        account: account2,
        chain: sepolia,
        transport: http(process.env.SEPOLIA_RPC_URL!),
    }).extend(publicActions);

    const address2 = await walletClient2.getAddresses();
    console.log(`The wallet2 address is ${address2}`);

    // 创建合约客户端
    const erc20Contract = getContract({
        address: ERC20_ADDRESS,
        abi: ERC20_ABI,
        client: {
            public: publicClient,
            wallet: walletClient1,
        },
    });

    // 读取合约的totalSupply方法
    const totalSupply = await erc20Contract.read.totalSupply();
    console.log(`The total supply is ${totalSupply}`);

    // 读取合约的balanceOf方法
    const balance1 = await erc20Contract.read.balanceOf([address1.toString()]);
    console.log(`The balance of wallet1 is ${balance1}`);

    // 读取合约的balanceOf方法
    const balance2 = await erc20Contract.read.balanceOf([address2.toString()]);
    console.log(`The balance of wallet2 is ${balance2}`);

    // 调用合约的transfer方法
    const tx = await erc20Contract.write.transfer([
        address2.toString(),
        parseEther("800"),
    ]);
    console.log(` 调用 transfer 方法的 transaction hash is ${tx}`);
    // 等待交易被确认
    const receipt = await publicClient.waitForTransactionReceipt({ hash: tx });
    console.log(`交易状态: ${receipt.status === 'success' ? '成功' : '失败'}`);

    // 读取合约的balanceOf方法
    const balance1After = await erc20Contract.read.balanceOf([address1.toString()]);
    console.log(`The balance of wallet1 after transfer is ${balance1After}`);

    // 读取合约的balanceOf方法
    const balance2After = await erc20Contract.read.balanceOf([address2.toString()]);
    console.log(`The balance of wallet2 after transfer is ${balance2After}`);

    // 创建合约客户端
    const erc20Contract2 = getContract({
        address: ERC20_ADDRESS,
        abi: ERC20_ABI,
        client: {
            public: publicClient,
            wallet: walletClient2,
        },
    });

    const tx2 = await erc20Contract2.write.transfer([
        address1.toString(),
        parseEther("900"),
    ]);
    console.log(` 调用 transfer 方法的 transaction hash is ${tx2}`);
    // 等待交易被确认
    const receipt2 = await publicClient.waitForTransactionReceipt({ hash: tx2 });
    console.log(`交易状态: ${receipt2.status === 'success' ? '成功' : '失败'}`);

    // 读取合约的balanceOf方法
    const balance1After1 = await erc20Contract2.read.balanceOf([address1.toString()]);
    console.log(`The balance of wallet1 after transfer is ${balance1After1}`);

    // 读取合约的balanceOf方法
    const balance2After2 = await erc20Contract2.read.balanceOf([address2.toString()]);
    console.log(`The balance of wallet2 after transfer is ${balance2After2}`);
};

main();