/* --------------------
   Case Study Questions
   --------------------*/
-- 1. What is the total amount each customer spent at the restaurant?

select customer_id, sum(price) as total_amount_spent
from sales s join menu m 
on s.product_id=m.product_id
group by customer_id;

-- 2. How many days has each customer visited the restaurant?

select customer_id, count(distinct order_date) as visit_cnt
from sales
group by customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with cte as(
select s.customer_id, s.order_date, m.product_name, dense_rank() over(partition by s.customer_id order by s.order_date) as rnk
from sales s join menu m 
on s.product_id=m.product_id)
select customer_id, product_name from cte 
where rnk=1
group by customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select m.product_name, count(*) as most_purchase
from sales s join menu m 
on s.product_id=m.product_id
group by m.product_name
order by most_purchase desc
limit 1;

-- 5. Which item was the most popular for each customer?

select s.customer_id, m.product_name, count(m.product_name) as order_cnt
from sales s left join menu m 
on s.product_id=m.product_id
group by s.customer_id, m.product_name
order by order_cnt desc;

-- 6. Which item was purchased first by the customer after they became a member?

select customer_id, order_date, join_date, product_name from
(select customer_id, order_date, join_date, product_name, dense_rank() over(partition by customer_id order by order_date) as rnk from
(select s.customer_id, order_date, join_date, me.product_name,
 case when order_date>join_date then 1 else 0 end as rnk
from sales s join members m 
on s.customer_id=m.customer_id join menu me 
on s.product_id=me.product_id) t1
where rnk=1) t2
where rnk=1;

-- 7. Which item was purchased just before the customer became a member?

select customer_id, order_date, join_date, product_name from
(select customer_id, order_date, join_date, product_name, dense_rank() over(partition by customer_id order by order_date desc) as rnk from
(select s.customer_id, order_date, join_date, me.product_name,
 case when order_date<join_date then 1 else 0 end as rnk
from sales s join members m 
on s.customer_id=m.customer_id join menu me 
on s.product_id=me.product_id) t1
where rnk=1) t2
where rnk=1;

-- 8. What is the total items and amount spent for each member before they became a member?

select s.customer_id, order_date, join_date, count(distinct s.product_id) as total_item,
sum(price) as total_amount_spent
from sales s left join members m 
on s.customer_id=m.customer_id left join menu me
on s.product_id=me.product_id
where order_date<join_date
group by s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select s.customer_id, sum(case when m.product_name='sushi' then 20*price else 10*price end) as total_points
from sales s join menu m 
on s.product_id=m.product_id
group by s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?

with cte as (
select s.customer_id,order_date, join_date,s.product_id,product_name, date_add(join_date,interval 6 day) as first_week_of_join_date, me.price
from sales s join members m 
on s.customer_id=m.customer_id join menu me 
on s.product_id=me.product_id)
select customer_id, sum(case when product_name = 'sushi' or order_date between join_date and first_week_of_join_date then 20*price 
else 10*price end) as points
from cte
where month(order_date)=1
group by customer_id
order by customer_id;

-- Bonus Question
-- Rcreate the following table output using the available data. 

select s.customer_id, order_date, product_name, price, 
case when order_date>=join_date then 'Y' else 'N' end as member
from sales s left join menu m 
on s.product_id=m.product_id left join members me
on s.customer_id=me.customer_id
order by s.customer_id,order_date;

-- Rank All The Things from previous questions

with cte as (
select s.customer_id, order_date, product_name, price, 
case when order_date>=join_date then 'Y' else 'N' end as member
from sales s left join menu m 
on s.product_id=m.product_id left join members me
on s.customer_id=me.customer_id
order by s.customer_id,order_date)
select customer_id, order_date, product_name, price, 
case when member='Y' then dense_rank() over(partition by customer_id,member order by order_date)
else null end as ranking
from cte;
