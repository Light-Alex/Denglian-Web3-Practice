// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {StdStorage} from "forge-std/StdStorage.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import "forge-std/console.sol";
import { Upgrades, Options } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 导入 V1 合约
import {MyTokenPermit} from "../src/MyTokenPermit.sol";
import {NFTMarketV1} from "../src/NFTMarketV1.sol";
import {SimpleNFTV1} from "../src/SimpleNFTV1.sol";

// 导入 V2 合约
import {NFTMarketV2} from "../src/NFTMarketV2.sol";
import {SimpleNFTV2} from "../src/SimpleNFTV2.sol";

/**
 * @title NFTMarketUpgradeTest
 * @notice 测试 NFTMarketV1 和 SimpleNFT 从 V1 升级到 V2 的功能
 * @dev 重点验证升级前后的状态一致性
 */
contract NFTMarketUpgradeTest is Test {

    // V1 合约实例
    MyTokenPermit token;
    SimpleNFTV1 nftV1;
    NFTMarketV1 marketV1;

    // V2 合约实例
    SimpleNFTV2 nftV2;
    NFTMarketV2 marketV2;

    // 代理地址
    address marketProxy;
    address nftProxy;

    // 测试用户
    address[] public users;
    address deployer;

    // Permit 类型哈希
    bytes32 nftPermitTypeHash;
    bytes32 erc20PermitTypeHash;

    // DOMAIN_SEPARATOR
    bytes32 nftDomainSeparator;
    bytes32 erc20DomainSeparator;

    // 事件定义
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
        deployer = address(this);

        // 部署 Token 合约
        token = new MyTokenPermit(100000 ether);

        // 创建测试用户
        for (uint256 i = 0; i < 5; i++) {
            address user = vm.addr(i + 1);
            users.push(user);
            token.transfer(user, 10000 ether);
        }

        // 使用透明代理部署NFT 和 NFTMarketV1 合约
        // 设置代理部署选项
        Options memory opts;

        // 跳过所有安全检查
        opts.unsafeSkipAllChecks = true;

        // 部署透明代理合约
        nftProxy = Upgrades.deployTransparentProxy(
            "SimpleNFTV1.sol:SimpleNFTV1",  // 逻辑合约名称（指定合约名称以避免歧义）
            deployer,           // ProxyAdmin 的 owner 地址
            abi.encodeCall(SimpleNFTV1.initialize, ("SimpleNFT", "SNFT")),  // 初始化参数
            opts                // 部署选项
        );

        marketProxy = Upgrades.deployTransparentProxy(
            "NFTMarketV1.sol:NFTMarketV1",  // 逻辑合约名称（指定合约名称以避免歧义）
            deployer,           // ProxyAdmin 的 owner 地址
            abi.encodeCall(NFTMarketV1.initialize, (address(token))),  // 初始化参数
            opts                // 部署选项
        );


        // 初始化类型哈希
        nftPermitTypeHash = keccak256("Permit(address spender,uint256 tokenId,uint256 price,uint256 nonce,uint256 deadline)");
        erc20PermitTypeHash = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    }

    // ==================== V1版本测试 ====================
    /**
     * @notice 测试在 V1 版本上铸造 NFT
     */
    function test_mintNFTOnV1() public {
        vm.startPrank(deployer);
        SimpleNFTV1 nft = SimpleNFTV1(nftProxy);
        // 为用户铸造 NFT
        for (uint256 i = 0; i < 3; i++) {
            // 如果用户有nft，就不用铸造了
            if (nft.balanceOf(users[i]) != 0) {
                continue;
            }

            uint256 tokenId = nft.mint(users[i], vm.toString(i));
            assertEq(tokenId, i, "Token ID should match");
        }
        vm.stopPrank();

        console.log("V1 mint nft success");

        // 验证所有权
        assertEq(SimpleNFTV1(nftProxy).ownerOf(0), users[0]);
        assertEq(SimpleNFTV1(nftProxy).ownerOf(1), users[1]);
        assertEq(SimpleNFTV1(nftProxy).ownerOf(2), users[2]);
    }

    /**
     * @notice 测试 V1 版本的上架功能
     */
    function test_listOnV1() public {
        test_mintNFTOnV1();

        vm.startPrank(users[0]);
        SimpleNFTV1 nft = SimpleNFTV1(nftProxy);
        NFTMarketV1 market = NFTMarketV1(marketProxy);

        // 授权
        nft.setApprovalForAll(marketProxy, true);

        // 上架
        uint256 listingId = market.list(nftProxy, 0, 100 ether);
        assertEq(listingId, 0, "First listing ID should be 0");

        // 验证上架信息
        NFTMarketV1.Listing memory listing = market.getListing(0);

        assertEq(listing.listingId, 0);
        assertEq(listing.seller, users[0]);
        assertEq(listing.nftContract, nftProxy);
        assertEq(listing.tokenId, 0);
        assertEq(listing.price, 100 ether);
        assertTrue(listing.active);

        vm.stopPrank();

        console.log("V1 list nft success");
    }

    /**
     * @notice 测试 V1 版本的购买功能
     */
    function test_buyOnV1() public {
        test_listOnV1();

        vm.startPrank(users[1]);
        NFTMarketV1 market = NFTMarketV1(marketProxy);

        // 授权 Token
        token.approve(marketProxy, 100 ether);

        // 购买
        market.buyNFT(0);

        // 验证所有权转移
        assertEq(SimpleNFTV1(nftProxy).ownerOf(0), users[1]);

        // 验证 Token 转移
        assertEq(token.balanceOf(users[1]), 10000 ether - 100 ether);
        assertEq(token.balanceOf(users[0]), 10000 ether + 100 ether);

        // 验证 Listing 已关闭
        NFTMarketV1.Listing memory listing = market.getListing(0);
        assertFalse(listing.active);

        vm.stopPrank();

        console.log("V1 buy nft success");
    }

    /**
     * @notice 测试 V1 版本的取消上架功能
     */
    function test_cancelListingOnV1() public {
        test_listOnV1();

        vm.startPrank(users[0]);
        NFTMarketV1 market = NFTMarketV1(marketProxy);

        // 取消上架
        market.cancelListing(0);

        // 验证 Listing 已关闭
        NFTMarketV1.Listing memory listing = market.getListing(0);
        assertFalse(listing.active);

        vm.stopPrank();

        console.log("V1 cancel listing success");
    }


    // ==================== 升级测试 ====================

    /**
     * @notice 测试将 NFT 从 V1 升级到 V2
     */
    function test_upgradeNFTToV2() public {
        test_mintNFTOnV1();

        // 记录升级前的状态
        string memory nameBefore = SimpleNFTV1(nftProxy).name();
        string memory symbolBefore = SimpleNFTV1(nftProxy).symbol();

        console.log("before upgrade:");
        console.log("  Name:", nameBefore);
        console.log("  Symbol:", symbolBefore);

        // 升级NFT合约到 V2
        vm.startPrank(deployer);

        Options memory nftOpts;
        nftOpts.unsafeSkipAllChecks = true;           // 跳过所有安全检查
        nftOpts.referenceContract = "SimpleNFTV1.sol:SimpleNFTV1";  // 设置参考合约

        Upgrades.upgradeProxy(
            nftProxy,   // 代理合约地址
            "SimpleNFTV2.sol:SimpleNFTV2",                // 新实现合约
            abi.encodeCall(SimpleNFTV2.reinitialize, ()), // 调用 reinitialize 初始化 EIP712
            nftOpts                                       // 部署选项
        );

        vm.stopPrank();

        // 验证升级后状态保持一致
        assertEq(SimpleNFTV2(nftProxy).name(), nameBefore, "Name should be preserved");
        assertEq(SimpleNFTV2(nftProxy).symbol(), symbolBefore, "Symbol should be preserved");

        // 验证所有权保持不变
        assertEq(SimpleNFTV2(nftProxy).ownerOf(0), users[0], "Ownership of token 0 should be preserved");
        assertEq(SimpleNFTV2(nftProxy).ownerOf(1), users[1], "Ownership of token 1 should be preserved");
        assertEq(SimpleNFTV2(nftProxy).ownerOf(2), users[2], "Ownership of token 2 should be preserved");

        // 验证 URI 保持不变
        assertEq(SimpleNFTV2(nftProxy).tokenURI(0), unicode"0", "Token URI should be preserved");
        assertEq(SimpleNFTV2(nftProxy).tokenURI(1), unicode"1", "Token URI should be preserved");
        assertEq(SimpleNFTV2(nftProxy).tokenURI(2), unicode"2", "Token URI should be preserved");

        console.log("upgrade nft to v2 success");
    }

    /**
     * @notice 测试将 Market 从 V1 升级到 V2
     */
    function test_upgradeMarketToV2() public {
        test_buyOnV1();

        // 记录升级前的状态
        uint256 listingCounterBefore = NFTMarketV1(marketProxy).listingCounter();
        IERC20 paymentTokenBefore = NFTMarketV1(marketProxy).paymentToken();

        console.log("before upgrade:");
        console.log("  Listing Counter:", listingCounterBefore);
        console.log("  Payment Token:", address(paymentTokenBefore));

        // 升级NFTMarket合约到 V2
        vm.startPrank(deployer);

        Options memory nftMarketOpts;
        nftMarketOpts.unsafeSkipAllChecks = true;           // 跳过所有安全检查
        nftMarketOpts.referenceContract = "NFTMarketV1.sol:NFTMarketV1";  // 设置参考合约

        Upgrades.upgradeProxy(
            marketProxy,  // 代理合约地址
            "NFTMarketV2.sol:NFTMarketV2",               // 新实现合约
            "",                                          // 初始化参数
            nftMarketOpts                                // 部署选项
        );
        
        vm.stopPrank();

        // 验证升级后状态保持一致
        assertEq(NFTMarketV2(marketProxy).listingCounter(), listingCounterBefore, "Listing counter should be preserved");
        assertEq(address(NFTMarketV2(marketProxy).paymentToken()), address(paymentTokenBefore), "Payment token should be preserved");

        // 验证 Listing 数据保持不变
        NFTMarketV2.Listing memory listing = NFTMarketV2(marketProxy).getListing(0);

        assertEq(listing.listingId, 0);
        assertEq(listing.seller, users[0]);
        assertEq(listing.nftContract, nftProxy);
        assertEq(listing.tokenId, 0);
        assertEq(listing.price, 100 ether);
        assertFalse(listing.active, "Listing should be inactive after purchase");

        console.log("upgrade market to v2 success");
    }

    /**
     * @notice 测试完整的升级流程：升级后继续使用
     */
    function test_upgradeAndContinueUsage() public {
        // // V1 阶段：上架并购买一个 NFT
        // test_buyOnV1();

        // 升级到 V2
        test_upgradeNFTToV2();
        test_upgradeMarketToV2();

        console.log("start to test v2 market...");

        // V2 阶段：铸造新的 NFT
        vm.startPrank(deployer);
        SimpleNFTV2 nft = SimpleNFTV2(nftProxy);
        nft.mint(users[3], "3");
        vm.stopPrank();

        // V2 阶段：使用 Permit 上架
        vm.startPrank(users[3]);
        NFTMarketV2 market = NFTMarketV2(marketProxy);

        // 构造 Permit 签名
        // nftPermitTypeHash = keccak256("Permit(address spender,uint256 tokenId,uint256 price,uint256 nonce,uint256 deadline)");
        uint256 deadline = block.timestamp + 10000;
        nftDomainSeparator = nft.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            nftPermitTypeHash,
            marketProxy,     // spender 是市场合约地址
            uint256(3),
            uint256(200 ether),
            nft.nonces(users[3]),
            deadline
        ));

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", nftDomainSeparator, structHash));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(4, digest); // users[3] 的私钥是 4

        // 上架（使用 permit 签名）
        uint256 listingId = market.list(nftProxy, 3, 200 ether, deadline, v, r, s);
        assertEq(listingId, 1, "Second listing ID should be 1");

        console.log("v2 market list success");
        vm.stopPrank();

        // V2 阶段：使用 PermitBuy 购买
        vm.startPrank(users[4]);

        // 构造 ERC20 Permit 签名
        erc20DomainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 erc20StructHash = keccak256(abi.encode(
            erc20PermitTypeHash,
            users[4],
            marketProxy,
            uint256(200 ether),
            token.nonces(users[4]),
            deadline
        ));

        bytes32 erc20Digest = keccak256(abi.encodePacked("\x19\x01", erc20DomainSeparator, erc20StructHash));
        (uint8 ev, bytes32 er, bytes32 es) = vm.sign(5, erc20Digest); // users[4] 的私钥是 5

        // 购买
        market.permitBuy(1, users[4], deadline, ev, er, es);

        // 验证
        assertEq(SimpleNFTV2(nftProxy).ownerOf(3), users[4]);
        assertEq(token.balanceOf(users[4]), 10000 ether - 200 ether);
        assertEq(token.balanceOf(users[3]), 10000 ether + 200 ether);

        console.log("v2 market permit buy success");
        vm.stopPrank();

        console.log("v2 market upgrade test success");
    }

    /**
     * @notice 测试存储布局兼容性
     */
    function test_storageLayoutCompatibility() public {
        test_mintNFTOnV1();

        // 直接读取存储槽位验证数据
        uint256 slot0 = uint256(vm.load(nftProxy, bytes32(uint256(0))));
        console.log("NFT Slot 0 (tokenIdCounter):", slot0);
        assertEq(slot0, 3, "Token ID counter should be 3");

        // 合约升级到 V2 版本
        vm.startPrank(deployer);

        Options memory nftOpts;
        nftOpts.unsafeSkipAllChecks = true;           // 跳过所有安全检查
        nftOpts.referenceContract = "SimpleNFTV1.sol:SimpleNFTV1";  // 设置参考合约

        Upgrades.upgradeProxy(
            nftProxy,   // 代理合约地址
            "SimpleNFTV2.sol:SimpleNFTV2",                // 新实现合约
            abi.encodeCall(SimpleNFTV2.reinitialize, ()), // 调用 reinitialize 初始化 EIP712
            nftOpts                                       // 部署选项
        );

        vm.stopPrank();

        // 再次读取存储槽位，应该保持不变
        uint256 slot0After = uint256(vm.load(nftProxy, bytes32(uint256(0))));
        console.log("NFT Slot 0 after upgrade:", slot0After);
        assertEq(slot0After, 3, "Token ID counter should still be 3 after upgrade");

        console.log("storage layout compatibility test success");
    }

    /**
     * @notice 测试 V2 的新功能
     */
    function test_V2NewFeatures() public {
        test_upgradeNFTToV2();

        SimpleNFTV2 nft = SimpleNFTV2(nftProxy);

        // 测试 nonce 功能（V2 新增）
        assertEq(nft.nonces(users[0]), 0, "Initial nonce should be 0");

        // 测试 DOMAIN_SEPARATOR（V2 新增）
        bytes32 domainSeparator = nft.DOMAIN_SEPARATOR();
        assertTrue(domainSeparator != bytes32(0), "DOMAIN_SEPARATOR should be set");
        console.log("v2 nft DOMAIN_SEPARATOR:", vm.toString(domainSeparator));

        console.log("v2 nft new features test success");
    }
}