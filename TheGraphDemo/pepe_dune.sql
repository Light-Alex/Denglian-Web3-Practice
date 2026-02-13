
-- 查询PEPE币转账明细
select "from", "to", value, evt_block_date from erc20_ethereum.evt_transfer where contract_address=0x6982508145454ce325ddbe47a25d4ec3d2311933 and evt_block_number >= 17046105 limit 10
select * from pepe_multichain.pepetoken_evt_transfer where contract_address=0x6982508145454ce325ddbe47a25d4ec3d2311933 limit 1

-- select * from shib_ethereum.SHIB_evt_Transfer limit 10

-- 查询用户的PEPE币持仓明细
-- UNION ALL: 垂直合并（堆叠）
-- UNION: 垂直合并（去重）
WITH
  balance_changes AS (
    SELECT
      "from" AS address,
      - value AS balance_change
    FROM
      erc20_ethereum.evt_transfer
      where contract_address=0x6982508145454ce325ddbe47a25d4ec3d2311933 and evt_block_number >= 17046105
    UNION ALL
    SELECT
      "to" AS address,
      value AS balance_change
    FROM
      erc20_ethereum.evt_transfer
      where contract_address=0x6982508145454ce325ddbe47a25d4ec3d2311933 and evt_block_number >= 17046105
  ),
  address_balances AS (
    SELECT
      address,
      SUM(balance_change)/1e18 AS balance
    FROM
      balance_changes
    GROUP BY
      address
    HAVING
      SUM(balance_change) > 0
  )

SELECT
  *
FROM
  address_balances
ORDER BY balance desc


-- 查询PEPE币 用户总持币数量及发行量: 根据之前的查询语句query_6692779, 做二次查询
-- 1. 加载 query_6692779 的 SQL 语句
-- 2. 执行 query_6692779 的完整查询
-- 3. 将结果作为临时表
-- 4. 在此基础上执行 count() 和 sum()
select 
count(address) as holders,
sum(balance) as totalSupply
from  query_6692779


-- 查询PEPE币 过去半年 每日交易笔数
select DATE_TRUNC('day', evt_block_time) day, count(*) as txs
from erc20_ethereum.evt_transfer 
where contract_address=0x6982508145454ce325ddbe47a25d4ec3d2311933 and evt_block_time >= CURRENT_TIMESTAMP - INTERVAL '180' day
group by 1
order by 1 

-- 查询EVM链上PEPE币价格
select * from prices.usd where blockchain='ethereum' and contract_address=0x6982508145454ce325ddbe47a25d4ec3d2311933 limit 10;

-- 查询EVM链上PEPE币 过去7天 每天的交易总额(单位：美元)
WITH daily_transactions AS (
select DATE_TRUNC('day', evt_block_time) day, SUM(value) / 1e18 AS total_transfer_amount
from erc20_ethereum.evt_transfer 
where contract_address=0x6982508145454ce325ddbe47a25d4ec3d2311933 and evt_block_time >= CURRENT_TIMESTAMP - INTERVAL '7' day
group by 1
order by 1 
),

pepe_daily_volume as (
    select dt.day, total_transfer_amount, price from daily_transactions dt JOIN prices.usd_daily d on d.day = dt.day
    where d.contract_address = 0x6982508145454ce325ddbe47a25d4ec3d2311933 and d.blockchain = 'ethereum' 
)

SELECT 
    day,
    SUM(total_transfer_amount * price) AS usd_volume
FROM 
    pepe_daily_volume
group by 1 order by 1