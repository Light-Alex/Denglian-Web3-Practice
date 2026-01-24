import { BLOCKED_PRICE_IMPACT_NON_EXPERT } from '../constants'
import { CurrencyAmount, Fraction, JSBI, Percent, TokenAmount, Trade } from '@light-uniswap/sdk'
import { ALLOWED_PRICE_IMPACT_HIGH, ALLOWED_PRICE_IMPACT_LOW, ALLOWED_PRICE_IMPACT_MEDIUM } from '../constants'
import { Field } from '../state/swap/actions'
import { basisPointsToPercent } from './index'

const BASE_FEE = new Percent(JSBI.BigInt(30), JSBI.BigInt(10000))
const ONE_HUNDRED_PERCENT = new Percent(JSBI.BigInt(10000), JSBI.BigInt(10000))
const INPUT_FRACTION_AFTER_FEE = ONE_HUNDRED_PERCENT.subtract(BASE_FEE)

// computes price breakdown for the trade
export function computeTradePriceBreakdown(
  trade?: Trade
): { priceImpactWithoutFee?: Percent; realizedLPFee?: CurrencyAmount } {
  // for each hop in our trade, take away the x*y=k price impact from 0.3% fees
  // e.g. for 3 tokens/2 hops: 1 - ((1 - .03) * (1-.03))
  const realizedLPFee = !trade
    ? undefined
    : ONE_HUNDRED_PERCENT.subtract(
        trade.route.pairs.reduce<Fraction>(
          (currentFee: Fraction): Fraction => currentFee.multiply(INPUT_FRACTION_AFTER_FEE),
          ONE_HUNDRED_PERCENT
        )
      )
  
  const midPrice = trade ? JSBI.toNumber(trade.route.midPrice.raw.numerator) / JSBI.toNumber(trade.route.midPrice.raw.denominator) : undefined
  console.log('midPrice:', midPrice)
  
  const inputAmount = trade ? trade.inputAmount.raw.toString() : undefined
  const outputAmount = trade ? trade.outputAmount.raw.toString() : undefined
  console.log('inputAmount:', inputAmount)
  console.log('outputAmount:', outputAmount)

  if (trade && midPrice !== undefined) {
    // 使用Fraction进行高精度计算
    // exactQuote = midPrice * inputAmount
    const exactQuoteFraction = new Fraction(
      JSBI.multiply(
        JSBI.BigInt(Math.floor(midPrice * 1e18)), // 将midPrice放大为整数（假设18位小数）
        trade.inputAmount.raw
      ),
      JSBI.BigInt(1e18)
    )
    
    // slippage = (exactQuote - outputAmount) / exactQuote
    const outputAmountFraction = new Fraction(trade.outputAmount.raw, JSBI.BigInt(1))

    // Declare variables before assignment
    let slippageRaw: Fraction | undefined = undefined
    let slippagePercent: Percent | undefined = undefined

    slippageRaw = exactQuoteFraction
      .subtract(outputAmountFraction)
      .divide(exactQuoteFraction)
    
    // 转换为Percent类型
    slippagePercent = new Percent(slippageRaw.numerator, slippageRaw.denominator)
    
    // 显示原始数据
    console.log('滑点原始数据 - numerator:', slippageRaw.numerator.toString())
    console.log('滑点原始数据 - denominator:', slippageRaw.denominator.toString())
    console.log('滑点原始数据 - 分数值:', slippageRaw.toSignificant(10))
    console.log('滑点百分比:', slippagePercent.toSignificant(6), '%')
    console.log('滑点小数形式:', JSBI.toNumber(slippageRaw.numerator) / JSBI.toNumber(slippageRaw.denominator))
  }

  // remove lp fees from price impact
  const priceImpactWithoutFeeFraction = trade && realizedLPFee ? trade.priceImpact.subtract(realizedLPFee) : undefined

  // the x*y=k impact
  if (priceImpactWithoutFeeFraction) {
    // 使用JSBI的除法并转换为数字
    const numerator = JSBI.toNumber(priceImpactWithoutFeeFraction.numerator)
    const denominator = JSBI.toNumber(priceImpactWithoutFeeFraction.denominator)
    console.log('priceImpactWithoutFeeFraction numerator:', numerator)
    console.log('priceImpactWithoutFeeFraction denominator:', denominator)
    console.log('priceImpactWithoutFeeFraction:', numerator / denominator)
  }

  const priceImpactWithoutFeePercent = priceImpactWithoutFeeFraction
    ? new Percent(priceImpactWithoutFeeFraction?.numerator, priceImpactWithoutFeeFraction?.denominator)
    : undefined

  // the amount of the input that accrues to LPs
  const realizedLPFeeAmount =
    realizedLPFee &&
    trade &&
    (trade.inputAmount instanceof TokenAmount
      ? new TokenAmount(trade.inputAmount.token, realizedLPFee.multiply(trade.inputAmount.raw).quotient)
      : CurrencyAmount.ether(realizedLPFee.multiply(trade.inputAmount.raw).quotient))
  
  return { priceImpactWithoutFee: priceImpactWithoutFeePercent, realizedLPFee: realizedLPFeeAmount }
}

// computes the minimum amount out and maximum amount in for a trade given a user specified allowed slippage in bips
export function computeSlippageAdjustedAmounts(
  trade: Trade | undefined,
  allowedSlippage: number
): { [field in Field]?: CurrencyAmount } {
  const pct = basisPointsToPercent(allowedSlippage)
  return {
    [Field.INPUT]: trade?.maximumAmountIn(pct),
    [Field.OUTPUT]: trade?.minimumAmountOut(pct)
  }
}

export function warningSeverity(priceImpact: Percent | undefined): 0 | 1 | 2 | 3 | 4 {
  if (!priceImpact?.lessThan(BLOCKED_PRICE_IMPACT_NON_EXPERT)) return 4
  if (!priceImpact?.lessThan(ALLOWED_PRICE_IMPACT_HIGH)) return 3
  if (!priceImpact?.lessThan(ALLOWED_PRICE_IMPACT_MEDIUM)) return 2
  if (!priceImpact?.lessThan(ALLOWED_PRICE_IMPACT_LOW)) return 1
  return 0
}

export function formatExecutionPrice(trade?: Trade, inverted?: boolean): string {
  if (!trade) {
    return ''
  }
  return inverted
    ? `${trade.executionPrice.invert().toSignificant(6)} ${trade.inputAmount.currency.symbol} / ${
        trade.outputAmount.currency.symbol
      }`
    : `${trade.executionPrice.toSignificant(6)} ${trade.outputAmount.currency.symbol} / ${
        trade.inputAmount.currency.symbol
      }`
}
