-- Monday Coffee: SQL case study (MySQL)
-- Goal: recommend the top 3 Indian cities for new coffee shops from online sales since Jan 2023.
-- Tables: city, customers, products, sales (imported with the Table Data Import Wizard).

create schema if not exists mydatabase;
use mydatabase;

-- ===== 1. Data loading: inspect the tables =====
select * from city;
select * from customers;
select * from products;
select * from sales;

-- ===== 2. Cleaning =====
-- NULL checks
select * from city where city_id is null or city_name is null or population is null or estimated_rent is null or city_rank is null;
select * from customers where customer_id is null or customer_name is null or city_id is null;
select * from products where product_id is null or product_name is null or price is null;
select * from sales where sale_id is null or sale_date is null or quantity is null or product_id is null
   or customer_id is null or total_amount is null or rating is null;

-- Duplicate checks
select city_name, count(*) from city group by city_name having count(*) > 1;
select customer_id, count(*) from customers group by customer_id having count(*) > 1;
select product_id, count(*) from products group by product_id having count(*) > 1;
select sale_id, count(*) from sales group by sale_id having count(*) > 1;

-- total_amount should equal price * quantity: find mismatches, then correct them
select sales.sale_id
from sales join products on products.product_id = sales.product_id
where sales.total_amount != products.price * sales.quantity;

update sales
join products on products.product_id = sales.product_id
set sales.total_amount = products.price * sales.quantity
where sales.total_amount != products.price * sales.quantity;

-- ===== 3. Transformation and integration: sales report with customer and product details =====
select customers.customer_id, products.product_name, sales.sale_id, sales.total_amount, sales.sale_date
from sales
join customers on customers.customer_id = sales.customer_id
join products on products.product_id = sales.product_id
where customers.city_id = 1
order by sales.sale_date;

-- ===== 4. Analysis and aggregation =====
-- Total sales per city
select city.city_id, city.city_name, sum(sales.total_amount) as total_sales
from sales
join customers on sales.customer_id = customers.customer_id
join city on customers.city_id = city.city_id
group by city.city_id, city.city_name;

-- Transactions per city
select city.city_id, city.city_name, count(sales.sale_id) as no_of_transactions
from sales
join customers on customers.customer_id = sales.customer_id
join city on customers.city_id = city.city_id
group by city.city_id, city.city_name;

-- Unique customers per city (fixed: DISTINCT; the original counted orders, not customers)
select city.city_id, city.city_name, count(distinct sales.customer_id) as no_of_customers
from sales
join customers on customers.customer_id = sales.customer_id
join city on customers.city_id = city.city_id
group by city.city_id, city.city_name;

-- Average order value per city
select city.city_id, city.city_name, avg(sales.total_amount) as avg_order_value
from sales
join customers on customers.customer_id = sales.customer_id
join city on city.city_id = customers.city_id
group by city.city_id, city.city_name;

-- Product demand per city, bucketed
select city.city_id, city.city_name, count(sales.product_id) as product_total,
       case when count(sales.product_id) > 1500 then 'high'
            when count(sales.product_id) > 500 then 'normal'
            else 'low' end as demand_category
from sales
join customers on customers.customer_id = sales.customer_id
join city on city.city_id = customers.city_id
group by city.city_id, city.city_name
order by product_total desc;

-- Monthly sales trend with month-over-month change
with monthly_sales as (
  select date_format(str_to_date(sale_date, '%m/%d/%Y'), '%Y-%m') as sale_month,
         sum(total_amount) as total_sales
  from sales
  group by sale_month
)
select sale_month, total_sales,
       lag(total_sales) over (order by sale_month) as prev_month_sales,
       total_sales - lag(total_sales) over (order by sale_month) as change_in_sales,
       case when total_sales > lag(total_sales) over (order by sale_month) then 'Increase'
            when total_sales < lag(total_sales) over (order by sale_month) then 'Decrease'
            else 'No Change' end as trend
from monthly_sales
order by sale_month;

-- Average rating per city
select city.city_id, city.city_name, avg(sales.rating) as avg_rating
from sales
join customers on customers.customer_id = sales.customer_id
join city on city.city_id = customers.city_id
group by city.city_id, city.city_name;

-- ===== 5. Decision: top cities by sales, unique customers and order count =====
select city.city_name, sum(sales.total_amount) as total_sales,
       count(distinct sales.customer_id) as unique_customers, count(sales.sale_id) as order_count
from sales
join customers on customers.customer_id = sales.customer_id
join city on city.city_id = customers.city_id
group by city.city_id, city.city_name
order by total_sales desc
limit 3;

-- Combined ranking across all three measures
select *
from (
  select city_name, total_sales, unique_customers, order_count,
         rank() over (order by total_sales desc) as sales_rank,
         rank() over (order by unique_customers desc) as customer_rank,
         rank() over (order by order_count desc) as order_rank
  from (
    select city.city_name, sum(sales.total_amount) as total_sales,
           count(distinct sales.customer_id) as unique_customers, count(sales.sale_id) as order_count
    from sales
    join customers on customers.customer_id = sales.customer_id
    join city on city.city_id = customers.city_id
    group by city.city_id, city.city_name
  ) as city_stats
) as ranked_cities
where sales_rank <= 3 or customer_rank <= 3 or order_rank <= 3
order by city_name;
