# Lab | SQL Rolling Calculations
# In this lab, you will be using the Sakila database of movie rentals.
use sakila;
set sql_safe_updates=0;
SET sql_mode=(SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''));

### Instructions
	-- 1. Get number of monthly active customers.
select * from sakila.payment;
select * from sakila.rental;
select * from sakila.customer;

# Getting date, month and year for each rental. I am using RENTAL_DATE as a measure of activity.
create or replace view client_activity as
select customer_id, convert(rental_date, date) as Activity_date,
date_format(convert(rental_date,date), '%m') as Activity_Month,
date_format(convert(rental_date,date), '%Y') as Activity_year
from sakila.rental;

select * from sakila.client_activity;

# Get the amount of distinct customers who are renting by month.
create or replace view Monthly_active_clients as
select count(distinct customer_id) as Amount_active_clients, Activity_year, Activity_Month
from sakila.client_activity
group by Activity_year, Activity_Month
order by Activity_year, Activity_Month;

select * from sakila.Monthly_active_clients;


-- ---------------------------------------------------------------------------------
	-- 2. Active users in the previous month.
# Get a new column which shows the amount of “Active customers” the previous month.
with cte_activity as (
  select Amount_active_clients, lag(Amount_active_clients,1) over (partition by Activity_year) as Amount_active_clients_previous_month, Activity_year, Activity_month
  from Monthly_active_clients
)
select * from cte_activity
where Amount_active_clients_previous_month is not null;


-- ---------------------------------------------------------------------------------
	-- 3. Percentage change in the number of active customers.
# Make the calculation for % change in regards to previous month, in the second select to be able to reference the LAG alias.
with cte_activity as (
	select Amount_active_clients, lag(Amount_active_clients,1) over (partition by Activity_year) as Amount_active_clients_previous_month, Activity_year, Activity_month
	from Monthly_active_clients
)
select *, (((Amount_active_clients-Amount_active_clients_previous_month)*100)/Amount_active_clients_previous_month) as '% client difference compared with previous month' from cte_activity
where Amount_active_clients_previous_month is not null;


-- ---------------------------------------------------------------------------------
	-- 4. Retained customers every month.
# Name the first subquery, count distinct customer_id and self join (with a 1 month gap). We can then compare same clients from one month to another.
with distinct_clients as (
  select distinct customer_id , Activity_Month, Activity_year
  from client_activity
)
select d1.Activity_year, d1.Activity_Month, count(distinct d1.customer_id) as Retained_customers
from distinct_clients d1
join distinct_clients d2
on d1.customer_id = d2.customer_id and d1.activity_Month = d2.activity_Month + 1
group by d1.Activity_Month, d1.Activity_year
order by d1.Activity_year, d1.Activity_Month;
