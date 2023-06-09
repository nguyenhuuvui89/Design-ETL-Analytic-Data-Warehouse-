/*After loading all data from the python into DBMS (After code below, i drop listing_dim and review_fact, only use listing_dim_new and review_fact_new, 
I creat new listing_dim_new serial primary key and new review_fact_new table to get easier maintance SCD2 */


select * from listing_dim

select * from listing_dim_new

Create table listing_dim_new (
	listing_dim_id serial primary key,
	listing_id int,
	name varchar,
	property_type varchar, 
	room_type varchar, 
	price int, 
	accommodates varchar, 
	amenities varchar,
    description varchar, 
	effective_timestamp date, 
	expire_timestamp date, 
	current_flag varchar)
-- Insert from listing_dim into listing_dim_new (with serial key for SCD2 maintance easier)
insert into listing_dim_new (listing_id,name, property_type, room_type, price, accommodates, 
							 amenities, description, effective_timestamp,expire_timestamp, current_flag)
select listing_id,name, property_type, room_type, price, accommodates, 
	   amenities, description, effective_timestamp,expire_timestamp, current_flag
from listing_dim;
----- 
select * from review_fact_new
select * from listing_dim_new

---------- Making new review fact table with listing serial keys
CREATE TABLE Review_fact_new (review_id int Primary Key, 
             time_id int References Time_dim (time_id), 
			 listing_id int References Listing_dim_new(listing_dim_id), 
             reviewer_id int References reviewer_dim (reviewer_id), 
             reviews_scores_accuracy int, 
			 review_scores_communication int, review_score_rating int);

----- insert new values into new review fact table
insert into Review_fact_new (review_id, time_id, listing_id, reviewer_id, reviews_scores_accuracy, review_scores_communication, review_score_rating)
select b.review_id, b.time_id, b.listing_dim_id_serial, b.reviewer_id, b.reviews_scores_accuracy, b.review_scores_communication, b.review_score_rating
from
(select review_fact.*, a.* 
from review_fact
join (select  listing_dim.listing_dim_id as listing_dim_id_old_not_serial,
		listing_dim_new.listing_dim_id as listing_dim_id_serial,
listing_dim_new.* 
from listing_dim_new
join listing_dim on listing_dim_new.listing_id = listing_dim.listing_id) a
on review_fact.listing_id = a.listing_dim_id_old_not_serial) b;

------ I will work with review_fact_new and listing_dim_new from now on (not using listing_dim and review_fact tables any more)
drop table listing_dim;
drop table review_fact;
--------
select * from listing_dim_new;
select * from review_fact_new;

------Create Host_Dim table for uploading from Python
Create table Host_Dim (
	host_id int primary key,
	host_name varchar,
	host_is_superhost varchar,
	host_response_time varchar )



---

--
select * from listing_dim_new  where listing_id = 29979667

select * 
from review_fact_new f 
join reviewer_dim d on f.reviewer_id = d.reviewer_id
join time_dim t on f.time_id = t.time_id
join listing_dim_new l on l.listing_dim_id = f.listing_id where l.listing_id = 6369

select * from property_available
-------Create location_dim
Create table location_dim (
	location_id serial primary key,
	country varchar,
	city varchar,
	neighborhood varchar,
	neighborhood_prev varchar)
---
select * from property_available;

select * from location_dim
select * from listing_dim_new

select * from booking_fact_preparation where listing_id_p = 2818;

-----Create table booking_fact_hold_back_data to hold some data
Create table booking_fact_hold_back_data (
			listing_id_p int,
			time_id int,
			country varchar,
			city varchar,
			neighborhood varchar,
			available_id int,
			host_id	int	)
----- Create time_delta table
create table time_delta (
	time_id int primary key,
	date Date,
	day int,
	month varchar,
	year int)
----
select * from property_available

select * from booking_fact_hold_back_data

