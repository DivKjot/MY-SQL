CREATE SCHEMA dannys_diner;
USE dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  (1, 'sushi', 10),
  (2, 'curry', 15),
  (3, 'ramen', 12);
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
SELECT * FROM sales;
SELECT * FROM menu;
SELECT * FROM members;

-- 1. What is the total amount each customer spent at the restaurant?

SELECT
    customer_id,
    SUM(price) AS total_spent
FROM
    sales s
INNER JOIN menu m 
ON s.product_id = m.product_id
GROUP BY
    customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS days_visited
FROM
    sales
GROUP BY
    customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH CTE AS (
    SELECT * ,
        RANK() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rnk,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS rn
    FROM menu m
    INNER JOIN sales s 
    ON s.product_id = m.product_id
)
SELECT
    customer_id,
    product_name,
    order_date
FROM CTE
WHERE rnk = 1;

/*4. What is the most purchased item on the menu and how many times
 was it purchased by all customers?*/
 
 SELECT
    m.product_name,
    COUNT(s.product_id) AS number_of_times_sold
FROM sales s
JOIN menu m 
ON s.product_id = m.product_id
GROUP BY
    m.product_name
ORDER BY
    number_of_times_sold DESC
LIMIT 1;


 -- 5. Which item was the most popular for each customer?
 WITH CTE AS (
	SELECT product_name, customer_id,
	COUNT(order_date) AS orders,
		RANK() OVER(PARTITION BY customer_id order BY count(order_date) DESC) AS rnk,
		ROW_NUMBER() OVER(PARTITION BY customer_id order BY count(order_date) DESC) AS rn
	FROM sales s
	INNER JOIN menu m
	ON s.product_id = m.product_id
	GROUP BY product_name 
    ,customer_id
    )
SELECT product_name, customer_id
FROM CTE
WHERE rn=1;
 
-- 6. Which item was purchased first by the customer after they became a member?

WITH CTE AS(
	SELECT mb.customer_id,join_date,order_date,product_name,
		RANK() OVER(PARTITION BY mb.customer_id ORDER BY order_date ASC) AS rnk,
		ROW_NUMBER() OVER(PARTITION BY mb.customer_id ORDER BY order_date ASC) AS rn
	FROM members AS mb
		INNER JOIN sales AS s
		ON s.customer_id = mb.customer_id
		INNER JOIN menu m
		ON m.product_id = s.product_id
	WHERE s.order_date > mb.join_date -- gives dates after joining 
)
SELECT * 
FROM CTE 
WHERE rnk=1;

-- 7. Which item was purchased just before the customer became a member?

WITH CTE AS(
	SELECT mb.customer_id,join_date,order_date,product_name,
		RANK() OVER(PARTITION BY mb.customer_id ORDER BY order_date DESC) AS rnk,
		ROW_NUMBER() OVER(PARTITION BY mb.customer_id ORDER BY order_date DESC) AS rn
	FROM members AS mb
		INNER JOIN sales AS s
		ON s.customer_id = mb.customer_id
		INNER JOIN menu m
		ON m.product_id = s.product_id
	WHERE s.order_date < mb.join_date -- dates before they became members
)
SELECT * 
FROM CTE 
WHERE rnK=1;

-- 8. What is the total items and amount spent for each member before they became a member?

WITH CTE AS(
	SELECT mb.customer_id,join_date,order_date,product_name,
	SUM(m.price) as total_spent,
    COUNT(m.product_id) AS items_bought,
		RANK() OVER(PARTITION BY mb.customer_id ORDER BY order_date DESC) AS rnk,
		ROW_NUMBER() OVER(PARTITION BY mb.customer_id ORDER BY order_date DESC) AS rn
	FROM members AS mb
	INNER JOIN sales AS s
	ON s.customer_id = mb.customer_id
	INNER JOIN menu m
	ON m.product_id = s.product_id
		WHERE s.order_date < mb.join_date 
		GROUP BY customer_id
)
SELECT customer_id, product_name ,total_spent,items_bought 
FROM CTE 
WHERE rnK=1;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH CTE AS (
	SELECT m.product_id,m.product_name,m.price,s.customer_id,
		CASE
		WHEN product_name = 'sushi'
		THEN price*10*2
		ELSE price*10
		END AS points
	FROM menu m
	INNER JOIN sales s
	ON m.product_id =s.product_id
)
SELECT customer_id ,SUM(points) as total_points
FROM CTE
GROUP BY customer_id;

