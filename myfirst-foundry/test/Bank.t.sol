// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";
import "forge-std/console.sol";

// 1. 断言检查存款前后用户在 Bank 合约中的存款额更新是否正确。
// 2. 检查存款金额的前 3 名用户是否正确，分别检查有1个、2个、3个、4 个用户， 以及同一个用户多次存款的情况。
// 3. 检查只有管理员可取款，其他人不可以取款。

contract BankTest is Test {
    Bank public bank;

    address public user1 = makeAddr("user1");
    address public user2 = makeAddr("user2");
    address public user3 = makeAddr("user3");
    address public user4 = makeAddr("user4");

    function setUp() public {
        // 部署 Bank 合约
        bank = new Bank();
    }

    function test_Deposit() public {
        // 用户2存款0.5 ETH
        vm.deal(user2, 0.5 ether);

        // 检查用户2存款前的余额为0.5 ether, 银行余额为0 ether
        assertEq(user2.balance, 0.5 ether);
        assertEq(bank.deposits(user2), 0 ether);

        vm.prank(user2);
        bank.deposit{value: 0.3 ether}();
        // 检查用户2存款后的余额为0.2 ether, 银行余额为0.3 ether
        assertEq(user2.balance, 0.2 ether);
        assertEq(bank.deposits(user2), 0.3 ether);
        console.log("user2 balance: %d, balance of bank: %d", user2.balance, bank.deposits(user2));
    }

    function test_Top3Users() public {
        // console.log("user1: %s\n user2: %s\n user3: %s\n user4: %s", user1, user2, user3, user4);
        console.log("user1: %s", user1);
        console.log("user2: %s", user2);
        console.log("user3: %s", user3);
        console.log("user4: %s", user4);

        // 用户1存款1 ETH
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        assertEq(bank.users(0), user1);
        assertEq(bank.users(1), address(0));
        assertEq(bank.users(2), address(0));
        console.log("bank users: %s, %s, %s", bank.users(0), bank.users(1), bank.users(2));

        // 用户2存款0.5 ETH
        vm.deal(user2, 0.5 ether);
        vm.prank(user2);
        bank.deposit{value: 0.5 ether}();
        assertEq(bank.users(0), user1);
        assertEq(bank.users(1), user2);
        assertEq(bank.users(2), address(0));
        console.log("bank users: %s, %s, %s", bank.users(0), bank.users(1), bank.users(2));

        // 用户3存款2 ETH
        vm.deal(user3, 2 ether);
        vm.prank(user3);
        bank.deposit{value: 2 ether}();
        assertEq(bank.users(0), user3);
        assertEq(bank.users(1), user1);
        assertEq(bank.users(2), user2);
        console.log("bank users: %s, %s, %s", bank.users(0), bank.users(1), bank.users(2));

        // 用户4存款3 ETH
        vm.deal(user4, 3 ether);
        vm.prank(user4);
        bank.deposit{value: 3 ether}();
        assertEq(bank.users(0), user4);
        assertEq(bank.users(1), user3);
        assertEq(bank.users(2), user1);
        console.log("bank users: %s, %s, %s", bank.users(0), bank.users(1), bank.users(2));

        // 用户1存款1.5 ETH
        vm.deal(user1, 1.5 ether);
        vm.prank(user1);
        bank.deposit{value: 1.5 ether}();
        assertEq(bank.users(0), user4);
        assertEq(bank.users(1), user1);
        assertEq(bank.users(2), user3);
        console.log("bank users: %s, %s, %s", bank.users(0), bank.users(1), bank.users(2));
    }

    function test_Withdraw() public {
        // 检查只有管理员可取款，其他人不可以取款
        vm.prank(user1);
        vm.expectRevert("Only admin can withdraw");
        bank.withdraw(1 ether);

        // 检查取款金额不超过合约余额
        vm.prank(address(this));
        vm.expectRevert("Insufficient balance");
        bank.withdraw(1 ether);
    }

    function test_WithdrawAll() public {
        // 检查只有管理员可取款，其他人不可以取款
        vm.prank(user1);
        vm.expectRevert("Only admin can withdraw");
        bank.withdrawAll();

        // 检查取款金额不超过合约余额
        vm.prank(address(this));
        vm.expectRevert("No balance to withdraw");
        bank.withdrawAll();
    }

    function test_CollectWithThreshold() public {
        // 检查只有管理员可取款，其他人不可以取款
        vm.startPrank(user1);
        vm.deal(user1, 1 ether);
        bank.deposit{value: 1 ether}();
        console.log("bank balance", address(bank).balance);
        bank.collectWithThreshold();
        // 检查管理员取款金额为合约余额的一半
        assertEq(address(bank).balance, 0.5 ether, "Bank balance should be 0.5 ether");
        vm.stopPrank();
    }

    // 添加 receive 函数，让 BankTest 合约可以接收 ETH
    receive() external payable {}
}
