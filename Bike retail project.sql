-- Q1) List all products with their brand and category 
select products.product_name, brands.brand_name, categories.category_name from products
join brands on brands.brand_id = products.brand_id
join categories on   categories.category_id = products.category_id;


-- Q2) Count total orders in the system
select count(orders.order_id) as total_orders from orders;


-- Q3) Find customers in California (state = 'CA') 
select first_name, last_name, city from customers
where state = "CA";


-- Q4) Show orders along with order status and order dates, ordered by most recent
select order_id, order_status, order_date, shipped_date from orders
order by order_date desc;


-- Q5) Total quantity of products stocked per store
select stores.store_id, stores.store_name, sum(stocks.quantity) as total_stock from stocks
join stores on stores.store_id = stocks.store_id
group by stores.store_id, stores.store_name;


-- Q6) Total revenue per order (assuming revenue = sum of quantity × list_price × (1 - discount))
select order_items.order_id,
round(sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)), 2) as total_revenue
from order_items
group by order_items.order_id;


-- Q7) List order revenues along with customer names
select orders.order_id, concat(customers.first_name, ' ', customers.last_name) as customer,
round(sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)), 2) as order_revenue
from orders
join customers on customers.customer_id = orders.customer_id
join order_items on order_items.order_id = orders.order_id
group by orders.order_id, customer;
 

-- Q8) Categorize orders as 'Low', 'Medium', 'High' value using CASE 
select orders.order_id,
round(sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)), 2) as revenue,
case
when round(sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)), 2) < 1000 then 'Low'
when round(sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)), 2) > 10000 then 'High'
else 'Medium'
end as revenue_category
from orders
join order_items on order_items.order_id = orders.order_id
group by orders.order_id order by revenue desc;


-- Q9) Stores with more than 200 orders (using HAVING)
select store_id, count(order_id) from orders
group by store_id having count(order_id) > 200; 


-- Q10) Products never sold
select products.product_name from products
left join order_items on products.product_id = order_items.product_id
where order_items.order_id is null;


-- Q11) CTE: Total spent per customer
with customer_spend as(
 select orders.customer_id, round(sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)), 2) as total_spent
 from orders
 join order_items on order_items.order_id = orders.order_id
 group by orders.customer_id
)
select concat(customers.first_name, ' ', customers.last_name) as customer_name, customer_spend.total_spent
from customer_spend
join customers on customers.customer_id = customer_spend.customer_id
order by total_spent desc;


-- Q12) Top 5 products by revenue using window function
select product_id, revenue
from (
  select order_items.product_id,
    round(sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)), 2) as revenue,
    row_number() over (order by sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)) desc) as rn
  from order_items
  group by order_items.product_id
) t
where rn <= 5;


-- Q13) Complex CASE: Product performance category
select products.product_name,
  round(sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)), 2) as revenue,
  case
    when sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)) < 1000 then 'Low Performer'
    when sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)) between 1000 and 5000 then 'Mid Performer'
    else 'Top Performer'
  end as performance_tier
from products
join order_items on products.product_id = order_items.product_id
group by products.product_name order by revenue desc;


-- Q14) Recursive CTE to count down staff hierarchy levels:  
with recursive staff_hierarchy as (
  select staff_id, first_name, last_name, manager_id, 1 as levels
  from staffs
  where manager_id is null
  union all
  select staffs.staff_id, staffs.first_name, staffs.last_name, staffs.manager_id, staff_hierarchy.levels + 1
  from staffs
  join staff_hierarchy on staffs.manager_id = staff_hierarchy.staff_id
)
select * from staff_hierarchy;
 
 
 -- Q15) WHILE loop in stored procedure: list first N customers by spend
 DELIMITER //
create procedure top_n_customers(in n int)
begin
  declare i int default 1;
  declare cust_id int;
  create temporary table temp_spend as
    select orders.customer_id,
      round(sum(order_items.quantity * order_items.list_price * (1 - order_items.discount)), 2) as total_spent
    from orders
    join order_items on orders.order_id = order_items.order_id
    group by orders.customer_id
    order by total_spent desc
    limit n;
  
  select customer_id, total_spent from temp_spend;
  
  drop table temp_spend;
end //
DELIMITER ;

call top_n_customers(5);

