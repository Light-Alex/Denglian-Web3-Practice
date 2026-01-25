# Foundry DeFi Project - LaunchPad Module

基于 Foundry 的 Token 销售平台（LaunchPad）智能合约项目。

## 📋 目录

- [技术栈](#技术栈)
- [LaunchPad 模块](#launchpad-模块)
- [快速开始](#快速开始)
- [部署指南](#部署指南)
- [测试](#测试)
- [自定义指南](#自定义指南)

## 🛠 技术栈

- **Foundry** - 以太坊开发工具链
- **Solidity 0.8.20** - 智能合约语言
- **OpenZeppelin** - 安全合约库

## 🚀 LaunchPad 模块

### 概述

LaunchPad 是一个代币销售平台，支持项目方发起代币销售，用户参与购买。

### 核心功能

**传统 LaunchPad (LaunchPad.sol)**:
- 创建代币销售（设置价格、数量、时间）
- 用户使用 USDC 购买代币
- 销售结束后领取购买的代币
- 实时进度跟踪

**增强版 LaunchPad (LaunchPadV2.sol)**:
- 支持 EIP-1167 最小代理模式部署
- 节省 Gas 费用
- 支持多个销售项目同时进行
- 灵活的销售参数配置

### 已部署合约

#### Sepolia 测试网

| 合约 | 地址 |
|------|------|
| LaunchPadV2 | `0x0CfF6fe40c8c2c15930BFce84d27904D8a8461Cf` |
| PaymentToken (USDC) | `0x2d6BF73e7C3c48Ce8459468604fd52303A543dcD` |

### 合约说明

**LaunchPad.sol**:
- 基础版本的代币销售合约
- 适合单一项目销售
- 简单易懂，适合学习

**LaunchPadV2.sol**:
- 工厂模式，支持创建多个销售
- 使用 EIP-1167 克隆模式节省 Gas
- 生产级实现

**PaymentToken.sol**:
- ERC20 标准的支付代币
- 用于购买 LaunchPad 上的代币
- 模拟 USDC

## 🚀 快速开始

### 前置要求

- **Foundry** - 安装: `curl -L https://foundry.paradigm.xyz | bash && foundryup`
- **钱包私钥** - 用于部署
- **测试网 ETH** - Sepolia 测试币

### 安装

```bash
# 克隆项目
git clone <your-repo-url>
cd foundry-demo

# 安装依赖
forge install

# 配置环境变量
cp .env.example .env
# 编辑 .env 填入私钥
```

### 环境变量配置

创建 `.env` 文件:

```bash
# 私钥 (不要提交到 Git!)
PRIVATE_KEY=your_private_key_here

# RPC URLs
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY

# Etherscan API Key (用于验证合约)
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## 📖 部署指南

### 方法 1: 部署 LaunchPadV2 (推荐)

```bash
forge script script/DeployLaunchPadV2.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

**输出**:
- LaunchPadV2: `0x0CfF6fe40c8c2c15930BFce84d27904D8a8461Cf`
- PaymentToken: `0x2d6BF73e7C3c48Ce8459468604fd52303A543dcD`

### 方法 2: 自定义部署

**步骤 1**: 部署 PaymentToken

```bash
forge create src/PaymentToken.sol:PaymentToken \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --verify
```

**步骤 2**: 部署 LaunchPadV2

```bash
forge create src/LaunchPadV2.sol:LaunchPadV2 \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --constructor-args <PAYMENT_TOKEN_ADDRESS> \
  --verify
```

## 🧪 测试

### 编译合约

```bash
forge build
```

### 运行测试

```bash
forge test
```

### Gas 报告

```bash
forge test --gas-report
```

## 🔧 自定义指南

### 修改支付代币

**文件**: `src/LaunchPadV2.sol`

```solidity
// 修改构造函数中的 paymentToken
constructor(address _paymentToken) {
    paymentToken = IERC20(_paymentToken);
}
```

### 修改销售参数

创建销售时设置参数:

```solidity
function createSale(
    address saleToken,
    uint256 price,        // 价格 (1 token = ? USDC)
    uint256 totalAmount,  // 总销售数量
    uint256 startTime,    // 开始时间
    uint256 endTime       // 结束时间
) external;
```

### 添加白名单功能

在 `LaunchPadV2.sol` 中添加:

```solidity
mapping(uint256 => mapping(address => bool)) public whitelist;

modifier onlyWhitelisted(uint256 saleId) {
    require(whitelist[saleId][msg.sender], "Not whitelisted");
    _;
}

function buy(uint256 saleId, uint256 amount) 
    external 
    onlyWhitelisted(saleId) 
{
    // 购买逻辑
}
```

### 添加最小/最大购买限制

```solidity
struct Sale {
    // ... 现有字段
    uint256 minPurchase;
    uint256 maxPurchase;
}

function buy(uint256 saleId, uint256 amount) external {
    Sale storage sale = sales[saleId];
    require(amount >= sale.minPurchase, "Below minimum");
    require(amount <= sale.maxPurchase, "Above maximum");
    // ... 购买逻辑
}
```

## 💰 Gas 费用估算

| 操作 | Gas (Sepolia) | 费用 (Gwei=50) |
|------|---------------|----------------|
| Deploy LaunchPadV2 | ~800,000 | ~0.04 ETH |
| Deploy PaymentToken | ~600,000 | ~0.03 ETH |
| Create Sale | ~200,000 | ~0.01 ETH |
| Buy Tokens | ~100,000 | ~0.005 ETH |
| Claim Tokens | ~80,000 | ~0.004 ETH |

**总计**: 约 0.07 ETH (首次部署) + 0.01 ETH (每次创建销售)

## 🐛 故障排除

### 问题 1: 编译错误

**错误**: `Compiler version not found`

**解决方案**:
```bash
# 安装 Solidity 0.8.20
foundryup --version 0.8.20
```

### 问题 2: 部署失败

**错误**: `insufficient funds`

**解决方案**:
- 确保钱包有足够的 Sepolia ETH
- 从水龙头获取: https://sepoliafaucet.com/

### 问题 3: 验证失败

**错误**: `Contract verification failed`

**解决方案**:
```bash
# 手动验证
forge verify-contract \
  <CONTRACT_ADDRESS> \
  src/LaunchPadV2.sol:LaunchPadV2 \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

## 📚 参考资源

- **Foundry Book**: https://book.getfoundry.sh/
- **OpenZeppelin Contracts**: https://docs.openzeppelin.com/contracts/
- **Sepolia Faucet**: https://sepoliafaucet.com/
- **Etherscan Sepolia**: https://sepolia.etherscan.io/

## 📄 许可证

MIT License - 免费用于教育目的。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 🙏 致谢

- Foundry 团队 - 开发工具
- OpenZeppelin - 合约库
