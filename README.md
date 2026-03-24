# 🚴‍♂️ AdventureWorks: Bicycle Manufacturer Data Analysis
This repository showcases my SQL skills through a data analysis project focusing on a bicycle manufacturer, AdventureWorks.

---



## 📑 Table of Contents  
1. [📌 Overview](#-overview)  
2. [📂 Data Source & Data Dictionary](#-data-source--data-dictionary)
3. [🔎 Exploring the Dataset](#-exploring-the-dataset)
4. [🚩 Final Conclusion](#-final-conclusion)
---

## 📌 Overview
This project analyzes the AdventureWorks dataset using **Google BigQuery** to extract actionable business intelligence. 
The analysis have multiple business domains including **Sales Performance, Inventory Management, Customer Retention (Cohort Analysis), and Purchasing operations**.

---

## 📁 Data Source & Data Dictionary

### Data Source  
The dataset used in this project is `AdventureWorks 2019`. 
The data is queried using **Google BigQuery** and  various business modules including Sales, Production, and Purchasing.
**Relational Structure:** This project requires complex `JOIN` operations across multiple tables (e.g., Sales, Product subcategories and Special Offers).

### Data Dictionary
Below are the exact tables and fields utilized in the SQL queries for this analysis:

<details>
  <summary><b>1. Sales & Customers</b></summary>

  <br>

  *Tables: `Sales.SalesOrderHeader`, `Sales.SalesOrderDetail`*
  
  | Field Name | Type | Description |
  | :--- | :--- | :--- |
  | `SalesOrderID` | `INT` | Unique identifier for each sales order. |
  | `CustomerID` | `INT` | Unique identifier for the customer making the purchase. |
  | `ModifiedDate` | `TIMESTAMP` | Used to extract the transaction/order date. |
  | `OrderQty` | `INT` | The quantity of a specific product ordered in a single line item. |
  | `UnitPrice` | `FLOAT` | The selling price of a single unit of the product. |
  | `LineTotal` | `FLOAT` | Total revenue per line item (`OrderQty` * `UnitPrice` * `Discount`). |
  | `TerritoryID` | `INT` | Identifier for the sales region/territory. |
  | `Status` | `INT` | Current status of the order (e.g., 5 = Shipped). |

</details>

<details>
  <summary><b>2. Products & Inventory</b></summary>

  <br>

  *Tables: `Production.Product`, `Production.ProductSubcategory`, `Production.WorkOrder`*
  
  | Field Name | Type | Description |
  | :--- | :--- | :--- |
  | `ProductID` | `INT` | Unique identifier for each product. |
  | `ProductSubcategoryID`| `INT` | Foreign key linking products to their specific subcategory. |
  | `Name` | `STRING` | The name of the Product or Product Subcategory (e.g., 'Road Bikes'). |
  | `StockedQty` | `INT` | The quantity of products successfully built and added to inventory. |

</details>

<details>
  <summary><b>3. Purchasing & Discounts</b></summary>

  <br>

  *Tables: `Purchasing.PurchaseOrderHeader`, `Sales.SpecialOffer`*
  
  | Field Name | Type | Description |
  | :--- | :--- | :--- |
  | `PurchaseOrderID` | `INT` | Unique identifier for a purchase order (buying from vendors). |
  | `OrderDate` | `TIMESTAMP` | The date the purchase order was created. |
  | `TotalDue` | `FLOAT` | Total amount owed to the vendor for the purchase order. |
  | `SpecialOfferID` | `INT` | Foreign key linking an order item to a specific promotional offer. |
  | `DiscountPct` | `FLOAT` | The discount percentage applied to an item. |
  | `Type` | `STRING` | The category of the discount (e.g., 'Seasonal Discount'). |
  | `Status` | `INT` | Purchase order status (e.g., 1 = Pending). |

</details>

* (Note: For a complete breakdown of all available fields and their definitions, please refer to the **[AdventureWorks _ Data Dictionary.pdf](https://drive.google.com/file/d/1bwwsS3cRJYOg1cvNppc1K_8dQLELN16T/view)**.)


---

## 🔎 Exploring the Dataset
<details>
  <summary><b>Query 01: Calculate Quantity of items, Sales value & Order quantity by each Subcategory in the Last 12 Months (L12M)</b></summary>
  
  <br>

  **🎯 Business Purpose:** To evaluate the performance of all product subcategories over the last 12 months. This helps identify which products generate the most revenue and volume, showing the overall health of the business.

  **SQL Code:**
  ```sql
  SELECT FORMAT_DATETIME('%b %Y', a.ModifiedDate) AS month,
         c.Name,
         SUM(a.OrderQty) AS qty_item,
         SUM(a.LineTotal) AS total_sales,
         COUNT(DISTINCT a.SalesOrderID) AS order_cnt
  FROM `adventureworks2019.Sales.SalesOrderDetail` a 
  LEFT JOIN `adventureworks2019.Production.Product` b
      ON a.ProductID = b.ProductID
  LEFT JOIN `adventureworks2019.Production.ProductSubcategory` c
      ON b.ProductSubcategoryID = CAST(c.ProductSubcategoryID AS STRING)
  WHERE DATE(a.ModifiedDate) >= (
      SELECT DATE_SUB(DATE(MAX(a.ModifiedDate)), INTERVAL 12 MONTH)
      FROM `adventureworks2019.Sales.SalesOrderDetail`
  )
  GROUP BY 1, 2
  ORDER BY 1, 2;
  ```

  **Query Results:**

  | Month | Name | Qty Item | Total Sales (USD) | Order Cnt |
  | :--- | :--- | :--- | :--- | :--- |
  | Apr 2012 | Caps | 114 | $591.26 | 34 |
  | Apr 2012 | Helmets | 212 | $4,279.54 | 23 |
  | Apr 2012 | Jerseys | 206 | $5,941.12 | 36 |
  | Apr 2012 | Mountain Bikes | 501 | $403,252.25 | 69 |
  | Apr 2012 | Mountain Frames | 126 | $94,630.50 | 19 |
  | Apr 2012 | Road Bikes | 932 | $1,078,663.63 | 193 |
  | Apr 2012 | Road Frames | 205 | $46,666.80 | 24 |
  | Apr 2012 | Socks | 109 | $575.70 | 17 |
  | Apr 2013 | Bib-Shorts | 280 | $14,833.12 | 34 |
  | Apr 2013 | Caps | 182 | $926.12 | 36 |

  *(Note: Showing top 10 rows of the result)*

</details>

<details>
  <summary><b>Query 02: Calculate % YoY growth rate by SubCategory and identify the top 3 categories with the highest growth rate</b></summary>
  
  <br>

  **🎯 Business Purpose:** To measure Year-over-Year (YoY) growth across product subcategories. Tracking YoY growth helps the business identify expanding product lines, shifting consumer trends, and the success of recent marketing efforts.

  **SQL Code:**
  ```sql
  WITH sale_info AS (
      SELECT 
          FORMAT_TIMESTAMP("%Y", a.ModifiedDate) AS yr,
          c.Name,
          SUM(a.OrderQty) AS qty_item
      FROM `adventureworks2019.Sales.SalesOrderDetail` a 
      LEFT JOIN `adventureworks2019.Production.Product` b 
          ON a.ProductID = b.ProductID
      LEFT JOIN `adventureworks2019.Production.ProductSubcategory` c 
          ON CAST(b.ProductSubcategoryID AS INT) = c.ProductSubcategoryID
      GROUP BY 1, 2
  ),
  sale_diff AS (
      SELECT 
          yr,
          Name,
          qty_item,
          LEAD(qty_item) OVER (PARTITION BY Name ORDER BY yr DESC) AS prv_qty,
          ROUND(qty_item / LEAD(qty_item) OVER (PARTITION BY Name ORDER BY yr DESC) - 1, 2) AS qty_diff
      FROM sale_info
  ),
  rk_qty_diff AS (
      SELECT 
          yr,
          Name,
          qty_item,
          prv_qty,
          qty_diff,
          DENSE_RANK() OVER(ORDER BY qty_diff DESC) AS dk
      FROM sale_diff
  )
  SELECT DISTINCT 
      Name,
      qty_item,
      prv_qty,
      qty_diff
  FROM rk_qty_diff 
  WHERE dk <= 3
  ORDER BY prv_qty;
  ```

  **Query Results:**

  | Subcategory Name | Current Year Qty | Previous Year Qty | YoY Growth Rate |
  | :--- | :--- | :--- | :--- |
  | Mountain Frames | 3,168 | 510 | 5.21 |
  | Socks | 2,724 | 523 | 4.21 |
  | Road Frames | 5,564 | 1,137 | 3.89 |
  
  **💡 Business Insights:**
  * **The Rise of  SubCategory:** `Mountain Frames` (521% growth) and `Road Frames` (389% growth) are seeing massive spikes.
</details>

<details>
  <summary><b>Query 03: Ranking Top 3 TerritoryID with the biggest Order quantity of every year</b></summary>
  
  <br>

  **🎯 Business Purpose:** To identify the consistently top-performing sales regions over time. To optimize inventory distribution, regional marketing budgets, and sales force allocation.

  **SQL Code:**
  ```sql
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
  ```

  **Query Results:**

  | Year | TerritoryID | Order Quantity | Rank |
  | :--- | :--- | :--- | :--- |
  | 2011 | 4 | 3,238 | 1 |
  | 2011 | 6 | 2,705 | 2 |
  | 2011 | 1 | 1,964 | 3 |
  | 2012 | 4 | 17,553 | 1 |
  | 2012 | 6 | 14,412 | 2 |
  | 2012 | 1 | 8,537 | 3 |
  | 2013 | 4 | 26,682 | 1 |
  | 2013 | 6 | 22,553 | 2 |
  | 2013 | 1 | 17,452 | 3 |
  | 2014 | 4 | 11,632 | 1 |
  | 2014 | 6 | 9,711 | 2 |
  | 2014 | 1 | 8,823 | 3 |

  **💡 Business Insights:**
  * **Highly Stable Market Leaders:** The sales distribution is extremely static. From 2011 to 2014, Territory 4, 6, and 1 have maintained the exact same 1st, 2nd, and 3rd positions without any fluctuation. This indicates very stable market demand and customer loyalty in these specific regions.
  * **The Drop in 2014:** Order quantities peaked in 2013 across all regions but show a significant drop in 2014. 
  * **Actionable Recommendation:** The supply chain team must prioritize inventory routing to Territories 4, 6, and 1 to prevent stockouts in these regions. Meanwhile, sales leadership needs to investigate why other territories consistently fail to break into the top 3 and adjust regional sales strategies accordingly.

</details>

<details>
  <summary><b>Query 04: Calculate Total Discount Cost of Seasonal Discounts for each Subcategory</b></summary>
  
  <br>

  **🎯 Business Purpose:** To measure how much money is spent on seasonal promotion campaigns. To evaluate the financial impact of current discounting strategies.

  **SQL Code:**
  ```sql
SELECT 
    FORMAT_TIMESTAMP("%Y", header.OrderDate) AS year,
    c.Name,
    SUM(a.OrderQty * d.DiscountPct * a.UnitPrice) AS total_cost
FROM `adventureworks2019.Sales.SalesOrderDetail` a
INNER JOIN `adventureworks2019.Sales.SalesOrderHeader` header 
    ON a.SalesOrderID = header.SalesOrderID
INNER JOIN `adventureworks2019.Production.Product` b 
    ON a.ProductID = b.ProductID
INNER JOIN `adventureworks2019.Production.ProductSubcategory` c 
    ON CAST(b.ProductSubcategoryID AS INT64) = c.ProductSubcategoryID
INNER JOIN `adventureworks2019.Sales.SpecialOffer` d 
    ON a.SpecialOfferID = d.SpecialOfferID
WHERE d.Type = 'Seasonal Discount'
GROUP BY 1, 2
ORDER BY 1;
  ```

  **Query Results:**

  | Year | Subcategory Name | Total Discount Cost (USD) |
  | :--- | :--- | :--- |
  | 2012 | Helmets | $149.72 |
  | 2013 | Helmets | $543.22 |

  **💡 Business Insights:**
  * **Lack of Promotional Investment:** `Helmets` is the only subcategory receiving seasonal discounts.
  * **Explaining Poor Cross-Selling:** This explains the low helmet sales discovered in Query 01. The company is not spending enough marketing budget to promote accessories.
  * **Actionable Recommendation:** To fix this, the marketing team should increase the promotional budget for accessories.

</details>

<details>
  <summary><b>Query 05: Retention rate of Customers in 2014 with status of Successfully Shipped (Cohort Analysis)</b></summary>
  
  <br>

  **🎯 Business Purpose:** To track customer loyalty and repeat purchase behavior over time. Cohort analysis helps identify the exact life cycle of a customer and when they are most likely to return to the store.

  **SQL Code:**
  ```sql
  WITH info AS (
      SELECT  
          EXTRACT(MONTH FROM ModifiedDate) AS month_no,
          EXTRACT(YEAR FROM ModifiedDate) AS year_no,
          CustomerID,
          COUNT(DISTINCT SalesOrderID) AS order_cnt
      FROM `adventureworks2019.Sales.SalesOrderHeader`
      WHERE FORMAT_TIMESTAMP("%Y", ModifiedDate) = '2014'
        AND Status = 5
      GROUP BY 1, 2, 3
  ),
  row_num AS (
      SELECT 
          month_no,
          year_no,
          CustomerID,
          order_cnt,
          ROW_NUMBER() OVER (PARTITION BY CustomerID ORDER BY month_no) AS row_numb
      FROM info 
  ), 
  first_order AS (
      SELECT 
          month_no,
          year_no,
          CustomerID,
          order_cnt
      FROM row_num
      WHERE row_numb = 1
  ), 
  month_gap AS (
      SELECT 
          a.CustomerID,
          b.month_no AS month_join,
          a.month_no AS month_order,
          a.order_cnt,
          CONCAT('M - ', a.month_no - b.month_no) AS month_diff
      FROM info a 
      LEFT JOIN first_order b 
          ON a.CustomerID = b.CustomerID
  )
  SELECT month_join,
         month_diff,
         COUNT(DISTINCT CustomerID) AS customer_cnt
  FROM month_gap
  GROUP BY 1, 2
  ORDER BY 1, 2;
  ```

  **Query Results:**

  | Month Join (Cohort) | Month Diff | Retained Customers |
  | :--- | :--- | :--- |
  | 1 (Jan) | M - 0 | 2,076 |
  | 1 | M - 1 | 78 |
  | 1 | M - 2 | 89 |
  | 1 | M - 3 | 252 |
  | 1 | M - 4 | 96 |
  | ... | ... | ... |
  | 2 (Feb) | M - 0 | 1,805 |
  | 2 | M - 1 | 51 |
  | 2 | M - 2 | 61 |
  | 2 | M - 3 | 234 |

</details>

<details>
  <summary><b>Query 06: Trend of Stock level & MoM diff % by all products in 2011</b></summary>
  
  <br>

  **🎯 Business Purpose:** To track Month-over-Month (MoM) inventory levels. Understanding stock fluctuations helps the supply chain team identify production cycles, prevent overstocking, and optimize working capital.

  **SQL Code:**
  ```sql
  WITH raw_data AS (
      SELECT
          EXTRACT(MONTH FROM a.ModifiedDate) AS mth,
          EXTRACT(YEAR FROM a.ModifiedDate) AS yr,
          b.Name,
          SUM(StockedQty) AS stock_qty
      FROM `adventureworks2019.Production.WorkOrder` a
      LEFT JOIN `adventureworks2019.Production.Product` b 
          ON a.ProductID = b.ProductID
      WHERE FORMAT_TIMESTAMP("%Y", a.ModifiedDate) = '2011'
      GROUP BY 1, 2, 3
  )
  SELECT 
      Name,
      mth, 
      yr, 
      stock_qty,
      stock_prv,
      ROUND(COALESCE((stock_qty / stock_prv - 1) * 100, 0), 1) AS diff   
  FROM (                                                              
      SELECT *,
             LEAD(stock_qty) OVER (PARTITION BY Name ORDER BY mth DESC) AS stock_prv
      FROM raw_data
  )
  ORDER BY 1 ASC, 2 DESC;
  ```

  **Query Results:**

  | Product Name | Month | Year | Current Stock | Previous Stock | MoM Diff (%) |
  | :--- | :--- | :--- | :--- | :--- | :--- |
  | BB Ball Bearing | 12 | 2011 | 8,475 | 14,544 | -41.7% |
  | BB Ball Bearing | 11 | 2011 | 14,544 | 19,175 | -24.2% |
  | BB Ball Bearing | 10 | 2011 | 19,175 | 8,845 | 116.8% |
  | BB Ball Bearing | 9 | 2011 | 8,845 | 9,666 | -8.5% |
  | BB Ball Bearing | 8 | 2011 | 9,666 | 12,837 | -24.7% |
  | BB Ball Bearing | 7 | 2011 | 12,837 | 5,259 | 144.1% |

  *(Note: Showing partial results to highlight cyclical patterns)*

  **💡 Business Insights:**
  * **Batch Production Strategy:** This data confirms that AdventureWorks utilizes a periodic "Batch Production" model rather than a Just-In-Time (JIT) approach. They manufacture large runs of components at the start of specific quarters and consume them over the next few months.

</details>

<details>
  <summary><b>Query 07: Calculate the Ratio of Stock to Sales in 2011 by product and month</b></summary>
  
  <br>

  **🎯 Business Purpose:** To measure inventory efficiency by comparing how much is stocked versus how much is actually sold.

  **SQL Code:**
  ```sql
  WITH sale_info AS (
      SELECT 
          EXTRACT(MONTH FROM a.ModifiedDate) AS mth,
          EXTRACT(YEAR FROM a.ModifiedDate) AS yr,
          a.ProductId,
          b.Name,
          SUM(a.OrderQty) AS sales
      FROM `adventureworks2019.Sales.SalesOrderDetail` a 
      LEFT JOIN `adventureworks2019.Production.Product` b 
          ON a.ProductID = b.ProductID
      WHERE FORMAT_TIMESTAMP("%Y", a.ModifiedDate) = '2011'
      GROUP BY 1, 2, 3, 4
  ), 
  stock_info AS (
      SELECT
          EXTRACT(MONTH FROM o.ModifiedDate) AS mth,
          EXTRACT(YEAR FROM o.ModifiedDate) AS yr,
          o.ProductId,
          SUM(o.StockedQty) AS stock_cnt
      FROM `adventureworks2019.Production.WorkOrder` o
      WHERE FORMAT_TIMESTAMP("%Y", ModifiedDate) = '2011'
      GROUP BY 1, 2, 3
  )
  SELECT
      a.mth,
      a.yr,
      a.ProductId,
      a.Name,
      a.sales,
      b.stock_cnt AS stock,
      ROUND(COALESCE(b.stock_cnt, 0) / sales, 2) AS ratio
  FROM sale_info a 
  FULL JOIN stock_info b 
      ON a.ProductId = b.ProductId
      AND a.mth = b.mth 
      AND a.yr = b.yr
  ORDER BY 1 DESC, 7 DESC;
  ```

  **Query Results:**

  | Month | Year | Product Name | Sales | Stock | Stock/Sales Ratio |
  | :--- | :--- | :--- | :--- | :--- | :--- |
  | 12 | 2011 | HL Mountain Frame - Black, 48 | 1 | 27 | 27.0 |
  | 12 | 2011 | HL Mountain Frame - Black, 42 | 1 | 26 | 26.0 |
  | 12 | 2011 | HL Mountain Frame - Silver, 38 | 2 | 32 | 16.0 |
  | ... | ... | ... | ... | ... | ... |
  | 12 | 2011 | Road-150 Red, 48 | 32 | 47 | 1.47 |
  | 12 | 2011 | Mountain-100 Black, 38 | 23 | 28 | 1.22 |
  | 12 | 2011 | Road-650 Black, 44 | 19 | 21 | 1.11 |

  *(Note: Showing partial results to highlight the contrast between high and low ratios)*

  **💡 Business Insights:**
  * **Overstocking of Specific Frames:** Certain frame models (like the `HL Mountain Frame - Black, 48`) have a dangerously high ratio of 27.0. This means the factory produced 27 units just to sell 1. This ties up significant warehouse space.
  * **Highly Efficient Finished Goods:** Conversely, fully assembled bicycles (like the `Road-650 Black` and `Mountain-100`) have very healthy ratios (between 1.1 and 1.5). They are selling almost as fast as they are being produced.
  * **Actionable Recommendation:** Reduce production batches that have a high stock/sales ratio, and redirect factory capacity toward fast-selling assembled bicycles to maximize revenue and capital efficiency.

</details>

<details>
  <summary><b>Query 08: Number of orders and value at Pending status in 2014</b></summary>
  
  <br>

  **🎯 Business Purpose:** To evaluate the backlog of unfulfilled purchase orders . To identify supply chain bottlenecks and manage cash flow.

  **SQL Code:**
  ```sql
  SELECT
      EXTRACT(YEAR FROM DATE(OrderDate)) AS Year,
      Status,
      COUNT(DISTINCT PurchaseOrderID) AS Order_cnt,
      SUM(TotalDue) AS Value
  FROM `adventureworks2019.Purchasing.PurchaseOrderHeader`
  WHERE Status = 1
      AND EXTRACT(YEAR FROM DATE(OrderDate)) = 2014
  GROUP BY Year, Status
  ORDER BY Year;
  ```

  **Query Results:**

  | Year | Status | Order Count | Total Value (USD) |
  | :--- | :--- | :--- | :--- |
  | 2014 | 1 (Pending) | 224 | $3,873,579.01 |

  **💡 Business Insights:**
  * **High Pending Value:** There are 224 pending purchase orders in 2014, representing a massive value of nearly **$3.87 million**.
  * **Supply Chain Risk:** This large backlog means millions of dollars worth of inventory or raw materials have not yet arrived. This delay could stall factory production and cause stockouts for fast-selling items.

</details>

---

## 🚩 Final Conclusion
---
In conclusion, this project used Google BigQuery and advanced SQL to analyze the full business cycle of a bicycle manufacturer, from purchasing and inventory to sales and customer retention. 

Overall, the analysis showed that bikes sell very well, but keeping too many parts (like frames) in stock wastes company money. We also found that customers usually return to buy again after 3 months, and $3.8M in delayed orders is creating a supply risk. These insights may help the company cut inventory costs, fix supply problems, and plan better marketing.
