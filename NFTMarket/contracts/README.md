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

## 合约测试
```bash
# 测试NFTMarket合约
forge test ./test/NFTMarket.t.sol -vv
```

## 生成Gas报告
```bash
# 生成NFTMarket合约的Gas报告
forge test ./test/NFTMarket.t.sol -vv --gas-report

# 生成Gas snapshot，并保存到 NFTMarket.gas-snapshot 文件
forge snapshot ./test/NFTMarket.t.sol --snap ./gas_reports/NFTMarket.gas-snapshot

# 对比当前Gas消耗与snapshot中的数据
forge snapshot ./test/NFTMarket.t.sol --diff .\gas_reports\NFTMarket.gas-snapshot
# 输出
# PS E:\web3_workspace\denglian-practice\NFTMarket\contracts> forge snapshot ./test/NFTMarket.t.sol --diff .\gas_reports\NFTMarket.gas-snapshot
# [⠊] Compiling...
# No files changed, compilation skipped

# Ran 4 tests for test/NFTMarket.t.sol:NFTMarketTest
# [PASS] test_buy() (gas: 246084)
# [PASS] test_cancelListing() (gas: 190776)
# [PASS] test_list() (gas: 196919)
# [PASS] test_permitBuy() (gas: 329279)
# Suite result: ok. 4 passed; 0 failed; 0 skipped; finished in 3.74ms (5.58ms CPU time)

# Ran 1 test suite in 14.62ms (3.74ms CPU time): 4 tests passed, 0 failed, 0 skipped (4 total tests)
# ↓ NFTMarketTest::test_buy() (gas: 251246 → 246084 | -5162 -2.055%)
# ↓ NFTMarketTest::test_permitBuy() (gas: 336888 → 329279 | -7609 -2.259%)
# ↓ NFTMarketTest::test_list() (gas: 203237 → 196919 | -6318 -3.109%)
# ↓ NFTMarketTest::test_cancelListing() (gas: 197094 → 190776 | -6318 -3.206%)

# --------------------------------------------------------------------------------
# Total tests: 4, ↑ 0, ↓ 4, ━ 0
# Overall gas change: -25407 (-2.570%)
```