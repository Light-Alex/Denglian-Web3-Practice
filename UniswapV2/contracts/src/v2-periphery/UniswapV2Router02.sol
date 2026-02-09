pragma solidity ^0.8.0;

import '../v2-core/interfaces/IUniswapV2Factory.sol';
import '../solidity-lib/TransferHelper.sol';

import './interfaces/IUniswapV2Router02.sol';
import './libraries/UniswapV2Library.sol';
import './libraries/SafeMath.sol';
import './interfaces/IERC20.sol';
import './interfaces/IWETH.sol';

/**
 * @title UniswapV2Router02
 * @notice Uniswap V2 路由器合约第二版，为用户提供流动性管理和代币交换的便捷接口
 * @dev 这是 Uniswap V2 的第二版路由器，在 V1 基础上增加了对转账收费代币（fee-on-transfer tokens）的支持
 */
contract UniswapV2Router02 is IUniswapV2Router02 {
    using SafeMath for uint;

    // Uniswap V2 工厂合约地址（不可变）
    address public immutable override factory;
    // WETH（Wrapped Ether）合约地址（不可变）
    address public immutable override WETH;

    // 确保交易在截止时间之前执行
    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'UniswapV2Router: EXPIRED');
        _;
    }

    // 构造函数，初始化路由器
    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    // 接收 ETH 的回退函数
    // only accept ETH via fallback from the WETH contract // 只接受从 WETH 合约回退来的 ETH
    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    // **** ADD LIQUIDITY ****
    // **** 添加流动性 ****
    /**
     * @notice 内部函数：计算添加流动性的最优代币数量
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param amountADesired 用户希望添加的代币A数量
     * @param amountBDesired 用户希望添加的代币B数量
     * @param amountAMin 代币A最小可接受数量（滑点保护）
     * @param amountBMin 代币B最小可接受数量（滑点保护）
     * @return amountA 实际添加的代币A数量
     * @return amountB 实际添加的代币B数量
     */
    function _addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin
    ) internal virtual returns (uint amountA, uint amountB) {
        // create the pair if it doesn't exist yet // 如果交易对不存在则创建
        if (IUniswapV2Factory(factory).getPair(tokenA, tokenB) == address(0)) {
            IUniswapV2Factory(factory).createPair(tokenA, tokenB);
        }
        (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, tokenA, tokenB);
        // 如果是新的流动性池（储备金都为0），使用用户提供的数量
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            // 根据存储金比例代币B数量
            uint amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                // 否则，根据存储金比例代币A数量
                uint amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
                assert(amountAOptimal <= amountADesired);
                require(amountAOptimal >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
    }

    /**
     * @notice 添加 ERC20 代币流动性
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param amountADesired 希望添加的代币A数量
     * @param amountBDesired 希望添加的代币B数量
     * @param amountAMin 代币A最小可接受数量（滑点保护）
     * @param amountBMin 代币B最小可接受数量（滑点保护）
     * @param to 接收流动性代币的地址
     * @param deadline 交易截止时间
     * @return amountA 实际添加的代币A数量
     * @return amountB 实际添加的代币B数量
     * @return liquidity 获得的流动性代币数量
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
        // 计算添加流动性的最优代币数量
        (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);

        // 获取 Uniswap 交易对合约地址
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);

        // 将用户的 ERC20 代币从用户地址转移到 Uniswap 交易对合约中
        TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
        TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);

        // 为用户铸造流动性代币(LP Token)
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    /**
     * @notice 添加 ETH 和 ERC20 代币流动性
     * @param token ERC20代币地址
     * @param amountTokenDesired 希望添加的代币数量
     * @param amountTokenMin 代币最小可接受数量（滑点保护）
     * @param amountETHMin ETH最小可接受数量（滑点保护）
     * @param to 接收流动性代币的地址
     * @param deadline 交易截止时间
     * @return amountToken 实际添加的代币数量
     * @return amountETH 实际添加的ETH数量
     * @return liquidity 获得的流动性代币数量
     */
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external virtual override payable ensure(deadline) returns (uint amountToken, uint amountETH, uint liquidity) {
        // 计算添加流动性的最优代币数量
        (amountToken, amountETH) = _addLiquidity(
            token,
            WETH,
            amountTokenDesired,
            msg.value,
            amountTokenMin,
            amountETHMin
        );

        // 获取 UniswapV2Pair 合约地址
        address pair = UniswapV2Library.pairFor(factory, token, WETH);

        // 将用户的 ERC20 代币从用户地址转移到 UniswapV2Pair 合约中
        TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);

        // 存入ETH换取WETH
        IWETH(WETH).deposit{value: amountETH}();

        // 将用户的 WETH 从用户地址转移到 UniswapV2Pair 合约中
        assert(IWETH(WETH).transfer(pair, amountETH));

        // 为用户铸造流动性代币(LP Token)
        liquidity = IUniswapV2Pair(pair).mint(to);
        // refund dust eth, if any // 如果有多余的ETH，退还给用户
        if (msg.value > amountETH) TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    // **** REMOVE LIQUIDITY ****
    // **** 移除流动性 ****
    /**
     * @notice 移除 ERC20 代币流动性
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountAMin 代币A最小可接受数量（滑点保护）
     * @param amountBMin 代币B最小可接受数量（滑点保护）
     * @param to 接收回退代币的地址
     * @param deadline 交易截止时间
     * @return amountA 回退的代币A数量
     * @return amountB 回退的代币B数量
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
        // 获取 UniswapV2Pair 合约地址
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        bool success = IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair // 将流动性发送到交易对
        require(success, 'UniswapV2Router: TRANSFER_FAILED');

        // 销毁LP Token，获得代币A和代币B
        (uint amount0, uint amount1) = IUniswapV2Pair(pair).burn(to);

        // 排序代币A和代币B，确保 token0 是较小的代币
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);

        // 确保换取的代币A和代币B数量大于等于最小可接受数量
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
        require(amountA >= amountAMin, 'UniswapV2Router: INSUFFICIENT_A_AMOUNT');
        require(amountB >= amountBMin, 'UniswapV2Router: INSUFFICIENT_B_AMOUNT');
    }

    /**
     * @notice 移除 ETH 和 ERC20 代币流动性
     * @param token ERC20代币地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountTokenMin 代币最小可接受数量（滑点保护）
     * @param amountETHMin ETH最小可接受数量（滑点保护）
     * @param to 接收回退代币的地址
     * @param deadline 交易截止时间
     * @return amountToken 回退的代币数量
     * @return amountETH 回退的ETH数量
     */
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountToken, uint amountETH) {
        // 移除流动性，获取代币A和WETH，收款地址是当前合约
        (amountToken, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );

        // 将回退的代币A从当前合约转到用户地址
        TransferHelper.safeTransfer(token, to, amountToken);

        // 将WETH转成ETH在转给当前合约
        IWETH(WETH).withdraw(amountETH);

        // 从当前合约将ETH给用户
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @notice 使用 Permit 签名移除流动性（无需预先授权）
     * @param tokenA 代币A地址
     * @param tokenB 代币B地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountAMin 代币A最小可接受数量（滑点保护）
     * @param amountBMin 代币B最小可接受数量（滑点保护）
     * @param to 接收回退代币的地址
     * @param deadline 交易截止时间
     * @param approveMax 是否授权最大值
     * @param v 签名的v值
     * @param r 签名的r值
     * @param s 签名的s值
     * @return amountA 回退的代币A数量
     * @return amountB 回退的代币B数量
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountA, uint amountB) {
        // 获取 UniswapV2Pair 合约地址
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);

        // EIP2612离线签名方式授权当前合约操作msg.sender的流动性
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);

        // 移除流动性，获取代币A和代币B
        (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
    }

    /**
     * @notice 使用 Permit 签名移除 ETH 流动性（无需预先授权）
     * @param token ERC20代币地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountTokenMin 代币最小可接受数量（滑点保护）
     * @param amountETHMin ETH最小可接受数量（滑点保护）
     * @param to 接收回退代币的地址
     * @param deadline 交易截止时间
     * @param approveMax 是否授权最大值
     * @param v 签名的v值
     * @param r 签名的r值
     * @param s 签名的s值
     * @return amountToken 回退的代币数量
     * @return amountETH 回退的ETH数量
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountToken, uint amountETH) {
        // 获取 UniswapV2Pair 合约地址
        address pair = UniswapV2Library.pairFor(factory, token, WETH);

        // EIP2612离线签名方式授权当前合约操作msg.sender的流动性
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);

        // 移除流动性，获取代币A和ETH
        (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
    }

    // **** REMOVE LIQUIDITY (supporting fee-on-transfer tokens) ****
    // **** 移除流动性（支持转账收费代币） ****
    /**
     * @notice 移除 ETH 流动性（支持转账收费代币）
     * @dev 对于转账收费的代币，使用实际余额而非预计算的数量
     * @param token ERC20代币地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountTokenMin 代币最小可接受数量（滑点保护）
     * @param amountETHMin ETH最小可接受数量（滑点保护）
     * @param to 接收回退代币的地址
     * @param deadline 交易截止时间
     * @return amountETH 回退的ETH数量
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public virtual override ensure(deadline) returns (uint amountETH) {
        // 移除流动性，获取代币A和WETH
        (, amountETH) = removeLiquidity(
            token,
            WETH,
            liquidity,
            amountTokenMin,
            amountETHMin,
            address(this),
            deadline
        );


        // 转移当前余额（已扣除转账费用）
        // 将代币A转给用户
        TransferHelper.safeTransfer(token, to, IERC20(token).balanceOf(address(this)));

        // 将WETH换成ETH，提取到当前合约
        IWETH(WETH).withdraw(amountETH);
        // 将ETH转给用户
        TransferHelper.safeTransferETH(to, amountETH);
    }

    /**
     * @notice 使用 Permit 签名移除 ETH 流动性（支持转账收费代币，无需预先授权）
     * @dev 对于转账收费的代币，使用实际余额而非预计算的数量
     * @param token ERC20代币地址
     * @param liquidity 要移除的流动性代币数量
     * @param amountTokenMin 代币最小可接受数量（滑点保护）
     * @param amountETHMin ETH最小可接受数量（滑点保护）
     * @param to 接收回退代币的地址
     * @param deadline 交易截止时间
     * @param approveMax 是否授权最大值
     * @param v 签名的v值
     * @param r 签名的r值
     * @param s 签名的s值
     * @return amountETH 回退的ETH数量
     */
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external virtual override returns (uint amountETH) {
        // 获取 UniswapV2Pair 合约地址
        address pair = UniswapV2Library.pairFor(factory, token, WETH);

        // EIP2612离线签名方式授权当前合约操作msg.sender的流动性
        uint value = approveMax ? type(uint).max : liquidity;
        IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);

        // 移除流动性，获取代币A和ETH
        amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(
            token, liquidity, amountTokenMin, amountETHMin, to, deadline
        );
    }

    // **** SWAP ****
    // **** 交换代币 ****
    // requires the initial amount to have already been sent to the first pair // 需要将初始数量已发送到第一个交易对
    /**
     * @notice 内部函数：执行多跳交换
     * @param amounts 每一跳的代币数量数组
     * @param path 交换路径（代币地址数组）
     * @param _to 最终接收地址
     */
    function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
        // 遍历路径中的每一跳
        for (uint i; i < path.length - 1; i++) {
            // 获取当前跳的输入代币地址和输出代币地址
            (address input, address output) = (path[i], path[i + 1]);

            // 按地址大小排序，确定 token0（较小的地址）
            (address token0,) = UniswapV2Library.sortTokens(input, output);

            // 获取当前跳的输出代币数量
            uint vUSDCAmountOut = amounts[i + 1];

            // 确定 amount0Out 和 amount1Out
            // 如果输入是 token0，则输出 amount1Out（amount0Out = 0）
            // 如果输入是 token1，则输出 amount0Out（amount1Out = 0
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));

            // 确定当前跳输出的代币发送到哪里
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;

            // 调用交易对的 swap 函数执行交换
            // amount0Out：token0 输出数量（0 或具体数值）
            // amount1Out：token1 输出数量（0 或具体数值）
            // to：接收输出代币的地址
            // new bytes(0)：额外数据（通常为空）
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output)).swap(
                amount0Out, amount1Out, to, new bytes(0)
            );
        }
    }

    /**
     * @notice 用精确的输入代币数量交换尽可能多的输出代币
     * @param amountIn 输入代币数量
     * @param amountOutMin 输出代币最小可接受数量（滑点保护）
     * @param path 交换路径（代币地址数组）
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间
     * @return amounts 每一跳的代币数量数组
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        // 计算通过路径交换后的输出代币数量
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);

        // 输出代币数量需要 >= amountOutMin
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

        // 从用户地址转账输入代币到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );

        // 执行多跳交换
        _swap(amounts, path, to);
    }

    /**
     * @notice 用尽可能少的输入代币交换精确数量的输出代币
     * @param amountOut 期望的输出代币数量
     * @param amountInMax 输入代币最大可接受数量（滑点保护）
     * @param path 交换路径（代币地址数组）
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间
     * @return amounts 每一跳的代币数量数组
     */
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) returns (uint[] memory amounts) {
        // 计算通过路径交换后的需要输入代币数量
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);

        // 需要输入代币数量需要 <= amountInMax
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');

        // 从用户地址转账输入代币到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );

        // 执行多跳交换
        _swap(amounts, path, to);
    }

    /**
     * @notice 用精确的 ETH 交换尽可能多的输出代币
     * @param amountOutMin 输出代币最小可接受数量（滑点保护）
     * @param path 交换路径（代币地址数组，第一个必须是 WETH）
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间
     * @return amounts 每一跳的代币数量数组
     */
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 路径必须以 WETH 开头
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');

        // 计算通过路径交换后的输出代币数量
        amounts = UniswapV2Library.getAmountsOut(factory, msg.value, path);

        // 输出代币数量需要 >= amountOutMin
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

        // 从合约地址存款 ETH 到 WETH 合约(ETH等值交换WETH)
        IWETH(WETH).deposit{value: amounts[0]}();

        // 将 WETH 转账到第一个交易对
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));

        // 执行多跳交换
        _swap(amounts, path, to);
    }

    /**
     * @notice 用尽可能少的输入代币交换精确数量的 ETH
     * @param amountOut 期望的 ETH 输出数量
     * @param amountInMax 输入代币最大可接受数量（滑点保护）
     * @param path 交换路径（代币地址数组，最后一个必须是 WETH）
     * @param to 接收 ETH 的地址
     * @param deadline 交易截止时间
     * @return amounts 每一跳的代币数量数组
     */
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 路径必须以 WETH 结尾
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');

        // 计算通过路径交换后的需要输入代币数量
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);

        // 需要输入的代币数量需要 <= amountInMax
        require(amounts[0] <= amountInMax, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');

        // 将输入代币转账到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );

        // 执行多跳交换, 最终得到的WETH会转到当前合约
        _swap(amounts, path, address(this));

        // 从WETH合约地址提取 ETH
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);

        // 将 ETH 转账到接收地址
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @notice 用精确的输入代币数量交换尽可能多的 ETH
     * @param amountIn 输入代币数量
     * @param amountOutMin ETH最小可接受数量（滑点保护）
     * @param path 交换路径（代币地址数组，最后一个必须是 WETH）
     * @param to 接收 ETH 的地址
     * @param deadline 交易截止时间
     * @return amounts 每一跳的代币数量数组
     */
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 路径必须以 WETH 结尾
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');

        // 计算通过路径交换后的输出代币数量
        amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path);

        // 输出代币数量需要 >= amountOutMin
        require(amounts[amounts.length - 1] >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

        // 将输入代币转账到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]
        );

        // 执行多跳交换, 最终得到的WETH会转到当前合约
        _swap(amounts, path, address(this));

        // 从WETH合约地址提取 ETH
        IWETH(WETH).withdraw(amounts[amounts.length - 1]);

        // 将 ETH 转账到接收地址
        TransferHelper.safeTransferETH(to, amounts[amounts.length - 1]);
    }

    /**
     * @notice 用尽可能少的 ETH 交换精确数量的输出代币
     * @param amountOut 期望的输出代币数量
     * @param path 交换路径（代币地址数组，第一个必须是 WETH）
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间
     * @return amounts 每一跳的代币数量数组
     */
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        virtual
        override
        payable
        ensure(deadline)
        returns (uint[] memory amounts)
    {
        // 路径必须以 WETH 开头
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');

        // 计算通过路径交换后的需要输入代币数量
        amounts = UniswapV2Library.getAmountsIn(factory, amountOut, path);

        // 需要输入的代币数量需要 <= msg.value（用户提供的ETH数量）
        require(amounts[0] <= msg.value, 'UniswapV2Router: EXCESSIVE_INPUT_AMOUNT');

        // 将 ETH 转换为 WETH 并转账到第一个交易对
        IWETH(WETH).deposit{value: amounts[0]}();
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amounts[0]));

        // 执行多跳交换, 最终得到的输出代币会转到接收地址
        _swap(amounts, path, to);
        // refund dust eth, if any // 如果有多余的ETH，退还给用户
        if (msg.value > amounts[0]) TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
    }

    // **** SWAP (supporting fee-on-transfer tokens) ****
    // **** 交换代币（支持转账收费代币） ****
    // requires the initial amount to have already been sent to the first pair // 需要将初始数量已发送到第一个交易对
    /**
     * @notice 内部函数：执行多跳交换（支持转账收费代币）
     * @dev 对于转账收费的代币，通过检查余额变化来计算实际输出数量
     * @param path 交换路径（代币地址数组）
     * @param _to 最终接收地址
     */
    function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
        // 遍历路径中的每对交易对
        for (uint i; i < path.length - 1; i++) {
            // 计算当前交易对的输入和输出代币地址
            (address input, address output) = (path[i], path[i + 1]);
            // 按大小排序，token0 为较小的代币
            (address token0,) = UniswapV2Library.sortTokens(input, output);
            // 获取当前交易对合约实例
            IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output));

            // 定义实际输入和输出数量（不在参数中预计算）
            uint amountInput;
            uint amountOutput;

            // 计算实际输入数量
            { // scope to avoid stack too deep errors // 作用域，避免栈过深错误
            // 获取交易对当前的储备金
            (uint reserve0, uint reserve1,) = pair.getReserves();

            // 根据输入代币是 token0 还是 token1，确定对应的储备金
            (uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            // 通过检查交易对余额变化来计算实际输入数量（已扣除转账收费代币的转账手续费）
            amountInput = IERC20(input).balanceOf(address(pair)).sub(reserveInput);

            // 计算实际输出数量（已扣除0.3% 的uniswap手续费）
            amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
            }

            // 确定输出参数
            (uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));

            // 确定下一个交换的接收地址
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2]) : _to;
            // 执行交换（转账输出代币到下一个交易对或接收地址）
            pair.swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }

    /**
     * @notice 用精确的输入代币数量交换尽可能多的输出代币（支持转账收费代币）
     * @dev 对于转账收费的代币，通过检查余额变化来计算实际输出数量
     * @param amountIn 输入代币数量
     * @param amountOutMin 输出代币最小可接受数量（滑点保护）
     * @param path 交换路径（代币地址数组）
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external virtual override ensure(deadline) {
        // 将用户输入的代币转账到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );

        // 记录接收地址的输出代币余额（交换前）
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        // 执行多跳交换, 最终得到的输出代币会转到接收地址
        _swapSupportingFeeOnTransferTokens(path, to);

        // 检查实际收到的代币数量（已扣除转账费用）
        // 确保接收地址接收的代币数量 >= amountOutMin
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @notice 用精确的 ETH 交换尽可能多的输出代币（支持转账收费代币）
     * @dev 对于转账收费的代币，通过检查余额变化来计算实际输出数量
     * @param amountOutMin 输出代币最小可接受数量（滑点保护）
     * @param path 交换路径（代币地址数组，第一个必须是 WETH）
     * @param to 接收输出代币的地址
     * @param deadline 交易截止时间
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        payable
        ensure(deadline)
    {
        // 确保路径第一个代币是 WETH
        require(path[0] == WETH, 'UniswapV2Router: INVALID_PATH');

        // 将用户输入的 ETH 存款到 WETH 合约, 换取WETH
        uint amountIn = msg.value;
        IWETH(WETH).deposit{value: amountIn}();

        // 将 WETH 转账到第一个交易对
        assert(IWETH(WETH).transfer(UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn));

        // 记录接收地址的输出代币余额（交换前）
        uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);

        // 执行多跳交换, 最终得到的输出代币会转到接收地址
        _swapSupportingFeeOnTransferTokens(path, to);

        // 检查实际收到的代币数量（已扣除转账费用）
        // 确保接收地址接收的输出代币数量 >= amountOutMin
        require(
            IERC20(path[path.length - 1]).balanceOf(to).sub(balanceBefore) >= amountOutMin,
            'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT'
        );
    }

    /**
     * @notice 用精确的输入代币数量交换尽可能多的 ETH（支持转账收费代币）
     * @dev 对于转账收费的代币，通过检查余额变化来计算实际输出数量
     * @param amountIn 输入代币数量
     * @param amountOutMin ETH最小可接受数量（滑点保护）
     * @param path 交换路径（代币地址数组，最后一个必须是 WETH）
     * @param to 接收 ETH 的地址
     * @param deadline 交易截止时间
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        virtual
        override
        ensure(deadline)
    {
        // 确保路径最后一个代币地址是 WETH
        require(path[path.length - 1] == WETH, 'UniswapV2Router: INVALID_PATH');

        // 将用户输入的代币转账到第一个交易对
        TransferHelper.safeTransferFrom(
            path[0], msg.sender, UniswapV2Library.pairFor(factory, path[0], path[1]), amountIn
        );

        // 执行多跳交换, 最终得到的输出代币(WETH)会转到当前合约地址
        _swapSupportingFeeOnTransferTokens(path, address(this));

        // 获取实际收到的 WETH 数量
        uint amountOut = IERC20(WETH).balanceOf(address(this));

        // 确保实际收到的 WETH 数量 >= amountOutMin
        require(amountOut >= amountOutMin, 'UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT');

        // 将 WETH 从合约中提取出来, 转账给接收地址
        IWETH(WETH).withdraw(amountOut);
        TransferHelper.safeTransferETH(to, amountOut);
    }

    // **** LIBRARY FUNCTIONS ****
    // **** 库函数 ****
    /**
     * @notice 根据储备金比例计算输出数量
     * @param amountA 输入代币数量
     * @param reserveA 输入代币储备金
     * @param reserveB 输出代币储备金
     * @return amountB 计算得出的输出代币数量
     */
    function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
        return UniswapV2Library.quote(amountA, reserveA, reserveB);
    }

    /**
     * @notice 根据输入数量和储备金计算输出数量（考虑0.3%手续费）
     * @param amountIn 输入代币数量
     * @param reserveIn 输入代币储备金
     * @param reserveOut 输出代币储备金
     * @return amountOut 计算得出的输出代币数量
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountOut)
    {
        return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
    }

    /**
     * @notice 根据输出数量和储备金计算输入数量（考虑0.3%手续费）
     * @param amountOut 期望的输出代币数量
     * @param reserveIn 输入代币储备金
     * @param reserveOut 输出代币储备金
     * @return amountIn 需要的输入代币数量
     */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
        public
        pure
        virtual
        override
        returns (uint amountIn)
    {
        return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
    }

    /**
     * @notice 计算多跳交换的输出数量
     * @param amountIn 输入代币数量
     * @param path 交换路径（代币地址数组）
     * @return amounts 每一跳的代币数量数组
     */
    function getAmountsOut(uint amountIn, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsOut(factory, amountIn, path);
    }

    /**
     * @notice 计算多跳交换的输入数量
     * @param amountOut 期望的最终输出代币数量
     * @param path 交换路径（代币地址数组）
     * @return amounts 每一跳的代币数量数组
     */
    function getAmountsIn(uint amountOut, address[] memory path)
        public
        view
        virtual
        override
        returns (uint[] memory amounts)
    {
        return UniswapV2Library.getAmountsIn(factory, amountOut, path);
    }
}
