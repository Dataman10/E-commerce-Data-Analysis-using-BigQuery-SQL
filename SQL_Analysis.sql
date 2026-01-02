#Q1. Import the dataset and do usual exploratory analysis steps like checking the 
#structure & characteristics of the dataset: 

#1. Data type of all columns in the "customers" table. 
SELECT *FROM `TARGET_SQL.customers`;

#1.2. Get the time range between which the orders were placed. 
SELECT
 MIN(order_purchase_timestamp) AS start_time,
 MAX(order_purchase_timestamp) AS end_time
 FROM `TARGET_SQL.orders`;


#1.3. Count the Cities & States of customers who ordered during the given period.
   SELECT
   COUNT(c.customer_city) AS city_count,COUNT(c.customer_state) AS state_count
   FROM `TARGET_SQL.orders` AS o
   JOIN `TARGET_SQL.customers` AS c 
   ON c.customer_id = o.customer_id
   WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) = 2018 AND 
         EXTRACT(MONTH FROM o.order_purchase_timestamp) BETWEEN 1 AND 3;


# 2. In-depth Exploration: 

# 2.1. Is there a growing trend in the no. of orders placed over the past years?.
SELECT COUNT(*) AS order_count , EXTRACT(YEAR FROM order_purchase_timestamp) AS YEAR FROM `TARGET_SQL.orders`
GROUP BY EXTRACT(YEAR FROM order_purchase_timestamp)
ORDER BY YEAR;

# 2.2 Can we see some kind of monthly seasonality in terms of the no. of orders being placed? 
SELECT COUNT(*) AS order_count , EXTRACT(MONTH FROM order_purchase_timestamp) AS month FROM `TARGET_SQL.orders`
GROUP BY EXTRACT(MONTH FROM order_purchase_timestamp)
ORDER BY month;

/* 2.3. During what time of the day, do the Brazilian customers mostly place 
their orders? (Dawn, Morning, Afternoon or Night) 
■ 0-6 hrs : Dawn 
■ 7-12 hrs : Mornings 
■ 13-18 hrs : Afternoon 
■ 19-23 hrs : Night */

SELECT 
CASE
 WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 0 AND 6 THEN 'Dawn'
 WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 7 AND 12 THEN 'Mornings'
 WHEN EXTRACT(HOUR FROM order_purchase_timestamp) BETWEEN 13 AND 18 THEN 'Afternoon'
 ELSE 'Night'
END AS TIME_PERIOD,
COUNT(*) AS total_count
 FROM `TARGET_SQL.orders`
 GROUP BY TIME_PERIOD
 ORDER BY total_count DESC;


# 3. Evolution of E-commerce orders in the Brazil region: 

# 3.1. Get the month on month no. of orders placed in each state. 
SELECT COUNT(o.order_id) AS total_orders , EXTRACT(MONTH FROM o.order_purchase_timestamp) AS month ,
       EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
       c.customer_state
       FROM `TARGET_SQL.orders` AS o 
       JOIN `TARGET_SQL.customers` AS c 
       ON o.customer_id = c.customer_id
       GROUP BY c.customer_state , month , year
       ORDER BY c.customer_state , month , year;
# 3.2. How are the customers distributed across all the states? 
SELECT customer_state,
COUNT(DISTINCT customer_id) AS customer_count
FROM `TARGET_SQL.customers`
GROUP BY customer_state
ORDER BY customer_count DESC;

#4. Impact on Economy: Analyze the money movement by e-commerce by looking 
#   at order prices, freight and others.

/* 4.1. Get the % increase in the cost of orders from year 2017 to 2018 
(include months between Jan to Aug only). 
You can use the "payment_value" column in the payments table to get 
the cost of orders. */
WITH yearly_totals AS (
SELECT 
EXTRACT(YEAR FROM o.order_purchase_timestamp) AS year,
SUM(p.payment_value) AS total_payment
FROM `TARGET_SQL.payments` AS p
JOIN `TARGET_SQL.orders` AS o 
ON o.order_id = p.order_id
WHERE EXTRACT(YEAR FROM o.order_purchase_timestamp) IN (2017 , 2018)
AND EXTRACT(MONTH FROM order_purchase_timestamp) BETWEEN 1 AND 8  
GROUP BY EXTRACT(YEAR FROM o.order_purchase_timestamp)
),yearly_comparisons AS(
  SELECT
  year,total_payment,
  LEAD(total_payment) OVER(ORDER BY year DESC) AS prev_year_payment
  FROM yearly_totals
)
SELECT ROUND(((total_payment - prev_year_payment)/prev_year_payment)*100,2)
FROM yearly_comparisons

