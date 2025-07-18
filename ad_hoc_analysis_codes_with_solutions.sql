/*AdHoc SQL Challenge Requests:   */

/*1.  Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region.  */

SELECT distinct market FROM gdb023.dim_customer
where customer= 'Atliq Exclusive' and region='APAC';

SELECT distinct(market) FROM gdb023.dim_customer
where customer= 'Atliq Exclusive' and region='APAC';

SELECT market FROM gdb023.dim_customer
where customer= 'Atliq Exclusive' and region='APAC'
group by market
order by market;

/*2.  What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 unique_products_2021 percentage_chg */

with cte20 as
(select count(distinct(product_code)) as unique_2020 from fact_sales_monthly as f where fiscal_year=2020 ),
cte21 as
(select count(distinct(product_code)) as unique_2021 from fact_sales_monthly as f where fiscal_year=2021)
select *, round((unique_2021-unique_2020)*100/unique_2020,2) as percentage_chg
from cte20
cross join
cte21;

/*3.  Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, 
segment product_count   */

select segment,count(distinct(product_code)) as product_count from dim_product
group by segment
order by product_count desc;

/*4.  Follow-up: Which segment had the most increase in unique products in 
2021 vs 2020? The final output contains these fields, 
segment product_count_2020 product_count_2021 difference   */

with cte20 as
(select p.segment ,count(distinct(f.product_code)) as unique_2020 from dim_product p
join fact_sales_monthly as f 
	on p.product_code=f.product_code
where fiscal_year=2020 
group by segment),
cte21 as
(select p.segment ,count(distinct(f.product_code)) as unique_2021 from dim_product p
join fact_sales_monthly as f 
	on p.product_code=f.product_code
where fiscal_year=2021
group by segment)
select cte20.segment,cte20.unique_2020,cte21.unique_2021, (unique_2021-unique_2020) as difference_chg
from cte20
join
cte21 on cte20.segment=cte21.segment;

/*5.  Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code product manufacturing_cost   */

select f.product_code,p.product,f.manufacturing_cost
from fact_manufacturing_cost f 
join dim_product p 
	on f.product_code=p.product_code
where manufacturing_cost in (
		(select max(manufacturing_cost) from fact_manufacturing_cost),
        (select min(manufacturing_cost) from fact_manufacturing_cost)
)        
order by manufacturing_cost desc;

/*6.  Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code customer average_discount_percentage   */

set sql_mode="";
select d.customer_code,c.customer,
round(avg(d.pre_invoice_discount_pct)*100,2) as av
 from dim_customer c
join fact_pre_invoice_deductions as d
using(customer_code)
where fiscal_year=2021 and market='India'
group by d.customer_code
order by avg(pre_invoice_discount_pct) desc	
limit 5;

/*7.  Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month Year Gross sales Amount   */

select 
date_format(fs.date,"%M (%Y)") as montHly, 
concat(monthname(fs.date),'(',Year(fs.date),')') as Month,
fs.fiscal_year,
round(sum(g.gross_price*fs.sold_quantity),2) as gross_sales_amount
from fact_sales_monthly fs
join dim_customer c on fs.customer_code=c.customer_code
join fact_gross_price g on fs.product_code=g.product_code
where c.customer='Atliq Exclusive'
group by Month ,fs.fiscal_year
order by fs.fiscal_year;

/*8.  In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, 
Quarter total_sold_quantity  */

select 
case
 when date between '2019-09-01' and '2019-11-01' then 'q1'
 when date between '2019-12-01' and '2020-02-01' then 'q2'
 when date between '2020-03-01' and '2020-05-01' then 'q3'
 when date between '2020-06-01' and '2020-08-01' then 'q4'
 end as quarters,
 sum(sold_quantity) as total_sold_quantity
from fact_sales_monthly
where fiscal_year=2020
group by quarters
order by total_sold_quantity desc;

/*9.  Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel gross_sales_mln percentage  */

with cte as(
select c.channel, round(sum(gross_price*sold_quantity/1000000),2 ) as gross_sales_mln
from dim_customer as c
join fact_sales_monthly as fs on c.customer_code=fs.customer_code
join fact_gross_price as g on fs.product_code=g.product_code
where fs.fiscal_year =2021
group by channel
)
select *,concat(round(gross_sales_mln*100/sum(gross_sales_mln) over(),2),"%") as percentage
from cte
order by percentage desc;

/*10.  Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division product_code product total_sold_quantity rank_order*/

with cte1 as(
select p.division,p.product_code,p.product ,sum(fs.sold_quantity) as total_sold_quantity 
from dim_product as p
join fact_sales_monthly as fs on p.product_code=fs.product_code
where fs.fiscal_year =2021
group by division,product_code,p.product
order by total_sold_quantity  desc
),
cte2 as(
select *, 
	dense_rank() over(partition by division 
    order by total_sold_quantity desc
    ) as rank_order
from cte1)
select division,product_code,product ,total_sold_quantity,rank_order from cte2
where rank_order<=3;
