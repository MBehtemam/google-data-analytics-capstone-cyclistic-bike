-- ============================================================================
-- Cyclistic Bike-Share Analysis - Data Import Script
-- ============================================================================
-- Purpose: Import CSV data into SQLite database
-- Note: This script assumes you're running it from the SQL directory
--       and that CSV files are in the ../data/ directory
-- ============================================================================

-- ============================================================================
-- IMPORT Q1 2019 DATA
-- ============================================================================
-- Q1 has standard column structure

.mode csv
.import ../data/Divvy_Trips_2019_Q1.csv trips_raw_temp

-- Insert with quarter tag
INSERT INTO trips_raw
SELECT *, 'Q1' as quarter FROM trips_raw_temp WHERE trip_id IS NOT NULL;

DROP TABLE trips_raw_temp;

-- ============================================================================
-- IMPORT Q2 2019 DATA
-- ============================================================================
-- Q2 has different column names that need to be mapped
-- Column mapping:
--   01 - Rental Details Rental ID -> trip_id
--   01 - Rental Details Local Start Time -> start_time
--   01 - Rental Details Local End Time -> end_time
--   01 - Rental Details Bike ID -> bikeid
--   01 - Rental Details Duration In Seconds Uncapped -> tripduration
--   03 - Rental Start Station ID -> from_station_id
--   03 - Rental Start Station Name -> from_station_name
--   02 - Rental End Station ID -> to_station_id
--   02 - Rental End Station Name -> to_station_name
--   User Type -> usertype
--   Member Gender -> gender
--   05 - Member Details Member Birthday Year -> birthyear

.mode csv
.import ../data/Divvy_Trips_2019_Q2.csv q2_temp

-- Map Q2 columns to standard structure
INSERT INTO trips_raw (
    trip_id,
    start_time,
    end_time,
    bikeid,
    tripduration,
    from_station_id,
    from_station_name,
    to_station_id,
    to_station_name,
    usertype,
    gender,
    birthyear,
    quarter
)
SELECT
    "01 - Rental Details Rental ID",
    "01 - Rental Details Local Start Time",
    "01 - Rental Details Local End Time",
    "01 - Rental Details Bike ID",
    "01 - Rental Details Duration In Seconds Uncapped",
    "03 - Rental Start Station ID",
    "03 - Rental Start Station Name",
    "02 - Rental End Station ID",
    "02 - Rental End Station Name",
    "User Type",
    "Member Gender",
    "05 - Member Details Member Birthday Year",
    'Q2'
FROM q2_temp
WHERE "01 - Rental Details Rental ID" IS NOT NULL;

DROP TABLE q2_temp;

-- ============================================================================
-- IMPORT Q3 2019 DATA
-- ============================================================================
-- Q3 has standard column structure

.mode csv
.import ../data/Divvy_Trips_2019_Q3.csv trips_raw_temp

INSERT INTO trips_raw
SELECT *, 'Q3' as quarter FROM trips_raw_temp WHERE trip_id IS NOT NULL;

DROP TABLE trips_raw_temp;

-- ============================================================================
-- IMPORT Q4 2019 DATA
-- ============================================================================
-- Q4 has standard column structure

.mode csv
.import ../data/Divvy_Trips_2019_Q4.csv trips_raw_temp

INSERT INTO trips_raw
SELECT *, 'Q4' as quarter FROM trips_raw_temp WHERE trip_id IS NOT NULL;

DROP TABLE trips_raw_temp;

-- ============================================================================
-- VERIFY IMPORT
-- ============================================================================

-- Check total records imported
SELECT 'Total Records Imported' as metric, COUNT(*) as value FROM trips_raw
UNION ALL
SELECT 'Q1 Records', COUNT(*) FROM trips_raw WHERE quarter = 'Q1'
UNION ALL
SELECT 'Q2 Records', COUNT(*) FROM trips_raw WHERE quarter = 'Q2'
UNION ALL
SELECT 'Q3 Records', COUNT(*) FROM trips_raw WHERE quarter = 'Q3'
UNION ALL
SELECT 'Q4 Records', COUNT(*) FROM trips_raw WHERE quarter = 'Q4';

-- Check user type distribution
SELECT usertype, COUNT(*) as count, quarter
FROM trips_raw
GROUP BY usertype, quarter
ORDER BY quarter, usertype;

-- Display sample records
SELECT * FROM trips_raw LIMIT 5;
