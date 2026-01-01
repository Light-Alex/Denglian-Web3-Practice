var bip39 = require('bip39') // BIP-39助记词标准实现
var hdkey = require('ethereumjs-wallet/hdkey') // 分层确定性钱包
var util = require('ethereumjs-util') // 以太坊工具函数

// 生成一个随机的12词BIP-39助记词
var mnemonic = bip39.generateMnemonic()
console.log("助记词："+ mnemonic)

// // 生成助记词
// var mnemonic = "candy maple cake sugar pudding cream honey rich smooth crumble sweet treat"; // bip39.generateMnemonic()
// console.log("助记词："+ mnemonic );

// 使用PBKDF2算法将助记词转换为512位的种子; 这个种子是确定性钱包的基础
var seed = bip39.mnemonicToSeed(mnemonic);

// 从种子创建主密钥; 支持BIP-32标准的分层确定性钱包结构
var hdWallet = hdkey.fromMasterSeed(seed);

// 使用BIP-44路径规范：m/44'/60'/0'/0/1
// m：主密钥
// 44': BIP-44规范
// 60': 以太坊币种类型
// 0': 账户索引
// 0 : 外部接收地址
// 1: 地址索引
// 输出第1个外部接收地址的私钥和公钥
var key1 = hdWallet.derivePath("m/44'/60'/0'/0/1");
console.log("私钥："+util.bufferToHex(key1._hdkey._privateKey));

// 从公钥计算以太坊地址
var address1 = util.pubToAddress(key1._hdkey._publicKey, true);
console.log("地址："+util.bufferToHex(address1));

// 符合EIP-55标准的地址，包含大小写校验
console.log("校验和地址："+ util.toChecksumAddress(address1.toString('hex')));
