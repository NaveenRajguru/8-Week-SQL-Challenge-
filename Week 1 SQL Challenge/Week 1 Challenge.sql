---What is the total amount each customer spent at the restaurant?

select * from members
select* from menu
select* from sales

select s.customer_id,sum(m.price) as Total_Price
from sales s
join menu m
on m.product_id=s.product_id
group by customer_id

---How many days has each customer visited the restaurant?

select customer_id,count(distinct order_date) as No_of_Times_Visits
from sales
group by customer_id

---What was the first item from the menu purchased by each customer?


with cte as(
SELECT s.customer_id,s.order_date,m.product_name,
DENSE_RANK() over(partition by s.customer_id order by s.order_date) as rank
from sales s
join menu m
on m.product_id=s.product_id
)
select customer_id,product_name
from cte
where rank=1
group by customer_id,product_name

---What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name,count(s.product_id) as No_of_Times
from menu m
join sales s
on s.product_id=m.product_id
group by m.product_name
order by No_of_Times desc


---Which item was the most popular for each customer?

with cte as(
select s.customer_id,m.product_name,count(s.product_id)as No_of_orders,
DENSE_RANK() over(partition by s.customer_id order by count(s.customer_id) desc) as rank
from sales s
join menu m
on m.product_id=s.product_id
group by s.customer_id,m.product_name)
select customer_id,product_name,No_of_orders
from cte
where rank=1

---Which item was purchased first by the customer after they became a member?

with cte as
(
select m.customer_id,s.product_id,s.order_date,
ROW_NUMBER()over(partition by m.customer_id order by s.order_date desc) as rank
from members m
join sales s
on s.customer_id=m.customer_id
and m.join_date>s.order_date)

select cte.customer_id,m.product_name
from cte 
join menu m
on m.product_id=cte.product_id
where rank =1


---Which item was purchased just before the customer became a member? 


with cte as(
select m.customer_id,s.product_id,s.order_date,
ROW_NUMBER()over(partition by m.customer_id order by s.order_date desc) as rank
from members m
join sales s
on s.customer_id=m.customer_id
and m.join_date<s.order_date)

select cte.customer_id,m.product_name
from cte 
join menu m
on m.product_id=cte.product_id
where rank =1


---What is the total items and amount spent for each member before they became a member?


select sales.customer_id,sum(menu.price) as Total_Price
from sales
inner join members
on sales.customer_id=members.customer_id
and sales.order_date<members.join_date
join menu
on menu.product_id=sales.product_id
group by sales.customer_id


---If each $1 spent equates to 10 points and sushi has a 2x points multiplier — how many points would each customer have?


with cte as(
select menu.product_id,
case when product_id =1 then price *20
else price * 10
end as Points
from menu)
select sales.customer_id,sum(cte.points) as Total_Points
from sales
join cte
on sales.product_id=cte.product_id
group by sales.customer_id


--- In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
 ---not just sushi — how many points do customer A and B have at the end of January?

-- Common Table Expression (CTE) to define date ranges
WITH dates_cte AS (
    SELECT 
        customer_id, 
        join_date, 
        DATEADD(DAY, 6, join_date) AS valid_date, 
        DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, '2021-01-31') + 1, 0)) AS last_date
    FROM members
)

-- Main query to calculate points
SELECT 
    sales.customer_id, 
    SUM(CASE
        WHEN menu.product_name = 'sushi' THEN 2 * 10 * menu.price
        WHEN sales.order_date BETWEEN dates.join_date AND dates.valid_date THEN 2 * 10 * menu.price
        ELSE 10 * menu.price 
    END) AS points
FROM sales
INNER JOIN dates_cte AS dates
    ON sales.customer_id = dates.customer_id
    AND dates.join_date <= sales.order_date
    AND sales.order_date <= dates.last_date
INNER JOIN menu
    ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;
