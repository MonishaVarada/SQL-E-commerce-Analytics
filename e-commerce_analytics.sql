CREATE DATABASE ecommerce_analytics;

CREATE TABLE Products (
    product_id SERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    category VARCHAR(50),
    price DECIMAL(10,2) CHECK (price > 0),
    stock INT CHECK (stock >= 0)
);
CREATE TABLE Customers (
    customer_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    first_purchase_date DATE
);
CREATE TABLE Sales (
    sale_id SERIAL PRIMARY KEY,
    customer_id INT REFERENCES Customers(customer_id),
    product_id INT REFERENCES Products(product_id),
    quantity INT CHECK (quantity > 0),
    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO Products (name, category, price, stock)
VALUES
    ('Wireless Headphones', 'Electronics', 149.99, 50),
    ('Running Shoes', 'Apparel', 89.99, 100),
    ('Coffee Maker', 'Home Appliances', 59.99, 30);
INSERT INTO Customers (name, email, first_purchase_date)
VALUES
    ('Alice Brown', 'alice@example.com', '2023-01-15'),
    ('Bob Wilson', 'bob@example.com', '2023-02-20'),
    ('Charlie Green', 'charlie@example.com', '2023-03-10');
INSERT INTO Sales (customer_id, product_id, quantity, sale_date)
VALUES
    (1, 1, 2, '2023-10-01 09:00:00'),
    (1, 2, 1, '2023-10-05 14:30:00'),
    (2, 3, 1, '2023-10-10 11:15:00'),
    (3, 1, 3, '2023-10-15 16:45:00');
    
-- Identify new customers (first purchase within 30 days) vs. returning customers:

WITH CustomerPurchaseStats AS (
    SELECT
        c.customer_id,
        COUNT(s.sale_id) AS total_orders,
        MIN(s.sale_date) AS first_order_date,
        MAX(s.sale_date) AS last_order_date
    FROM Customers c
    LEFT JOIN Sales s ON c.customer_id = s.customer_id
    GROUP BY c.customer_id
)
SELECT
    CASE
        WHEN total_orders = 1 THEN 'New Customer'
        ELSE 'Returning Customer'
    END AS customer_type,
    COUNT(customer_id) AS count
FROM CustomerPurchaseStats
GROUP BY customer_type;


-- Aggregate revenue by category and month:
SELECT
    EXTRACT(YEAR FROM sale_date) AS year,
    EXTRACT(MONTH FROM sale_date) AS month,
    p.category,
    SUM(s.quantity * p.price) AS revenue
FROM Sales s
JOIN Products p ON s.product_id = p.product_id
GROUP BY year, month, p.category WITH ROLLUP
ORDER BY year, month, category;

-- Track monthly revenue growth:
WITH MonthlyRevenue AS (
    SELECT
        EXTRACT(YEAR FROM sale_date) AS year,
        EXTRACT(MONTH FROM sale_date) AS month,
        SUM(quantity * price) AS revenue
    FROM Sales s
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY year, month
)
SELECT
    year,
    month,
    revenue,
    LAG(revenue) OVER (ORDER BY year, month) AS prev_month_revenue,
    (revenue - LAG(revenue) OVER (ORDER BY year, month)) / LAG(revenue) OVER (ORDER BY year, month) * 100 AS growth_percent
FROM MonthlyRevenue;
-- Identify customers in the top 10% by spending:

WITH CustomerSpend AS (
    SELECT
        customer_id,
        SUM(quantity * price) AS total_spend
    FROM Sales s
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY customer_id
),
RankedCustomers AS (
    SELECT
        customer_id,
        total_spend,
        PERCENT_RANK() OVER (ORDER BY total_spend DESC) AS percentile_rank
    FROM CustomerSpend
)
SELECT
    customer_id,
    total_spend,
    percentile_rank
FROM RankedCustomers
WHERE percentile_rank <= 0.1;

-- Create a view to flag low-stock products:

CREATE VIEW LowStockAlert AS
SELECT
    product_id,
    name,
    stock
FROM Products
WHERE stock < 20;

SELECT * FROM LowStockAlert;



