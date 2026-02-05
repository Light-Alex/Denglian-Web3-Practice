pragma solidity ^0.8.0;

import './interfaces/IUniswapV2Pair.sol';
import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Callee.sol';

// UniswapV2Pair: Uniswap V2 交易对合约
// 实现了自动做市商(AMM)的核心功能，包括流动性提供、代币交换和价格追踪
contract UniswapV2Pair is IUniswapV2Pair, UniswapV2ERC20 {
    using SafeMath  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;  // 最小流动性常量，永久锁定以防止首次供应时的攻击
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));  // transfer函数选择器

    address public factory;  // 工厂合约地址burn
    address public token0;   // 交易对的第一个代币地址（按地址大小排序）
    address public token1;   // 交易对的第二个代币地址

    uint112 private reserve0;           // token0储备量，使用单个存储槽，可通过getReserves访问
    uint112 private reserve1;           // token1储备量，使用单个存储槽，可通过getReserves访问
    uint32  private blockTimestampLast; // 上次更新时间戳，使用单个存储槽，可通过getReserves访问

    uint public price0CumulativeLast;  // token0的价格累计值（用于TWAP预言机）
    uint public price1CumulativeLast;  // token1的价格累计值（用于TWAP预言机）
    uint public kLast; // reserve0 * reserve1，最近一次流动性事件后的值

    uint private unlocked = 1;  // 重入锁状态标志：1=未锁定，0=锁定
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // 获取当前储备量和时间戳
    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    // 安全转账函数，处理代币转账并检查返回值
    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    constructor() {
        factory = msg.sender;  // 记录工厂合约地址
    }

    // called once by the factory at time of deployment
    // 初始化交易对，由工厂合约在部署时调用一次
    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
    }

    // update reserves and, on the first call per block, price accumulators
    // 更新储备量，并在每个区块首次调用时更新价格累计器
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= type(uint112).max && balance1 <= type(uint112).max, 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            // 计算并累加价格：price0 = reserve1/reserve0, price1 = reserve0/reserve1
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    // 如果开启手续费，铸造流动性代币给手续费接收地址（相当于增长量的1/6）
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        // 1. 从工厂合约获取手续费接收地址
        address feeTo = IUniswapV2Factory(factory).feeTo();

        // 2. 判断是否开启手续费：feeTo不为零地址表示开启
        feeOn = feeTo != address(0);

        // 3. 缓存kLast，节省gas（避免多次读取存储）
        uint _kLast = kLast; // gas savings

        // 4. 如果手续费开启
        if (feeOn) {
            if (_kLast != 0) {
                // 4.1 计算当前和上次的√K值
                // K = reserve0 × reserve1（恒定乘积）
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1)); // 当前√K
                uint rootKLast = Math.sqrt(_kLast); // 上次√K

                // // 4.2 流动性增长了，计算协议应得的手续费
                if (rootK > rootKLast) {
                    // 计算流动性增长并铸造给feeTo
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast)); // 分子：总供应量 × (√K当前 - √K上次)
                    uint denominator = rootK.mul(5).add(rootKLast);         // 分母：5 × √K当前 + √K上次

                    // 4.3 计算手续费流动性 约等于 totalSupply*增长比例(rootK/rootKLast-1) / 6
                    // 公式推导：liquidity = totalSupply × (rootK - rootKLast) / (5×rootK + rootKLast)
                    // 这个公式保证手续费约为流动性增长的1/6
                    uint liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity); // 铸造LP代币给feeTo地址
                }
            }
        } else if (_kLast != 0) {
            // 5. 如果手续费关闭，清除kLast以节省gas（下次计算时重新开始）
            kLast = 0;
        }
    }

    // this low-level function should be called from a contract which performs important safety checks
    // 添加流动性，铸造LP代币给提供者（应通过执行安全检查的外部合约调用）
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20(token0).balanceOf(address(this));
        uint balance1 = IERC20(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);  // 新增的token0数量
        uint amount1 = balance1.sub(_reserve1);  // 新增的token1数量

        // 计算并铸造手续费流动性 约等于 totalSupply*增长比例(rootK/rootKLast-1) / 6
        bool feeOn = _mintFee(_reserve0, _reserve1);

        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            // 首次添加流动性：使用几何平均计算，并永久锁定最小流动性(1000 wei)，防止价格操纵：攻击者无法以微小成本设置初始价格
            // liquidity = 几何平均(amount0 * amount1) - MINIMUM_LIQUIDITY
            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            // 后续添加：按现有流动性比例计算新增流动性
            // liquidity = min(新增token0数量 / 旧reserve0) * 总供应量, (新增token1数量 / 旧reserve1) * 总供应量 )
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');

        // 铸造LP代币给提供者
        _mint(to, liquidity);

        // 更新 reserves 并记录最新时间戳
        _update(balance0, balance1, _reserve0, _reserve1);

        // 如果开启手续费，更新kLast（缓存当前K值，用于后续计算手续费）
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // 移除流动性，销毁LP代币并返还代币（应通过执行安全检查的外部合约调用）
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        // 缓存池子当前的储备量
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings

        // 缓存代币地址
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings

        // 查询 Pair 合约当前持有的代币数量
        uint balance0 = IERC20(_token0).balanceOf(address(this));
        uint balance1 = IERC20(_token1).balanceOf(address(this));

        // 查询Pair合约当前持有的LP代币数量(to地址需要提前把LP代币转给Pair合约)
        uint liquidity = balanceOf[address(this)];

        // 处理协议手续费
        bool feeOn = _mintFee(_reserve0, _reserve1);

        // 缓存总供应量
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        // 计算移除流动性时，用户能收到的代币数量（按流动性比例分配）
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');

        // 销毁 LP 代币
        _burn(address(this), liquidity);

        // 将代币转给用户
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);

        // 更新 reserves 并记录最新时间戳
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);

        // 如果开启手续费，更新kLast（缓存当前K值，用于后续计算手续费）
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
    }

    // this low-level function should be called from a contract which performs important safety checks
    // 代币交换函数（应通过执行安全检查的外部合约调用）
    // amount0Out: 输出的token0数量，amount1Out: 输出的token1数量
    // to: 接收代币的地址
    // data: 闪贷回调数据
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');

        // 缓存池子当前的储备量
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');

        uint balance0;
        uint balance1;

        // 乐观转账（Optimistic Transfer）: 先转出代币，不检查用户是否转回
        { // scope for _token{0,1}, avoids stack too deep errors
        address _token0 = token0;
        address _token1 = token1;
        require(to != _token0 && to != _token1, 'UniswapV2: INVALID_TO');

        // 先转出代币给用户
        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens
        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens

        // 如果提供了data，调用接收方的uniswapV2Call函数（支持闪贷）
        if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);

        // 重新查询 Pair 合约的余额
        balance0 = IERC20(_token0).balanceOf(address(this));
        balance1 = IERC20(_token1).balanceOf(address(this));
        }

        // 计算实际输入的代币数量
        // 实际输入 = 新余额 - (旧储备 - 输出量)
        // 示例：用户输入4000 ETH，输出1 ETH
        // - 旧储备：100 ETH
        // - 输出：1 ETH
        // - 如果用户转回 4000 USDC：
        // - 新余额 = 100 - 1 = 99 ETH
        // - amount0In = 99 - (100 - 1) = 99 - 99 = 0 ETH
        // - amount1In = 404,000 - (400,000 - 0) = 4,000 USDC ✓
        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;
        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');


        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
        // 检查恒定乘积公式 (x + 0.003*x)*(y + 0.003*y) >= x*y
        // 手续费为0.3%，即1000中有3份
        // 计算调整后的余额（考虑手续费）
        // balance0Adjusted = balance0 × 1000 - amountIn × 3(放大了1000倍, 原始实际参与x * y = k计算的balance: balance0 - amount0In*(3/1000))
        // balance1Adjusted = balance1 × 1000 - amountIn × 3
        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(3));
        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(3));
        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'UniswapV2: K');
        }

        // 更新 reserves 并记录最新时间戳
        _update(balance0, balance1, _reserve0, _reserve1);
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    // 强制将余额转为储备，提取多余代币
    function skim(address to) external lock {
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    // 强制将储备同步为当前余额（用于处理直接转账等情况）
    function sync() external lock {
        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);
    }
}
