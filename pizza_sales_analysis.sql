-- To create a Database --
CREATE database pizzahut;

-- To create new table Orders --
USE pizzahut;
CREATE TABLE orders (
order_id int NOT NULL,
order_date date NOT NULL,
order_time time NOT NULL,
primary key (order_id) );

-- To create new table order_details --
CREATE TABLE order_details (
order_details_id int NOT NULL,
order_id int NOT NULL,
pizza_id  text NOT NULL,
quantity int NOT NULL,
primary key (order_details_id) );

-- To retrieve entire pizzas table --
SELECT * FROM pizzahut.pizzas;

-- To retrieve entire pizza_types table --
SELECT * FROM pizzahut.pizza_types;

-- To retrieve entire orders table --
SELECT * FROM pizzahut.orders;

-- To retrieve entire order_details table --
SELECT * FROM pizzahut.order_details;

-- Retrieve the total number of orders placed  --
SELECT COUNT(order_id) AS total_orders FROM orders;

-- Calculate the total revenue generated from pizza sales --
SELECT 
    ROUND(SUM(order_details.quantity * pizzas.price),2) AS total_revenue
FROM
    order_details
        JOIN
    pizzas ON pizzas.pizza_id = order_details.pizza_id;
    
-- Identify the highest-priced pizza --
SELECT 
    pizza_types.name, pizzas.price
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
ORDER BY pizzas.price DESC
LIMIT 1;

-- Identify the most common pizza size ordered --
SELECT 
    pizzas.size, SUM(order_details.quantity) AS total_orders
FROM
    order_details
        JOIN
    pizzas ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizzas.size
ORDER BY total_orders DESC
LIMIT 1;

-- List the top 5 most ordered pizza types along with their quantities --
SELECT 
    pizza_types.name,
    SUM(order_details.quantity) AS total_quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY total_quantity DESC
LIMIT 5;

-- Join the necessary tables to find the total quantity of each pizza category ordered --
SELECT 
    pizza_types.category,
    SUM(order_details.quantity) AS total_quantity
FROM
    pizza_types
        JOIN
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.category
ORDER BY total_quantity DESC;

-- Determine the distribution of orders by hour of the day --
SELECT 
    HOUR(order_time) AS hour, COUNT(order_id) AS total_orders
FROM
    orders
GROUP BY HOUR(order_time);

-- Join relevant tables to find the category-wise distribution of pizzas --
SELECT 
    category, COUNT(name) AS total_count
FROM
    pizza_types
GROUP BY category;

-- Group the orders by date and calculate the average number of pizzas ordered per day --
SELECT 
    ROUND(AVG(total_quantity), 0) AS Avg_pizzas_ordered_per_day
FROM
    (SELECT 
        orders.order_date,
            SUM(order_details.quantity) AS total_quantity
    FROM
        orders
    JOIN order_details ON orders.order_id = order_details.order_id
    GROUP BY orders.order_date) AS order_quantity;
    
-- Determine the top 3 most ordered pizza types based on revenue --
SELECT 
    pizza_types.name,
    SUM(order_details.quantity * pizzas.price) AS revenue
FROM
    pizza_types
        JOIN
    pizzas ON pizzas.pizza_type_id = pizza_types.pizza_type_id
        JOIN
    order_details ON order_details.pizza_id = pizzas.pizza_id
GROUP BY pizza_types.name
ORDER BY revenue DESC
LIMIT 3;

-- Calculate the percentage contribution of each pizza type to total revenue --
SELECT 
    pizza_types.category,
    CONCAT(ROUND((SUM(order_details.quantity * pizzas.price) / 
    (SELECT SUM(order_details.quantity * pizzas.price) 
     FROM order_details
     JOIN pizzas ON pizzas.pizza_id = order_details.pizza_id)) * 100, 2), '%') AS revenue_percentage
FROM 
    pizza_types
JOIN 
    pizzas ON pizza_types.pizza_type_id = pizzas.pizza_type_id
JOIN 
    order_details ON pizzas.pizza_id = order_details.pizza_id
GROUP BY 
    pizza_types.category
ORDER BY 
    revenue_percentage DESC;
    
-- Analyze the cumulative revenue generated over time --
SELECT 
    order_date,
    SUM(revenue) OVER (ORDER BY order_date) AS cumulative_revenue
FROM (
    SELECT 
        orders.order_date,
        SUM(order_details.quantity * pizzas.price) AS revenue
    FROM 
        order_details 
    JOIN 
        pizzas ON order_details.pizza_id = pizzas.pizza_id
    JOIN 
        orders ON orders.order_id = order_details.order_id
    GROUP BY 
        orders.order_date
) AS sales;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category --
USE pizzahut;

SELECT name, category, revenue
FROM (
    SELECT 
        category, 
        name, 
        revenue,
        RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS rn
    FROM (
        SELECT 
            pizza_types.category, 
            pizza_types.name, 
            SUM(order_details.quantity * pizzas.price) AS revenue
        FROM pizza_types
        JOIN pizzas
            ON pizza_types.pizza_type_id = pizzas.pizza_type_id
        JOIN order_details
            ON order_details.pizza_id = pizzas.pizza_id
        GROUP BY pizza_types.category, pizza_types.name
    ) AS a
) AS b
WHERE rn <= 3;
