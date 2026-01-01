# Readme

## install

Node.js 18.17.1:
```shell
nvm install 18.17.1
nvm use 18.17.1
```

```shell
npm install
```

1. create eth account by random private key 

```shell
node create_by_raw.js 
```

2. create ethereum account by random  mnemonic

```shell
node create_by_mnemonic.js
```

3. build raw transaction
```shell
node build_raw_tx.js
```

**Terminal display:**
```shell
账户地址: 0x682e260c6722774Aa32c2328fe5114Ef29A04ef3
(node:7468) [MODULE_TYPELESS_PACKAGE_JSON] Warning: Module type of file:///E:/web3_workspace/denglian-practice/CliWallet/build_raw_tx.ts is not specified and it doesn't parse as CommonJS.
Reparsing as ES module because module syntax was detected. This incurs a performance overhead.
To eliminate this warning, add "type": "module" to E:\web3_workspace\denglian-practice\CliWallet\package.json.
(Use `node --trace-warnings ...` to show where the warning was created)
当前区块号: 9959030n
当前 gas 价格: 1001878000000000n Wei , 0.000000000001001878 Ether
账户余额:  636888616000000000000000000000n Wei , 0.000000636888616 Ether
当前 Nonce: 3
ERC20 代币余额: 1000 Ether
准备后的交易参数: {
  account: {
    address: '0x682e260c6722774Aa32c2328fe5114Ef29A04ef3',
    nonceManager: undefined,
    sign: [AsyncFunction: sign],
    signAuthorization: [AsyncFunction: signAuthorization],
    signMessage: [AsyncFunction: signMessage],
    signTransaction: [AsyncFunction: signTransaction],
    signTypedData: [AsyncFunction: signTypedData],
    source: 'privateKey',
    type: 'local',
    publicKey: '0x048de5687f542d4fd30fbb35e2fc9967aa5af486dc6862b3290f512ec27ddb1a4e9879c7524fac5f04666c836e714fa64e6892e6819a96ad03923785a5cbc57f0d'
  },
  to: '0x6F31CEECfbe1C80554C275b1975A2b17d379383E',
  value: 0n,
  data: '0xa9059cbb0000000000000000000000006687e46c68c00bd1c10f8cc3eb000b1752737e94000000000000000000000000000000000000000000000002b5e3af16b1880000',
  chainId: 11155111,
  type: 'eip1559',
  chain: {
    formatters: undefined,
    fees: undefined,
    serializers: undefined,
    id: 11155111,
    name: 'Sepolia',
    nativeCurrency: { name: 'Sepolia Ether', symbol: 'ETH', decimals: 18 },
    rpcUrls: { default: [Object] },
    blockExplorers: { default: [Object] },
    contracts: { multicall3: [Object], ensUniversalResolver: [Object] },
    extend: [Function (anonymous)]
  },
  maxFeePerGas: 2003756000000000n,
  maxPriorityFeePerGas: 1000000000000000n,
  gas: 50000n,
  nonce: 3,
  from: '0x682e260c6722774Aa32c2328fe5114Ef29A04ef3'
}
签名后的交易: 0x02f8b083aa36a703830f4240831e932c82c350946f31ceecfbe1c80554c275b1975a2b17d379383e80b844a9059cbb0000000000000000000000006687e46c68c00bd1c10f8cc3eb000b1752737e94000000000000000000000000000000000000000000000002b5e3af16b1880000c001a081a528fb6051ff9a88d615db29b0ab97f376046a43268ceab28945b6b2bf1862a0617fe818cc336b7db28cc4cae86fbae7496c807e2b700abd79b1b5bcdae06ec4
Transaction Hash: 0xcc914729beebafdfb1be50dd4e4da40fe4ad12e9a3dba0cca2c986eed290163e
交易状态: 成功
区块号: 9959031n
Gas 使用量: 35038
```