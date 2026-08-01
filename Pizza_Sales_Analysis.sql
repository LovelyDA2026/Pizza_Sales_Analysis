-- PIZZA SALES ANALYSIS PROJECT

-- STEP 1: CREATE DATABASE
CREATE DATABASE pizza_sales_db;

USE pizza_sales_db;


-- STEP 2: CREATE TABLES

CREATE TABLE orders(
order_id INT PRIMARY KEY,
order_date DATE NOT NULL,
order_time TIME NOT NULL
);

SELECT * FROM orders 
LIMIT 10;

CREATE TABLE pizza_types(
pizza_type_id VARCHAR(50) PRIMARY KEY,
name VARCHAR(100) NOT NULL,
category VARCHAR(50) NOT NULL,
ingredients TEXT NOT NULL
);

SELECT * FROM pizza_types
LIMIT 10;

CREATE TABLE pizzas (
pizza_id VARCHAR(50) PRIMARY KEY,
pizza_type_id VARCHAR(50) NOT NULL,
size VARCHAR(5) NOT NULL,
price DECIMAL(5,2) NOT NULL,
FOREIGN KEY (pizza_type_id)
REFERENCES pizza_types(pizza_type_id)
);

SELECT * FROM pizzas
LIMIT 10;

CREATE TABLE order_details (
order_details_id INT PRIMARY KEY,
order_id INT NOT NULL,
pizza_id VARCHAR(50) NOT NULL,
quantity INT NOT NULL,
FOREIGN KEY (order_id)
REFERENCES orders (order_id),
FOREIGN KEY (pizza_id)
REFERENCES pizzas(pizza_id)
);

SELECT * FROM order_details
LIMIT 10;


-- STEP 3: DATA VALIDATION

-- TOTAL ROWS 
SELECT COUNT(*) AS total_orders
FROM orders;

SELECT COUNT(*) AS total_order_details
FROM order_details;

SELECT COUNT(*) AS total_pizzas
FROM pizzas;

SELECT COUNT(*) AS total_pizza_type
FROM pizza_types;


-- CHECK DUPLICATE PRIMARY KEY
SELECT order_id, COUNT(*)
FROM orders
GROUP BY order_id
HAVING COUNT(*)>1;

SELECT order_details_id, COUNT(*)
FROM order_details
GROUP BY order_details_id
HAVING COUNT(*)>1;

SELECT pizza_id, COUNT(*)
FROM pizzas
GROUP BY pizza_id
HAVING COUNT(*)>1;

SELECT pizza_type_id, COUNT(*)
FROM pizza_types
GROUP BY pizza_type_id
HAVING COUNT(*)>1;


-- CHECK NULL VALUES
SELECT *
FROM orders
WHERE order_date IS NULL
OR order_time IS NULL;
 
SELECT *
FROM order_details
WHERE order_details_id IS NULL
OR order_id IS NULL
OR pizza_id IS NULL
OR quantity IS NULL;

SELECT *
FROM pizzas
WHERE pizza_type_id IS NULL
OR size IS NULL
OR price IS NULL;

SELECT *
FROM pizza_types
WHERE name IS NULL
OR category IS NULL
OR ingredients IS NULL;


-- CHECK RANGE
SELECT MIN(order_date) AS first_date,
MAX(order_date) AS last_date 
FROM orders;

SELECT MIN(quantity) AS min_qty,
MAX(quantity) AS max_qty
FROM order_details;

SELECT MIN(price) AS min_price,
MAX(price) AS max_price
FROM pizzas;


-- STEP 4: BUSINESS ANALYSIS
-- LEVEL 1- BASICS

-- Q1. Total numbers of orders
SELECT COUNT(*) AS total_orders
FROM orders;

-- Q2. Total pizzas sold
SELECT SUM(quantity) AS total_pizzas_sold
FROM order_details;

-- Q3. Total unique pizza types
SELECT COUNT(DISTINCT pizza_type_id) 
AS unique_pizza_types
FROM pizza_types;

-- Q4. Most expensive pizza
SELECT pizza_id, price
FROM pizzas
ORDER BY price DESC
LIMIT 1;

-- Q5. Cheapest pizza
SELECT pizza_id, price
FROM pizzas
ORDER BY price ASC
LIMIT 1;

