// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import "../src/Bank.sol";
import "../src/AutoCollectupKeep.sol";

contract AutoCollectupKeepScript is BaseScript {

    // 部署 MyToken 合约
    function run() public broadcaster {
        uint256 deployerPrivateKey;
        // 从私钥中获取到部署者地址
        if (block.chainid == 11155111) {
          deployerPrivateKey = vm.envUint("SEPOLIA_PRIVATE_KEY");
        } else {
          deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        }
        deployer = vm.addr(deployerPrivateKey);
        console.log("Deployer address: %s", deployer);

        Bank bank = new Bank();
        saveContract(getNetworkName(block.chainid), "Bank", address(bank));
        console.log("Bank deployed on %s", address(bank));


        AutoCollectupKeep keep = new AutoCollectupKeep(address(bank));
        saveContract(getNetworkName(block.chainid), "AutoCollectupKeep", address(keep));
        console.log("AutoCollectupKeep deployed on %s", address(keep));
    }
}