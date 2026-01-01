var Crypto = require('crypto')
var secp256k1=require('secp256k1')
var createKeccakHash=require('keccak')

// 一个32字节的随机数（1~2^256-1）, 直接把他当成私钥
var privateKey=Crypto.randomBytes(32);

//var privateKey = new Buffer("c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3", "hex");
// var privateKey = new Buffer("c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3", "hex");

console.log(privateKey.toString('hex'));

// 由secp256k1椭圆曲线算法先计算出公钥
var pubKey = secp256k1.publicKeyCreate(privateKey, false).slice(1);

// 将 Uint8Array 转换为 Buffer
pubKey = Buffer.from(pubKey);

// 进行keccak256 hash运算再取后40位得到
var address = createKeccakHash('keccak256')
                .update(pubKey).digest().slice(-20);
console.log("0x" + address.toString('hex'));

//
