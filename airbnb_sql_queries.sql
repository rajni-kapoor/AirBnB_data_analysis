/*Q1. Which neighbourhoods generate the highest total revenue (price × minimum_nights)?
•	neighbourhood revenue ranking */

select neighbourhood, sum(price*minimum_nights) as revenue
from airbnb_2020
group by neighbourhood
order by revenue desc

/* Q2. Which room type has the highest average demand (reviews_per_month) in both year?
•	room type demand comparison */

WITH cte_2023 AS
( 
SELECT room_type, year, ROUND(AVG(reviews_per_month)::numeric, 2) AS average_demand 
FROM airbnb_2023 
GROUP BY room_type, year ), 
cte_2020 AS 
( 
SELECT room_type, year, ROUND(AVG(reviews_per_month)::numeric, 2) AS average_demand 
FROM airbnb_2020 GROUP BY room_type, year 
) 
SELECT * FROM cte_2023 
WHERE average_demand = (SELECT MAX(average_demand) FROM cte_2023)
UNION ALL 
SELECT * FROM cte_2020 
WHERE average_demand = (SELECT MAX(average_demand) FROM cte_2020);


/* Q3. Compare average prices between 2020 and 2023 for each neighbourhood.
•	neighbourhood price evolution */

with cte_2020 as
(
select neighbourhood, round((avg(price)::numeric),2) as avg_price_2020
from airbnb_2020
group by neighbourhood
), cte_2023 as (
select neighbourhood, round((avg(price)::numeric),2) as avg_price_2023
from airbnb_2023
group by neighbourhood )
select a.neighbourhood, a.avg_price_2020, b.avg_price_2023,
case when a.avg_price_2020 > b.avg_price_2023 THEN '-' || (a.avg_price_2020 - b.avg_price_2023)::text 
	WHEN b.avg_price_2023 > a.avg_price_2020 THEN '+' || (b.avg_price_2023 - a.avg_price_2020)::text
	else '0'
	end as change
from cte_2020 a
join cte_2023 b
on a.neighbourhood=b.neighbourhood
order by a.avg_price_2020 desc


/* 4. Which neighbourhoods gained the most new listings between 2020 and 2023?
*/

with cnt_2020 as
(
select neighbourhood, count(id) as total_listing
from airbnb_2020
group by neighbourhood
), cnt_2023 as
(
select neighbourhood, count(id) as total_listing
from airbnb_2023
group by neighbourhood
)
select a.neighbourhood, a.total_listing as listing_2020, b.total_listing as listing_2023,
(case when (b.total_listing > a.total_listing) then
'+'||((b.total_listing - a.total_listing)::text) 
when (b.total_listing < a.total_listing) then
'-' || (a.total_listing - b.total_listing)::text
else '0' end) as listing_change
from cnt_2020 a
join cnt_2023 b
on a.neighbourhood=b.neighbourhood

/* 5. Which listings had the biggest price increase from 2020 to 2023? */

with diff_price as
(
select a20.id, a20.price as price_2020, a23.price as price_2023,
	a23.price - a20.price as price_jump
from 
	airbnb_2020 a20
join
	airbnb_2023 a23
on a20.id=a23.id
)
select id as listing,price_2020,price_2023, 
	row_number() over(order by price_jump desc) as rank, 
	price_jump
from diff_price
WHERE price_2020 IS NOT NULL AND price_2023 IS NOT NULL

/* 6. Which neighbourhoods saw the biggest drop in availability?
•	Compare avg availability_365 in both years.
*/
with cte_2020 as
(
select neighbourhood, round(avg(availability_365)::decimal,2) as avlblty_2020
from airbnb_2020
group by neighbourhood
),
cte_2023 as
(
select neighbourhood, round(avg(availability_365)::decimal,2) as avlblty_2023
from airbnb_2023
group by neighbourhood
)
select c20.neighbourhood, c20.avlblty_2020, c23.avlblty_2023,
row_number() over (order by (c20.avlblty_2020-c23.avlblty_2023)desc) as rank,
(c20.avlblty_2020 - c23.avlblty_2023) AS drop_in_availability
from cte_2020 c20
join cte_2023 c23
on c20.neighbourhood=c23.neighbourhood
where c20.avlblty_2020> c23.avlblty_2023

/*7. Which listings received the highest number of reviews in 2023?
top‑reviewed listings */

select id,name, number_of_reviews as listing_high_review 
from airbnb_2023 
order by listing_high_review desc 
limit 10

/* 8. Which hosts have more than 10 listings (super‑hosts by volume)?
high‑volume hosts */

select host_id, count(id) as total_listing from airbnb_2023 
group by host_id 
having count(id)>10
order by count(id) desc

/* 9. Which neighbourhoods have the highest concentration of low‑priced listings?
budget neighbourhoods 
median -low_price_listing_neighbourhood */

with median_price as
(
select percentile_cont(0.5) WITHIN GROUP (ORDER BY price) as mp
from airbnb_2023 
),
low_price_listing as
(
select id, price
from airbnb_2023
where price < (select mp from median_price)
)
select a.neighbourhood, count(lp.id) as total_low_price_listing,
count(a.id) as total_listing,
ROUND(100.0 * COUNT(lp.id) / COUNT(a.id), 2) AS low_price_concentration
from low_price_listing lp
right join airbnb_2023 a
on a.id=lp.id
group by a.neighbourhood
order by low_price_concentration desc

/* Which neighbourhoods have the highest average minimum nights requirement? */

select neighbourhood, round(avg(minimum_nights),2) as avg_min_nights
from airbnb_2020
group by neighbourhood
order by avg_min_nights desc

/* 11. What percentage of listings in each neighbourhood are entire homes? */

with total_listing as
(select neighbourhood, count(id) as total_listing
from airbnb_2023
group by neighbourhood)
, entire_home_counting as
(
select neighbourhood, count(id) as entire_home_listing
from airbnb_2023
where room_type='Entire home/apt'
group by neighbourhood
)
select a.neighbourhood, total_listing, entire_home_listing,
ROUND(100.0 * entire_home_listing / total_listing, 2) AS entire_home_concentration
from total_listing a
join entire_home_counting b
on a.neighbourhood=b.neighbourhood
order by entire_home_concentration desc






