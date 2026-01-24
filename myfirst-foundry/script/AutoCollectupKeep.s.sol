// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import "../src/Bank.sol";
import "../src/AutoCollectupKeep.sol";

contract AutoCollectupKeepScript is BaseScript {

    // 部署 MyToken 合约
    function run() public broadcaster {
        console.log("Deployer address: %s", deployer);

        Bank bank = new Bank();
        saveContract(getNetworkName(block.chainid), "Bank", address(bank));
        console.log("Bank deployed on %s", address(bank));


        AutoCollectupKeep keep = new AutoCollectupKeep(address(bank));
        saveContract(getNetworkName(block.chainid), "AutoCollectupKeep", address(keep));
        console.log("AutoCollectupKeep deployed on %s", address(keep));
    }
}