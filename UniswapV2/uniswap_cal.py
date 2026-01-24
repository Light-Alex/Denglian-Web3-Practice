from decimal import Decimal, getcontext

# 设置精度（小数点后位数）
getcontext().prec = 36  # 默认28位

def cal_liquidity_value(add_token1, add_token2, reserve1, reserve2, total_supply):
    """
    计算添加流动性后应获得的流动性代币数量。
    
    根据Uniswap V2的恒定乘积公式，当用户向流动性池添加代币时，
    他们获得的流动性代币数量基于他们添加的代币比例与现有储备的比例。
    
    参数:
        add_token1 (Decimal/int): 添加的第一个代币数量（以最小单位计）
        add_token2 (Decimal/int): 添加的第二个代币数量（以最小单位计）
        reserve1 (Decimal/int): 流动性池中第一个代币的当前储备量
        reserve2 (Decimal/int): 流动性池中第二个代币的当前储备量
        total_supply (Decimal/int): 当前流动性代币的总供应量
    
    返回:
        Decimal: 应获得的流动性代币数量（除以1e18后）
    
    算法说明:
        1. 计算基于第一个代币的流动性：add_token1 * total_supply / reserve1
        2. 计算基于第二个代币的流动性：add_token2 * total_supply / reserve2
        3. 取两者中的较小值，确保添加的代币比例与池中现有比例一致
        4. 除以1e18将结果从最小单位转换为标准单位
    """

    liquidity = min(add_token1 * total_supply / reserve1, add_token2 * total_supply / reserve2)
    return liquidity / Decimal('1e18')

def cal_token_value(liquidity, reserve1, reserve2, total_supply):
    """
    计算流动性代币对应的代币数量。
    
    根据Uniswap V2的恒定乘积公式，当用户从流动性池中移除流动性代币时，
    他们获得的代币数量基于移除的流动性代币比例与池中现有储备的比例。
    
    参数:
        liquidity (Decimal/int): 移除的流动性代币数量（以最小单位计）
        reserve1 (Decimal/int): 流动性池中第一个代币的当前储备量
        reserve2 (Decimal/int): 流动性池中第二个代币的当前储备量
        total_supply (Decimal/int): 当前流动性代币的总供应量
    
    返回:
        tuple: 包含两个元素的元组，分别为第一个代币数量（除以1e18后）和第二个代币数量（除以1e18后）
    
    算法说明:
        1. 计算基于流动性的第一个代币数量：liquidity * reserve1 / total_supply
        2. 计算基于流动性的第二个代币数量：liquidity * reserve2 / total_supply
        3. 除以1e18将结果从最小单位转换为标准单位
    """

    token1 = liquidity * reserve1 / total_supply
    token2 = liquidity * reserve2 / total_supply
    return token1 / Decimal('1e18'), token2 / Decimal('1e18')

def cal_swap_token_value(swap_token, reserve_in, reserve_out, fee=Decimal('0.003')):
    """
    计算交换代币时的输出代币数量。
    
    根据Uniswap V2的恒定乘积公式，当用户交换代币时，
    输出的代币数量基于输入的代币数量与池中现有储备的比例。
    
    参数:
        swap_token (Decimal/int): 输入的代币数量（以最小单位计）
        reserve_in (Decimal/int): 流动性池中输入代币的当前储备量
        reserve_out (Decimal/int): 流动性池中输出代币的当前储备量
        fee (Decimal, 可选): 交易手续费比例（默认0.003）
    
    返回:
        tuple: 包含三个元素的元组，分别为输出代币数量（除以1e18后）、手续费代币数量（除以1e18后）、无手续费滑点
    
    算法说明:
        1. 计算基于输入代币的输出代币数量：(1 - fee) * swap_token * reserve_out / (reserve_in + swap_token * (1 - fee))
        2. 除以1e18将结果从最小单位转换为标准单位
        3. 计算手续费代币数量：fee * swap_token
        4. 计算滑点：(理论输出 - 实际输出) / 理论输出
    """
    token_out = (1 - fee) * swap_token * reserve_out / (reserve_in + swap_token * (1 - fee))

    # 手续费
    fee_token = fee * swap_token

    # 计算滑点
    midPrice = reserve_out / reserve_in # 理论中间价格
    print("midPrice: %s" % midPrice)
    print("swap_token: %s" % swap_token)
    print("token_out: %s" % token_out)

    exactQuote = midPrice * swap_token  # 理论输出代币数量
    slippage = ((exactQuote - token_out) / exactQuote) # 实际滑点 = (理论输出 - 实际输出) / 理论输出
    priceImpactWithoutFee = slippage - fee # 无手续费滑点 = 实际滑点 - 手续费

    return token_out / Decimal('1e18'), fee_token / Decimal('1e18'), priceImpactWithoutFee

if __name__ == '__main__':
    total_supply = Decimal('1249773955360961185660707')
    reserve1 = Decimal('1376001000000000000000001')
    reserve2 = Decimal('1135439096973336348800074')

    add_token1 = Decimal('10000000000000000000000')
    add_token2 = Decimal('8251730000000000000000')

    liquidity = cal_liquidity_value(add_token1, add_token2, reserve1, reserve2, total_supply)
    print("liquidity: ", liquidity)

    liquidity = Decimal('360000') * Decimal('1e18')
    total_supply = Decimal('1258856608319505265102950')
    reserve1 = Decimal('1386001000000000000000001')
    reserve2 = Decimal('1143690828599791099550982')
    token1, token2 = cal_token_value(liquidity, reserve1, reserve2, total_supply)
    print("token1: %.2f, token2: %.2f" % (token1, token2))

    swap_token = Decimal('50000') * Decimal('1e18')
    reserve1 = Decimal('989640640000000000000397')
    reserve2 = Decimal('816624896791292046417276')
    token_out, fee_token, priceImpactWithoutFee = cal_swap_token_value(swap_token, reserve1, reserve2)
    print("token_out: %.2f, Liquidity Provider Fee: %.2f, Price Impact: %s" % (token_out, fee_token, priceImpactWithoutFee))

    print(Decimal('1.9320122687062743e+81')/Decimal('4.040825927502341e+82'))
