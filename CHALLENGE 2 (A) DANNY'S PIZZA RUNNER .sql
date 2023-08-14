CREATE SCHEMA pizza_runner;

SET search_path = pizza_runner;

USE pizza_runner;

DROP TABLE IF EXISTS runners;
-- creating tables

CREATE TABLE runners (
runner_id INT,
registration_date DATE
);
INSERT INTO runners VALUES
(1, '2021-01-01'),
(2, '2021-01-03'),
(3, '2021-01-08'),
(4, '2021-01-15');

DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
order_id INTEGER,
customer_id INTEGER,
pizza_id INTEGER,
exclusions VARCHAR(4),
extras VARCHAR(4),
order_time TIMESTAMP
);

INSERT INTO customer_orders VALUES
('1', '101', '1', '', '', '2020-01-01 18:05:02'),
('2', '101', '1', '', '', '2020-01-01 19:00:52'),
('3', '102', '1', '', '', '2020-01-02 23:51:23'),
('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');

DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
order_id INTEGER,
runner_id INTEGER,
pickup_time VARCHAR(19),
distance VARCHAR(7),
duration VARCHAR(10),
cancellation VARCHAR(23)
);

INSERT INTO runner_orders VALUES
('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');

DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
pizza_id INTEGER,
pizza_name TEXT
);
INSERT INTO pizza_names VALUES
(1, 'Meatlovers'),
(2, 'Vegetarian');

DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
pizza_id INTEGER,
toppings TEXT
);
INSERT INTO pizza_recipes VALUES
(1, '1, 2, 3, 4, 5, 6, 8, 10'),
(2, '4, 6, 7, 9, 11, 12');

DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
topping_id INTEGER,
topping_name TEXT
);
INSERT INTO pizza_toppings VALUES
(1, 'Bacon'),
(2, 'BBQ Sauce'),
(3, 'Beef'),
(4, 'Cheese'),
(5, 'Chicken'),
(6, 'Mushrooms'),
(7, 'Onions'),
(8, 'Pepperoni'),
(9, 'Peppers'),
(10, 'Salami'),
(11, 'Tomatoes'),
(12, 'Tomato Sauce');

-- CLEANING THE DATA / creating temporary tables
DROP TABLE IF EXISTS customer_orders_temp;

CREATE TABLE customer_orders_temp
SELECT order_id, customer_id, pizza_id,
	CASE 
		WHEN exclusions ='null' OR exclusions IS NULL
		THEN ''
	ELSE exclusions
	END AS exclusions,
	CASE 
		WHEN extras ='null' OR extras IS NULL
		THEN ''
		ELSE extras
		END AS extras,
order_time
FROM customer_orders;

DROP TABLE IF EXISTS runner_orders_temp;
CREATE TABLE runner_orders_temp
SELECT order_id ,runner_id,
	CASE 
		WHEN pickup_time = 'null' THEN NULL
		ELSE pickup_time END AS pickup_time,
	CASE 
		WHEN distance ='null' THEN NULL 
		WHEN distance LIKE '%km' THEN TRIM('km' FROM distance)
		ELSE distance END AS distance,
	CASE
		WHEN duration = 'null' THEN NULL
		WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
		WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
		WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
		ELSE duration END AS duration,
	CASE
		WHEN cancellation ='null' OR cancellation IS NULL THEN ''
		ELSE cancellation END AS cancellation
FROM runner_orders;

-- CHANGE DATATYPE
ALTER TABLE runner_orders_temp
MODIFY pickup_time TIMESTAMP;
ALTER TABLE runner_orders_temp
MODIFY duration INT;
ALTER TABLE runner_orders_temp
MODIFY distance NUMERIC;


--				A. Pizza Metrics
-- Q1 How many pizzas were ordered?

SELECT 
COUNT(pizza_id) AS no_of_orders
FROM customer_orders;

-- Q2 How many unique customer orders were made?

SELECT 
COUNT(DISTINCT(order_id)) AS unique_orders
FROM customer_orders;

-- Q3 How many successful orders were delivered by each runner?

SELECT runner_id,
COUNT(order_id) AS orders_delivered
FROM runner_orders
WHERE runner_orders.pickup_time <> 'null'
GROUP BY runner_id;

-- Q4 How many of each type of pizza was delivered?

WITH CTE AS(
SELECT runner_id ,co.pizza_id,pizza_name-- ,COUNT(pizza_id) 
FROM runner_orders ro
INNER JOIN customer_orders co
ON ro.order_id = co.order_id
INNER JOIN pizza_names pn
ON pn.pizza_id = co.pizza_id
WHERE ro.pickup_time <> 'null'
)
SELECT pizza_name,-- to select a column name from cte it should be present in the subquery
COUNT(pizza_name) AS pizza_count
FROM CTE
GROUP BY pizza_name;

-- for all the orders(delivered or not)

SELECT pizza_id,COUNT(pizza_id)
FROM customer_orders
GROUP BY pizza_id;

