-- QUERY 3
--Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number--
WITH order_cte AS (
  SELECT
    EXTRACT(YEAR FROM a.ModifiedDate) AS yr,
    b.TerritoryID AS TerritoryID,
    SUM(a.OrderQty) AS ord_cnt
  FROM `adventureworks2019.Sales.SalesOrderDetail` a
  LEFT JOIN `adventureworks2019.Sales.SalesOrderHeader` b
    ON a.SalesOrderID = b.SalesOrderID
  GROUP BY yr, TerritoryID
),
rank_qty AS (
  SELECT
    o.yr,
    o.TerritoryID,
    o.ord_cnt,
    DENSE_RANK() OVER (
      PARTITION BY o.yr
      ORDER BY o.ord_cnt DESC
    ) AS rn
  FROM order_cte o
)
SELECT
  r.yr,
  r.TerritoryID,
  r.ord_cnt,
  r.rn
FROM rank_qty r
WHERE r.rn <= 3
ORDER BY r.yr ASC, r.rn ASC, r.TerritoryID;
