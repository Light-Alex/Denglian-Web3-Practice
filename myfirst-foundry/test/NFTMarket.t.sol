// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {MyToken} from "../src/MyERC20.sol";
import {MyERC721} from "../src/MyERC721.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

/*
编写 NFTMarket 合约：

支持设定任意ERC20价格来上架NFT
支持支付ERC20购买指定的NFT
要求测试内容：

上架NFT：测试上架成功和失败情况，要求断言错误信息和上架事件。
购买NFT：测试购买成功、自己购买自己的NFT、NFT被重复购买、支付Token过多或者过少情况，要求断言错误信息和购买事件。
模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
「可选」不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
提交内容要求

使用 foundry 测试和管理合约；
提交 Github 仓库链接到挑战中；
提交 foge test 测试执行结果txt到挑战中；
*/

contract NFTMarketTest is Test {
    MyToken token;
    MyERC721 nft;
    NFTMarket market;

    address[] public users;

    // 定义NFTMarket合约中相同的事件
    event NFTListed(address seller, uint256 tokenId, uint256 price);
    event NFTPurchased(address buyer, uint256 tokenId, uint256 price);

    function setUp() public {
        token = new MyToken("MyToken", "MTK");
        nft = new MyERC721();
        market = new NFTMarket(address(token), address(nft));

        // 创建 10 个测试用户
        for (uint256 i = 0; i < 10; i++) {
            address user = vm.addr(i+1);
            // address user = address(uint160(i));
            users.push(user);
            // 为每个用户分配 100 个 Token
            token.transfer(user, 100 ether);
            // 为每个用户铸造NFT
            nft.mint(user, string.concat("tokenUri_", vm.toString(i)));
        }
        
        targetContract(address(this));
    }

    // 测试上架NFT
    function test_list() public {
        // 测试用户0上架NFT0（成功情况）
        vm.startPrank(users[0]);
        nft.approve(address(market), 0);

        // 断言上架事件
        // 主题检查（Topic 1-3）:
        // 1. 主题1（事件签名）: 检查是否为 NFTListed 事件
        // 2. 主题2（indexed seller）: 检查 seller 是否为 users[0]
        // 3. 主题3（indexed tokenId）: 检查 tokenId 是否为 0
        // 
        // 数据检查（Data）:
        // 4. 事件数据: 检查 price 是否为 100 ether
        vm.expectEmit(true, true, true, true);
        emit NFTListed(users[0], 0, 100 ether);
        market.list(0, 100 ether);
        vm.stopPrank();

        // 测试用户1上架NFT0（失败情况）
        vm.startPrank(address(market));
        vm.expectRevert("NFTMarket: NFT already listed");
        market.list(0, 100 ether);
        vm.stopPrank();
    }

    // 测试购买NFT
    function test_buy() public {
        // 测试用户0上架NFT0（成功情况）
        vm.startPrank(users[0]);
        nft.approve(address(market), 0);
        market.list(0, 100 ether);
        vm.stopPrank();

        // 测试用户1购买NFT0（成功情况）
        vm.startPrank(users[1]);
        token.approve(address(market), 100 ether);
        
        // 断言购买事件
        vm.expectEmit(true, true, true, true);
        emit NFTPurchased(users[1], 0, 100 ether);
        market.buy(0, 100 ether);

        vm.assertEq(nft.ownerOf(0), users[1]);
        vm.assertEq(token.balanceOf(users[1]), 0);
        vm.assertEq(token.balanceOf(users[0]), 200 ether);

        vm.stopPrank();

        // 测试用户1购买NFT0（失败情况）：自己购买自己的NFT
        vm.startPrank(users[1]);
        nft.approve(address(market), 1);
        market.list(1, 100 ether);

        token.approve(address(market), 100 ether);
        vm.expectRevert("NFTMarket: caller is the seller");
        market.buy(1, 100 ether);
        vm.stopPrank();

        // 测试用户1购买NFT0（失败情况）：NFT已被购买
        vm.startPrank(users[1]);
        token.approve(address(market), 100 ether);
        vm.expectRevert("NFTMarket: NFT not for sale");
        market.buy(0, 100 ether);
        vm.stopPrank();

        // 测试用户2购买NFT1（失败情况）：支付Token过少
        vm.startPrank(users[2]);
        token.approve(address(market), 10000 ether);
        vm.expectRevert("NFTMarket: not enough price");
        market.buy(1, 50 ether);
        vm.stopPrank();

        // 测试用户2购买NFT1（成功情况）：支付Token过多
        vm.startPrank(users[2]);
        token.approve(address(market), 10000 ether);

        // 断言购买事件
        vm.expectEmit(true, true, true, true);
        emit NFTPurchased(users[2], 1, 100 ether);
        market.buy(1, 150 ether);
        
        vm.assertEq(nft.ownerOf(1), users[2]);
        vm.assertEq(token.balanceOf(users[2]), 0);
        vm.assertEq(token.balanceOf(users[1]), 100 ether);
        vm.stopPrank();
    }

    // 模糊测试：测试随机使用 0.01-10000 Token价格上架NFT，并随机使用任意Address购买NFT
    function testFuzz_listAndBuy(uint256 sellerIndex, uint256 buyerIndex, uint256 price) public {
        // 限制 price 在 0.01-10000 Token 范围内
        price = bound(price, 0.01 ether, 10000 ether);

        // 确保 sellerIndex 在有效范围内
        sellerIndex = bound(sellerIndex, 0, users.length - 1);
        address seller = users[sellerIndex];

        // 确保 buyerIndex 在有效范围内
        buyerIndex = bound(buyerIndex, 0, users.length - 1);
        address buyer = users[buyerIndex];

        // 确保 seller 不是买家
        vm.assume(seller != buyer);

        // 确保买家有足够的Token余额
        vm.assume(token.balanceOf(buyer) >= price);

        uint256 buyerBalance = token.balanceOf(buyer);
        uint256 sellerBalance = token.balanceOf(seller);

        // 卖家上架NFT
        vm.startPrank(seller);
        nft.approve(address(market), sellerIndex);
        // 断言上架事件
        vm.expectEmit(true, true, true, true);
        emit NFTListed(seller, sellerIndex, price);
        market.list(sellerIndex, price);
        vm.stopPrank();
        assertEq(nft.ownerOf(sellerIndex), address(market));

        // 买家购买NFT
        vm.startPrank(buyer);
        token.approve(address(market), price);
        // 断言购买事件
        vm.expectEmit(true, true, true, true);
        emit NFTPurchased(buyer, sellerIndex, price);
        // market.buyNFT(sellerIndex, price);
        token.transferWithCallback(address(market), price, abi.encode(sellerIndex));
        vm.stopPrank();
        assertEq(nft.ownerOf(sellerIndex), buyer);
        assertEq(token.balanceOf(buyer), buyerBalance - price);
        assertEq(token.balanceOf(seller), sellerBalance + price);
    }

    // 不可变测试：测试无论如何买卖，NFTMarket合约中都不可能有 Token 持仓
    function invariant_tokenBalanceOfNFTMarket() public view {
        // 确保 NFTMarket 合约初始时没有 Token 持仓
        assertEq(token.balanceOf(address(market)), 0, "NFTMarket should not hold any tokens");
    }

}