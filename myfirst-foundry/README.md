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

### Test Bank.sol
```shell
$ forge test --match-contract BankTest -vv
```
```shell
# 结果：
PS E:\web3_workspace\denglian-practice\myfirst-foundry> forge test --match-contract BankTest -vv
Warning: Found unknown config section in foundry.toml: [account]
This notation for profiles has been deprecated and may result in the profile not being registered in future versions.
Please use [profile.account] instead or run `forge config --fix`.
Warning: Found unknown config section in foundry.toml: [verify]
This notation for profiles has been deprecated and may result in the profile not being registered in future versions.
Please use [profile.verify] instead or run `forge config --fix`.
[⠊] Compiling...
[⠘] Compiling 1 files with Solc 0.8.25
[⠃] Solc 0.8.25 finished in 669.04ms
Compiler run successful!

Ran 4 tests for test/Bank.t.sol:BankTest
[PASS] test_Deposit() (gas: 84480)
Logs:
Logs:
  user2 balance: 200000000000000000, balance of bank: 300000000000000000

[PASS] test_Top3Users() (gas: 318635)
Logs:
  user1: 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF
  user2: 0x537C8f3d3E18dF5517a58B3fB9D9143697996802
  user3: 0xc0A55e2205B289a967823662B841Bd67Aa362Aec
  user4: 0x90561e5Cd8025FA6F52d849e8867C14A77C94BA0
  bank users: 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF, 0x0000000000000000000000000000000000000000, 0x0000000000000000000000000000000000000000
  bank users: 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF, 0x537C8f3d3E18dF5517a58B3fB9D9143697996802, 0x0000000000000000000000000000000000000000
  bank users: 0xc0A55e2205B289a967823662B841Bd67Aa362Aec, 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF, 0x537C8f3d3E18dF5517a58B3fB9D9143697996802
  bank users: 0x90561e5Cd8025FA6F52d849e8867C14A77C94BA0, 0xc0A55e2205B289a967823662B841Bd67Aa362Aec, 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF
  bank users: 0x90561e5Cd8025FA6F52d849e8867C14A77C94BA0, 0x29E3b139f4393aDda86303fcdAa35F60Bb7092bF, 0xc0A55e2205B289a967823662B841Bd67Aa362Aec

[PASS] test_Withdraw() (gas: 14650)
[PASS] test_WithdrawAll() (gas: 13703)
Suite result: ok. 4 passed; 0 failed; 0 skipped; finished in 1.34ms (1.03ms CPU time)

Ran 1 test suite in 15.06ms (1.34ms CPU time): 4 tests passed, 0 failed, 0 skipped (4 total tests)
```

### Test NFTMarket.sol
```shell
$ forge test ./test/NFTMarket.t.sol
```
```shell
Warning: Found unknown config section in foundry.toml: [account]
This notation for profiles has been deprecated and may result in the profile not being registered in future versions.
Please use [profile.account] instead or run `forge config --fix`.
Warning: Found unknown config section in foundry.toml: [verify]
This notation for profiles has been deprecated and may result in the profile not being registered in future versions.
Please use [profile.verify] instead or run `forge config --fix`.
[⠊] Compiling...
No files changed, compilation skipped

Ran 4 tests for test/NFTMarket.t.sol:NFTMarketTest
[PASS] invariant_tokenBalanceOfNFTMarket() (runs: 256, calls: 128000, reverts: 65854)

╭---------------+---------------------+-------+---------+----------╮
| Contract      | Selector            | Calls | Reverts | Discards |
+==================================================================+
╭---------------+---------------------+-------+---------+----------╮
| Contract      | Selector            | Calls | Reverts | Discards |
+==================================================================+
| NFTMarketTest | setUp               | 40305 | 659     | 0        |
| Contract      | Selector            | Calls | Reverts | Discards |
+==================================================================+
| NFTMarketTest | setUp               | 40305 | 659     | 0        |
+==================================================================+
| NFTMarketTest | setUp               | 40305 | 659     | 0        |
| NFTMarketTest | setUp               | 40305 | 659     | 0        |
|---------------+---------------------+-------+---------+----------|
|---------------+---------------------+-------+---------+----------|
| NFTMarketTest | testFuzz_listAndBuy | 40165 | 7045    | 32490    |
|---------------+---------------------+-------+---------+----------|
| NFTMarketTest | test_buy            | 39927 | 35568   | 0        |
|---------------+---------------------+-------+---------+----------|
| NFTMarketTest | test_list           | 40093 | 22582   | 0        |
╰---------------+---------------------+-------+---------+----------╯

[PASS] testFuzz_listAndBuy(uint256,uint256,uint256) (runs: 257, μ: 203367, ~: 203410)
[PASS] test_buy() (gas: 354669)
[PASS] test_list() (gas: 121124)
Suite result: ok. 4 passed; 0 failed; 0 skipped; finished in 86.83s (87.04s CPU time)

Ran 1 test suite in 86.84s (86.83s CPU time): 4 tests passed, 0 failed, 0 skipped (4 total tests)
```