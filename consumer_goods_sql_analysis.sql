SELECT * FROM gdb023.dim_customer;
SELECT 
DISTINCT market
FROM dim_customer
WHERE customer = 'Atliq Exclusive' and region = 'APAC';

/*What is the percentage of unique product increase in 2021 vs. 2020? The
final output contains these fields,
unique_products_2020
unique_products_2021
percentage_chg */

WITH products_2020 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2020
    FROM fact_sales_monthly
    WHERE fiscal_year = 2020
),
products_2021 AS (
    SELECT COUNT(DISTINCT product_code) AS unique_products_2021
    FROM fact_sales_monthly
    WHERE fiscal_year = 2021
)
SELECT 
    p2020.unique_products_2020,
    p2021.unique_products_2021,
    ROUND(((p2021.unique_products_2021 - p2020.unique_products_2020) / p2020.unique_products_2020) * 100, 2) AS percentage_chg
FROM products_2020 p2020
CROSS JOIN products_2021 p2021;

/* Provide a report with all the unique product counts for each segment and
sort them in descending order of product counts. The final output contains
2 fields,
segment
product_count */

SELECT
segment, 
COUNT(DISTINCT product_code ) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

/* Follow-up: Which segment had the most increase in unique products in
2021 vs 2020? The final output contains these fields,
segment
product_count_2020
product_count_2021
difference */

WITH segment_counts AS (
    SELECT
        dp.segment,
        fsm.fiscal_year,
        COUNT(DISTINCT fsm.product_code) AS product_count
    FROM fact_sales_monthly fsm
    JOIN dim_product dp
        ON fsm.product_code = dp.product_code
    WHERE fsm.fiscal_year IN (2020, 2021)
    GROUP BY dp.segment, fsm.fiscal_year
)

SELECT
    s2020.segment,
    s2020.product_count AS product_count_2020,
    s2021.product_count AS product_count_2021,
    (s2021.product_count - s2020.product_count) AS difference
FROM segment_counts s2020
JOIN segment_counts s2021
    ON s2020.segment = s2021.segment
WHERE s2020.fiscal_year = 2020
AND s2021.fiscal_year = 2021
ORDER BY difference DESC;

/* Get the products that have the highest and lowest manufacturing costs.
The final output should contain these fields,
product_code
product
manufacturing_cos */

SELECT
p.product_code,
p.product,
m.manufacturing_cost
FROM dim_product p
JOIN fact_manufacturing_cost m
ON p.product_code = m.product_code
WHERE m.manufacturing_cost = ( SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost ) OR 
	  m.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

/*Generate a report which contains the top 5 customers who received an
average high pre_invoice_discount_pct for the fiscal year 2021 and in the
Indian market. The final output contains these fields,
customer_code
customer
average_discount_percentage */

SELECT
d.customer_code,
d.customer,
ROUND(AVG(p.pre_invoice_discount_pct),2) AS average_discount_percentage 
FROM dim_customer d
JOIN fact_pre_invoice_deductions p
ON d.customer_code = p.customer_code
WHERE p.fiscal_year = 2021 AND d.market = "India"
GROUP BY d.customer_code, d.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

/* Get the complete report of the Gross sales amount for the customer “Atliq
Exclusive” for each month. This analysis helps to get an idea of low and
high-performing months and take strategic decisions.
The final report contains these columns:
Month
Year
Gross sales Amount */

SELECT
MONTH(s.date) as Month,
YEAR(s.date) as Year,
ROUND(SUM(g.gross_price * s.sold_quantity),2) AS Gross_sales_amount
FROM fact_sales_monthly s
JOIN fact_gross_price g 
ON s.product_code = g.product_code
AND s.fiscal_year = g.fiscal_year
JOIN dim_customer c
ON c.customer_code = s.customer_code
WHERE c.customer = 'Atliq Exclusive'
GROUP BY YEAR(s.date), MONTH(s.date)
ORDER BY YEAR(s.date), MONTH(s.date);


/* 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
output contains these fields sorted by the total_sold_quantity,
Quarter
total_sold_quantity */

SELECT
CASE
    WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
	WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
	WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
    ELSE 'Q4'
END AS Quarter,
SUM(sold_quantity) as total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC;

/*Which channel helped to bring more gross sales in the fiscal year 2021
and the percentage of contribution? The final output contains these fields,
channel
gross_sales_mln
percentage */

WITH sales_mln AS(
SELECT
c.channel,
ROUND(SUM(g.gross_price*s.sold_quantity)/1000000,2) AS gross_sales_mln
FROM fact_sales_monthly s
JOIN fact_gross_price g 
ON s.product_code = g.product_code
AND s.fiscal_year = g.fiscal_year
JOIN dim_customer c
ON c.customer_code = s.customer_code
WHERE s.fiscal_year = 2021
GROUP BY c.channel
)
SELECT
channel,
gross_sales_mln,
ROUND(gross_sales_mln * 100 / SUM(gross_sales_mln) OVER(),2) as percentage
FROM sales_mln
ORDER BY gross_sales_mln DESC;
                
/* 10. Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? The final output contains these
fields: division, product_code, product, total_sold_quantity, rank_order*/

WITH cte1 AS (
SELECT
p.division, p.product_code, p.product,
SUM(s.sold_quantity) as total_sold_quantity
FROM fact_sales_monthly s
JOIN dim_product p
ON s.product_code = p.product_code
WHERE s.fiscal_year = 2021
GROUP BY p.product, p.division, p.product_code
),
cte2 AS (
SELECT *,
DENSE_RANK() OVER(PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
FROM cte1
)
SELECT * FROM cte2 WHERE rank_order <= 3;





























