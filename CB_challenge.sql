use gdb023;


-- Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region

select distinct(market) from dim_customer 
where customer='atliq exclusive'
and region = 'apac';






 -- What is the percentage of unique product increase in 2021 vs. 2020?
 -- The final output contains these fields,
				-- unique_products_2020
				-- unique_products_2021
				-- percentage_chg



SELECT
  t1.unique_products_2020,
  t2.unique_products_2021,
  (t2.unique_products_2021 - t1.unique_products_2020) / t1.unique_products_2020 * 100 AS percentage_chg
FROM
  (SELECT COUNT(DISTINCT product_code) AS unique_products_2020 FROM fact_sales_monthly WHERE fiscal_year = 2020) t1,
  (SELECT COUNT(DISTINCT product_code) AS unique_products_2021 FROM fact_sales_monthly WHERE fiscal_year = 2021) t2;









-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
					-- 2 fields,
					-- segment
					-- product_count



select segment, count(distinct(product)) as NoOfProduct from dim_product
group by segment
order by 2 desc;









-- Follow-up: 	Which segment had the most increase in unique products in
-- 				2021 vs 2020? The final output contains these fields,
					-- segment
					-- product_count_2020
					-- product_count_2021
					-- difference




SELECT
  s.segment,
  COUNT(DISTINCT CASE WHEN t.fiscal_year = 2020 THEN t.product_code END) AS product_count_2020,
  COUNT(DISTINCT CASE WHEN t.fiscal_year = 2021 THEN t.product_code END) AS product_count_2021,
  COUNT(DISTINCT CASE WHEN t.fiscal_year = 2021 THEN t.product_code END) - COUNT(DISTINCT CASE WHEN t.fiscal_year = 2020 THEN t.product_code END) AS difference
FROM
  fact_sales_monthly t
  INNER JOIN dim_product s 
  ON t.product_code = s.product_code
WHERE
  t.fiscal_year IN (2020, 2021)
GROUP BY
  s.segment
ORDER BY
  difference DESC;








-- Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
				-- product_code
				-- product
				-- manufacturing_cost




select a.product,a.product_code,b.manufacturing_cost
from dim_product a inner join fact_manufacturing_cost b
on a.product_code	= b.product_code
where manufacturing_cost in (select max(manufacturing_cost) from fact_manufacturing_cost)
or
manufacturing_cost in (select min(manufacturing_cost) from fact_manufacturing_cost)
order by b.manufacturing_cost desc;









-- Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
					-- customer_code
					-- customer
					-- average_discount_percentage



select a.customer,a.customer_code, avg(b.pre_invoice_discount_pct) as average_discount_percentage
from dim_customer a inner join fact_pre_invoice_deductions b
on a.customer_code = b.customer_code

where a.market = 'India'
and 
b.fiscal_year = 2021

group by a.customer,a.customer_code
order by 3 desc limit 5;










-- Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
					-- Month
					-- Year
					-- Gross sales Amount




select  month(b.date) as month, b.fiscal_year, round(sum(a.gross_price*b.sold_quantity)/1000000,2) as Gross_sales_amount_in_M
from fact_gross_price a 
inner join fact_sales_monthly b on a.product_code = b.product_code and a.fiscal_year = b.fiscal_year
inner join dim_customer c  on b.customer_code = c.customer_code
where c.customer = 'Atliq Exclusive'
group by month, b.fiscal_year 
order by b.fiscal_year;







-- In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
						-- Quarter
						-- total_sold_quantity



select quarter(date) as quarter, sum(sold_quantity) as total_sold_quantity from fact_sales_monthly
where fiscal_year = 2020
group by quarter
order by 2;









-- Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
					-- channel
					-- gross_sales_mln
					-- percentage







SELECT 
  c.channel,
  ROUND(SUM(s.sold_quantity * g.gross_price)/1000000, 2) AS gross_sales_mln,
  ROUND(SUM(s.sold_quantity * g.gross_price) / (SELECT SUM(s.sold_quantity * g.gross_price) 
  FROM fact_sales_monthly s JOIN fact_gross_price g ON s.product_code = g.product_code 
  AND s.fiscal_year = g.fiscal_year WHERE s.fiscal_year = 2021) * 100, 2) AS percentage
FROM 
  fact_sales_monthly s 
  JOIN fact_gross_price g ON s.product_code = g.product_code AND s.fiscal_year = g.fiscal_year
  JOIN dim_customer c ON s.customer_code = c.customer_code
WHERE 
  s.fiscal_year = 2021
GROUP BY 
  c.channel
ORDER BY 
  gross_sales_mln DESC;






-- Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
					-- division
					-- product_code
					-- product
					-- total_sold_quantity
					-- rank_order





WITH cte AS (
  SELECT 
    p.division, 
    p.product_code, 
    p.product,
    SUM(s.sold_quantity) AS total_sold,
    ROW_NUMBER() OVER (PARTITION BY p.division ORDER BY SUM(s.sold_quantity) DESC) AS rank_order
  FROM 
    fact_sales_monthly s
    JOIN dim_product p ON s.product_code = p.product_code
   
  WHERE 
    s.fiscal_year = 2021
  GROUP BY 
    p.division, p.product_code, p.product
)
SELECT 
  division, product_code, product, total_sold, rank_order
FROM 
  cte
WHERE 
  rank_order <= 3
ORDER BY 
  division, total_sold DESC;










