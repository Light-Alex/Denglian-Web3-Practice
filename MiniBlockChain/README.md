# MiniBlockChain

这是一个使用Golang实现的简单区块链，包含了创建区块链、挖矿（Proof of Work）、验证区块链等功能。

## 功能
- 创建区块链
- 工作量证明挖矿（难度为4个0开头）
- 交易记录存储（每个区块包含多个交易）
- 交易验证（对每一笔交易进行Hash）
- 区块链验证（检查每个区块的Hash是否正确）

## 项目

项目包含以下主要结构体：

- `Transaction` 结构体：处理交易信息
- `Block` 结构体：区块结构和挖矿功能
- `Blockchain` 结构体：管理区块链和交易

## 运行说明
### 环境要求
- Golang 1.16 或以上版本

### 运行方法
在项目目录下执行以下命令：
```Golang
go run main.go
```

### 运行结果
```
Create block chain...
Start mining block...
Mining block success! block index: 1, Nonce: 14469, Hash: 0000ec715d8a9a23b4cf6b8a40b278e4043a6352a018002d382d1cf5bd859630
Start mining block...
Mining block success! block index: 2, Nonce: 72525, Hash: 00002a847d4084a22db27685b958f1918aa30df91ac236f5e061c40fc3476dc7
Start mining block...
Mining block success! block index: 3, Nonce: 221561, Hash: 000091431fd4954852c84992ae488c044f0f0ee8982e24e03cfc4b273637f64b
Blockchain is valid: true
Blockchain difficulty: 4
=======================================================

Block index: 0
Block timestamp: 1765976913
Block prev hash:
Block hash: f24143d74ee4e84ccd5c2232eb2ac433c1926e2b5dbeda8335fe35cfa6b2c8f0
Block nonce: 0
Block transactions:
=======================================================
Block index: 1
Block timestamp: 1765976913
Block prev hash: f24143d74ee4e84ccd5c2232eb2ac433c1926e2b5dbeda8335fe35cfa6b2c8f0
Block hash: 0000ec715d8a9a23b4cf6b8a40b278e4043a6352a018002d382d1cf5bd859630
Block nonce: 14469
Block transactions:
-------------------------------------------------------
Transaction From: 416c696365
Transaction To: 426f62
Transaction Amount: 100
Transaction Timestamp: 1765976913
-------------------------------------------------------
Transaction From: 426f62
Transaction To: 436861726c6965
Transaction Amount: 50
Transaction Timestamp: 1765976913
=======================================================
Block index: 2
Block timestamp: 1765976913
Block prev hash: 0000ec715d8a9a23b4cf6b8a40b278e4043a6352a018002d382d1cf5bd859630
Block hash: 00002a847d4084a22db27685b958f1918aa30df91ac236f5e061c40fc3476dc7
Block nonce: 72525
Block transactions:
-------------------------------------------------------
Transaction From: 436861726c6965
Transaction To: 44617665
Transaction Amount: 20
Transaction Timestamp: 1765976913
=======================================================
Block index: 3
Block timestamp: 1765976913
Block prev hash: 00002a847d4084a22db27685b958f1918aa30df91ac236f5e061c40fc3476dc7
Block hash: 000091431fd4954852c84992ae488c044f0f0ee8982e24e03cfc4b273637f64b
Block nonce: 221561
Block transactions:
-------------------------------------------------------
Transaction From: 44617665
Transaction To: 457665
Transaction Amount: 10
Transaction Timestamp: 1765976913
=======================================================
```