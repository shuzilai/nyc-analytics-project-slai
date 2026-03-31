-- Clean and standardize NYC open restaurant apps data


WITH source AS (
   SELECT * FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),


cleaned AS (
   SELECT
       * EXCEPT (
           objectid,
           globalid,
           restaurant_name,
           food_service_establishment,
           legal_business_name,
           time_of_submission,
           borough,
           bulding_number,
           street,
           zip,
           sidewalk_dimensions_area,
           roadway_dimensions_area,
           approved_for_sidewalk_seating,
           approved_for_roadway_seating,
           latitude,
           longitude,
           roadway_dimensions_length,
           roadway_dimensions_width,
           seating_interest_sidewalk,
           sidewalk_dimensions_length,
           sidewalk_dimensions_width
       ),


       -- identifiers
       CAST(objectid AS STRING) AS objectid,
       CAST(globalid AS STRING) AS globalid,
	 CAST(food_service_establishment AS STRING) AS restaurant_id,
       CAST(restaurant_name AS STRING) AS restaurant_name,
       CAST(legal_business_name AS STRING) AS legal_business_name,


       -- time
       CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,


       -- borough cleaning
       CASE
           WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
           WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
           WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
           WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
           WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
           ELSE 'UNKNOWN'
       END AS borough,


       -- building info
       CAST(bulding_number AS STRING) AS building_number,
       CAST(street AS STRING) AS street,


       -- zip
       CASE 
           WHEN LENGTH(CAST(zip AS STRING)) = 5 THEN CAST(zip AS STRING)
           ELSE NULL
       END AS zip,


       -- seating
       CAST(sidewalk_dimensions_area AS FLOAT64) AS sidewalk_dimensions_area,
       CAST(roadway_dimensions_area AS FLOAT64) AS roadway_dimensions_area,
       CAST(approved_for_sidewalk_seating AS STRING) AS approved_for_sidewalk_seating,
       CAST(approved_for_roadway_seating AS STRING) AS approved_for_roadway_seating,


       -- coordinates
       CAST(latitude AS FLOAT64) AS latitude,
       CAST(longitude AS FLOAT64) AS longitude,


       -- dimensions
       CAST(roadway_dimensions_length AS FLOAT64) AS roadway_dimensions_length,
       CAST(roadway_dimensions_width AS FLOAT64) AS roadway_dimensions_width,
       CAST(sidewalk_dimensions_length AS FLOAT64) AS sidewalk_dimensions_length,
       CAST(sidewalk_dimensions_width AS FLOAT64) AS sidewalk_dimensions_width,
       CAST(seating_interest_sidewalk AS STRING) AS seating_interest_sidewalk,


       -- metadata
       CURRENT_TIMESTAMP() AS _stg_loaded_at


   FROM source


   WHERE restaurant_name IS NOT NULL
     AND borough IS NOT NULL


   QUALIFY ROW_NUMBER() OVER (
       PARTITION BY objectid
       ORDER BY time_of_submission DESC
   ) = 1
)


SELECT * FROM cleaned