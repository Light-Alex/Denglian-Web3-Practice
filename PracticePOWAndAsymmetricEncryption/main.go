package main

import (
	"crypto/rand"
	"crypto/rsa"
	"crypto/sha256"
	"fmt"
	"strconv"
	"strings"
	"time"
)

type Result struct {
	Content string
	Hash    string
	Time    time.Duration
}

func sha256Hash(data []byte) []byte {
	hash := sha256.New()
	hash.Write([]byte(data))
	return hash.Sum(nil)
}

/*
mining: 挖矿函数, 用于找到符合难度值的哈希值

参数解释：
difficulty: 难度值, 用于挖矿的哈希值前缀0的数量
data: 要进行挖矿的数据
res: 挖矿结果, 包含Content, Hash, Time三个字段
*/
func mining(difficulty int, data string) (res Result) {
	nonce := 0
	start := time.Now()
	for {
		res.Content = strconv.Itoa(nonce) + data
		res.Hash = fmt.Sprintf("%x", sha256Hash([]byte(res.Content)))
		if strings.HasPrefix(res.Hash, strings.Repeat("0", difficulty)) {
			res.Time = time.Since(start)
			return res
		}
		nonce++
	}
}

/*
generateRSAKeyPair: 生成RSA密钥对函数, 用于生成RSA密钥对

参数解释：
bits: RSA密钥对的位数, 常用2048位
privateKey: 生成的RSA私钥
publicKey: 生成的RSA公钥
err: 错误信息, 生成密钥对失败时返回
*/
func generateRSAKeyPair(bits int) (*rsa.PrivateKey, *rsa.PublicKey, error) {
	privateKey, err := rsa.GenerateKey(rand.Reader, bits)
	if err != nil {
		return nil, nil, err
	}
	return privateKey, &privateKey.PublicKey, nil
}

// func encryptRSA(publicKey *rsa.PublicKey, data []byte) ([]byte, error) {
// 	return rsa.EncryptPKCS1v15(rand.Reader, publicKey, data)
// }

// func decryptRSA(privateKey *rsa.PrivateKey, data []byte) ([]byte, error) {
// 	return rsa.DecryptPKCS1v15(rand.Reader, privateKey, data)
// }

/*
signRSA: RSA签名函数, 用于对数据进行RSA签名

参数解释：
privateKey: RSA私钥, 用于对数据进行签名
data: 要进行签名的数据
signature: 生成的RSA签名
err: 错误信息, 签名失败时返回
*/
func signRSA(privateKey *rsa.PrivateKey, data []byte) ([]byte, error) {
	return rsa.SignPKCS1v15(rand.Reader, privateKey, 0, data)
}

/*
verifyRSA: RSA验证函数, 用于验证RSA签名的有效性

参数解释：
publicKey: RSA公钥, 用于验证签名
data: 要进行验证的数据
signature: 要验证的RSA签名
err: 错误信息, 验证失败时返回
*/
func verifyRSA(publicKey *rsa.PublicKey, data, signature []byte) error {
	return rsa.VerifyPKCS1v15(publicKey, 0, data, signature)
}

func main() {
	// 挖矿, 难度值为4
	resFor4 := mining(4, "Light Alex")
	// 打印结果
	fmt.Printf("mining completed for difficulty 4, hash content: %s, hash value: %s, cost time: %v\n", resFor4.Content, resFor4.Hash, resFor4.Time)

	// 挖矿, 难度值为5
	resFor5 := mining(5, "Light Alex")
	// 打印结果
	fmt.Printf("mining completed for difficulty 5, hash content: %s, hash value: %s, cost time: %v\n", resFor5.Content, resFor5.Hash, resFor5.Time)

	// 生成RSA密钥对, 2048位
	privateKey, publicKey, err := generateRSAKeyPair(2048)
	if err != nil {
		fmt.Printf("generate RSA key pair failed, err: %v\n", err)
		return
	}

	// 对哈希值进行RSA签名
	signature, err := signRSA(privateKey, []byte(resFor4.Hash))
	if err != nil {
		fmt.Printf("sign RSA failed, err: %v\n", err)
		return
	}
	// 打印签名
	fmt.Printf("RSA signature: %x\n", signature)

	// 验证RSA签名
	err = verifyRSA(publicKey, []byte(resFor4.Hash), signature)
	if err != nil {
		fmt.Printf("verify RSA failed, err: %v\n", err)
		return
	}
	// 打印验证成功
	fmt.Printf("verify RSA success\n")
}
