Q 1.What is the total amount each customer spent at the restaurant?

select s.customer_id , sum(m.price) as total_spent
from sales as s
join menu as m
on s.product_id = m.product_id
group by s.customer_id 

Q 2. How many days has each customer visited the restaurant?

select customer_id , count(distinct order_date)
from sales
group by customer_id


Q 3. What was the first item from the menu purchased by each customer?

WITH cte AS 
( 
select s.customer_id, m.product_name, s.order_date, DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS 'rank_no'
from sales as s
join menu as m
on s.product_id = m.product_id
)
select customer_id, product_name, rank_no
from cte
where rank_no = 1
group by customer_id, product_name

Q 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

select  m.product_name ,count(s.product_id) as total_items
from sales as s
join menu as m
on s.product_id = m.product_id
group by m.product_name
order by count(s.product_id) desc
limit 1

Q 5. Which item was the most popular for each customer?

with cte as (
select  s.customer_id, m.product_name ,count(s.product_id) as total_items, dense_rank () over (partition by  s.customer_id 
order by count(s.product_id) desc) as 'rank_no'
from sales as s
join menu as m
on s.product_id = m.product_id
group by s.customer_id, m.product_name
order by count(s.product_id) desc
)
select customer_id, product_name, total_items
from cte 
where rank_no = 1

Q 6. Which item was purchased first by the customer after they became a member?

with cte as (
select mem.customer_id, s.product_id, row_number() over (partition by mem.customer_id) as row_no
from sales as s
join members as mem
on s.customer_id = mem.customer_id
and s.order_date > mem.join_date
)
select customer_id, product_name
from cte
join menu as m
on cte.product_id = m.product_id
where  row_no =1

Q 7. Which item was purchased just before the customer became a member

with cte as (
select mem.customer_id, s.product_id, row_number() over (partition by mem.customer_id) as row_no
from sales as s
join members as mem
on s.customer_id = mem.customer_id
and s.order_date < mem.join_date
)
select customer_id, product_name
from cte
join menu as m
on cte.product_id = m.product_id
where  row_no =1

Q 8. What is the total items and amount spent for each member before they became a member?

select mem.customer_id, count(s.product_id) as total_items, sum(m.price) as total_spent
from members as mem
join sales as s
on mem.customer_id = s.customer_id
join menu as m
on s.product_id = m.product_id
where s.order_date < mem.join_date
group by mem.customer_id
order by mem.customer_id

Q 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT s.customer_id,
  SUM(
    CASE
      WHEN m.product_name = 'sushi' THEN (m.price * 2) * 10
      ELSE m.price * 10
    END
  ) AS total_points
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY s.customer_id;

Q 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

with jan_points as(
SELECT *, DATE_ADD(join_date,interval +6 day) as valid_date, LAST_DAY("2021-01-1") as last_date
FROM members
 )
 SELECT
	s.customer_id,
       SUM(case 
				WHEN s.product_id = 1 THEN price*20
               WHEN s.order_date between j.join_date and j.valid_date then price*20
               ELSE price*10
			END) as total_points
 FROM
		jan_points as j, sales as s, menu as m
 WHERE
		j.customer_id=s.customer_id
       and
       m.product_id =s.product_id
       and
     s.order_date <= j.last_date
 GROUP BY s.customer_id
 order by s.customer_id;
