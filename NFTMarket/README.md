# NFTMarket - Web3 DAPP 教学项目

这是一个完整的NFT市场教学项目，帮助学员学习如何从零开始构建一个Web3 DAPP应用。项目包含智能合约开发、前端开发和后端API开发的完整流程。

## 项目概述

本项目在Sepolia测试网上部署，包含以下核心功能：

### 智能合约（Foundry）
- **NFTMarket.sol** - 基础版市场合约，支持NFT上架、购买、取消上架
- **NFTMarketV2.sol** - 增强版市场合约，新增出价系统、价格更新、批量上架
- **SimpleNFT.sol** - 示例ERC721合约，用于测试市场功能

### 前端应用（Next.js）
- **NFTMarket页面** - 基础市场功能界面
- **NFTMarket V2页面** - 增强市场功能界面
- **买卖记录页面** - 查看所有交易历史
- 全局钱包连接（RainbowKit）
- 响应式设计（Tailwind CSS）

## 项目结构

```
NFTMarket/
├── contracts/              # Foundry智能合约项目
│   ├── src/               # 合约源代码
│   │   ├── NFTMarket.sol
│   │   ├── NFTMarketV2.sol
│   │   └── SimpleNFT.sol
│   ├── script/            # 部署脚本
│   ├── test/              # 测试文件
│   ├── foundry.toml       # Foundry配置
│   └── .env.example       # 环境变量示例
│
├── web/                   # Next.js前端项目
│   ├── app/              # Next.js App Router
│   │   ├── page.tsx      # NFTMarket页面
│   │   ├── v2/           # NFTMarket V2页面
│   │   └── transactions/ # 买卖记录页面
│   ├── components/        # React组件
│   │   ├── Navigation.tsx
│   │   └── Web3Provider.tsx
│   ├── lib/              # 工具函数
│   │   ├── contracts.ts  # 合约地址管理
│   │   └── wagmi.ts      # Wagmi配置
│   ├── contracts/        # 合约ABI文件
│   └── .env.example      # 环境变量示例
│
└── README.md             # 本文件
```

## 快速开始

### 前置要求

- Node.js 20+
- pnpm/npm/yarn
- Foundry（用于智能合约开发）
- MetaMask或其他Web3钱包

### 1. 克隆项目

```bash
git clone <your-repo-url>
cd NFTMarket
```

### 2. 部署智能合约

```bash
cd contracts

# 安装依赖
forge install

# 配置环境变量
cp .env.example .env
# 编辑 .env 文件，填入你的私钥和RPC URL

# 编译合约
forge build

# 部署到Sepolia测试网
forge script script/Deploy.s.sol:DeployScript --rpc-url sepolia --broadcast --verify

# 导出ABI到前端项目
cat out/NFTMarket.sol/NFTMarket.json | jq .abi > ../web/contracts/NFTMarket.json
cat out/NFTMarketV2.sol/NFTMarketV2.json | jq .abi > ../web/contracts/NFTMarketV2.json
cat out/SimpleNFT.sol/SimpleNFT.json | jq .abi > ../web/contracts/SimpleNFT.json
```

### 3. 配置前端

```bash
cd ../web

# 安装依赖
npm install

# 配置环境变量
cp .env.example .env.local
# 编辑 .env.local，填入：
# 1. WalletConnect Project ID（从 https://cloud.walletconnect.com/ 获取）
# 2. 部署的合约地址

# 启动开发服务器
npm run dev
```

访问 http://localhost:3000 查看应用。

## 学员替换指南

本项目是一个模板，学员可以按照以下步骤替换为自己的实现：

### 替换智能合约

1. **修改合约代码**
   - 编辑 `contracts/src/` 目录下的合约文件
   - 添加或修改业务逻辑

2. **更新部署脚本**
   - 编辑 `contracts/script/Deploy.s.sol`
   - 确保部署你修改后的合约

3. **重新部署**
   ```bash
   cd contracts
   forge build
   forge script script/Deploy.s.sol:DeployScript --rpc-url sepolia --broadcast --verify
   ```

