// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

interface IBank {
    function collectWithThreshold() external;
}

contract AutoCollectupKeep is AutomationCompatibleInterface {
  address public immutable bank;

  constructor(address _bank) {
    bank = _bank;
  }
  
  // 检查是否需要执行自动取款
  function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData){
    uint256 threshold = abi.decode(checkData, (uint256));

    upkeepNeeded = false;  // 初始化为 false
    if (bank.balance > threshold) {
      upkeepNeeded = true;
    }
    performData = checkData;
  }

  function performUpkeep(bytes calldata performData) external override {
    uint256 threshold = abi.decode(performData, (uint256));
    if (bank.balance > threshold) {
        IBank(bank).collectWithThreshold();
    }
  }
}