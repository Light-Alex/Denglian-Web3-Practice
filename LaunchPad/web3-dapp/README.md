# Token LaunchPad DApp

基于 Next.js 的去中心化代币发行平台（LaunchPad）Web 应用。

## 📋 目录

- [技术栈](#技术栈)
- [功能特性](#功能特性)
- [快速开始](#快速开始)
- [环境配置](#环境配置)
- [自定义和扩展](#自定义和扩展)
- [部署](#部署)

## 🛠 技术栈

- **Next.js 15** (App Router) - React 框架
- **wagmi v2** + **viem v2** - Web3 Hooks
- **RainbowKit** - 钱包连接
- **Tailwind CSS** - 样式框架

## ✨ 功能特性

### LaunchPad 核心功能

**创建销售**:
- 设置代币信息（名称、符号、价格）
- 配置销售参数（总量、开始/结束时间）
- 自动部署销售合约（EIP-1167 最小代理）

**参与购买**:
- 浏览所有销售项目
- 使用 USDC 购买代币
- 实时显示销售进度
- 销售结束后领取代币

**实时数据**:
- 已售/总量进度条
- 销售开始/结束倒计时
- 实时价格计算
- 我的购买记录

## 🚀 快速开始

```bash
# 安装依赖
npm install

# 配置环境变量
cp .env.example .env.local
# 编辑 .env.local 填入 WalletConnect Project ID

# 运行开发服务器
npm run dev
# 访问 http://localhost:3000
```

## 🔧 环境配置

创建 `.env.local`:

```bash
# WalletConnect Project ID (必需)
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=your_project_id

# LaunchPad 合约地址（已部署）
NEXT_PUBLIC_LAUNCHPAD_ADDRESS=0x0CfF6fe40c8c2c15930BFce84d27904D8a8461Cf
NEXT_PUBLIC_PAYMENT_TOKEN_ADDRESS=0x2d6BF73e7C3c48Ce8459468604fd52303A543dcD
```

获取 WalletConnect Project ID: https://cloud.walletconnect.com/

## 🔄 自定义和扩展

### 修改合约地址

更新 `.env.local` 中的地址即可，无需修改代码。

### 添加新的销售参数

在 `/app/launchpad/create/page.js` 中添加表单字段：

```javascript
const [minPurchase, setMinPurchase] = useState('')
const [maxPurchase, setMaxPurchase] = useState('')

// 在 createSale 函数中传递参数
```

### 自定义 UI 样式

修改 Tailwind 配置或直接修改组件的 className。

## 🚀 部署

### Vercel（推荐）

1. 导入项目到 Vercel
2. 设置环境变量
3. 部署

详细步骤查看 [Vercel 文档](https://vercel.com/docs)

## 📚 参考资源

- [Next.js 文档](https://nextjs.org/docs)
- [wagmi 文档](https://wagmi.sh/)
- [RainbowKit 文档](https://www.rainbowkit.com/)
- [Foundry 合约项目](../foundry-demo/)

## 📄 许可证

MIT License