4. **导出新的ABI**
   ```bash
   cat out/YourContract.sol/YourContract.json | jq .abi > ../web/contracts/YourContract.json
   ```

### 替换前端代码

1. **更新合约地址配置**
   - 编辑 `web/lib/contracts.ts`
   - 填入新部署的合约地址

2. **修改页面组件**
   - 编辑 `web/app/` 目录下的页面文件
   - 实现你的业务逻辑和UI

3. **添加新的合约交互**
   - 使用 `wagmi` 的 hooks（如 `useWriteContract`, `useReadContract`）
   - 导入新的合约ABI

示例：
```typescript
import { useWriteContract } from 'wagmi';
import YourContractABI from '@/contracts/YourContract.json';
import { getContractAddress } from '@/lib/contracts';

const { writeContract } = useWriteContract();

// 调用合约函数
writeContract({
  address: getContractAddress(chainId, 'YourContract'),
  abi: YourContractABI,
  functionName: 'yourFunction',
  args: [arg1, arg2],
});
```

### 替换合约ABI

1. 部署新合约后，导出ABI：
   ```bash
   cd contracts
   cat out/YourContract.sol/YourContract.json | jq .abi > ../web/contracts/YourContract.json
   ```

2. 在前端导入新的ABI：
   ```typescript
   import YourContractABI from '@/contracts/YourContract.json';
   ```

## 核心功能说明

### NFTMarket（基础版）

- **上架NFT** - `listNFT(address, uint256, uint256)`
- **购买NFT** - `buyNFT(uint256)`
- **取消上架** - `cancelListing(uint256)`
- **手续费率** - 默认2.5%，可由管理员调整

### NFTMarket V2（增强版）

除了基础功能外，还包括：

- **出价系统** - `makeOffer(uint256, uint256)` / `acceptOffer(uint256, uint256)` / `cancelOffer(uint256, uint256)`
- **更新价格** - `updatePrice(uint256, uint256)`
- **批量上架** - `batchListNFTs(address, uint256[], uint256[])`
- **出价过期机制** - 设置出价有效期

## 环境变量配置

### 智能合约（contracts/.env）

```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
PRIVATE_KEY=your_private_key_here
ETHERSCAN_API_KEY=your_etherscan_api_key_here
```

### 前端（web/.env.local）

```env
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_walletconnect_project_id
NEXT_PUBLIC_NFT_MARKET_ADDRESS=deployed_nftmarket_address
NEXT_PUBLIC_SIMPLE_NFT_ADDRESS=deployed_simplenft_address
```

## 测试网资源

- **Sepolia Faucet**:
  - https://sepoliafaucet.com/
  - https://faucet.sepolia.dev/

- **Sepolia Etherscan**: https://sepolia.etherscan.io/

- **WalletConnect Cloud**: https://cloud.walletconnect.com/

## 技术栈

### 智能合约
- Solidity ^0.8.24
- Foundry
- OpenZeppelin Contracts

### 前端
- Next.js 15
- React 19
- TypeScript
- Tailwind CSS
- Wagmi
- Viem
- RainbowKit
- TanStack Query

## 常见问题

### 1. 合约部署失败

**问题**: `insufficient funds` 错误
**解决**: 确保你的钱包有足够的Sepolia ETH

### 2. 前端连接不上钱包

**问题**: WalletConnect报错
**解决**: 检查 `NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID` 是否正确配置

### 3. 合约调用失败

**问题**: 交易回滚
**解决**:
- 检查是否授权了市场合约（NFT的approve）
- 检查合约地址是否正确
- 查看Etherscan上的错误信息

### 4. ABI导入错误

**问题**: 找不到合约函数
**解决**: 确保重新编译合约后导出了最新的ABI文件

## 学习资源

- [Solidity文档](https://docs.soliditylang.org/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Next.js文档](https://nextjs.org/docs)
- [Wagmi文档](https://wagmi.sh/)
- [OpenZeppelin文档](https://docs.openzeppelin.com/)

## 贡献指南

欢迎提交Issue和Pull Request！

## 许可证

MIT License
