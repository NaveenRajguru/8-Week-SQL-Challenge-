-- A. Customer Nodes Exploration

--1.How many unique nodes are there on the Data Bank system?

select count(distinct node_id)as Unique_Nodes
from customer_nodes

-- 2.What is the number of nodes per region?

select regions.region_name,count(distinct cn.node_id) as node_count
from customer_nodes as cn
join regions
on regions.region_id=cn.region_id
group by region_name

-- 3. How many customers are allocated to each region?

select regions.region_name,count(cn.customer_id)as No_of_Customers
from regions
join customer_nodes as cn
on regions.region_id=cn.region_id
group by region_name

-- 4. How many days on average are customers reallocated to a different node?

with cte as(	
select customer_id,node_id,
end_date - start_date as No_of_Days
from customer_nodes
where end_date != '9999-12-31'
group by customer_id,node_id,start_date,end_date),
cte_2 as(
	select customer_id,node_id,
	sum(No_of_Days) as Total_Days
	from cte 
	group by customer_id,node_id
)
select round(avg(Total_Days)) AS avg_node_reallocation_days
From cte_2

-- B. Customer Transactions

-- 1. What is the unique count and total amount for each transaction type?
	
select txn_type, count(customer_id)as Transaction_count,sum(txn_amount)as Amount
from customer_transactions
group by txn_type

-- 2. What is the average total historical deposit counts and amounts for all customers?

with cte as(	
select customer_id,count(customer_id)as txn_count,
round(avg(txn_amount))as avg_txn_amount
from customer_transactions
where txn_type= 'deposit'
group by customer_id )
select round(avg (txn_count)) as avg_deposit_count,
round(avg(avg_txn_amount)) as avg_amount
from cte

-- 3. For each month - how many Data Bank customers make more than 1 deposit andeither 1
	-- purchase or 1 withdrawal in a single month ?

select* from customer_nodes
select * from customer_transactions
	
with cte as(
select customer_id,
Date_part('month',txn_date) as Month,
sum (case when txn_type ='deposit' then 0 else 1 end) as Deposit_Count,
sum (case when txn_type ='purchase' then 0 else 1 end) as Purchase_Count,
sum (case when txn_type ='withdrawal' then 1 else 0 end) as Withdrawal_Count
from customer_transactions
group by customer_id,Date_part('month',txn_date)
	)
select Month, count(distinct customer_id)
from cte
where deposit_count >1  AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY Month

-- 4. What is the closing balance for each customer at the end of the month? 
	-- Also show the change in balance each month in the same table output.
 
select * from customer_transactions
SELECT 
    customer_id, 
    (DATE_TRUNC('month', txn_date) + INTERVAL '1 MONTH - 1 DAY') AS closing_month, 
    SUM(CASE 
      WHEN txn_type = 'withdrawal' OR txn_type = 'purchase' THEN -txn_amount
      ELSE txn_amount END) AS transaction_balance
  FROM customer_transactions
  GROUP BY customer_id, txn_date 

, monthend_series_cte AS (
  SELECT
    DISTINCT customer_id,
    ('2020-01-31'::DATE + GENERATE_SERIES(0,3) * INTERVAL '1 MONTH') AS ending_month
  FROM customer_transactions
)
-----------------------(NOT FULL SOLUTION)---------------------

-- 5.What is the percentage of customers who increase their closing balance by more than 5%?



