// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import "../src/FlashSwap.sol";

contract DeployFlashSwap is BaseScript {

    // 部署 DeployFlashSwap 合约
    function run() public broadcaster {
        FlashSwap flashswap = new FlashSwap();
        saveContract(getNetworkName(block.chainid), "FlashSwap", address(flashswap));
        console.log("FlashSwap deployed on %s", address(flashswap));
    }
}