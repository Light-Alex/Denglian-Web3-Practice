// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import "../src/MyERC20.sol";

contract CounterScript is BaseScript {

    // 部署 MyToken 合约
    function run() public broadcaster {
        MyToken token = new MyToken("MyToken", "MTK");
        saveContract("localhost", "MyToken", address(token));
        console.log("MyToken deployed on %s", address(token));
    }
}