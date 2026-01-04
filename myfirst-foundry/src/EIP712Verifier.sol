// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

// 这个合约实现了基于结构化数据的签名验证机制，允许用户离线签名交易，然后在链上验证签名并执行交易
contract EIP712Verifier is EIP712 {

    // 使用ECDSA库进行椭圆曲线数字签名验证
    using ECDSA for bytes32;

    // 定义转账数据结构，包含接收地址和金额
    struct Send {
        address to;
        uint256 value;
    }

    // 生成Send结构体的类型哈希，用于EIP-712标准
    // EIP-712 标准明确规定：
    // 1. 类型哈希必须是完整的32字节
    // 2. 必须包含完整的类型定义字符串
    // 3. 目的是提供人类可读的签名体验
    bytes32 public constant SEND_TYPEHASH = keccak256("Send(address to,uint256 value)");

    // 初始化EIP712域，设置合约名称和版本号
    constructor() EIP712("EIP712Verifier", "1.0.0") {}

    // 生成Send结构体的EIP-712兼容哈希，用于签名验证
    function hashSend(Send memory send) public view returns (bytes32) {
        // _hashTypedDataV4: OpenZeppelin EIP712 合约的内部函数，用于生成符合 EIP-712 v4 标准的类型化数据哈希
        return _hashTypedDataV4(
            keccak256(
                // 用于将多个参数编码为紧凑的字节数组（bytes 类型） ，每个参数编码为字节后右对齐填充到32字节
                abi.encode(
                    SEND_TYPEHASH,
                    // 签名原始内容
                    send.to,
                    send.value
                )
            )
        );
    }

    function verify(
        address signer,
        Send memory send, // 转账数据
        bytes memory signature
    ) public view returns (bool) {
        // 计算转账数据的EIP-712哈希
        bytes32 digest = hashSend(send);

        // digest.recover: 根据EIP-712哈希和签名恢复签名者地址
        // digest.recover(signature) 能够准确得到签名者地址的原因是：
        // 1. 数学确定性：椭圆曲线密码学确保签名与公钥的一一对应关系
        // 2. 恢复算法：基于 (r, s, v) 和消息哈希可以唯一确定公钥
        // 3. 地址推导：从公钥通过 Keccak-256 哈希得到最终的以太坊地址
        // 4. 安全验证：整个过程保证了只有真正的私钥持有者才能通过验证
        return digest.recover(signature) == signer;
    }

    // 转账函数，根据签名验证转账数据并执行转账
    function sendByEIP712Signature(address signer, address to, uint256 value, bytes memory signature ) public {
        // verify: 验证签名是否有效
        require(verify(signer, Send({to: to, value: value}), signature), "Invalid signature");
        // 转账操作
        (bool success, ) = to.call{value: value}("");
        require(success, "Transfer failed");
    }
}