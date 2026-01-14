// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@soliditylabs/erc721-permit/contracts/interfaces/IERC721Permit.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title NFTMarket
 * @notice NFT marketplace that uses ERC20 tokens for trading
 * @dev Supports both regular buyNFT and callback-based purchases
 */
contract NFTMarket is ReentrancyGuard, EIP712 {

    using SafeERC20 for IERC20;

    // 使用ECDSA库进行椭圆曲线数字签名验证
    using ECDSA for bytes32;

    // 白名单签名相关的常量
    bytes32 private constant _WHITELIST_TYPEHASH = 
        keccak256("Whitelist(address buyer,uint256 listingId)");
    
    address public immutable whitelistSigner; // 项目方签名地址

    struct Listing {
        uint256 listingId;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;      // Price in ERC20 tokens
        bool active;
    }

    // The ERC20 token used for payments 
    // Gas优化项：paymentToken 是一个不可变变量，所以可设置为 immutable
    IERC20 public immutable paymentToken;

    // Mapping from listing ID to Listing
    mapping(uint256 => Listing) public listings;
    uint256 public listingCounter;

    // Events
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

    constructor(address _paymentToken, address _whitelistSigner) EIP712("NFTMarket", "1.0.0") {
        require(_paymentToken != address(0), "Invalid token address");
        paymentToken = IERC20(_paymentToken);

        require(_whitelistSigner != address(0), "Invalid whitelist signer");
        whitelistSigner = _whitelistSigner;
    }

    /**
     * @notice List an NFT for sale
     * @param nftContract Address of the NFT contract
     * @param tokenId Token ID of the NFT
     * @param price Price in ERC20 tokens
     * @param nftPermitDeadline Expiration time of the nft permit
     * @param nftPermitSignature ERC-721 permit signature
     * @return listingId The ID of the created listing
     */
    function list(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 nftPermitDeadline,
        bytes memory nftPermitSignature
    ) external nonReentrant returns (uint256) {
        require(price > 0, "Price must be greater than 0");
        require(nftContract != address(0), "Invalid NFT contract");
        
        // Verify ERC-721 permit signature
        IERC721Permit(nftContract).permit(address(this), tokenId, nftPermitDeadline, nftPermitSignature);

        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");

        // // Gas优化项：已经完成了授权，这些检查是冗余的
        // require(
        //     nft.isApprovedForAll(msg.sender, address(this)) ||
        //         nft.getApproved(tokenId) == address(this),
        //     "Market not approved"
        // );

        // uint256 listingId = listingCounter++;
        // Gas优化项：listingCounter 不会溢出（除非你有 2^256 个上架），所以可以安全地跳过检查
        uint256 listingId = listingCounter;
        unchecked {
            listingCounter++;
        }
        
        // listings[listingId] = Listing({
        //     listingId: listingId,
        //     seller: msg.sender,
        //     nftContract: nftContract,
        //     tokenId: tokenId,
        //     price: price,
        //     active: true
        // });
        // Gas优化项：直接赋值（减少一次 SSTORE）
        Listing storage listing = listings[listingId];
        listing.listingId = listingId;
        listing.seller = msg.sender;
        listing.nftContract = nftContract;
        listing.tokenId = tokenId;
        listing.price = price;
        listing.active = true;

        emit NFTListed(listingId, msg.sender, nftContract, tokenId, price);

        return listingId;
    }

    /**
     * @notice Buy an NFT using ERC20 tokens
     * @param listingId The ID of the listing to purchase
     */
    function buyNFT(uint256 listingId) external nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(msg.sender != listing.seller, "Cannot buy own NFT");

        // Mark as inactive
        listing.active = false;

        // Transfer payment tokens from buyer to seller
        paymentToken.safeTransferFrom(msg.sender, listing.seller, listing.price);

        // Transfer NFT from seller to buyer
        IERC721(listing.nftContract).safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        emit NFTPurchased(listingId, msg.sender, listing.seller, listing.price);
    }

    /**
     * @notice Buy an NFT using ERC20 tokens with permit signature
     * @param listingId The ID of the listing to purchase
     * @param buyer Address of the buyer
     * @param erc20PermitDeadline Expiration time of the erc20 permit
     * @param v ECDSA signature parameter for ERC20 permit
     * @param r ECDSA signature parameter for ERC20 permit
     * @param s ECDSA signature parameter for ERC20 permit
     * @param nftPermitDeadline Expiration time of the nft permit
     * @param nftPermitSignature ERC-721 permit signature
     * @param nftWhitelistSignature Whitelist signature for the NFT
     */
    function permitBuy(
        uint256 listingId,
        address buyer,
        uint256 erc20PermitDeadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 nftPermitDeadline,
        bytes calldata nftPermitSignature,   // Gas优化项：calldata 代替 memory
        bytes calldata nftWhitelistSignature // Gas优化项：calldata 代替 memory
    ) external nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(msg.sender != listing.seller, "Cannot buy own NFT");

        // Verify EIP-2612 permit signature
        IERC20Permit(address(paymentToken)).permit(msg.sender, address(this), listing.price, erc20PermitDeadline, v, r, s);

        // Verify ERC-721 permit signature
        IERC721Permit(listing.nftContract).permit(address(this), listing.tokenId, nftPermitDeadline, nftPermitSignature);

        // Verify whitelist signature
        _verifyWhitelistSignature(
            buyer,
            listingId,
            nftWhitelistSignature
        );

        // Mark as inactive
        listing.active = false;

        // Transfer payment tokens from buyer to seller
        paymentToken.safeTransferFrom(buyer, listing.seller, listing.price);

        // Transfer NFT from seller to buyer
        IERC721(listing.nftContract).safeTransferFrom(
            listing.seller,
            buyer,
            listing.tokenId
        );

        emit NFTPurchased(listingId, buyer, listing.seller, listing.price);
    }

    /**
     * @dev Verify whitelist signature for the NFT
     * @param buyer Address of the buyer
     * @param listingId ID of the listing
     * @param whitelistSignature Whitelist signature
     */
    function _verifyWhitelistSignature(
        address buyer,
        uint256 listingId,
        bytes memory whitelistSignature
    ) private view {
        // Reconstruct the whitelist message
        bytes32 structHash = keccak256(
            abi.encode(
                _WHITELIST_TYPEHASH,
                buyer,
                listingId
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = digest.recover(whitelistSignature);

        require(signer != address(0), "ECDSA: invalid signature");
        require(signer == whitelistSigner, "Invalid whitelist signature");
    }

    /**
     * @notice Callback function for receiving tokens
     * @dev Implements purchase when tokens are transferred via transferWithCallback
     * @param from Address sending the tokens (buyer)
     * @param amount Amount of tokens sent
     * @param data Encoded listing ID
     * @return bool Success status
     */
    function tokensReceived(
        address from,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant returns (bool) {
        require(msg.sender == address(paymentToken), "Invalid token");
        require(data.length == 32, "Invalid data");

        // Decode listing ID from data
        uint256 listingId = abi.decode(data, (uint256));

        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(from != listing.seller, "Cannot buy own NFT");
        require(amount == listing.price, "Incorrect amount");

        // Mark as inactive
        listing.active = false;

        // Transfer tokens to seller
        paymentToken.safeTransfer(listing.seller, amount);


        // Transfer NFT to buyer
        IERC721(listing.nftContract).safeTransferFrom(
            listing.seller,
            from,
            listing.tokenId
        );

        emit NFTPurchased(listingId, from, listing.seller, amount);

        return true;
    }

    /**
     * @notice Cancel a listing
     * @param listingId The ID of the listing to cancel
     */
    function cancelListing(uint256 listingId) external {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(listing.seller == msg.sender, "Not the seller");

        listing.active = false;

        emit ListingCancelled(listingId);
    }

    /**
     * @notice Get listing details
     * @param listingId The ID of the listing
     * @return Listing struct
     */
    function getListing(uint256 listingId) external view returns (Listing memory) {
        return listings[listingId];
    }
}
