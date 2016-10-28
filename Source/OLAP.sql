/******************************************************************
Q1: a) Determine the top 3 products in Dec 2014 in terms of total 
       sales.
    b) Determine the top 3 stores in Dec 2014 in terms of total 
       sales.
*******************************************************************/
--Q1a
SELECT rank() OVER( ORDER BY sales DESC) rank, product_id, product_name, sales FROM (
  SELECT a.product_id, b.product_name, sum(a.sales) sales
  FROM Sales_fact a, Product_D b, Time_D c
  WHERE b.product_id = a.product_id
    AND c.time_id = a.t_date
    AND c.month_code = '12'
  GROUP BY a.product_id, b.product_name
  ORDER BY sales DESC
)
WHERE rownum <4
;

--Q1b
SELECT rank() OVER( ORDER BY sales DESC) rank, store_id, store_name, sales FROM (
  SELECT a.store_id, b.store_name, sum(a.sales) sales
  FROM Sales_fact a, Store_d b, Time_D c
  WHERE b.store_id = a.store_id
    AND c.time_id = a.t_date
    AND c.month_code = '12'
  GROUP BY a.store_id, b.store_name
  ORDER BY sales DESC
)
WHERE rownum <4
;

/******************************************************************
Q2: Determine which store produced highest sales in the whole year?
*******************************************************************/
SELECT rank() OVER( ORDER BY sales DESC) rank, store_id, store_name, sales FROM (
  SELECT a.store_id, b.store_name, sum(a.sales) sales
  FROM Sales_fact a, Store_d b, Time_D c
  WHERE b.store_id = a.store_id
    AND c.time_id = a.t_date
    AND c.year_code = '2014'
  GROUP BY a.store_id, b.store_name
  ORDER BY sales DESC
)
WHERE rownum <2
;
  
/******************************************************************
Q3: How many sales transactions were there for the product that 
    generated maximum sales revenue in 2014? Also identify the a) 
    product quantity sold and b) supplier name.
*******************************************************************/
SELECT a.product_id, b.product_name, a.supplier_id, c.supplier_name, count(*) transactions, sum (a.quantity) quantity 
FROM Sales_fact a, Product_d b, Supplier_d c, (
  SELECT rank() OVER( ORDER BY sales DESC) rank, product_id, supplier_id, sales 
  FROM (
    SELECT a.product_id, a.supplier_id, sum(a.sales) sales
    FROM Sales_fact a
    GROUP BY a.product_id, a.supplier_id
    ORDER BY sales DESC
  )
  WHERE rownum <2
) d
WHERE a.product_id = b.product_id
  AND b.product_id = d.product_id
  AND a.supplier_id = c.supplier_id
  AND c.supplier_id = d.supplier_id
  AND d.rank = '1'
GROUP BY a.product_id, b.product_name, a.supplier_id, c.supplier_name
;

/******************************************************************
Q4: Present the quarterly sales analysis for all stores using drill
    down query concepts, resulting in a report that looks like:
    
    STORE_NAME    Q1_2014   Q2_2014   Q3_2014   Q4_2014
    ----------    -------   -------   -------   -------
*******************************************************************/
select distinct b.store_name, 
  (select sum(sales) total_sales 
    from sales_fact ia, time_d ib
    where ia.t_date = ib.time_id and ia.store_id = a.store_id and ib.quarter_code = 1
  ) Q1_2014, 
  (select sum(sales) total_sales 
    from sales_fact ia, time_d ib
    where ia.t_date = ib.time_id and ia.store_id = a.store_id and ib.quarter_code = 1
  ) Q2_2014, 
  (select sum(sales) total_sales 
    from sales_fact ia, time_d ib
    where ia.t_date = ib.time_id and ia.store_id = a.store_id and ib.quarter_code = 3
  ) Q3_2014, 
  (select sum(sales) total_sales 
    from sales_fact ia, time_d ib
    where ia.t_date = ib.time_id and ia.store_id = a.store_id and ib.quarter_code = 4
  ) Q4_2014
from sales_fact a, store_d b
where a.store_id = b.store_id
order by store_name
;
/******************************************************************
Q5: Determine the top 3 products for a particular month (say Dec 
    2014), and for each of the 2 months before that, in terms of
    total sales.
*******************************************************************/
VAR MONTH NUMBER;
EXEC :MONTH := &INPUT_YOUR_MONTH;
Select * from (
  SELECT rank() OVER( ORDER BY sales DESC) rank, product_id, product_name, month_code, sales FROM (
    SELECT a.product_id, b.product_name, c.month_code, sum(a.sales) sales
    FROM Sales_fact a, Product_D b, Time_D c
    WHERE b.product_id = a.product_id
      AND c.time_id = a.t_date
      AND c.month_code =: MONTH
    GROUP BY a.product_id, b.product_name, c.month_code
    ORDER BY sales DESC
  )
  WHERE rownum <4
  union
  SELECT rank() OVER( ORDER BY sales DESC) rank, product_id, product_name, month_code, sales FROM (
    SELECT a.product_id, b.product_name, c.month_code, sum(a.sales) sales
    FROM Sales_fact a, Product_D b, Time_D c
    WHERE b.product_id = a.product_id
      AND c.time_id = a.t_date
      AND c.month_code =: MONTH-1
    GROUP BY a.product_id, b.product_name, c.month_code
    ORDER BY sales DESC
  )
  WHERE rownum <4
  union
  SELECT rank() OVER( ORDER BY sales DESC) rank, product_id, product_name, month_code, sales FROM (
    SELECT a.product_id, b.product_name, c.month_code, sum(a.sales) sales
    FROM Sales_fact a, Product_D b, Time_D c
    WHERE b.product_id = a.product_id
      AND c.time_id = a.t_date
      AND c.month_code =: MONTH-2
    GROUP BY a.product_id, b.product_name, c.month_code
    ORDER BY sales DESC
  )
  WHERE rownum <4
)
order by month_code desc, sales desc
;
/******************************************************************
Q6: Create a materialised view with name “STOREANALYSIS” that
    presents the product-wise sales analysis for each store. Think
    about what information can be retrieved from this materialised 
    view using ROLLUP or CUBE concepts and provide some useful 
    information of your choice for management.
*******************************************************************/
DROP MATERIALIZED VIEW STOREANALYSIS;
CREATE MATERIALIZED VIEW STOREANALYSIS(
  store_id, store_name, product_id, product_name, supplier_id, 
  supplier_name, price, quantity, sales, t_date, date_code, 
  week_code, month_code, quarter, year_code, day_code
)  
  AS Select
      a.store_id, b.store_name, a.product_id, c.product_name, a.supplier_id, 
      d.supplier_name, c.price, a.quantity, a.sales, a.t_date, e.date_year_code,
      e.week_code, e.month_code, e.quarter_code, e.year_code, e.day_code  
    FROM Sales_fact a, store_d b, product_d c, supplier_d d, time_d e
    WHERE a.store_id = b.store_id
      AND a.product_id = c.product_id
      AND a.supplier_id = d.supplier_id
      AND a.t_date = e.time_id;
	  
--Sample Query
SELECT DISTINCT store_name, product_name, sum(sales) 
FROM STOREANALYSIS
WHERE week_code = 6
	AND product_id IN ('P-1002', 'P-1003', 'P-1005')
GROUP BY ROLLUP (store_name, product_name)
;

SELECT DISTINCT store_name, product_name, sum(sales) 
FROM STOREANALYSIS
WHERE week_code = 6
	AND product_id IN ('P-1002', 'P-1003', 'P-1005')
GROUP BY CUBE (store_name, product_name)
ORDER BY 1
;
