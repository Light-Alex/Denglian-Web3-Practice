pragma solidity ^0.8.0;

import '../../v2-core/interfaces/IUniswapV2Pair.sol';

import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    // 按地址大小排序，确保 token0 是较小的地址
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    // 计算 UniswapV2Pair 合约地址（CREATE2 部署）
    // Create2生成规则：
    // keccak256(abi.encodePacked(
    //     hex'ff',
    //     deployer_address,     // 由Factory创建, 这里就是 factory合约地址
    //     salt,                // salt 是创建者自定义的数据, 避免重复, 这里的
    //     // salt = keccak256(abi.encodePacked(token0, token1)), 且 token0 < token1
    //     keccak256(type(Contract_to_Deploy).creationCode)  // 此处 Contract_to_Deploy = UniswapV2Pair
    // ))))
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        // 使用CREATE2提前计算pair地址
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',  // CREATE2 的标识字节
                factory, // 工厂合约地址
                keccak256(abi.encodePacked(token0, token1)), // 盐值（用于区分不同交易对）
                hex'd9d3b144298859dd7f44fb251113fa3cb3dab51c22ca4ac33a8fc3f5407b016d' // init code hash, UniswapV2Pair 合约字节码的 keccak256 哈希值
            )))));
    }

    // fetches and sorts the reserves for a pair
    // 获取 UniswapV2Pair 合约中的 reserves 信息（token0 与 token1 的储藏量）
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    // 按照 reserves 比例计算另一个代币数量
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    // 根据输入代币数量和当前流动性池储备金，计算可得到的最大输出代币数量（考虑 0.3% 手续费）。
    // amountIn: 输入的代币数量
    // reserveIn: 流动性池中的输入代币储备量
    // reserveOut: 流动性池中的输出代币储备量
    // amountOut: 计算得出的输出代币数量
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        // 确保输入数量大于 0
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');

        // 确保流动性池有足够的资产
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');

        // 计算扣除 0.3% 手续费后的输入数量
        uint amountInWithFee = amountIn.mul(997);

        // 计算公式的分子部分
        // 公式: numerator = amountInWithFee × reserveOut = (amountIn × 997) × reserveOut
        uint numerator = amountInWithFee.mul(reserveOut);

        // 计算公式的分母部分
        // 公式: denominator = reserveIn × 1000 + amountInWithFee = reserveIn × 1000 + (amountIn × 997)
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);

        // 计算输出数量（考虑 0.3% 手续费）
        // 公式: amountOut = numerator / denominator = (amountIn × 997) × reserveOut / (reserveIn × 1000 + (amountIn × 997))
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    // 根据期望的输出代币数量和当前流动性池储备金，计算需要多少输入代币（考虑 0.3% 手续费）。
    // amountOut: 期望的输出代币数量
    // reserveIn: 流动性池中的输入代币储备量
    // reserveOut: 流动性池中的输出代币储备量
    // amountIn: 计算得出的需要输入的代币数量
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        // amountOut = (amountIn × 997 × reserveOut) / (reserveIn × 1000 + amountIn × 997)
        // amountIn = (reserveIn × amountOut × 1000) / (reserveOut - amountOut) × 997 + 1
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    // 根据输入代币数量和路径，计算通过多个交易对交换后的输出代币数量（考虑 0.3% 手续费）。
    // factory: UniswapV2Factory 合约地址
    // amountIn: 初始输入代币数量
    // path: 交换路径，包含多个代币地址
    // amounts: 计算得出的通过多个交易对交换后的输出代币数量数组
    // 示例: 
    // path = [DAI, WETH, USDC]
    // amountIn = 100 DAI
    // amounts = [100 DAI, 0.0498 WETH, 19.82 USDC]
    // 注意：amounts[0]为初始输入代币数量，amounts[path.length - 1]为最终输出代币数量
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            // 获取当前交易对的储备金
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            // 计算通过当前交易对交换后的输出代币数量
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    // 根据期望的输出代币数量和路径，计算通过多个交易对交换后的输入代币数量（考虑 0.3% 手续费）。
    // factory: UniswapV2Factory 合约地址
    // amountOut: 期望的输出代币数量
    // path: 交换路径，包含多个代币地址
    // amounts: 计算得出的通过多个交易对交换后的输入代币数量数组
    // 示例: 
    // path = [DAI, WETH, USDC]
    // amountOut = 19.82 USDC
    // amounts = [100 DAI, 0.0498 WETH, 19.82 USDC]
    // 注意：amounts[path.length - 1]为期望的输出代币数量，amounts[0]为需要输入代币数量
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}