-----Create view for inserting data into booking_fact
Create view booking_fact_view AS
select ln.price, ln.listing_dim_id, loc.location_id, booking.*
from booking_fact_preparation booking
join location_dim loc on loc.country = booking.country
						and loc.city = booking.city
						and loc.neighborhood = booking.neighborhood
join listing_dim_new ln on ln.listing_id = booking.listing_id_p


----Create booking_fact table
Create table booking_fact(
	booking_id serial primary key,
	host_id int References host_dim (host_id), 
	listing_id int References Listing_dim_new(listing_dim_id),
	available_id in References property_available(available_id),
	location_id in References location_dim(location_id),
	time_id int References time_dim (time_id),
	sale_total int)
	
----insert data into booking_fact
insert into booking_fact (host_id,listing_id,available_id,location_id,time_id,sale_total)
select bvf.host_id, bvf.listing_dim_id, bvf.available_id,bvf.location_id,bvf.time_id,bvf.price
from booking_fact_view bvf
--- 


------ Check results----
select booking.*, loc.*, time.date, ln.listing_id, pro.* 
from booking_fact booking
join listing_dim_new ln on ln.listing_dim_id = booking.listing_id 
join location_dim loc on loc.location_id = booking.location_id
join property_available pro on pro.available_id = booking.available_id
join time_dim time on time.time_id = booking.time_id
where booking.listing_id = 1
------- create month_dim
create table month_dim (
	month_id serial primary key,
	date_month varchar,
	date_year int)
--- insert data into month_dim	
insert into month_dim (date_month, date_year)
select t.month, t.year from
(select month, year 
from time_dim 
group by (month, year)) t 
------
select * from month_dim

----Calculate total_revenue for each month
Create view monthly_revenue as 
select list.listing_dim_id as listing_id, sum(list.price) as total_revenue, time_dim.month, time_dim.year, pro.available_id, pro.available
from listing_dim_new list
join booking_fact book on book.listing_id = list.listing_dim_id
join time_dim on time_dim.time_id = book.time_id
join property_available pro on pro.available_id = book.available_id 
group by list.listing_dim_id, list.price, time_dim.month, time_dim.year, pro.available_id,pro.available
having pro.available = 'f'

------------- Create view booking_monthly_revenue_data----This view use to load data into booking_rev_fact

create view booking_monthly_revenue_data as
select monthly_revenue.*, month_dim.*
from monthly_revenue
join month_dim on monthly_revenue.month = month_dim.date_month
				and monthly_revenue.year = month_dim.date_year;
	
				
------ Create Booking_Rev_Fact table
create table booking_rev_fact (
		revenue_id serial primary key,
		listing_id int references listing_dim_new (listing_dim_id),
		available_id int references property_available (available_id),
		month_id int references month_dim (month_id),
		total_revenue int);

------Insert data into booking_rev_fact from booking_monthly_revenue_data view

insert into booking_rev_fact (listing_id,available_id,month_id,total_revenue)	
select booking_monthly_revenue_data.listing_id, booking_monthly_revenue_data.available_id, 
		booking_monthly_revenue_data.month_id, booking_monthly_revenue_data.total_revenue
from booking_monthly_revenue_data;


select * from booking_rev_fact;
----------Check result---
select b.*, month_dim.date_month,month_dim.date_year, list.*, month_dim.* 
from booking_rev_fact b
join month_dim on b.month_id = month_dim.month_id
join listing_dim_new list on list.listing_dim_id = b.listing_id where b.listing_id = 1

------Doing SCD 0. SCD 0 don't change any data, just add new records if not exist.
select *from time_delta 

Merge into time_dim as target
using time_delta 
on target.time_id = time_delta.time_id
When not matched then
insert (time_id, date, day, month,year)
values (time_delta.time_id, time_delta.date, time_delta.day, time_delta.month, time_delta.year)

select time_id, date, day, month, year
from time_dim
where exists (select 1 
			  from time_delta where time_dim.time_id = time_delta.time_id)



