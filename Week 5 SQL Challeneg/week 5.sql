select * from weekly_sales

-- A. DATA CLEANING PROCESS

	
drop table if exists weekly_sales;
create temp table weekly_sales AS
select
  Cast(week_date AS DATE) AS week_date, 
  DATE_PART('week', CAST(week_date AS DATE)) AS week_number,
  DATE_PART('month', CAST(week_date AS DATE)) AS month_number,
  DATE_PART('year', CAST(week_date AS DATE)) AS calendar_year,
  region, 
  platform, 
  segment,
  CASE 
    WHEN RIGHT(segment, 1) = '1' THEN 'Young Adults'
    WHEN RIGHT(segment, 1) = '2' THEN 'Middle Aged'
    WHEN RIGHT(segment, 1) IN ('3', '4') THEN 'Retirees'
    ELSE 'Unknown' 
  END AS age_band,
  CASE 
    WHEN LEFT(segment, 1) = 'C' THEN 'Couples'
    WHEN LEFT(segment, 1) = 'F' THEN 'Families'
    ELSE 'Unknown' 
  END AS demographic,
  transactions,
  ROUND(sales::NUMERIC / transactions, 2) AS avg_transaction,
  sales
FROM weekly_sales;



-- B. DATA EXPLORATION


-- 1. What day of the week is used for each week_date value?

SELECT DISTINCT(TO_CHAR(week_date,'day'))as week_day
from weekly_sales
	
-- 2.What range of week numbers are missing from the dataset?

with cte as(
select generate_series(1,52) as Week_number)
select distinct week_no.week_number
from cte as week_no
left join weekly_sales as sales
on week_no.week_number=sales.week_number
where sales.week_number is null

-- The data set is missing of total 28 week_number records

-- 3. How many total transactions were there for each year in the dataset?

select calendar_year,sum(transactions) as Total_Transactions
from weekly_sales
group by calendar_year
order by calendar_year

-- 4. What is the total sales for each region for each month?

select region,month_number,sum(sales) as Total_sales
from weekly_sales
group by region,month_number
order by month_number

-- 5.What is the total count of transactions for each platform ?

select platform,count(transactions) as No_of_Transactions
from weekly_sales
group by platform

-- 6. What is the percentage of sales for Retail vs Shopify for each month?	

WITH MonthlySales AS (
SELECT calendar_year, month_number,platform,
SUM(sales) AS total_sales
FROM weekly_sales
GROUP BY calendar_year, month_number, platform
),
TotalMonthlySales AS (
SELECT calendar_year,month_number,SUM(total_sales) AS monthly_total_sales
FROM MonthlySales
GROUP BY calendar_year, month_number
),
SalesPercentage AS (
SELECT ms.calendar_year,ms.month_number,ms.platform,ms.total_sales,tm.monthly_total_sales,
(ms.total_sales * 100.0 / tm.monthly_total_sales) AS percentage_of_sales
FROM  MonthlySales ms
JOIN TotalMonthlySales tm
ON ms.calendar_year = tm.calendar_year AND ms.month_number = tm.month_number
)
SELECT calendar_year,month_number,platform,percentage_of_sales
FROM SalesPercentage
ORDER BY calendar_year, month_number, platform;

-- 7. What is the percentage of sales by demographic for each year in the dataset?

with cte as(
select
Calendar_year,demographic,sum(sales) as Total_Yearly_Sales
from weekly_sales
group by demographic,Calendar_year)

select Calendar_year, round(100 * max
(case when demographic = 'Couples' then Total_yearly_sales else null end) / sum(Total_yearly_sales),2) as couples_percentage,

round(100* max
(case when demographic ='Families' then Total_yearly_sales else null end) / sum(Total_yearly_sales),2) as families_percentage,

round(100* max
(case when demographic='Unknown' then Total_yearly_sales else null end) / sum(Total_yearly_sales),2) as unknown_percentage
from cte 
group by Calendar_year

-- 8. Which age_band and demographic values contribute the most to Retail sales?

select age_band,platform,sum(sales) as Total_Sales,
round (100*
sum(sales)/sum(sum(sales))over(),1) as contribution
from weekly_sales
where platform='Retail'
group by age_band,platform

-- 9. Can we use the avg_transaction column to find the average transaction size for each year 
-- for Retail vs Shopify? If not - how would you calculate it instead?

select calendar_year,platform,
round(avg(avg_transaction),0) as avg_transaction_row,
sum(sales)/sum(transactions) as avg_transaction_group
from weekly_sales
group by calendar_year,platform


-- C. BEFORE AND AFTER EXPLORATION


-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or 
-- reduction rate in actual values and percentage of sales?

select distinct week_number
from weekly_sales
where week_date= '2020-06-15'
and calendar_year =2020
-- The week_number is 25. So we need to find before 25th week and after 25th week

with cte as(
select week_date,week_number,sum(sales) as Total_sales
from weekly_sales
where (week_number between 21 and 28)
and calendar_year='2020'
group by week_number,week_date
order by week_date),

cte1 as (
select sum(case when week_number between 21 and 24 then total_sales end) as Before_Changes,
sum(case when week_number between 25 and 28 then total_sales end) as After_Changes
from cte)

select After_Changes-Before_Changes as sales_varience,
round(100*(After_Changes-Before_Changes)/ Before_Changes,2) as Varience_Percenatge
from cte1


-- 2. What about the entire 12 weeks before and after?

with cte as(
select week_date,week_number,sum(sales)as Total_Sales
from Weekly_sales 
where (week_number between 13 and 37)
and calendar_year='2020'
group by week_date,week_number),

cte1 as(
select sum(case when week_number between 13 and 24 then Total_Sales end) as Before_Changes,
sum(case when week_number between 25 and 37 then Total_Sales end ) as After_Changes
from cte)

select After_Changes-Before_Changes as Sales_Varience,
Round(100* (After_Changes - Before_Changes)/ Before_Changes,2) as Varience_Percenatge
from cte1

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?

with cte as(
select calendar_year,week_number,sum(sales)as Total_Sales
from Weekly_sales 
where (week_number between 21 and 28)
group by calendar_year,week_number),

cte1 as(
select calendar_year,sum(case when week_number between 13 and 24 then Total_Sales end) as Before_Changes,
sum(case when week_number between 25 and 37 then Total_Sales end ) as After_Changes
from cte
Group by calendar_year)

select calendar_year, After_Changes-Before_Changes as Sales_Varience,
Round(100* (After_Changes - Before_Changes)/ Before_Changes,2) as Varience_Percenatge
from cte1

-- Part 2: How do the sale metrics for 12 weeks before and after compare with the previous years in 2018 and 2019?

with cte as(
select calendar_year,week_number,sum(sales)as Total_Sales
from Weekly_sales 
where (week_number between 13 and 37)
group by calendar_year,week_number),

cte1 as(
select calendar_year,sum(case when week_number between 13 and 24 then Total_Sales end) as Before_Changes,
sum(case when week_number between 25 and 37 then Total_Sales end ) as After_Changes
from cte
Group by calendar_year)

select calendar_year, After_Changes-Before_Changes as Sales_Varience,
Round(100* (After_Changes - Before_Changes)/ Before_Changes,2) as Varience_Percenatge
from cte1