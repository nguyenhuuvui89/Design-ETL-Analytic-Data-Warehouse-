---After loading all data from the python into DBMS, I creat new listing_dim_new serial primary key and new review_fact_new table to get easier
-- maintance SCD2


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
select * from review_fact
select * from listing_dim_new

---------- Making new review fact table with listing serial keys
CREATE TABLE Review_fact_new (review_id bigint Primary Key, 
             time_id bigint References Time_dim (time_id), 
			 listing_id bigint References Listing_dim_new(listing_dim_id), 
             reviewer_id bigint References reviewer_dim (reviewer_id), 
             reviews_scores_accuracy bigint, 
			 review_scores_communication bigint, review_score_rating bigint);

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
select * from listing_dim_new;
select * from review_fact_new;

------Create Host_Dim table for uploading from Python
Create table Host_Dim (
	host_id serial primary key,
	host_name varchar,
	host_is_superhost varchar,
	host_response_time varchar )
---
select * from host_dim
----



