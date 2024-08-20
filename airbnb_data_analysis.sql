-- Create new table
CREATE TABLE airbnb(
	id BIGINT, 
	name VARCHAR(255),
	host_id BIGINT, 
	host_name VARCHAR(255),
	neighbourhood_group_cleansed VARCHAR(255),
	neighbourhood VARCHAR(255),
	latitude DECIMAL(12,8),
	longitude DECIMAL(13,8),
	room_type VARCHAR(50),
	price BIGINT,
	minimum_nights BIGINT,
	number_of_reviews BIGINT,
	last_review DATE,
	reviews_per_month DECIMAL(5,2),
	calculated_host_listings_count BIGINT,
	availability_365 BIGINT
);

-- Copy wanted columns from the original table
INSERT INTO airbnb(
	id, 
	name, 
	host_id, 
	host_name,
	neighbourhood_group_cleansed,
	neighbourhood,
	latitude,
	longitude,
	room_type,
	price,
	minimum_nights,
	number_of_reviews,
	last_review,
	reviews_per_month,
	calculated_host_listings_count,
	availability_365
)
SELECT
	id, 
	name, 
	host_id, 
	host_name,
	neighbourhood_group_cleansed,
	neighbourhood,
	latitude,
	longitude,
	room_type,
	price,
	minimum_nights,
	number_of_reviews,
	last_review,
	reviews_per_month,
	calculated_host_listings_count,
	availability_365

FROM airbnb_og;
	

SELECT *
FROM airbnb

-- drop neighbourhood_group_cleaned and neighbourhood columns
ALTER TABLE airbnb
DROP COLUMN neighbourhood_group_cleansed;

ALTER TABLE airbnb
DROP COLUMN neighbourhood;


-- Remove duplicates
SELECT DISTINCT *
INTO temp_airbnb
FROM airbnb;


WITH CTE AS(
	SELECT id,
		ROW_NUMBER() OVER (
			PARTITION BY id, name, host_id, host_name, latitude, longitude, room_type, price, minimum_nights, number_of_reviews, last_review, reviews_per_month, calculated_host_listings_count, availability_365
			ORDER BY (SELECT NULL)
		) AS row_num
	FROM temp_airbnb
)
DELETE FROM airbnb
WHERE EXISTS(
	SELECT 1
	FROM CTE
	WHERE CTE.id = airbnb.id
	AND CTE.name = airbnb.name
	AND CTE.host_id = airbnb.host_id
	AND CTE.host_name = airbnb.host_name
	AND CTE.latitude = airbnb.latitude
	AND CTE.longitude = airbnb.longitude
	AND CTE.room_type = airbnb.room_type
	AND CTE.price = airbnb.price
	AND CTE.minimum_nights = airbnb.minimum_nights
	AND CTE.number_of_reviews = airbnb.number_of_reviews
	AND CTE.last_review = airbnb.last_review
	AND CTE.reviews_per_month = airbnb.reviews_per_month
	AND CTE.calculated_host_listings_count = airbnb.calculated_host_listings_count
	AND CTE.availability_365 = airbnb.availability_365
	AND CTE.row_num > 1
);




SELECT *
FROM airbnb

DELETE FROM airbnb
WHERE id IN(
    SELECT id FROM(
		SELECT
			id,
		   ROW_NUMBER() OVER (
               PARTITION BY id, name, host_id, host_name, latitude, longitude, room_type, price, minimum_nights, number_of_reviews, last_review, reviews_per_month, calculated_host_listings_count, availability_365
               ORDER BY (SELECT NULL)
           ) AS row_num
		FROM
			airbnb
	) AS subquery
	WHERE row_num > 1
);

/*
Remove NULL Values
*/

SELECT *
FROM airbnb

--update last review
UPDATE airbnb
SET last_review = '2000-01-01'
WHERE last_review IS NULL;

-- update mean reviews
CREATE TABLE mean_reviews(
	mean_reviews_per_month FLOAT
);

INSERT INTO mean_reviews (mean_reviews_per_month)
SELECT AVG(reviews_per_month) AS mean_reviews_per_month
FROM airbnb
WHERE reviews_per_month IS NOT NULL;

UPDATE airbnb
SET reviews_per_month =(SELECT mean_reviews_per_month FROM mean_reviews)
WHERE reviews_per_month IS NULL;

-- update last review
ALTER TABLE airbnb
ADD last_review_null INT DEFAULT 0,
	reviews_per_month_null INT DEFAULT 0;

UPDATE airbnb
SET last_review_null = 0
WHERE last_review_null is NULL;

UPDATE airbnb
SET reviews_per_month_null = 0
WHERE reviews_per_month_null IS NULL;

UPDATE airbnb
SET last_review_null = 1
WHERE last_review = '2000-01-01';

UPDATE airbnb
SET reviews_per_month_null = 1
WHERE reviews_per_month = (SELECT mean_reviews_per_month FROM mean_reviews);


-- find the relationship between the host and the area
SELECT *
FROM airbnb

SELECT
	host_name,
	COUNT(id) AS listings_count,
	ROUND(AVG(number_of_reviews),2) AS avg_reviews,
	ROUND(AVG(reviews_per_month),2) AS avg_reviews_per_month
FROM
	airbnb
GROUP BY
	host_name
ORDER BY
	COUNT(*) DESC;

-- Distributions of rooms
SELECT
	room_type,
	COUNT(*) AS room_count
FROM airbnb
GROUP BY room_type
ORDER BY room_count DESC;

-- Who is the busiest host based on reviews?
SELECT
	host_name,
	AVG(reviews_per_month) AS avg_reviews_per_month

FROM airbnb
GROUP BY host_name
ORDER BY avg_reviews_per_month DESC;

SELECT *
FROM airbnb