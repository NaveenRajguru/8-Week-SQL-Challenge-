select * from campaign_identifier
select * from event_identifier
select * from events
select * from users
select * from page_hierarchy

-- A. DIGITAL ANALYSIS

-- 1.How many users are there?

SELECT Count(distinct user_id) as No_of_Users
from users

-- 2. How many cookies does each user have on average?

with cte as(
select user_id,count(cookie_id) as cookies
from users
group by user_id)
select round(avg(cookies),0) as avg_cookies
from cte

-- 3. What is the unique number of visits by all users per month?

select extract(Month from event_time) as Month,
count(distinct visit_id) 
from events
group by Month
order by Month asc

-- 4. What is the number of events for each event type?

select distinct event_type,count(event_type)
from events
group by event_type

-- 5. What is the percentage of visits which have a purchase event?

select 100*count(distinct e.visit_id)/(select count(distinct visit_id)from events) as Percentage_visit
from events as e
join event_identifier as ei
on e.event_type=ei.event_type
where ei.event_name='Purchase'

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event? 


-- 7. What are the top 3 pages by number of views?

select pg.page_name,count(e.page_id)as Top_Views
from page_hierarchy as pg
join events as e
on e.page_id=pg.page_id
group by  e.page_id,page_name
order by top_views desc
limit 3

-- 8. What is the number of views and cart adds for each product category?

select ph.product_category,
sum(case when e.event_type= 1 then 1 else 0 end ) as Page_Views,
sum(case when e.event_type= 2 then 1 else 0 end ) as Add_To_Cart
from events as e
join page_hierarchy as ph
on e.page_id=ph.page_id
where ph.product_category is not null
group by ph.product_category


 -- B. PRODUCT FUNNEL ANALYSIS

-- Using a single SQL query - create a new output table which has the following details:

-- 1.How many times was each product viewed?
-- 2.How many times was each product added to cart?
-- 3.How many times was each product added to a cart but not purchased (abandoned)?
-- 4.How many times was each product purchased?
-- Additionally, create another table which further aggregates the data for the above points 
-- but this time for each product category instead of individual products.

with cte1 as (
select e.visit_id,ph.product_id,ph.page_name as product_name,ph.product_category,
sum(case when e.event_type=1 then 1 else 0 end) as Page_Views,
sum(case when e.event_type=2 then 1 else 0 end) as cart_add
from events as e
join page_hierarchy as ph
on e.page_id=ph.page_id
where product_id is not null
group by e.visit_id,ph.product_id,ph.page_name,ph.product_category),
cte2 as(
	select distinct visit_id
	from events
	where event_type =3),
cte3 as(
	select cte1.visit_id,cte1.product_id,cte1.product_name,cte1.product_category,
	cte1.Page_Views, cte1.cart_add,
	case when cte2.visit_id is not null then 1 else 0 end as Purchase
	from cte1
	left join cte2
	on cte1.visit_id=cte2.visit_id),
cte4 as(
	select product_name,product_category,
	sum(Page_Views) as Views,
	sum(cart_add) as Cart_Adds,
	sum(case when cart_add = 1 and purchase = 0 then 1 else 0 END) AS abandoned,
    SUM(CASE WHEN cart_add = 1 and purchase = 1 then 1 else 0 END) AS purchases
	from cte3
	group by product_id, product_name, product_category)
select *
from cte4

 -- Additionally, create another table which further aggregates the data for the above points
-- but this time for each product category instead of individual products.

with cte1 as (
select e.visit_id,ph.product_id,ph.page_name as product_name,ph.product_category,
sum(case when e.event_type=1 then 1 else 0 end) as Page_Views,
sum(case when e.event_type=2 then 1 else 0 end) as cart_add
from events as e
join page_hierarchy as ph
on e.page_id=ph.page_id
where product_id is not null
group by e.visit_id,ph.product_id,ph.page_name,ph.product_category),
cte2 as(
	select distinct visit_id
	from events
	where event_type =3),
cte3 as(
	select cte1.visit_id,cte1.product_id,cte1.product_name,cte1.product_category,
	cte1.Page_Views, cte1.cart_add,
	case when cte2.visit_id is not null then 1 else 0 end as Purchase
	from cte1
	left join cte2
	on cte1.visit_id=cte2.visit_id),
cte5 as(
	select product_category,
	sum(Page_Views) as Views,
	sum(cart_add) as Cart_Adds,
	sum(case when cart_add = 1 and purchase = 0 then 1 else 0 END) AS abandoned,
    SUM(CASE WHEN cart_add = 1 and purchase = 1 then 1 else 0 END) AS purchases
	from cte3
	group by product_category)
select *
from cte5


