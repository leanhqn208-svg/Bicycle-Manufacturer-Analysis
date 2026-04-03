--QUERY 8
--No of order and value at Pending status in 2014
SELECT
  EXTRACT(YEAR FROM DATE(OrderDate)) AS Year,
  Status,
  COUNT(DISTINCT PurchaseOrderID)    AS Order_cnt,
  SUM(TotalDue)                      AS Value
FROM `adventureworks2019.Purchasing.PurchaseOrderHeader`
WHERE Status = 1
  AND EXTRACT(YEAR FROM DATE(OrderDate)) = 2014
GROUP BY Year, Status
ORDER BY Year;
