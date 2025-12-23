//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IERC20Callback {
    function transferFromWithCallback(address _from, address _to, uint256 _amount, bytes calldata data) external returns (bool);
}

contract NFTMarket is IERC721Receiver {
    mapping (uint => uint) public tokenIdPrice;
    mapping(uint => address) public tokenSeller;
    address public immutable token;
    address public immutable nftToken;

    constructor(address _token, address _nftToken) {
        token = _token;
        nftToken = _nftToken;
    }

    // 定义修饰器
    modifier onlyApproved(uint256 _tokenId, address _nftContract) {
        // 确保NFT合约地址和tokenId有效
        require(_tokenId >= 0, "NFTMarket: tokenId must be greater than or equal to zero");
        require(_nftContract != address(0), "NFTMarket: NFT contract address cannot be zero");

        IERC721 nftContract = IERC721(_nftContract);
        address owner = nftContract.ownerOf(_tokenId);
        require(
            msg.sender == owner || 
            nftContract.isApprovedForAll(owner, msg.sender) || 
            nftContract.getApproved(_tokenId) == msg.sender,
            "NFTMarket: caller is not the owner of the NFT or not approved"
        );
        _;
    }

    // 当NFT（ERC721代币）通过 safeTransferFrom 方法转移到合约时，这个函数会被自动调用
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }

    function tokensReceived(address _from, uint256 _amount, bytes calldata _data) external returns (bool) {
        require(msg.sender == token, "NFTMarket: caller must be the payment token contract");

        // 解析_data, 提取tokenId
        require(_data.length == 32, "NFTMarket: invalid data length");
        uint256 tokenId = abi.decode(_data, (uint256));

        // 确保saleId有效
        require(tokenId >= 0, "NFTMarket: tokenId must be greater than or equal to zero");

        // 确保支付价格等于NFT价格
        require(_amount == tokenIdPrice[tokenId], "NFTMarket: payment amount must equal token price");

        // 将Token从市场合约中提取到卖家
        require(IERC20(token).transfer(tokenSeller[tokenId], _amount), "NFTMarket: token transfer failed");

        // 将NFT所有权转移到买家
        IERC721(nftToken).safeTransferFrom(address(this), _from, tokenId, "");

        tokenIdPrice[tokenId] = 0;
        tokenSeller[tokenId] = address(0);

        return true;
    }

    // 上架NFT
    function list(uint256 tokenId, uint256 price) external onlyApproved(tokenId, nftToken) {
        require(tokenIdPrice[tokenId] == 0, "NFTMarket: NFT already listed");
        IERC721(nftToken).safeTransferFrom(msg.sender, address(this), tokenId, "");
        tokenIdPrice[tokenId] = price;
        tokenSeller[tokenId] = msg.sender;
    }

    function buy(uint256 tokenId, uint256 price) external {
        require(price >= tokenIdPrice[tokenId], "NFTMarket: not enough price");
        require(IERC721(nftToken).ownerOf(tokenId) == address(this), "NFTMarket: NFT not for sale");
        // 确保调用者是买家
        require(msg.sender != tokenSeller[tokenId], "NFTMarket: caller is the seller");

        require(IERC20(token).transferFrom(msg.sender, tokenSeller[tokenId], tokenIdPrice[tokenId]), "NFTMarket: token transfer failed");
        IERC721(nftToken).safeTransferFrom(address(this), msg.sender, tokenId, "");
    }

    // 购买NFT, 调用CallBack函数
    function buyNFT(uint256 tokenId, uint256 price) external {
        require(price >= tokenIdPrice[tokenId], "NFTMarket: not enough price");
        require(IERC721(nftToken).ownerOf(tokenId) == address(this), "NFTMarket: NFT not for sale");
        
        require(IERC20Callback(token).transferFromWithCallback(msg.sender, address(this), tokenIdPrice[tokenId], abi.encode(tokenId)), "NFTMarket: token transfer failed");
    }
}