------Doing SCD 1 Maintenance---Not keep historical records, simply update or add new records
select * from host_dim
select * from host_dim_delta
-----
Merge into host_dim as ta
using host_dim_delta as so
on ta.host_id = so.host_id

When not matched then
insert (host_id, host_name, host_is_superhost, host_response_time)
values (so.host_id,so.host_name, so.host_is_superhost, so.host_response_time)

when matched and (ta.host_name != so.host_name
			   or ta.host_is_superhost != so.host_is_superhost
			   or ta.host_response_time != so.host_response_time)
then update set host_name = so.host_name, 
				host_is_superhost = so.host_is_superhost, 
				host_response_time = so.host_response_time

----Check after SCD1
select * from host_dim order by host_id


------ Doing SCD 2 Maintenance


---- Have new record of listing_id 2818 changes accommodates from 2 to 4----
select * from listing_delta_scd2 


---Create union view----
Create view delta_union As
(select li.listing_id as mergeKey, li.*
from listing_delta_scd2 li
 union all
--get record change
 select Null as mergeKey,lis.* -- force the mergeKey to Null so i can recognize change
 from listing_delta_scd2 lis
 join listing_dim_new li_di on li_di.listing_id = lis.listing_id and (lis.name != li_di.name 
																	 or lis.property_type != li_di.property_type
																	 or lis.room_type != li_di.room_type
																	 or lis.price != li_di.price
																	 or lis.accommodates != li_di.accommodates
																	 or lis.amenities != li_di.amenities
																	 or lis.description != li_di.description)
 where li_di.current_flag = 'Current')
-----
select * from delta_union

-------Using Merge to handle SCD2
Merge into listing_dim_new as target
using delta_union
on delta_union.mergeKey = target.listing_id

When not matched then
insert (listing_id,name,property_type,room_type,price,accommodates,amenities,description,effective_timestamp, expire_timestamp, current_flag)
values (delta_union.listing_id,delta_union.name,delta_union.property_type,delta_union.room_type,
		delta_union.price,delta_union.accommodates,delta_union.amenities,delta_union.description,
		delta_union.effective_timestamp, '9999-12-31', 'Current')
When matched and current_flag = 'Current' and (delta_union.name != target.name 
												or delta_union.property_type != target.property_type
												or delta_union.room_type != target.room_type
												or delta_union.price != target.price
												or delta_union.accommodates != target.accommodates
												or delta_union.amenities != target.amenities
												or delta_union.description != target.description)												
then update set current_flag = 'Expired', expire_timestamp = delta_union.effective_timestamp -1

select * from listing_dim_new where listing_id = 2818

----------------Create booking_fact_data_after_scd2 view 
Create view booking_fact_data_after_scd2 As
select bb.*, listing_dim_new.listing_dim_id,listing_dim_new.price, listing_dim_new.listing_id, ldi.location_id
from booking_fact_hold_back_data bb
join listing_dim_new on listing_dim_new.listing_id = bb.listing_id_p
join location_dim ldi on ldi.country = bb.country
						and ldi.city = bb.city
						and ldi.neighborhood = bb.neighborhood
where listing_dim_new.listing_id = 2818 and listing_dim_new.current_flag ='Current'
----------------
select * from booking_fact_data_after_scd2

------Insert hold back data after scd2 into booking_fact

insert into booking_fact (host_id,listing_id,available_id,location_id,time_id,sale_total)
select scd2.host_id, scd2.listing_dim_id, scd2.available_id,scd2.location_id,scd2.time_id,scd2.price
from booking_fact_data_after_scd2 scd2

----Verify new records added into booking_fact with new booking_id and cordinate with new listing_dim_id
select b.booking_id, b.listing_id as listing_dim_id_fk , ln.listing_dim_id, ln.listing_id, b.time_id, t.date, 
ln.effective_timestamp, ln.expire_timestamp, ln.current_flag
from booking_fact b
join time_dim t on t.time_id = b.time_id
join listing_dim_new ln on ln.listing_dim_id = b.listing_id
where ln.listing_id = 2818
order by b.time_id desc