-- Alternatively

SELECT s.customer_id,
	SUM(CASE
	WHEN product_name = 'sushi'
	THEN price*10*2
	ELSE price*10
	END ) AS points
FROM menu m
INNER JOIN sales s
ON m.product_id =s.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have 
-- at the end of January?

SELECT s.customer_id,
	SUM(CASE
	WHEN s.order_date between mb.join_date AND DATE_ADD(mb.join_date , interval 6 day)
	THEN price*10*2
	WHEN m.product_name = 'sushi'
	THEN price*10*2
	ELSE price*10
	END)  AS points
-- DATE_FORMAT(s.order_date ,'%Y-%m-01') ,
-- mb.join_date AS membership_start_date,
-- DATE_ADD(mb.join_date , interval 6 day) as offer_ends_date,
-- s.order_date
FROM menu m
INNER JOIN sales s
ON m.product_id =s.product_id
INNER JOIN members mb
ON mb.customer_id =s.customer_id
WHERE DATE_FORMAT(s.order_date ,'%Y-%m-01') = '2021-01-01'
GROUP BY s.customer_id
ORDER BY s.customer_id ;

 
 -- BONUS Q1: create a column of memeber with Y as yes if ythe customer is a member 
 -- and N if not by joining all the tables
 
 SELECT mb.customer_id ,order_date,product_name ,price,
	 CASE 
	 WHEN join_date IS NULL THEN 'N'
	 WHEN join_date > order_date THEN 'N'
	 ELSE 'Y'
	 END AS member
 FROM sales s
 INNER JOIN menu m ON m.product_id = s.product_id
 LEFT JOIN members mb ON mb.customer_id =s.customer_id
 ORDER BY s.customer_id, order_date ,price DESC;
 
  -- BONUS Q2:Rank all the things
  
WITH CTE AS (
	SELECT s.customer_id ,order_date,product_name ,price,
		CASE 
		WHEN join_date IS NULL THEN 'N'
		WHEN order_date < join_date THEN 'N'
		ELSE 'Y'
		END AS member
	FROM sales s
	INNER JOIN menu m ON m.product_id = s.product_id
	LEFT JOIN members mb ON mb.customer_id =s.customer_id
	ORDER BY s.customer_id, order_date ,price DESC
)
SELECT * , 
	CASE 
	WHEN member = 'N' THEN NULL -- N in member column
	ELSE 
		RANK() OVER (PARTITION BY s.customer_id,member
		ORDER BY order_date)
		END AS rnk
FROM CTE;

SELECT s.customer_id ,order_date,product_name ,price,
	CASE 
	WHEN join_date IS NULL THEN 'N' -- A customer who has not joined is not a member (cust -C)
	WHEN order_date < join_date THEN 'N'
	ELSE 'Y'
	END AS member,
CASE 
WHEN join_date is null then null
WHEN order_date < join_date THEN null -- give null when not a member
ELSE
	RANK() OVER (PARTITION BY s.customer_id  -- else rank when the person is a member 
/* ,(CASE 
WHEN join_date IS NULL THEN 'N' -- A customer who has not joined is not a member (cust -C)
WHEN order_date < join_date THEN 'N'
ELSE 'Y'
END )*/
ORDER BY order_date) end AS rnk
FROM sales s
INNER JOIN menu m ON m.product_id = s.product_id
LEFT JOIN members mb ON mb.customer_id =s.customer_id
ORDER BY s.customer_id, order_date ,price DESC;