# 2. Calculate the Total & Average value of order price , Total & Average value of order freight for each state. 

SELECT 
c.customer_state,
ROUND(AVG(price),2) AS avg_price,
ROUND(SUM(price),2) AS total_price,
ROUND(AVG(freight_value),2) AS avg_freight,
ROUND(SUM(freight_value),2) AS sum_freight
FROM `TARGET_SQL.orders` AS o
JOIN  `TARGET_SQL.order_items` AS oi 
ON o.order_id = oi.order_id
JOIN `TARGET_SQL.customers` AS c 
ON o.customer_id = c.customer_id
GROUP BY c.customer_state;
 

/* 5. Analysis based on sales, freight and delivery time. 

5.1. Find the no. of days taken to deliver each order from the order’s 
purchase date as delivery time. 
Also, calculate the difference (in days) between the estimated & actual 
delivery date of an order. 
Do this in a single query. 
You can calculate the delivery time and the difference between the 
estimated & actual delivery date using the given formula: 
■ time_to_deliver = order_delivered_customer_date - 
order_purchase_timestamp 
■ diff_estimated_delivery = order_delivered_customer_date - 
order_estimated_delivery_date .*/
        
SELECT order_id,
DATE_DIFF(DATE(order_delivered_customer_date) ,DATE(order_purchase_timestamp) , DAY) AS days_to_delivery,
DATE_DIFF(DATE(order_delivered_customer_date) ,DATE(order_estimated_delivery_date),DAY) AS diff_estimated_delivery,
FROM `TARGET_SQL.orders`;

# 5.2. Find out the top 5 states with the highest & lowest average freight value. 
SELECT 
c.customer_state,
AVG(oi.freight_value) AS avg_freight_val
FROM `TARGET_SQL.orders` AS o   
JOIN `TARGET_SQL.order_items` AS oi  
ON o.order_id = oi.order_id 
JOIN `TARGET_SQL.customers` AS c   
ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_freight_val DESC
LIMIT 5;


# 5.3. Find out the top 5 states with the highest & lowest average delivery time. 
SELECT 
c.customer_state,
AVG(EXTRACT(DATE FROM o.order_delivered_customer_date) - EXTRACT(DATE FROM o.order_purchase_timestamp)) AS avg_time_to_delivery
FROM `TARGET_SQL.orders` AS o   
JOIN `TARGET_SQL.order_items` AS oi  
ON o.order_id = oi.order_id 
JOIN `TARGET_SQL.customers` AS c   
ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY avg_time_to_delivery DESC
LIMIT 5;

/* 5.4. Find out the top 5 states where the order delivery is really fast as 
compared to the estimated date of delivery. 
You can use the difference between the averages of actual & estimated 
delivery date to figure out how fast the delivery was for each state. */

SELECT
    c.customer_state,
    AVG(
        DATE_DIFF(
            o.order_estimated_delivery_date,
            o.order_delivered_customer_date,
            DAY
        )
    ) AS avg_days_early
FROM `TARGET_SQL.orders` o
JOIN `TARGET_SQL.customers` c
    ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_days_early DESC
LIMIT 5;

# 6. Analysis based on the payments: 

/*1. Find the month on month no. of orders placed using different payment 
types.*/
SELECT
payment_type,
EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
COUNT(DISTINCT o.order_id) AS order_count
FROM `TARGET_SQL.orders` AS o 
JOIN `TARGET_SQL.payments` AS p    
ON o.order_id = p.order_id 
GROUP BY payment_type , year , month
ORDER BY payment_type , year , month;

/* 2. Find the no. of orders placed on the basis of the payment installments 
that have been paid.*/
SELECT payment_installments,
COUNT(DISTINCT order_id)AS num_orders
FROM `TARGET_SQL.payments`
GROUP BY payment_installments;

