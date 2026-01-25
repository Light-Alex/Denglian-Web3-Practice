# Learn-DeFi-Project - DApp 开发学习模板

这是一个完整的 DeFi DApp 项目模板，包含智能合约和前端应用，适合学习区块链应用开发。

## 项目结构

```
Learn-DeFi-Project/
├── foundry-demo/          # Solidity 智能合约（Foundry）
│   ├── src/               # 合约源代码
│   ├── script/            # 部署脚本
│   ├── test/              # 合约测试
│   ├── out/               # 编译输出
│   └── .env               # 环境变量（合约）
│
└── web3-dapp/             # Next.js 前端应用
    ├── app/               # 页面路由
    ├── components/        # React 组件
    ├── lib/               # 工具库
    │   ├── abis/          # 合约 ABI
    │   └── constants/     # 常量配置
    └── .env               # 环境变量（前端）
```

## 快速开始

### 1. 安装合约开发环境

#### 安装 Foundry

```bash
# macOS / Linux
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Windows (使用 WSL)
# 先安装 WSL，然后执行上面的命令
```

验证安装：
```bash
forge --version
cast --version
```

#### 配置合约环境变量

```bash
cd foundry-demo
cp .env.example .env  # 如果没有 .env.example，请手动创建
```

编辑 `foundry-demo/.env` 文件：
```bash
# 你的私钥（注意安全！）
PRIVATE_KEY=你的私钥

# Etherscan API Key（用于合约验证）
ETHERSCAN_API_KEY=你的Etherscan_API_Key

# Sepolia 测试网 RPC URL
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/你的Infura_Project_ID

# 已部署的合约地址
REWARD_TOKEN_ADDRESS=0x...
TOKEN_A_ADDRESS=0x...
TOKEN_B_ADDRESS=0x...
PAYMENT_TOKEN_ADDRESS=0x...
SWAP_ADDRESS=0x...
STAKE_POOL_ADDRESS=0x...
FARM_ADDRESS=0x...
LAUNCHPAD_ADDRESS=0x...
MEME_FACTORY_ADDRESS=0x...
```

### 2. 安装前端开发环境

#### 安装 Node.js

