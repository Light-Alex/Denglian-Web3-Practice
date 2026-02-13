-- 创建Azuki NFT 代币仪表板，包括：
-- 持有者总数
-- 持有人名单（持有人，持有的NFT数量）
-- 最近一段时间在 OpenSea 的交易量

-- ============================================
-- 1. 查询Azuki NFT的持有人名单（持有人，持有的NFT数量）
-- ============================================
WITH
  balance_changes AS (
    SELECT
      "from" AS address,
      -1 AS balance_change
    FROM
      erc721_ethereum.evt_transfer
      where contract_address=0xed5af388653567af2f388e6224dc7c4b3241c544
    UNION ALL
    SELECT
      "to" AS address,
      1 AS balance_change
    FROM
      erc721_ethereum.evt_transfer
      where contract_address=0xed5af388653567af2f388e6224dc7c4b3241c544
  ),
  address_balances AS (
    SELECT
      address,
      SUM(balance_change) AS balance
    FROM
      balance_changes
    GROUP BY
      address
    HAVING
      SUM(balance_change) > 0
  )

SELECT
  address as "holder_address",
  balance as "holding_count"
FROM
  address_balances
ORDER BY balance desc

-- ============================================
-- 2. 查询Azuki NFT的持有者总数
-- ============================================
select count(*) as "holder_count" from query_6692926

-- ============================================
-- 3. 查询Azuki NFT最近30天 每天在 OpenSea 的交易量（以USD计价）
-- ============================================
select 
    block_date as day, 
    sum(amount_usd) as usd_daily
from
    opensea.trades
where
    nft_contract_address=0xed5af388653567af2f388e6224dc7c4b3241c544 and
    block_time >= CURRENT_TIMESTAMP - INTERVAL '30' day
group by 1
order by 1 desc