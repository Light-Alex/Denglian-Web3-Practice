// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface ITokenReceiver {
    function tokensReceived(address from, uint256 amount, bytes calldata data) external returns (bool);
}

interface IERC721Permit {
    function permit(address spender, uint256 tokenId, uint256 price, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function nonces(address owner) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/**
 * @title NFTMarketV2
 * @notice NFT marketplace that uses ERC20 tokens for trading
 * @dev Supports both regular buyNFT and callback-based purchases
 */
contract NFTMarketV2 is ReentrancyGuard, Initializable, ITokenReceiver {

    using SafeERC20 for IERC20;

    struct Listing {
        uint256 listingId;
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;      // Price in ERC20 tokens
        bool active;
    }

    // The ERC20 token used for payments 
    IERC20 public paymentToken;

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

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        // 禁用构造函数，使用 initialize 替代
        _disableInitializers();
    }

    function initialize(address _paymentToken) external initializer {
        require(_paymentToken != address(0), "Invalid token address");
        paymentToken = IERC20(_paymentToken);
    }


    /**
     * @notice List an NFT for sale
     * @param nftContract Address of the NFT contract
     * @param tokenId Token ID of the NFT
     * @param price Price in ERC721 token
     * @param deadline Expiration time of the ERC721 permit
     * @param v ECDSA signature parameter for ERC721 permit
     * @param r ECDSA signature parameter for ERC721 permit
     * @param s ECDSA signature parameter for ERC721 permit
     * @return listingId The ID of the created listing
     */
    function list(
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant returns (uint256) {
        require(price > 0, "Price must be greater than 0");
        require(nftContract != address(0), "Invalid NFT contract");
        
        IERC721Permit nft = IERC721Permit(nftContract);
        nft.permit(address(this), tokenId, price, deadline, v, r, s);

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
        paymentToken.approve(address(this), listing.price);

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
     * @param deadline Expiration time of the erc20 permit
     * @param v ECDSA signature parameter for ERC20 permit
     * @param r ECDSA signature parameter for ERC20 permit
     * @param s ECDSA signature parameter for ERC20 permit
     */
    function permitBuy(
        uint256 listingId,
        address buyer,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant {
        Listing storage listing = listings[listingId];
        require(listing.active, "Listing not active");
        require(msg.sender != listing.seller, "Cannot buy own NFT");

        // Verify EIP-2612 permit signature
        IERC20Permit(address(paymentToken)).permit(buyer, address(this), listing.price, deadline, v, r, s);

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
