# viem_tutorial

 

## 环境配置
0. 使用 node.js 22:
```
nvm use 22 
```

1. 安装依赖：
```bash
cd viem_demo
pnpm install
```

2. 配置环境变量：
复制 env_sample 为 `.env` 并修改：

```
PRIVATE_KEY=你的私钥
RPC_URL=你的 RPC 节点地址
```

3. 运行：

运行脚本： `npm run index` 或 `pnpm index`


## 代码模块说明

## 代码模块说明

### 1. 基础示例 (index.ts)
演示 viem 的基础功能：
- 账户创建和管理
- 网络连接配置
- 基础交易操作

### 2. 原始交易构建 (build_raw_tx.js)
演示如何构建和发送原始交易：
- 手动构建 EIP-1559 类型交易
- 使用 `prepareTransactionRequest` 准备交易
- 支持交易签名和广播
- 包含交易确认等待

### 3. ERC20 代币操作 (weth.ts)
演示 ERC20 代币相关操作：
- 代币余额查询
- 代币转账
- 代币授权

### 4. 事件监听 (watchTransfer.ts)
演示如何监听区块链事件：
- 监听 ERC20 Transfer 事件
- 实时事件处理
- 使用 ABI 解析事件数据

例如，监听NFTMarket合约事件：
```shell
# 监听NFTMarket合约事件
npm run watchNFTMarket
```

```shell
# 进行NFT上架、买卖操作
npm run NFTMarketOperate
```

NFTMarketOperate日志打印：
```shell
> viem_tutorial@1.0.0 NFTMarketOperate
> tsc && node dist/NFTMarketOperate.js

The block number is 20
The balance of 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 is 9999.987082646019883485
The balance of 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 is 10000
The wallet 1 address is 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
The wallet 2 address is 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
MyToken 合约的 symbol 是 MTK
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 balance is 9999990000 MTK
0x70997970C51812dc3A010C7d01b50e0d17dc79C8 balance is 10000 MTK
 调用 transfer 方法的 transaction hash is 0x747aba07c7cb0011e641245d05a4e5767f0ac97adf334c665ee15d3d2a4b3267
交易状态: 成功
[
  {
    address: '0x8a791620dd6260079bf849dc5567adc3f2fdc318',
    topics: [
      '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef',
      '0x000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266',
      '0x00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8'
    ],
    data: '0x00000000000000000000000000000000000000000000021e19e0c9bab2400000',
    blockHash: '0x8f6441a1429af0281387d67dd868e4b8b0e0342df1e9285697a24b387dc3aa58',
    blockNumber: 21n,
    blockTimestamp: 1766999805n,
    transactionHash: '0x747aba07c7cb0011e641245d05a4e5767f0ac97adf334c665ee15d3d2a4b3267',
    transactionIndex: 0,
    logIndex: 0,
    removed: false
  }
]
转账事件详情:
从: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
到: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
金额: 10000
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 balance is 9999980000 MTK
0x70997970C51812dc3A010C7d01b50e0d17dc79C8 balance is 20000 MTK
 调用 mint 方法的 transaction hash is 0xa00208e93998249409e37c21e0aacf81a91962c32c9d83f7a365d8ba249813cb
交易状态: 成功
Token 0 的所有者是 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
从: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
到: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
金额: 10000
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 balance is 9999980000 MTK
0x70997970C51812dc3A010C7d01b50e0d17dc79C8 balance is 20000 MTK
 调用 mint 方法的 transaction hash is 0xa00208e93998249409e37c21e0aacf81a91962c32c9d83f7a365d8ba249813cb
交易状态: 成功
从: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
到: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
金额: 10000
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 balance is 9999980000 MTK
0x70997970C51812dc3A010C7d01b50e0d17dc79C8 balance is 20000 MTK
从: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
到: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
金额: 10000
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 balance is 9999980000 MTK
从: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
到: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
金额: 10000
从: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
到: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
从: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
从: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
从: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
从: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
到: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
从: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
到: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
金额: 10000
金额: 10000
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 balance is 9999980000 MTK
0x70997970C51812dc3A010C7d01b50e0d17dc79C8 balance is 20000 MTK
 调用 mint 方法的 transaction hash is 0xa00208e93998249409e37c21e0aacf81a91962c32c9d83f7a365d8ba249813cb
交易状态: 成功
Token 0 的所有者是 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
 调用 approve 方法的 transaction hash is 0xc3453b3c034ac3a9e1e5f0b28561b7a68fbdb5ea4c98b4cfc3bf7367dcd62e46
交易状态: 成功
 调用 list 方法的 transaction hash is 0x0700ac5135e5f5c457afa4fc1ccd4cc802abe233de192e8adeff5c34aab48ec1
交易状态: 成功
 调用 transferWithCallback 方法的 transaction hash is 0x668c61b313b9c441997280924b825393828a2497c1f3fcff59615915672f5f58
交易状态: 成功
0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 balance is 9999985000 MTK
0x70997970C51812dc3A010C7d01b50e0d17dc79C8 balance is 15000 MTK
Token 0 的所有者是 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

watchNFTMarket日志打印：
```shell
> viem_tutorial@1.0.0 watchNFTMarket
> tsc && node dist/watchNFTMarket.js

开始监听 NFTMarket 事件...

检测到新的NFT List事件:

检测到新的NFT List事件:
检测到新的NFT List事件:
合约地址: 0xb7f8bc63bbcad18155201308c8f3540b07f84f5e
合约地址: 0xb7f8bc63bbcad18155201308c8f3540b07f84f5e
Seller: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Seller: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Token ID: 0
Token ID: 0
Price: 5000
交易哈希: 0x2bcf26754efdc6261116fbe88d247dd9b2ff7489692cdf05dea8fde8c1a636dd
区块号: 19
Price: 5000
交易哈希: 0x2bcf26754efdc6261116fbe88d247dd9b2ff7489692cdf05dea8fde8c1a636dd
区块号: 19

检测到新的NFTPurchased事件:
区块号: 19

检测到新的NFTPurchased事件:
合约地址: 0xb7f8bc63bbcad18155201308c8f3540b07f84f5e

检测到新的NFTPurchased事件:
合约地址: 0xb7f8bc63bbcad18155201308c8f3540b07f84f5e
Buyer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
检测到新的NFTPurchased事件:
合约地址: 0xb7f8bc63bbcad18155201308c8f3540b07f84f5e
Buyer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
合约地址: 0xb7f8bc63bbcad18155201308c8f3540b07f84f5e
Buyer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Buyer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Token ID: 0
Token ID: 0
Price: 5000
交易哈希: 0xfc85429aa5c8eabaf64ea164450bdd8eff2c3473def42deaa76dc168a92a5e6a
区块号: 20

检测到新的NFT List事件:
合约地址: 0xb7f8bc63bbcad18155201308c8f3540b07f84f5e
Seller: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
Token ID: 0
Price: 5000
交易哈希: 0x0700ac5135e5f5c457afa4fc1ccd4cc802abe233de192e8adeff5c34aab48ec1
区块号: 24

检测到新的NFTPurchased事件:
合约地址: 0xb7f8bc63bbcad18155201308c8f3540b07f84f5e
Buyer: 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
Token ID: 0
Price: 5000
交易哈希: 0x668c61b313b9c441997280924b825393828a2497c1f3fcff59615915672f5f58
区块号: 25
```
 
## 注意事项
1. 确保账户有足够的 ETH 支付 gas 费用
2. 使用正确的网络配置（Sepolia/Foundry）
3. 妥善保管私钥，不要泄露
4. 建议在测试网络上进行测试