访问 [Node.js 官网](https://nodejs.org/) 下载并安装 LTS 版本（推荐 18.x 或更高版本）

验证安装：
```bash
node --version
npm --version
```

#### 安装前端依赖

```bash
cd web3-dapp
npm install
```

#### 配置前端环境变量

```bash
cp .env.example .env  # 如果没有 .env.example，请手动创建
```

编辑 `web3-dapp/.env` 文件：
```bash
# 合约地址（与 foundry-demo/.env 保持一致）
NEXT_PUBLIC_REWARD_TOKEN_ADDRESS=0x...
NEXT_PUBLIC_TOKEN_A_ADDRESS=0x...
NEXT_PUBLIC_TOKEN_B_ADDRESS=0x...
NEXT_PUBLIC_PAYMENT_TOKEN_ADDRESS=0x...
NEXT_PUBLIC_SWAP_ADDRESS=0x...
NEXT_PUBLIC_STAKE_POOL_ADDRESS=0x...
NEXT_PUBLIC_FARM_ADDRESS=0x...
NEXT_PUBLIC_LAUNCHPAD_ADDRESS=0x...
NEXT_PUBLIC_TOKEN_FACTORY_ADDRESS=0x...
NEXT_PUBLIC_MEME_FACTORY_ADDRESS=0x...
```

### 3. 运行项目

#### 编译合约

```bash
cd foundry-demo
forge build
```

#### 运行前端

```bash
cd web3-dapp
npm run dev
```

访问 http://localhost:3000

## 替换合约代码指南

### 1. 编写新合约

在 `foundry-demo/src/` 目录下创建或修改合约：

```solidity
// foundry-demo/src/YourContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract YourContract {
    // 你的合约代码
}
```

### 2. 编写部署脚本

在 `foundry-demo/script/` 目录下创建部署脚本：

```solidity
// foundry-demo/script/DeployYourContract.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/YourContract.sol";

contract DeployYourContract is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        YourContract yourContract = new YourContract();

        console.log("YourContract deployed to:", address(yourContract));

        vm.stopBroadcast();
    }
}
```

### 3. 编译合约

```bash
cd foundry-demo
forge build
```

### 4. 部署合约

```bash
# 部署到 Sepolia 测试网
forge script script/DeployYourContract.s.sol:DeployYourContract \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

部署成功后，记录合约地址。

### 5. 更新环境变量

在 `foundry-demo/.env` 中添加：
```bash
YOUR_CONTRACT_ADDRESS=0x部署后的合约地址
```

在 `web3-dapp/.env` 中添加：
```bash
NEXT_PUBLIC_YOUR_CONTRACT_ADDRESS=0x部署后的合约地址
```

## 替换合约 ABI 指南

### 1. 提取合约 ABI

编译后的 ABI 位于 `foundry-demo/out/YourContract.sol/YourContract.json`

提取 ABI：
```bash
cd foundry-demo
cat out/YourContract.sol/YourContract.json | jq '.abi' > /tmp/your_contract_abi.json
```

### 2. 创建 ABI 文件

在前端项目中创建 ABI 文件：

```javascript
// web3-dapp/lib/abis/yourContract.js
export const YOUR_CONTRACT_ABI = [
  // 从 /tmp/your_contract_abi.json 复制粘贴 ABI 内容
  {
    "type": "function",
    "name": "yourFunction",
    "inputs": [...],
    "outputs": [...],
    "stateMutability": "view"
  },
  // ... 更多 ABI 内容
]
```

### 3. 导出 ABI（可选）

如果需要在多个地方使用，可以在 `lib/abis/index.js` 中统一导出：

```javascript
// web3-dapp/lib/abis/index.js
export { YOUR_CONTRACT_ABI } from './yourContract'
export { LAUNCHPAD_ABI } from './launchpad'
// ... 其他 ABI
```

## 统一替换合约地址

### 方式 1: 使用环境变量（推荐）

#### 更新环境变量文件

```bash
# 更新 web3-dapp/.env
NEXT_PUBLIC_YOUR_CONTRACT_ADDRESS=0x新的合约地址
```

#### 在代码中使用

```javascript
const contractAddress = process.env.NEXT_PUBLIC_YOUR_CONTRACT_ADDRESS
```

### 方式 2: 使用配置文件

#### 更新地址配置

编辑 `web3-dapp/lib/constants/addresses.js`:

```javascript
import { sepolia } from 'wagmi/chains'

export const PROTOCOL_ADDRESSES = {
  [sepolia.id]: {
    SWAP: process.env.NEXT_PUBLIC_SWAP_ADDRESS,
    STAKE_POOL: process.env.NEXT_PUBLIC_STAKE_POOL_ADDRESS,
    // 添加你的合约地址
    YOUR_CONTRACT: process.env.NEXT_PUBLIC_YOUR_CONTRACT_ADDRESS || '0x默认地址',
  },
}

// 辅助函数：获取协议合约地址
export function getProtocolAddress(chainId, protocol) {
  return PROTOCOL_ADDRESSES[chainId]?.[protocol]
}
```

#### 在组件中使用

```javascript
import { getProtocolAddress } from '@/lib/constants/addresses'
import { useChainId } from 'wagmi'

function YourComponent() {
  const chainId = useChainId()
  const contractAddress = getProtocolAddress(chainId, 'YOUR_CONTRACT')

  // 使用合约地址...
}
```

### 批量替换地址（脚本方式）

创建替换脚本 `scripts/update-addresses.sh`:

```bash
#!/bin/bash

# 定义新地址
NEW_SWAP_ADDRESS="0x新地址"
NEW_LAUNCHPAD_ADDRESS="0x新地址"

# 替换 foundry-demo/.env
sed -i '' "s/SWAP_ADDRESS=.*/SWAP_ADDRESS=$NEW_SWAP_ADDRESS/" foundry-demo/.env
sed -i '' "s/LAUNCHPAD_ADDRESS=.*/LAUNCHPAD_ADDRESS=$NEW_LAUNCHPAD_ADDRESS/" foundry-demo/.env

# 替换 web3-dapp/.env
sed -i '' "s/NEXT_PUBLIC_SWAP_ADDRESS=.*/NEXT_PUBLIC_SWAP_ADDRESS=$NEW_SWAP_ADDRESS/" web3-dapp/.env
sed -i '' "s/NEXT_PUBLIC_LAUNCHPAD_ADDRESS=.*/NEXT_PUBLIC_LAUNCHPAD_ADDRESS=$NEW_LAUNCHPAD_ADDRESS/" web3-dapp/.env

echo "✅ 地址更新完成"
```

使用：
```bash
chmod +x scripts/update-addresses.sh
./scripts/update-addresses.sh
```

## 替换前端页面指南

### 1. 创建新页面

在 `web3-dapp/app/` 目录下创建新的页面路由：

```
web3-dapp/app/
└── your-page/          # 新页面目录
    └── page.js         # 页面组件
```

创建页面组件：

```javascript
// web3-dapp/app/your-page/page.js
'use client'

import { useAccount, useReadContract, useWriteContract } from 'wagmi'
import { YOUR_CONTRACT_ABI } from '@/lib/abis/yourContract'

export default function YourPage() {
  const { address } = useAccount()
  const contractAddress = process.env.NEXT_PUBLIC_YOUR_CONTRACT_ADDRESS

  // 读取合约数据
  const { data: contractData } = useReadContract({
    address: contractAddress,
    abi: YOUR_CONTRACT_ABI,
    functionName: 'yourReadFunction',
    args: [],
  })

  // 写入合约
  const { writeContract, isPending } = useWriteContract()

  const handleSubmit = () => {
    writeContract({
      address: contractAddress,
      abi: YOUR_CONTRACT_ABI,
      functionName: 'yourWriteFunction',
      args: [/* 参数 */],
    })
  }

  return (
    <div className="container py-12">
      <h1>Your Page</h1>
      {/* 你的页面内容 */}
    </div>
  )
}
```

访问: http://localhost:3000/your-page

### 2. 修改现有页面

直接编辑对应的页面文件：

```
web3-dapp/app/
├── launchpad/          # Launchpad 页面
│   ├── page.js         # 列表页
│   └── create/
│       └── page.js     # 创建页
├── swap/               # Swap 页面
│   └── page.js
├── stake/              # Stake 页面
│   └── page.js
└── farm/               # Farm 页面
    └── page.js
```

### 3. 添加导航链接

编辑导航组件（如果有）或在页面中添加链接：

```javascript
// web3-dapp/components/Navigation.js
import Link from 'next/link'

export default function Navigation() {
  return (
    <nav>
      <Link href="/">首页</Link>
      <Link href="/launchpad">Launchpad</Link>
      <Link href="/swap">Swap</Link>
      <Link href="/your-page">Your Page</Link>
    </nav>
  )
}
```

### 4. 使用组件

创建可复用组件：

```javascript
// web3-dapp/components/YourComponent.js
export default function YourComponent({ data }) {
  return (
    <div className="bg-white rounded-lg shadow p-6">
      {/* 组件内容 */}
    </div>
  )
}
```

在页面中使用：

```javascript
import YourComponent from '@/components/YourComponent'

export default function YourPage() {
  return (
    <div>
      <YourComponent data={someData} />
    </div>
  )
}
```

## 项目功能模块

### 已实现的合约

1. **Swap** - 简单的代币交换合约
2. **StakePool** - 质押挖矿合约
3. **Farm** - 流动性挖矿合约
4. **LaunchPad** - 代币发行平台
   - 传统 Launchpad: 标准代币销售
   - Meme Factory: 最小代理部署，自动 Uniswap 流动性
5. **TokenFactory** - ERC20 代币工厂

### 前端页面

- `/` - 首页
- `/launchpad` - Launchpad 列表页
- `/launchpad/create` - 创建代币销售（支持传统/Meme两种模式）
- `/swap` - 代币交换页面
- `/stake` - 质押页面
- `/farm` - 流动性挖矿页面

## 开发技巧

### 1. 调试合约

```bash
# 运行测试
forge test

# 运行特定测试
forge test --match-test testYourFunction

# 详细输出
forge test -vvvv

# 生成 Gas 报告
forge test --gas-report
```

### 2. 与合约交互（使用 cast）

```bash
# 读取合约数据
cast call 0x合约地址 "balanceOf(address)(uint256)" 0x用户地址 --rpc-url $SEPOLIA_RPC_URL

# 发送交易
cast send 0x合约地址 "transfer(address,uint256)" 0x接收地址 100 --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL

# 查看交易
cast tx 0x交易哈希 --rpc-url $SEPOLIA_RPC_URL
```

### 3. 前端开发

```bash
# 开发模式（热重载）
npm run dev

# 构建生产版本
npm run build

# 启动生产服务器
npm start

# 代码检查
npm run lint
```

### 4. 常见问题

#### Q: 合约部署失败？
A: 检查：
- 私钥是否正确
- RPC URL 是否有效
- 账户是否有足够的测试币
- Gas 限制是否足够

#### Q: 前端连接不上合约？
A: 检查：
- 环境变量是否配置正确
- 合约地址是否正确
- ABI 是否最新
- MetaMask 是否连接到正确的网络

#### Q: 如何获取测试币？
A:
- Sepolia: https://sepoliafaucet.com/
- 其他测试网: 搜索 "[网络名] faucet"

## 部署到生产环境

### 1. 部署到主网

**警告**: 主网部署涉及真实资金，请务必：
- 完整测试所有功能
- 审计智能合约代码
- 使用硬件钱包
- 分批部署降低风险

```bash
# 部署到主网（以 Ethereum 为例）
forge script script/DeployYourContract.s.sol:DeployYourContract \
  --rpc-url $MAINNET_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

### 2. 部署前端

```bash
# 构建
cd web3-dapp
npm run build

# 部署到 Vercel（推荐）
npm install -g vercel
vercel

# 或部署到其他平台（Netlify、AWS 等）
```

## 学习资源

### 智能合约开发
- [Solidity 官方文档](https://docs.soliditylang.org/)
- [Foundry 文档](https://book.getfoundry.sh/)
- [OpenZeppelin 合约库](https://docs.openzeppelin.com/contracts/)

### 前端开发
- [Next.js 文档](https://nextjs.org/docs)
- [Wagmi 文档](https://wagmi.sh/)
- [Viem 文档](https://viem.sh/)
- [TailwindCSS 文档](https://tailwindcss.com/docs)

### DeFi 协议
- [Uniswap 文档](https://docs.uniswap.org/)
- [Aave 文档](https://docs.aave.com/)
- [Compound 文档](https://docs.compound.finance/)

## 贡献指南

欢迎贡献！请遵循以下步骤：

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 许可证

MIT License

## 联系方式

如有问题，欢迎提 Issue 或 Pull Request。
