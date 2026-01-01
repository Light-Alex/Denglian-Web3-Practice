// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 导入ERC20标准接口，与ERC20合约交互
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// 定义接收代币回调的接口
interface ITokenReceiver {
    function tokensReceivedWithData(address from, uint256 amount, bytes calldata data) external returns (bool);
}

// 导入ERC721标准接口，与ERC721合约交互
interface IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function transfer(address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// 扩展的ERC20接口，添加带有回调功能的转账函数
interface IExtendedERC20 is IERC20 {
    function transferWithCallback(address _to, uint256 _amount) external returns (bool);
    function transferWithCallbackWithData(address _to, uint256 _amount, bytes calldata _data) external returns (bool);
    function transferFromWithCallbackWithData(address _from, address _to, uint256 _amount, bytes calldata _data) external returns (bool);
}

// NFTMarket合约
contract NFTMarket is ITokenReceiver {
    // 使用扩展的ERC20合约地址
    IExtendedERC20 public erc20Token;

   // NFT上架信息结构体
    struct NFTSale {
        uint256 tokenId;     // NFT的tokenId
        address nftContract; // NFT合约地址
        address seller;      // 卖家地址
        uint256 price;       // 上架价格（以Token为单位）
        bool isActive;       // 是否处于活跃状态
    }

    // 所有上架的NFT, 以saleId为唯一标识
    mapping(uint256 => NFTSale) public nftSales;
    uint256 public nextSaleId; // 下一个上架ID

    // 定义事件
    event NFTSaleCreated(uint256 indexed saleId, address indexed nftContract, uint256 tokenId, address seller, uint256 price);
    event NFTSold(uint256 indexed saleId, address indexed nftContract, uint256 tokenId, address seller, uint256 price, address buyer);
    event NFTSaleCanceled(uint256 indexed saleId, address indexed nftContract, uint256 tokenId, address seller);
    event NFTSaleRecovered(uint256 indexed saleId, address indexed nftContract, uint256 tokenId, address seller);

    // 定义修饰器
    modifier onlyApproved(uint256 _tokenId, address _nftContract) {
        // 确保NFT合约地址和tokenId有效
        require(_tokenId > 0, "NFTMarket: tokenId must be greater than zero");
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

    // 构造函数，设置支付代币地址
    constructor(address _paymentTokenAddress) {
        require(_paymentTokenAddress != address(0), "NFTMarket: payment token address cannot be zero");
        erc20Token = IExtendedERC20(_paymentTokenAddress);
    }

    // 上架NFT
    function list(address _nftContract, uint256 _tokenId, uint256 _price) external onlyApproved(_tokenId, _nftContract) returns (uint256) {
        // 确保上架价格大于0
        require(_price > 0, "NFTMarket: price must be greater than zero");

        // 确保NFT未被上架
        require(nftSales[nextSaleId].tokenId == 0, "NFTMarket: NFT is already listed");

        // 创建新的上架记录
        nftSales[nextSaleId] = NFTSale({
            tokenId: _tokenId,
            nftContract: _nftContract,
            seller: msg.sender,
            price: _price,
            isActive: true
        });

        // 增加上架ID
        nextSaleId++;

        // 触发事件
        emit NFTSaleCreated(nextSaleId, _nftContract, _tokenId, msg.sender, _price);
        
        // 返回上架ID
        return nextSaleId - 1;
    }
    
    // 取消上架
    function cancelListing(uint256 _saleId) external onlyApproved(nftSales[_saleId].tokenId, nftSales[_saleId].nftContract) {
        // 确保上架ID有效
        require(_saleId < nextSaleId, "NFTMarket: invalid saleId");

        NFTSale storage nftSale = nftSales[_saleId];

        // 检查上架是否活跃
        require(nftSale.isActive, "NFTMarket: sale is not active");

        // 确保调用者是上架者
        require(msg.sender == nftSale.seller, "NFTMarket: caller is not the seller");

        // 标记为非活跃状态
        nftSale.isActive = false;

        // 触发事件
        emit NFTSaleCanceled(_saleId, nftSale.nftContract, nftSale.tokenId, nftSale.seller);
    }

    // 购买NFT
    function buyNFT(uint256 _saleId) external {
        // 确保上架ID有效
        require(_saleId < nextSaleId, "NFTMarket: invalid saleId");

        NFTSale storage nftSale = nftSales[_saleId];

        // 检查上架是否活跃
        require(nftSale.isActive, "NFTMarket: sale is not active");

        // 确保购买金额足够
        require(erc20Token.balanceOf(msg.sender) >= nftSale.price, "NFTMarket: insufficient token balance");

        // 将NFT上架信息设置为非活跃状态
        nftSale.isActive = false;

        // 从买家账户中提取Token到卖家账户
        require(erc20Token.transferFrom(msg.sender, nftSale.seller, nftSale.price), "NFTMarket: token transfer failed");

        // 转移NFT所有权到买家
        IERC721(nftSale.nftContract).transferFrom(nftSale.seller, msg.sender, nftSale.tokenId);

        // 触发事件
        emit NFTSold(_saleId, nftSale.nftContract, nftSale.tokenId, nftSale.seller, nftSale.price, msg.sender);
    }

    // 实现tokensReceived接口, 处理通过 transferWithCallbackWithData 接收到的代币
    function tokensReceivedWithData(address _from, uint256 _amount, bytes calldata _data) external returns (bool) {
        // 确保调用者是支付合约
        require(msg.sender == address(erc20Token), "NFTMarket: caller is not the payment token contract");

        // 解析_data, 提取saleId
        require(_data.length == 32, "NFTMarket: invalid data length");
        uint256 saleId = abi.decode(_data, (uint256));

        // 确保saleId有效
        require(saleId < nextSaleId, "NFTMarket: invalid saleId");

        // 确保上架是否活跃
        NFTSale storage nftSale = nftSales[saleId];
        require(nftSale.isActive, "NFTMarket: sale is not active");

        // 确保支付价格等于NFT价格
        require(_amount == nftSale.price, "NFTMarket: payment amount must equal sale price");

        // 将NFT上架信息设置为非活跃状态
        nftSale.isActive = false;

        // 将Token从市场合约中提取到卖家
        require(erc20Token.transfer(nftSale.seller, _amount), "NFTMarket: token transfer failed");

        // 将NFT所有权转移到买家
        IERC721(nftSale.nftContract).transferFrom(nftSale.seller, _from, nftSale.tokenId);

        // 触发事件
        emit NFTSold(saleId, nftSale.nftContract, nftSale.tokenId, nftSale.seller, nftSale.price, _from);

        return true;
    }

    // 使用transferWithCallbackWithData购买NFT
    function buyNFTWithCallback(uint256 _saleId) external {
        // 确保上架ID有效
        require(_saleId < nextSaleId, "NFTMarket: invalid saleId");

        NFTSale storage nftSale = nftSales[_saleId];

        // 检查上架是否活跃
        require(nftSale.isActive, "NFTMarket: sale is not active");

        // 确保买家购买金额足够
        require(erc20Token.balanceOf(msg.sender) >= nftSale.price, "NFTMarket: insufficient token balance");

        // 调用transferWithCallbackWithData函数，将买家的Token转移到市场合约并附带上saleId
        require(erc20Token.transferFromWithCallbackWithData(msg.sender, address(this), nftSale.price, abi.encode(_saleId)), "NFTMarket: token transfer with callback failed");
    }
}