# NFTMarket 智能合约

本目录包含NFT市场的智能合约代码，使用Foundry开发框架。

## 合约说明

### SimpleNFT.sol
简单的ERC721 NFT合约，用于测试市场功能。

### NFTMarket.sol
基础版本的NFT市场合约。

**功能：** NFT上架、购买、取消上架、手续费机制

### NFTMarketV2.sol
增强版本的NFT市场合约。

**功能：** 所有NFTMarket的功能 + 出价系统 + 更新价格 + 批量上架

## 开发环境设置

### 1. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件填入你的配置
```

### 2. 编译合约

```bash
forge build
```

### 3. 部署合约

```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url sepolia --broadcast --verify
```

## 导出ABI

导出合约ABI用于前端集成：

```bash
cat out/NFTMarket.sol/NFTMarket.json | jq .abi > ../web/src/contracts/NFTMarket.json
cat out/NFTMarketV2.sol/NFTMarketV2.json | jq .abi > ../web/src/contracts/NFTMarketV2.json
cat out/SimpleNFT.sol/SimpleNFT.json | jq .abi > ../web/src/contracts/SimpleNFT.json
```

## 学员替换指南

1. 修改 `src/` 目录下的合约文件
2. 更新 `script/Deploy.s.sol` 部署脚本
3. 重新编译: `forge build`
4. 部署新合约并导出ABI