-------SCD 3 Maintenance----

Merge into location_dim as tg
using location_delta as s
on tg.location_id = s.location_id

When matched and tg.neighborhood != s.neighborhood 
Then Update set neighborhood_prev = tg.neighborhood, neighborhood = s.neighborhood

When not matched then
insert (location_id, country, city, neighborhood)
values (s.location_id, s.country, s.city, s.neighborhood)

select * from location_dim order by location_id

	
	
-----Answer Bussiness Question in the project.
----Answer Bussiness Question 1. What is the most popular property and its revenue in 2022

select list.listing_dim_id, list.name, time_dim.year, sum(booking_fact.sale_total) as revenue,
rank() over ( order by sum(booking_fact.sale_total) desc) as Rev_Ranking
from listing_dim_new list
join booking_fact on list.listing_dim_id = booking_fact.listing_id
join time_dim on time_dim.time_id = booking_fact.time_id
join property_available on property_available.available_id = booking_fact.available_id
where time_dim.year = 2022 and property_available.available = 'f'
group by list.listing_dim_id, time_dim.year, booking_fact.sale_total

--- Approaching by cummulative fact table
select booking_rev_fact.listing_id, month_dim.date_year, listing_dim_new.name,
sum(booking_rev_fact.total_revenue) as total_revenue_year,
rank() over ( order by sum(booking_rev_fact.total_revenue) desc) as Rev_Ranking
from booking_rev_fact 
join month_dim on month_dim.month_id = booking_rev_fact.month_id
join listing_dim_new on listing_dim_new.listing_dim_id = booking_rev_fact.listing_id
group by booking_rev_fact.listing_id, listing_dim_new.name, month_dim.date_year 
having month_dim.date_year = 2022

---Answer bussiness question 2.	What are the factors that effect to the listing’s price in Amsterdam? Answer by Tableau
---Answer bussiness question 3. What are the factors that effect to the listing’s price in Amsterdam? Answer by Tableau
---Answer bussiness question 4. Which are the top 10 listings with the highest number of excellent reviews for communication, 
--accuracy, and overall rating, along with their name and prices?
select * from (
select l.listing_dim_id, l.name, l.price, 
count(*) number_excellent_review,
rank() over ( order by count(*) desc ) as ranking
from review_fact_new r
join listing_dim_new l on r.listing_id = l.listing_dim_id
join reviewer_dim re on r.reviewer_id = re.reviewer_id
group by l.listing_dim_id, l.name
having round(avg(r.review_scores_communication)) = 10 and 
round(avg(r.reviews_scores_accuracy)) = 10 and
round(avg(r.review_score_rating)) = 100) a
where a.ranking <= 10


--- Answer question 5 Which neighborhoods have the highest occupancy and highest number of reviews in Madrid? -- Answer by Tableau

/*Answer question 6: What is the percentage of properties that were booked for more than 30 days in each neighborhood in 2019
Select Top 5 Hottes neighborhood base on booked percentage? */

SELECT * FROM 
(SELECT ld.neighborhood, 
to_char(COUNT(CASE WHEN pa.maximum_nights > 30 THEN bf.booking_id END)::float / COUNT(bf.booking_id) * 100, '99.99%') AS percentage,
DENSE_RANK() OVER (Order By COUNT(CASE WHEN pa.maximum_nights > 30 THEN bf.booking_id END)::float / COUNT(bf.booking_id) * 100 DESC) as Ranking
FROM Booking_Fact bf
JOIN Property_available pa ON bf.available_id = pa.available_id
JOIN Location_Dim ld ON bf.location_id = ld.location_id
JOIN Time_dim t on t.time_id = bf.time_id
WHERE t.year = 2019 
GROUP BY ld.neighborhood) a
Where a.Ranking <= 5 

