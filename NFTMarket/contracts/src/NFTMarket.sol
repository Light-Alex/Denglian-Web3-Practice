// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title NFTMarket
 * @notice NFT marketplace that uses ERC20 tokens for trading
 * @dev Supports both regular buyNFT and callback-based purchases
 */
contract NFTMarket is ReentrancyGuard {

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

    constructor(address _paymentToken) {
        require(_paymentToken != address(0), "Invalid token address");
        paymentToken = IERC20(_paymentToken);
    }

    /**
     * @notice List an NFT for sale
     * @param nftContract Address of the NFT contract
     * @param tokenId Token ID of the NFT
     * @param price Price in ERC20 tokens
     * @return listingId The ID of the created listing
     */
    function list(
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) external nonReentrant returns (uint256) {
        require(price > 0, "Price must be greater than 0");
        require(nftContract != address(0), "Invalid NFT contract");

        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "Not the owner");
        require(
            nft.isApprovedForAll(msg.sender, address(this)) ||
                nft.getApproved(tokenId) == address(this),
            "Market not approved"
        );

        uint256 listingId = listingCounter++;
        listings[listingId] = Listing({
            listingId: listingId,
            seller: msg.sender,
            nftContract: nftContract,
            tokenId: tokenId,
            price: price,
            active: true
        });

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
        require(
            paymentToken.transferFrom(msg.sender, listing.seller, listing.price),
            "Payment transfer failed"
        );

        // Transfer NFT from seller to buyer
        IERC721(listing.nftContract).safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId
        );

        emit NFTPurchased(listingId, msg.sender, listing.seller, listing.price);
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
        require(
            paymentToken.transfer(listing.seller, amount),
            "Payment transfer failed"
        );

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