-- Q5 How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_id,pizza_name,COUNT(pizza_name)
FROM customer_orders co
INNER JOIN pizza_names pn
ON pn.pizza_id = co.pizza_id
GROUP BY customer_id, pizza_name;

-- Q6 What was the maximum number of pizzas delivered in a single order?

WITH CTE AS (
SELECT order_id,COUNT(pizza_id) AS pizza_delivered
FROM customer_orders co
GROUP BY order_id
)
SELECT MAX(pizza_delivered) AS max_no_of_pizza_delivered
FROM CTE;

-- ALTERNATIVELY

SELECT co.order_id,COUNT(pizza_id) AS pizza_delivered
FROM customer_orders co
INNER JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE pickup_time <> 'null'
GROUP BY co.order_id 
ORDER BY COUNT(pizza_id) DESC
LIMIT 1;

-- Q7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT customer_id,exclusions,extras,
	COUNT(CASE 
		WHEN exclusions = '' AND extras = '' THEN 1
		END) AS not_changed ,
	COUNT(CASE 
		WHEN exclusions <> '' OR extras <> '' THEN 1
		END) AS changed 
FROM customer_orders_temp
INNER JOIN runner_orders_temp 
ON runner_orders_temp.order_id = customer_orders_temp.order_id
WHERE pickup_time IS NOT NULL
GROUP by customer_id;

-- ALTERNATIVELY

-- CREATE A VIEW FOR ALL THE ORDERS DELIVERED 

CREATE VIEW delivered_orders AS
SELECT cot.order_id ,customer_id ,pizza_id ,exclusions ,extras,order_time,
runner_id ,pickup_time ,distance ,duration ,cancellation
FROM customer_orders_temp cot
INNER JOIN runner_orders_temp rot 
ON cot.order_id = rot.order_id
WHERE rot.pickup_time IS NOT NULL;

SELECT customer_id,exclusions,extras,
	COUNT(CASE 
		WHEN exclusions = '' AND extras = '' THEN 1
		END) AS not_changed ,
	COUNT(CASE 
		WHEN exclusions <> '' OR extras <> '' THEN 1
		END) AS changed 
FROM delivered_orders
GROUP BY customer_id;

-- Q8 How many pizzas were delivered that had both exclusions and extras?

SELECT customer_id ,COUNT(*) AS pizza_having_exclusions_n_extras
FROM delivered_orders
WHERE exclusions <> ''
AND extras <> '';

-- Q9 What was the total volume of pizzas ordered for each hour of the day?

SELECT EXTRACT(hour FROM order_time) AS hrs,
COUNT(pizza_id) AS pizzas_ordered
FROM customer_orders_temp
GROUP BY hrs 
ORDER BY hrs;

-- 10 What was the volume of orders for each day of the week?

SELECT DAYOFWEEK(order_time) AS day_of_week,
DAYNAME(order_time) AS name,
COUNT(pizza_id) AS pizzas_ordered
FROM customer_orders_temp
GROUP BY day_of_week
ORDER BY day_of_week;

--				B. Runner and Customer Experience
-- Q1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT 
EXTRACT(week FROM registration_date+2) AS week_of_year,
COUNT(runner_id) AS number_of_runners
FROM runners
GROUP BY week_of_year ;

-- Q2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

SELECT runner_id,
AVG(TIMESTAMPDIFF(MINUTE, order_time, pickup_time) )AS time_difference_minutes
FROM delivered_orders
GROUP BY runner_id;

-- Q3 Is there any relationship between the number of pizzas and how long the order takes to prepare?

WITH CTE AS (
SELECT order_id,COUNT(pizza_id) as number_of_pizza,
TIMESTAMPDIFF(MINUTE, order_time, pickup_time) AS time_difference_minutes
FROM delivered_orders
GROUP BY order_id
)
	SELECT number_of_pizza,
	AVG(time_difference_minutes) AS avg_time
	FROM CTE
	GROUP BY number_of_pizza;

-- Q4 What was the average distance travelled for each customer?

SELECT customer_id , AVG(distance)
FROM runner_orders_temp rot
INNER JOIN customer_orders_temp cot
ON rot.order_id = cot.order_id
WHERE pickup_time IS NOT NULL
GROUP BY customer_id;

-- Q5 What was the difference between the longest and shortest delivery times for all orders?

SELECT
	MAX(duration) - MIN(duration) AS time_diff
FROM  runner_orders_temp rot
WHERE duration IS NOT NULL;

-- Q6 What was the average speed for each runner for each delivery and do you notice any trend for these values?

SELECT 
runner_id , order_id,
ROUND(AVG(distance/(duration/60)),4) AS speed
	FROM runner_orders_temp
	WHERE distance IS NOT NULL
	GROUP BY runner_id,order_id 
	ORDER BY runner_id , speed;
    
-- Q7 What is the successful delivery percentage for each runner?

SELECT runner_id, 
ROUND(count(distance)/count(runner_id)*100) AS success_rate
	FROM runner_orders_temp
	GROUP BY runner_id;

-- END OF DANNY MA'S PIZZA RUNNER CHALLENGE PART A.
