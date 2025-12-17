package main

import (
	"bytes"
	"crypto/sha256"
	"fmt"
	"strconv"
	"strings"
	"time"
)

type Transaction struct {
	From      []byte
	To        []byte
	Amount    int64
	Timestamp uint64
}

type Block struct {
	Index          uint64
	Timestamp      uint64
	hashMerkleRoot []byte
	Transactions   []Transaction
	nonce          uint64
	Hash           []byte
	PrevHash       []byte
}

func (b *Block) GetHash() []byte {
	index := []byte(strconv.FormatUint(b.Index, 10))
	timestamp := []byte(strconv.FormatUint(b.Timestamp, 10))
	nonce := []byte(strconv.FormatUint(b.nonce, 10))
	transactions := []byte{}
	for _, tx := range b.Transactions {
		transaction := []byte{}
		transaction = append(transaction, tx.From...)
		transaction = append(transaction, tx.To...)
		transaction = append(transaction, []byte(strconv.FormatInt(tx.Amount, 10))...)
		transaction = append(transaction, []byte(strconv.FormatUint(tx.Timestamp, 10))...)
		transactionHash := sha256.Sum256(transaction)
		transactions = append(transactions, transactionHash[:]...)
	}

	hashMerkleRoot := sha256.Sum256(transactions)
	b.hashMerkleRoot = hashMerkleRoot[:]

	header := bytes.Join([][]byte{index, timestamp, b.hashMerkleRoot, nonce, b.PrevHash}, []byte{})

	hash := sha256.Sum256(header)
	return hash[:]
}

func (b *Block) SetHash() {
	b.Hash = b.GetHash()
}

func NewBlock(transactions []Transaction, prevHash []byte, index uint64) *Block {
	block := &Block{
		Index:          index,
		Timestamp:      uint64(time.Now().Unix()),
		hashMerkleRoot: []byte{},
		Transactions:   transactions,
		nonce:          0,
		Hash:           []byte{},
		PrevHash:       prevHash,
	}
	block.SetHash()
	return block
}

func NewGenesisBlock() *Block {
	return NewBlock([]Transaction{}, []byte{}, 0)
}

func (b *Block) Mining(difficulty int) {
	fmt.Println("Start mining block...")

	for {
		b.SetHash()
		if strings.HasPrefix(fmt.Sprintf("%x", b.Hash), strings.Repeat("0", difficulty)) {
			fmt.Printf("Mining block success! block index: %d, Nonce: %d, Hash: %x\n", b.Index, b.nonce, b.Hash)
			return
		}
		b.Timestamp = uint64(time.Now().Unix())
		b.nonce++
	}
}

type Blockchain struct {
	Difficulty int
	Blocks     []*Block
}

func (bc *Blockchain) AddBlock(transactions []Transaction) {
	prevBlock := bc.Blocks[len(bc.Blocks)-1]
	block := NewBlock(transactions, prevBlock.Hash, prevBlock.Index+1)
	block.Mining(bc.Difficulty)
	bc.Blocks = append(bc.Blocks, block)
}

func (bc *Blockchain) IsValid() bool {
	for i := 1; i < len(bc.Blocks); i++ {
		currentBlock := bc.Blocks[i]
		prevBlock := bc.Blocks[i-1]

		if !bytes.Equal(currentBlock.Hash, currentBlock.GetHash()) {
			return false
		}

		if !bytes.Equal(currentBlock.PrevHash, prevBlock.Hash) {
			return false
		}
	}
	return true
}

func NewBlockchain() *Blockchain {
	return &Blockchain{
		Difficulty: 4,
		Blocks:     []*Block{NewGenesisBlock()},
	}
}

func main() {
	fmt.Println("Create block chain...")
	bc := NewBlockchain()

	transaction1 := Transaction{
		From:      []byte("Alice"),
		To:        []byte("Bob"),
		Amount:    100,
		Timestamp: uint64(time.Now().Unix()),
	}
	transaction2 := Transaction{
		From:      []byte("Bob"),
		To:        []byte("Charlie"),
		Amount:    50,
		Timestamp: uint64(time.Now().Unix()),
	}
	bc.AddBlock([]Transaction{transaction1, transaction2})

	transaction3 := Transaction{
		From:      []byte("Charlie"),
		To:        []byte("Dave"),
		Amount:    20,
		Timestamp: uint64(time.Now().Unix()),
	}
	bc.AddBlock([]Transaction{transaction3})
	transaction4 := Transaction{
		From:      []byte("Dave"),
		To:        []byte("Eve"),
		Amount:    10,
		Timestamp: uint64(time.Now().Unix()),
	}
	bc.AddBlock([]Transaction{transaction4})

	fmt.Println("Blockchain is valid:", bc.IsValid())

	// jsonData, err := json.MarshalIndent(bc, "", "  ")
	// if err != nil {
	// 	fmt.Println("Error marshaling JSON:", err)
	// 	return
	// }

	// fmt.Printf("Blockchain: %s\n", jsonData)

	fmt.Printf("Blockchain difficulty: %d\n", bc.Difficulty)
	fmt.Printf("=======================================================\n\n")
	for _, block := range bc.Blocks {
		fmt.Printf("Block index: %d\n", block.Index)
		fmt.Printf("Block timestamp: %d\n", block.Timestamp)
		fmt.Printf("Block prev hash: %x\n", block.PrevHash)
		fmt.Printf("Block hash: %x\n", block.Hash)
		fmt.Printf("Block nonce: %d\n", block.nonce)
		fmt.Println("Block transactions:")
		for _, tx := range block.Transactions {
			fmt.Println("-------------------------------------------------------")
			fmt.Printf("Transaction From: %x\n", tx.From)
			fmt.Printf("Transaction To: %x\n", tx.To)
			fmt.Printf("Transaction Amount: %d\n", tx.Amount)
			fmt.Printf("Transaction Timestamp: %d\n", tx.Timestamp)
		}
		fmt.Println("=======================================================")
	}
}
