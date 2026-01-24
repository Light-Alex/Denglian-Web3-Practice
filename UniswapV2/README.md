# UniswapV2项目介绍
这是一个完整的Uniswap V2项目，包含了Uniswap V2合约、Uniswap V2 SDK、Uniswap V2 前端。

## 目录

- [什么是 Uniswap V2？](#什么是-uniswap-v2)
  - [核心特性](#核心特性)
    - [自动做市商（AMM）模型](#1-自动做市商amm模型)
    - [核心功能](#2-核心功能)
    - [手续费机制](#3-手续费机制)
  - [总结](#总结)
- [Uniswap V2仓库说明](#uniswap-v2仓库说明)
  - [智能合约](#智能合约)
  - [SDK](#sdk)
  - [Interface(前端)](#interface前端)
- [v2-periphery和v2-core的关系](#v2-periphery和v2-core的关系)
- [部署](#部署)
  - [代码来源](#代码来源)
  - [环境要求](#环境要求)
  - [部署过程](#部署过程)
    - [部署UniswapV2Factory合约](#部署uniswapv2factory合约)
    - [修改UniswapV2Library库中init code hash](#修改uniswapv2library库中init-code-hash)
    - [部署WETH9和Router合约](#部署weth9和router合约)
    - [部署Multicall合约](#部署multicall合约)
    - [修改SDK](#修改sdk)
    - [修改interface](#修改interface)
    - [添加tokenList](#添加tokenlist)
    - [将SDK发布到npm上](#将sdk发布到npm上)
    - [启动interface(前端)](#启动interface前端)



## 什么是 Uniswap V2？
Uniswap V2 是一个基于以太坊的去中心化交易协议，允许用户：
- 🔄 **交换代币**：无需订单簿，通过流动性池进行交易
- 💧 **提供流动性**：存入代币对以赚取交易手续费
- 🏆 **无需许可**：任何人都可以创建交易对或添加流动性

### 核心特性
#### 1. 自动做市商（AMM）模型
- 采用恒定乘积公式 `x * y = k` 确定价格
- 无需订单簿，提供持续流动性
- 流动性提供者(LP)通过提供代币对赚取交易手续费

#### 2. 核心功能
- **代币交换**: 用户可以在任何ERC20代币对之间进行交换
- **流动性提供**: 用户可以向交易池添加流动性并获得LP代币
- **流动性移除**: LP代币持有者可以移除流动性并收回底层资产
- **TWAP预言机**: 内置时间加权平均价格（TWAP）预言机功能
- **闪贷**: 支持无需抵押的闪电贷款

#### 3. 手续费机制
- 基础手续费率: 0.3%（交易金额的3/1000）
- 手续费可配置: 通过factory合约的feeTo地址开启协议手续费
- 协议手续费为流动性的1/6（即手续费的1/6）

### 总结
Uniswap V2 的恒定乘积模型（`x * y = k`）是一个精妙的、自洽的、激励兼容的系统：
1. 用数学取代中介：一个函数自动化了报价、交易和结算。
2. 用套利取代预言机：依赖外部套利者来同步价格，而非主动获取数据。
3. 用流动性池取代订单簿：LP 被动提供流动性并赚取费用，交易者直接与合约交互。
4. 内置市场机制：滑点自动惩罚大额订单，保护流动性；价格冲击自动吸引套利，回归均衡。

其底层逻辑的核心是通过一个极其简洁的数学约束，创造了一个永不停歇、由市场力量驱动的去中心化交易引擎。它牺牲了订单簿市场的复杂性和零滑点理想，换来了无需许可、抗审查和高度可组合的革命性创新，成为了 DeFi 爆发的基础设施。

## Uniswap V2仓库说明
### 智能合约
| 仓库 | 说明 | 主要合约 |
|------|------|----------|
| **v2-periphery** | 周边合约，提供用户友好接口 | `Router`, `Migrator`, `Libraries` |
| **v2-core** | 核心合约，最小化且经过严格审计 | `UniswapV2Factory`, `UniswapV2Pair` |
| **Multicall** | 多合约调用合约，用于批量调用多个合约 | `Multicall` |
| **solidity-lib** | Solidity 库合约，包含一些常用的ERC20转账相关操作 | `TransferHelper` |
| **WETH9** | Wrapped Ether 合约，用于在 Uniswap V2 中交易 ETH | `WETH9` |

### SDK
| 仓库 | 说明 |
|------|------|
| **v2-sdk** | Uniswap V2 SDK，提供与UniswapV2合约交互的 JavaScript 库 |

### Interface(前端)
| 仓库 | 说明 |
|------|------|
| **interface** | Uniswap V2 前端界面，用户可以通过该界面进行交易、提供流动性等操作 |

## v2-periphery和v2-core的关系
<img src="./imgs/uniswapv2 workflow.svg" alt="Uniswap V2 Workflow" width="800" height="auto">

- [v2-periphery项目介绍](https://github.com/Light-Alex/v2-periphery/blob/master/%E9%A1%B9%E7%9B%AE%E4%BB%8B%E7%BB%8D.md)
- [v2-core项目介绍](https://github.com/Light-Alex/v2-core/blob/master/%E9%A1%B9%E7%9B%AE%E4%BB%8B%E7%BB%8D.md)

## 部署
> 参考: [从零部署一套 Uniswap V2：合约、SDK、前端到上线完整实战](https://learnblockchain.cn/article/22732)

### 代码来源
#### 合约代码来源：
- [v2-periphery](https://github.com/Uniswap/v2-periphery)
- [v2-core](https://github.com/Uniswap/v2-core)
- [solidity-lib](https://github.com/Uniswap/solidity-lib)
- [WETH9](https://etherscan.io/address/0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2)
- [Multicall](https://cn.etherscan.com/address/0x5e227ad1969ea493b43f840cff78d08a6fc17796#code)

> 为了统一用foundry部署，本项目统一将上述合约的编译器适配到了solidity ^0.8.0版本

#### SDK代码来源：
- [v2-sdk](https://github.com/Uniswap/v2-sdk/tree/00a1eca9456d37c3d467f56e57a0496d1bf28e40)

#### Interface代码来源：
- [interface](https://github.com/Uniswap/interface/tree/b8c383c20e1a9d2cf29d8becce3e31b69219f1f8#)

### 环境要求
- solidity ^0.8.0
- foundry
- node.js v16.20.2

### 部署过程
#### 部署UniswapV2Factory合约
```bash
cd .\UniswapV2\contracts\
forge script .\script\DeployFactoryScript.s.sol --rpc-url sepolia --broadcast --verify 
```
> 注意: UniswapV2Factory合约部署完成后，需要调用合约的pair_codehash()方法，获取UniswapV2Pair合约的字节码keccak256哈希值，Router合约中提前计算UniswapV2Pair合约地址需要使用该哈希值(Create2)。

#### 修改UniswapV2Library库中init code hash
修改pairFor方法中的init code hash，将其修改为UniswapV2Factory合约部署完成后获取的pair_codehash()值。
> 注意: hash值不要带0x

#### 部署WETH9和Router合约
```bash
cd .\UniswapV2\contracts\

# 将DeployRouter02Script.s.sol脚本中UniswapV2Router02合约的factory地址修改为UniswapV2Factory合约地址

# 部署WETH9和UniswapV2Router02合约
forge script .\script\DeployRouter02Script.s.sol --rpc-url sepolia --broadcast --verify 
```

#### 部署Multicall合约
```bash
cd .\UniswapV2\contracts\
forge script .\script\DeployMuticallScript.s.sol --rpc-url sepolia --broadcast --verify 
```

#### 修改SDK
1. 修改工厂合约地址和init_code_HASH
- 修改路径: `sdk/src/constants.ts`
- 对应值:
  - `FACTORY_ADDRESS`: UniswapV2Factory合约地址
  - `INIT_CODE_HASH`: UniswapV2Factory合约部署完成后获取的pair_codehash()值

2. 修改WETH地址
修改路径: `sdk/src/entities/token.ts`
```typescript
// 添加对应链上的WETH地址, 例如: Sepolia测试网
[ChainId.SEPOLIA]: new Token(ChainId.SEPOLIA, '0xc3963f95c0E5A25da149dC9F27268DCAf294586C', 18, 'WETH', 'Wrapped Ether')
```

#### 修改interface
1. 修改路由合约地址
- 修改路径: `interface/src/constants/index.ts`
- 对应值:
  - `ROUTER_ADDRESS`: UniswapV2Router02合约地址

2. 添加Multicall合约地址
- 修改路径: `interface/src/constants/multicall/index.ts`
```typescript
// 在MULTICALL_NETWORKS中添加Sepolia测试网的Multicall合约地址
[ChainId.SEPOLIA]: '0x3c8641072159759B17e734dB10A8A705c94d15f6'
```

#### 添加tokenList
[Uniswap的tokenList格式](https://app.unpkg.com/@uniswap/default-token-list@2.0.0/files/build/uniswap-default.tokenlist.json)
```json
// 将上述内容保存到一个文件中，例如uniswap-default.tokenlist.json

// 在uniswap-default.tokenlist.json中添加Sepolia测试网的WETH、待测试的ERC20代币
{
"name": "Wrapped Ether",
"address": "0xc3963f95c0E5A25da149dC9F27268DCAf294586C",
"symbol": "WETH",
"decimals": 18,
"chainId": 11155111,
"logoURI": "ipfs://QmZhqnVhFJF5yo3A2Rsc8hqEhS18aGFrqh3baGB7JujaMN"
},
{
"name": "Token For UniswapV2",
"address": "0xc0621dAf097317778A2fF8001a3c382956a4D31B",
"symbol": "TUNI",
"decimals": 18,
"chainId": 11155111,
"logoURI": "ipfs://QmZhqnVhFJF5yo3A2Rsc8hqEhS18aGFrqh3baGB7JujaMN"
},
{
"name": "Token2 For UniswapV2",
"address": "0x2d7F38B795E1A0C4184b4833E460Aa8BeAb12f58",
"symbol": "TUNI2",
"decimals": 18,
"chainId": 11155111,
"logoURI": "ipfs://QmZhqnVhFJF5yo3A2Rsc8hqEhS18aGFrqh3baGB7JujaMN"
}
```
将修改后的uniswap-default.tokenlist.json文件上传到IPFS，获取IPFS地址，例如: ipfs://QmZhqnVhFJF5yo3A2Rsc8hqEhS18aGFrqh3baGB7JujaMN，后续Uniswap前端部署后，可通过界面导入该tokenList文件，即可在Uniswap前端中使用WETH、TUNI、TUNI2等代币了。

#### 将SDK发布到npm上
1. 修改package.json
- 修改路径: `sdk/package.json`
- 对应值:
  - `name`: `@light-alex/uniswap-v2-sdk`
  - `version`: "1.0.0"
> 发布到npm上包的名称和版本号

2. 注册登录npm账号
```bash
npm login
```
在npm网站上创建一个组，例如light-alex

3. 新增Access Token
- 在npm网站上，点击个人头像 -> Access Tokens -> 新增访问令牌
- 填写令牌名称，例如: uniswap-v2-sdk
- 选择令牌权限: 读写
- 点击生成令牌
- 复制生成的令牌，后续发布到npm上需要使用该令牌

4. 设置Access Token
```bash
npm set //registry.npmjs.org/:_authToken=你的token

# 查看登入是否成功
npm whoami
```

5. 发布SDK到npm
```bash
cd sdk
npm publish --access public
```

#### 启动interface(前端)
1. 安装依赖包
将package.json中的@light-uniswap/sdk包替换成自己上传到npm上的包。

```bash
# 安装依赖包
cd interface
npm install
```
> 注意: 如果后续npm start启动后，登录界面未显示任何内容，可能是i18next和react-i18next的版本有误，需要指定版本安装
```bash
npm install i18next@15.0.9 react-i18next@10.7.0
```

2. 启动interface(前端)
```bash
# 启动interface(前端)
npm start
```

3. 访问interface(前端)
- 打开浏览器，访问: `http://localhost:3000`

4. 导入tokenList文件
- 在Uniswap前端界面，点击"选择通证"，在"Add a list"中输入tokenList文件的IPFS地址，例如: ipfs://QmZhqnVhFJF5yo3A2Rsc8hqEhS18aGFrqh3baGB7JujaMN
- 点击"Add"按钮，即可导入tokenList中定义的代币到Uniswap前端中
- 代币添加成功后，后续就可以在UniswapV2前端中使用这些自定义ERC20代币进行交易了

Have fun!!!