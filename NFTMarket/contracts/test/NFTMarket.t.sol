// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";
import {MyTokenPermit} from "../src/MyTokenPermit.sol";
import {MyNFTPermit} from "../src/MyNFTPermit.sol";
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
    MyTokenPermit token;
    MyNFTPermit nft;
    NFTMarket market;

    address public project_provider;
    address[] public users;

    // struct Sig {
    //     bytes32 r;
    //     bytes32 s;
    //     uint8 v;
    // }

    // Permit 类型哈希: keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)")
    bytes32 nftPermitTypeHash;

    // Whitelist 类型哈希: keccak256("Whitelist(address buyer,uint256 listingId)")
    bytes32 whitelistTypeHash;

    // Permit 类型哈希: keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 erc20PermitTypeHash;

    // 获取 DOMAIN_SEPARATOR
    bytes32 nftDomainSeparator;

    // 获取 ERC20 DOMAIN_SEPARATOR
    bytes32 erc20DomainSeparator;

    // 定义NFTMarket合约中相同的事件
        event NFTListed(
        uint256 indexed listingId,
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price
    );

    event NFTPurchased(
        uint256 indexed listingId,
        address indexed buyer,
        address indexed seller,
        uint256 price
    );

    event ListingCancelled(uint256 indexed listingId);

    function setUp() public {
        project_provider = vm.addr(100);
        token = new MyTokenPermit(10000 ether);
        nft = new MyNFTPermit();
        market = new NFTMarket(address(token), project_provider);

        // 创建 10 个测试用户
        for (uint256 i = 0; i < 10; i++) {
            address user = vm.addr(i+1);
            // address user = address(uint160(i));
            users.push(user);
            // 为每个用户分配 100 个 Token
            token.transfer(user, 200 ether);
            // 为每个用户铸造NFT
            nft.mint(user, string.concat("tokenUri_", vm.toString(i)));
        }

        // Permit 类型哈希: keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)")
        nftPermitTypeHash = keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

        // Whitelist 类型哈希: keccak256("Whitelist(address buyer,uint256 listingId)")
        whitelistTypeHash = keccak256("Whitelist(address buyer,uint256 listingId)");

        // Permit 类型哈希: keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
        erc20PermitTypeHash = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

        // 获取 DOMAIN_SEPARATOR
        nftDomainSeparator = nft.DOMAIN_SEPARATOR();

        // 获取 ERC20 DOMAIN_SEPARATOR
        erc20DomainSeparator = token.DOMAIN_SEPARATOR();
    }

    // 辅助函数：构造 NFT Permit 签名
    function signNFTPermit(
        uint256 privateKey,
        address spender,
        uint256 tokenId,
        uint256 deadline
    ) internal view returns (bytes memory) {
        uint256 nonce = nft.nonces(tokenId);

        bytes32 structHash = keccak256(
            abi.encode(
                nftPermitTypeHash,
                spender,
                tokenId,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                nftDomainSeparator,
                structHash
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }

    // 辅助函数：构造 ERC20 Permit 签名
    function signERC20Permit(
        uint256 privateKey,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline
    ) internal view returns (uint8 v, bytes32 r, bytes32 s) {
        uint256 nonce = token.nonces(owner);

        bytes32 structHash = keccak256(
            abi.encode(
                erc20PermitTypeHash,
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                erc20DomainSeparator,
                structHash
            )
        );

        return vm.sign(privateKey, digest);
    }

    // 辅助函数：构造白名单签名
    function signWhitelist(
        uint256 privateKey,
        address buyer,
        uint256 listingId
    ) internal view returns (bytes memory) {
        bytes32 structHash = keccak256(
            abi.encode(
                whitelistTypeHash,
                buyer,
                listingId
            )
        );

        // 手动计算 NFTMarket 的 DOMAIN_SEPARATOR
        // EIP712("NFTMarket", "1.0.0")
        bytes32 marketDomainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("NFTMarket"),
                keccak256("1.0.0"),
                block.chainid,
                address(market)
            )
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                marketDomainSeparator,
                structHash
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        return abi.encodePacked(r, s, v);
    }

    // 测试上架NFT
    function test_list() public {
        // 使用 Permit 方式上架 NFT
        vm.startPrank(users[0]);

        // 构造 NFT Permit 离线签名
        uint256 nftPermitDeadline = block.timestamp + 10000;
        uint256 tokenId = 0;
        bytes memory nftPermitSignature = signNFTPermit(
            1,
            address(market),
            tokenId,
            nftPermitDeadline
        );

        // 断言上架事件
        vm.expectEmit(true, true, true, true);
        emit NFTListed(0, users[0], address(nft), 0, 100 ether);
        market.list(address(nft), tokenId, 100 ether, nftPermitDeadline, nftPermitSignature);
        vm.stopPrank();

        // 验证 market 已被授权
        vm.assertEq(nft.getApproved(tokenId), address(market));
    }

    // 测试购买NFT
    function test_buy() public {
        // 测试用户0上架NFT0（成功情况）
        // 使用 Permit 方式上架 NFT
        vm.startPrank(users[0]);

        // 构造 NFT Permit 离线签名
        uint256 nftPermitDeadline = block.timestamp + 10000;
        uint256 tokenId = 0;
        bytes memory nftPermitSignature = signNFTPermit(
            1,
            address(market),
            tokenId,
            nftPermitDeadline
        );

        // 断言上架事件
        vm.expectEmit(true, true, true, true);
        emit NFTListed(0, users[0], address(nft), 0, 100 ether);
        market.list(address(nft), tokenId, 100 ether, nftPermitDeadline, nftPermitSignature);
        vm.stopPrank();

        // 测试用户1购买NFT0（成功情况）
        vm.startPrank(users[1]);
        token.approve(address(market), 100 ether);

        // 断言购买事件
        vm.expectEmit(true, true, true, true);
        emit NFTPurchased(0, users[1], users[0], 100 ether);
        market.buyNFT(0);

        vm.assertEq(nft.ownerOf(0), users[1]);
        vm.assertEq(token.balanceOf(users[1]), 100 ether);
        vm.assertEq(token.balanceOf(users[0]), 300 ether);

        vm.stopPrank();
    }

    function test_permitBuy() public {
        uint256 nftPermitDeadline = block.timestamp + 10000;
        uint256 permitDeadline = block.timestamp + 10000;

        // 用户1上架NFT
        vm.startPrank(users[1]);
        bytes memory nftPermitSignature = signNFTPermit(2, address(market), 1, nftPermitDeadline);

        vm.expectEmit(true, true, true, true);
        emit NFTListed(0, users[1], address(nft), 1, 100 ether);
        market.list(address(nft), 1, 100 ether, nftPermitDeadline, nftPermitSignature);
        vm.stopPrank();

        // 构造项目方签名
        bytes memory nftWhitelistSignature = signWhitelist(100, users[0], 0);

        // 测试用户0购买NFT
        vm.startPrank(users[0]);
        (uint8 v, bytes32 r, bytes32 s) = signERC20Permit(1, users[0], address(market), 100 ether, permitDeadline);

        vm.expectEmit(true, true, true, true);
        emit NFTPurchased(0, users[0], users[1], 100 ether);
        market.permitBuy(0, users[0], permitDeadline, v, r, s, nftPermitDeadline, nftPermitSignature, nftWhitelistSignature);

        vm.assertEq(nft.ownerOf(0), users[0]);
        vm.assertEq(token.balanceOf(users[0]), 100 ether);
        vm.assertEq(token.balanceOf(users[1]), 300 ether);

        vm.stopPrank();
    }

    function test_cancelListing() public {
        // 测试用户0上架NFT0（成功情况）
        // 使用 Permit 方式上架 NFT
        vm.startPrank(users[0]);

        // 构造 NFT Permit 离线签名
        uint256 nftPermitDeadline = block.timestamp + 10000;
        uint256 tokenId = 0;
        bytes memory nftPermitSignature = signNFTPermit(
            1,
            address(market),
            tokenId,
            nftPermitDeadline
        );

        // 断言上架事件
        vm.expectEmit(true, true, true, true);
        emit NFTListed(0, users[0], address(nft), 0, 100 ether);
        market.list(address(nft), tokenId, 100 ether, nftPermitDeadline, nftPermitSignature);
        vm.assertEq(market.getListing(0).active, true);
        vm.stopPrank();

        // 测试用户0取消上架NFT0（成功情况）
        vm.startPrank(users[0]);
        // 断言取消上架事件
        vm.expectEmit(true, true, true, true);
        emit ListingCancelled(0);
        market.cancelListing(0);
        vm.stopPrank();

        // 验证 NFT 已被取消上架
        vm.assertEq(market.getListing(0).active, false);
    }
}