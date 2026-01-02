// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";

// 创建一个测试用的目标合约
contract TestTarget {
    uint256 public value;
    address public sender;

    function setValue(uint256 _value) external payable {
        value = _value;
        sender = msg.sender;
    }
}

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;
    TestTarget public target;

    // 测试账户
    address public alice = makeAddr("alice");
    address public bob = makeAddr("bob");
    address public charlie = makeAddr("charlie");
    address public dave = makeAddr("dave");
    
    // 测试数据
    uint256 public constant TEST_VALUE = 42;
    uint256 public constant TEST_ETH = 1 ether;

    // 测试设置
    function setUp() public {
        // 部署目标合约
        target = new TestTarget();

        // 多签合约的所有者
        address[] memory owners = new address[](3);
        owners[0] = alice;
        owners[1] = bob;
        owners[2] = charlie;

        // 多签合约的阈值
        uint256 threshold = (owners.length * 2) / 3;

        // 部署多签合约
        wallet = new MultiSigWallet(
            owners,
            threshold
        );
        
        // 给钱包转入一些ETH
        vm.deal(address(wallet), 10 ether);
    }

    function test_Constructor() public {
        // 检查多签合约的所有者是否正确
        assertEq(wallet.getOwnerCount(), 3);
        assertTrue(wallet.isOwner(alice));
        assertTrue(wallet.isOwner(bob));
        assertTrue(wallet.isOwner(charlie));
        assertFalse(wallet.isOwner(dave));

        // 检查多签合约的阈值是否正确
        assertEq(wallet.threshold(), 2);
    }


    function test_Proposal() public {
        bytes memory data = abi.encodeWithSelector(
            TestTarget.setValue.selector,
            TEST_VALUE
        );

        vm.startPrank(alice);
        uint256 proposalId = wallet.submitProposal(
            address(target),
            TEST_ETH,
            data
        );

        // 验证提案
        (
            address to,
            uint256 value,
            bytes memory proposalData,
            bool executed,
            uint256 confirmations
        ) = wallet.proposals(proposalId);
        assertEq(to, address(target));
        assertEq(value, TEST_ETH);
        assertEq(proposalData, data);
        assertFalse(executed);
        assertEq(confirmations, 0);

        vm.stopPrank();
    }

    function test_Confirm() public {
        bytes memory data = abi.encodeWithSelector(
            TestTarget.setValue.selector,
            TEST_VALUE
        );

        vm.startPrank(alice);
        uint256 proposalId = wallet.submitProposal(
            address(target),
            TEST_ETH,
            data
        );
        vm.stopPrank();

        // Bob确认提案
        vm.startPrank(bob);
        wallet.confirmProposal(proposalId);
        assertTrue(wallet.confirmations(proposalId, bob));

        // 验证确认
        (, , , , uint256 confirmations) = wallet.proposals(proposalId);
        assertEq(confirmations, 1);

        vm.stopPrank();
    }

    function test_Execute() public {
        bytes memory data = abi.encodeWithSelector(
            TestTarget.setValue.selector,
            TEST_VALUE
        );

        // Alice提交并确认提案
        vm.startPrank(alice);
        uint256 proposalId = wallet.submitProposal(
            address(target),
            TEST_ETH,
            data
        );
        wallet.confirmProposal(proposalId);
        assertTrue(wallet.confirmations(proposalId, alice));
        vm.stopPrank();

        // Bob确认提案
        vm.startPrank(bob);
        wallet.confirmProposal(proposalId);
        assertTrue(wallet.confirmations(proposalId, bob));

        // 验证确认
        (, , , , uint256 confirmations) = wallet.proposals(proposalId);
        assertEq(confirmations, 2);

        // Dave执行提案
        vm.startPrank(dave);
        wallet.executeProposal(proposalId);
        vm.stopPrank();

        // 验证目标合约状态
        assertEq(target.value(), TEST_VALUE);
        assertEq(target.sender(), address(wallet));
        assertEq(address(target).balance, TEST_ETH);

        // 验证提案状态
        (, , , bool executed, ) = wallet.proposals(proposalId);
        assertTrue(executed);
        assertTrue(wallet.getProposalExecuted(proposalId));
    }

}