-- Q6. Highest quantity ordered in a single order line
SELECT MAX(quantity) AS highest_quantity
FROM order_details;

-- Q7. Number of pizza sizes available
SELECT COUNT(DISTINCT size) AS total_sizes
FROM pizzas;

-- Q8. Number of pizza categories
SELECT COUNT(DISTINCT category) AS total_categories
FROM pizza_types;


-- LEVEL 2- INTERMEDIATE

-- Q9. Number of orders placed each day
SELECT order_date, 
COUNT(*) AS total_orders
FROM orders
GROUP BY order_date
ORDER BY order_date ASC;

-- Q10. Number of orders placed each hour
SELECT HOUR(order_time) AS order_hours,
COUNT(*) AS total_orders
FROM orders
GROUP BY order_hours
ORDER BY order_hours ASC;

-- Q11. Total revenue generated from pizza sales
SELECT ROUND(SUM(od.quantity*p.price),2) AS total_revenue
FROM order_details od
JOIN pizzas p
ON od.pizza_id=p.pizza_id;

-- Q12. What is the average order value?
SELECT ROUND(SUM(od.quantity*p.price)
/COUNT(DISTINCT od.order_id),2) AS avg_order_value
FROM order_details od
JOIN pizzas p
ON od.pizza_id=p.pizza_id;

-- Q13. Top 10 Best-Selling Pizzas (by Quantity)
SELECT pt.name,
       SUM(od.quantity) AS total_quantity
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY total_quantity DESC
LIMIT 10;

-- Q14. Top 5 Highest Revenue-Generating Pizzas
SELECT pt.name,
       ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.name
ORDER BY revenue DESC
LIMIT 5;

-- Q15. Revenue by Pizza Category
SELECT pt.category,
       ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
ON p.pizza_type_id = pt.pizza_type_id
GROUP BY pt.category
ORDER BY revenue DESC;

-- Q16. Revenue by Pizza Size
SELECT p.size,
       ROUND(SUM(od.quantity * p.price), 2) AS revenue
FROM order_details od
JOIN pizzas p
ON od.pizza_id = p.pizza_id
GROUP BY p.size
ORDER BY revenue DESC;


-- LEVEL 3- ADVANCED

-- Q17. Find pizzas priced above the average pizza price
SELECT pizza_id,
       price
FROM pizzas
WHERE price >
(
    SELECT AVG(price)
    FROM pizzas
)
ORDER BY price DESC;

-- Q18. Find the top-selling pizza in each category 
WITH pizza_sales AS
(
    SELECT
        pt.category,
        pt.name,
        SUM(od.quantity) AS total_quantity,
        ROW_NUMBER() OVER
        (
            PARTITION BY pt.category
            ORDER BY SUM(od.quantity) DESC
        ) AS rn
    FROM order_details od
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    JOIN pizza_types pt
        ON p.pizza_type_id = pt.pizza_type_id
    GROUP BY pt.category, pt.name
)

SELECT category,
       name,
       total_quantity
FROM pizza_sales
WHERE rn = 1;

-- Q19. Compare each day's revenue with the previous day's revenue 
WITH daily_revenue AS
(
    SELECT
        o.order_date,
        ROUND(SUM(od.quantity * p.price),2) AS revenue
    FROM orders o
    JOIN order_details od
        ON o.order_id = od.order_id
    JOIN pizzas p
        ON od.pizza_id = p.pizza_id
    GROUP BY o.order_date
)

SELECT
    order_date,
    revenue,
    LAG(revenue) OVER(ORDER BY order_date) AS previous_day_revenue
FROM daily_revenue;

-- Q20. Create a Sales Analysis View
CREATE VIEW vw_pizza_sales AS
SELECT
    o.order_date,
    o.order_time,
    pt.name AS pizza_name,
    pt.category,
    p.size,
    od.quantity,
    p.price,
    (od.quantity * p.price) AS revenue
FROM orders o
JOIN order_details od
    ON o.order_id = od.order_id
JOIN pizzas p
    ON od.pizza_id = p.pizza_id
JOIN pizza_types pt
    ON p.pizza_type_id = pt.pizza_type_id;


