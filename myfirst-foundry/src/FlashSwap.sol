// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
}

// 闪电贷流程: 
// 1. 闪电贷合约从poolA中借贷tokenA
// 2. 闪电贷合约在poolB中用全部tokenA换tokenB
// 3. 闪电贷合约计算需要还poolA多少tokenA(加上手续费)
// 4. 闪电贷合约计算在poolA中如果需要还这么多tokenA，对应需要多少tokenB(加上手续费)
// 5. 闪电贷合约将对应数量tokenB还给poolA
// 6. 闪电贷合约中剩余的tokenB即为赚取费用
contract FlashSwap {
    address private immutable UNISWAP_V2_ROUTER_01; // 价格低的Uniswap V2 Router合约地址
    address private immutable UNISWAP_V2_ROUTER_02; // 价格高的Uniswap V2 Router合约地址
    address private immutable UNISWAP_V2_FACTORY_01; // 价格低的Uniswap V2 Factory合约地址
    address private immutable UNISWAP_V2_FACTORY_02; // 价格高的Uniswap V2 Factory合约地址
    
    address public owner;
    
    event FlashSwapExecuted(
        address indexed poolA, // 贷款池地址
        address indexed poolB, // 交换池地址
        address tokenA, // tokenA代币地址
        address tokenB, // tokenB代币地址
        uint256 amountBorrowed, // 从poolA中贷款的tokenA的数量
        uint256 profitA, // 剩余的tokenA
        uint256 profitB  // 剩余的tokenB
    );
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(address _UNISWAP_V2_ROUTER_01, address _UNISWAP_V2_ROUTER_02) {
        owner = msg.sender;
        UNISWAP_V2_ROUTER_01 = _UNISWAP_V2_ROUTER_01;
        UNISWAP_V2_ROUTER_02 = _UNISWAP_V2_ROUTER_02;
        UNISWAP_V2_FACTORY_01 = IUniswapV2Router02(_UNISWAP_V2_ROUTER_01).factory();
        UNISWAP_V2_FACTORY_02 = IUniswapV2Router02(_UNISWAP_V2_ROUTER_02).factory();
    }
    
    // 检查闪电贷条件
    function checkFlashSwapConditions(
        address tokenA,  // 贷款token
        address tokenB,  // 交换token
        uint256 amountToBorrow // 贷款数量
    ) external view returns (uint256 profit, string memory reason) {
        // 贷款池地址
        address poolA = IUniswapV2Factory(UNISWAP_V2_FACTORY_01).getPair(tokenA, tokenB);
        if (poolA == address(0)) {
            return (0, "PoolA not found");
        }

        // 检查 1: PoolA 流动性是否充足
        {
            (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(poolA).getReserves();
            address token0 = IUniswapV2Pair(poolA).token0();
            uint256 balanceA = tokenA == token0 ? reserve0 : reserve1;

            if (balanceA < amountToBorrow) {
                return (0, "Insufficient liquidity in PoolA");
            }
        }

        // 交换池地址
        address poolB = IUniswapV2Factory(UNISWAP_V2_FACTORY_02).getPair(tokenA, tokenB);
        if (poolB == address(0)) {
            return (0, "PoolB not found");
        }

        // 检查 2: 预估套利是否盈利
        return _checkArbitrageProfitability(tokenA, tokenB, amountToBorrow);
    }

    // 在router对应的<tokenIn, tokenOut>池中, 精确输出代币tokenOut数量为amountOut, 计算需要输入的代币tokenIn数量amountIn
    function _calculateAmountIn(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountOut
    ) internal view returns (uint256 amountIn) {
        address factory = IUniswapV2Router02(router).factory();
        address pool = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
        require(pool != address(0), "Pool not found");

        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        address token0 = pair.token0();
        bool token0IsTokenIn = tokenIn == token0;
        
        (uint112 reserveIn, uint112 reserveOut) = token0IsTokenIn ? 
            (reserve0, reserve1) : (reserve1, reserve0);
        
        amountIn = IUniswapV2Router02(router).getAmountIn(
            amountOut, reserveIn, reserveOut
        );
    }

    // 在router对应的<tokenIn, tokenOut>池中, 精确输入代币tokenIn数量为amountIn, 计算需要输出的代币tokenOut数量amountOut
    function _calculateAmountOut(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal view returns (uint256 amountOut) {
        address factory = IUniswapV2Router02(router).factory();
        address pool = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
        require(pool != address(0), "Pool not found");

        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        address token0 = pair.token0();
        bool token0IsTokenIn = tokenIn == token0;
        
        (uint112 reserveIn, uint112 reserveOut) = token0IsTokenIn ? 
            (reserve0, reserve1) : (reserve1, reserve0);
        
        amountOut = IUniswapV2Router02(router).getAmountOut(
            amountIn, reserveIn, reserveOut
        );
    }

    // 预估套利盈利性
    function _checkArbitrageProfitability(
        address tokenA,
        address tokenB,
        uint256 amountToBorrow
    ) internal view returns (uint256 profit, string memory reason) {
        // 1. 计算在PoolB中用全部的tokenA换tokenB能得到多少tokenB
        uint256 amountBOut = _calculateAmountOut(UNISWAP_V2_ROUTER_02, tokenA, tokenB, amountToBorrow);

        // 2. 计算需要还款的tokenA的数量（含0.3%手续费）
        uint256 amountToRepay = amountToBorrow * 1000 / 997 + 1;

        // 3. 计算在PoolA中需要多少tokenB才能换回足够的tokenA来还款
        uint256 amountBNeeded = _calculateAmountIn(UNISWAP_V2_ROUTER_01, tokenB, tokenA, amountToRepay);

        // 4. 检查是否盈利
        if (amountBOut <= amountBNeeded) {
            return (0, "Not profitable: price difference too small");
        }

        profit = amountBOut - amountBNeeded;
    }

    // 执行闪电兑换套利
    function executeFlashSwap(
        address tokenA,     // 要借贷的代币
        address tokenB,     // 要交换的代币
        uint256 amountToBorrow  // 借贷数量
    ) external onlyOwner {
        address poolA = IUniswapV2Factory(UNISWAP_V2_FACTORY_01).getPair(tokenA, tokenB);
        address poolB = IUniswapV2Factory(UNISWAP_V2_FACTORY_02).getPair(tokenA, tokenB);

        // 验证池子地址
        require(poolA != address(0), "Invalid PoolA address");
        require(poolB != address(0), "Invalid PoolB address");

        // 从 poolA 开始闪电贷
        IUniswapV2Pair pair = IUniswapV2Pair(poolA);
        address token0 = pair.token0();
        address token1 = pair.token1();

        uint256 amount0Out = tokenA == token0 ? amountToBorrow : 0;
        uint256 amount1Out = tokenA == token1 ? amountToBorrow : 0;

        // 验证至少有一个输出量大于0
        require(amount0Out > 0 || amount1Out > 0, "No output amount");
        
        // 编码数据传递给回调函数
        bytes memory data = abi.encode(poolB, tokenA, tokenB, amountToBorrow);
        
        // 执行闪电贷
        pair.swap(amount0Out, amount1Out, address(this), data);
    }
    
    // Uniswap V2 回调函数
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        // 验证调用者是合法的 Uniswap V2 配对合约
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address poolA = IUniswapV2Factory(UNISWAP_V2_FACTORY_01).getPair(token0, token1);
        require(msg.sender == poolA, "Invalid poolA");
        require(sender == address(this), "Invalid sender");

        // 解码数据
        (address poolB, address tokenA, address tokenB, uint256 amountBorrowed) =
            abi.decode(data, (address, address, address, uint256));

        // 获取借到的代币数量
        uint256 amountReceived = amount0 > 0 ? amount0 : amount1;

        // 在 PoolB 中将 tokenA 兑换为 tokenB
        uint256 amountOut = _swapOnPool(UNISWAP_V2_ROUTER_02, tokenA, tokenB, amountReceived);
        require(amountOut > 0, "First swap failed");

        // 计算需要还款的tokenA的数量（包含手续费）
        uint256 amountToRepay = _calculateRepayAmount(amountBorrowed);

        // 在 PoolA 中将部分 tokenB 兑换回 tokenA 以偿还借款
        // amountToSwapBack: 要偿还amountToRepay数量的tokenA，需要amountToSwapBack数量的tokenB（考虑手续费）
        uint256 amountToSwapBack = _calculateAmountIn(UNISWAP_V2_ROUTER_01, tokenB, tokenA, amountToRepay);
        require(amountToSwapBack <= IERC20(tokenB).balanceOf(address(this)), "Invalid amount to swap back");

        IERC20(tokenB).transfer(msg.sender, amountToSwapBack);

        // 将剩余代币转给 owner 并计算利润
        _transferRemainingAndEmit(msg.sender, poolB, tokenA, tokenB, amountBorrowed);
    }

    // 转移剩余代币并触发事件
    function _transferRemainingAndEmit(
        address callerPair,
        address poolB,
        address tokenA,
        address tokenB,
        uint256 amountBorrowed
    ) internal {
        uint256 remainingTokenB = IERC20(tokenB).balanceOf(address(this));
        uint256 remainingTokenA = IERC20(tokenA).balanceOf(address(this));

        if (remainingTokenB > 0) {
            IERC20(tokenB).transfer(owner, remainingTokenB);
        }
        if (remainingTokenA > 0) {
            IERC20(tokenA).transfer(owner, remainingTokenA);
        }

        emit FlashSwapExecuted(callerPair, poolB, tokenA, tokenB, amountBorrowed, remainingTokenA, remainingTokenB);
    }
    
    function _swapOnPool(
        address router,
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        address factory = IUniswapV2Router02(router).factory();
        address pool = IUniswapV2Factory(factory).getPair(tokenIn, tokenOut);
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        address token0 = pair.token0();
        bool token0IsTokenIn = tokenIn == token0;
        
        (uint112 reserveIn, uint112 reserveOut) = token0IsTokenIn ? 
            (reserve0, reserve1) : (reserve1, reserve0);
        
        // 计算输出数量
        amountOut = IUniswapV2Router02(router).getAmountOut(
            amountIn, reserveIn, reserveOut
        );
        
        // 转移代币到配对合约
        IERC20(tokenIn).transfer(pool, amountIn);
        
        // 执行交换
        (uint256 amount0Out, uint256 amount1Out) = token0IsTokenIn ? 
            (uint256(0), amountOut) : (amountOut, uint256(0));
        
        pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
    }
        
    // 计算还款数量（包含 0.3% 手续费）
    function _calculateRepayAmount(
        uint256 amountBorrowed
    ) internal pure returns (uint256) {
        // Uniswap V2 手续费是 0.3%
        return amountBorrowed * 1000 / 997 + 1;
    }
    
    // 紧急提取函数
    function emergencyWithdraw(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        if (balance > 0) {
            IERC20(token).transfer(owner, balance);
        }
    }
} 