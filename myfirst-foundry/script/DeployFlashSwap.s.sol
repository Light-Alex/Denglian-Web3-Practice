// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./BaseScript.s.sol";
import "../src/FlashSwap.sol";

contract DeployFlashSwap is BaseScript {

    // 部署 DeployFlashSwap 合约
    function run() public broadcaster {
        FlashSwap flashswap = new FlashSwap(0xB41C9bfE053DEF8Aa4e929A5699767D69eC7697A, 0xD7431DB53cD7EE76b0b28753A4394dc07E58eC30);
        saveContract(getNetworkName(block.chainid), "FlashSwap", address(flashswap));
        console.log("FlashSwap deployed on %s", address(flashswap));
    }
}