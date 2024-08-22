-- 1.How many customers has Foodie-Fi ever had?


select count(distinct customer_id) as Number_of_Customers
from subscriptions

	
-- 2.What is the monthly distribution of trial plan start_date values for our dataset - 
-- use the start of the month as the group by value

	
select 
Date_Part('Month',start_date) as Month_Date,count(sub.customer_id) as No_of_Customers
from Subscriptions sub
join plans p
on p.plan_id=sub.plan_id
where p.plan_id=0
group by Date_Part('Month',start_date)
order by Month_Date

	
-- 3. What plan start_date values occur after the year 2020 for our dataset?
-- Show the breakdown by count of events for each plan_name.

	
select p.plan_id,p.plan_name,count(sub.customer_id)
from plans p
join subscriptions sub
on sub.plan_id=p.plan_id
where sub.start_date>'2020-12-31'
group by p.plan_id,p.plan_name
order by p.plan_id


-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

	
select count(distinct sub.customer_id) as churned_customers,Round(100*count(sub.customer_id))/ 
	(SELECT COUNT(DISTINCT customer_id) 
 FROM subscriptions) as Churned_Percentage
FROM subscriptions AS sub
JOIN plans
  ON sub.plan_id = plans.plan_id
WHERE plans.plan_id = 4;


-- 5. How many customers have churned straight after their initial free trial -
	-- what percentage is this rounded to the nearest whole number?


with cte as(
select sub.customer_id,plans.plan_id,
row_number()over(partition by sub.customer_id order by sub.start_date) as row_num
from subscriptions sub
join plans 
on plans.plan_id=sub.plan_id)

select 
	count(
case when row_num=2 and plan_id= 4 then 1
else 0 end)as churned_Custumer,
	ROUND(100.0 * COUNT(	
case when row_num=2 and plan_id= 4 then 1
else 0 end)/(SELECT COUNT(DISTINCT customer_id) 
      FROM subscriptions)
	) as Churn_Percentage
from cte 
where plan_id=4 and row_num=2

	
-- 6. What is the number and percentage of customer plans after their initial free trial?

	
WITH next_plan AS
	(select *, 
LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date, plan_id) plans
	from subscriptions), 
planning AS
	(select s.plans,count(distinct customer_id) total,
(100 * cast(count(distinct customer_id)as float) / (select count(distinct customer_id)
from subscriptions)) percentage
from next_plan s
left join plans p on p.plan_id = s.plans
where s.plan_id = 0 
and s.plans is not null
group by s.plans)
select p.plan_name, s.total, s.percentage
from planning s
left join plans p 
on p.plan_id = s.plans

	
--7. What is the customer count and percentage breakdown of all 5 plan_name values after 2020-12-31?

	
with cte as(	
SELECT plans.plan_id,subscriptions.customer_id,plans.plan_name,
row_number() over(PARTITION BY customer_id ORDER BY start_date DESC) AS latest_plan
   FROM subscriptions 
   JOIN plans 
   on plans.plan_id=subscriptions.plan_id
   WHERE start_date <='2020-12-31')

SELECT plan_id, COUNT(DISTINCT customer_id) AS customers,
  ROUND(100.0 * COUNT(DISTINCT customer_id)
    / (SELECT COUNT(DISTINCT customer_id) 
      FROM subscriptions),1) AS percentage
FROM cte
where plan_id<>0	
GROUP BY plan_id

	
-- 8. How many customers have upgraded to an annual plan in 2020?

	
select count(distinct customer_id)as No_of_Annual_Plan_Users
from subscriptions
where plan_id=3 and start_date<'2020-12-31'


-- 9. How many days on average does it take for a customer to upgrade to an annual
	-- plan from the day they join Foodie-Fi?

	
with trail_plan as(
select customer_id,start_date as trial_date
from subscriptions
where plan_id=0 	
),annual_plan as(
	
select customer_id,start_date as annual_date
from subscriptions
where plan_id=3)

select Round(avg(annual.annual_date - trial.trial_date),0) as Avg_Days
from trail_plan as trial
join annual_plan as annual
on trial.customer_id=annual.customer_id


-- 10. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

	
with cte as(
select sub.customer_id,plans.plan_id,plans.plan_name,
lead(plans.plan_id)over(partition by sub.customer_id order by sub.start_date)as nxt_plan_id
from subscriptions sub
join plans 
on plans.plan_id=sub.plan_id
where date_part('Year',start_date)=2020)

select count(customer_id)as Churned_customer
from cte
where plan_id=2
and nxt_plan_id=1

