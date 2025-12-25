## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

### Build MyERC20
```shell
$ forge build src/MyERC20.sol
```

### Deploy MyERC20
```shell
# 以字节码形式部署MyERC20.s.sol合约到sepolia（相关配置在foundry.toml中）
$ forge script .\script\MyERC20.s.sol --keystore .\.keys\metamask1 --rpc-url sepolia --broadcast
```

### opensource MyERC20
```shell
# 将合约字节码开源（简洁版，相关配置在foundry.toml中）
$ forge verify-contract 0x45C0a3b13E5Dd59EF83056fE3Eb48D5850208f83 src/MyERC20.sol:MyERC20 --chain sepolia

# 开源部署MyERC20.s.sol合约到sepolia（相关配置在foundry.toml中）
$ forge script .\script\MyERC20.s.sol --keystore .\.keys\metamask1 --rpc-url sepolia --broadcast --verify
```