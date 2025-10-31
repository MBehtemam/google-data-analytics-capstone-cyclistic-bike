-- ============================================================================
-- Cyclistic Bike-Share Analysis - Data Cleaning & Transformation
-- ============================================================================
-- Purpose: Clean raw data and create analysis-ready dataset
-- This mirrors the data cleaning done in the R analysis
-- ============================================================================

-- ============================================================================
-- STEP 1: DATA QUALITY CHECKS
-- ============================================================================

-- Check for duplicate trip IDs
SELECT 'Duplicate Trip IDs Check' as check_name;
SELECT trip_id, COUNT(*) as duplicate_count
FROM trips_raw
GROUP BY trip_id
HAVING COUNT(*) > 1;

-- Check for missing values
SELECT 'Missing Values Check' as check_name;
SELECT
    COUNT(*) as total_records,
    SUM(CASE WHEN from_station_name IS NULL THEN 1 ELSE 0 END) as missing_from_station,
    SUM(CASE WHEN to_station_name IS NULL THEN 1 ELSE 0 END) as missing_to_station,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) as missing_gender,
    SUM(CASE WHEN birthyear IS NULL THEN 1 ELSE 0 END) as missing_birthyear
FROM trips_raw;

-- Check for invalid durations (< 1 minute or > 24 hours)
SELECT 'Invalid Duration Check' as check_name;
SELECT
    COUNT(*) as invalid_count,
    MIN(tripduration) as min_duration_sec,
    MAX(tripduration) as max_duration_sec
FROM trips_raw
WHERE tripduration < 60 OR tripduration > 86400;

-- Check for invalid timestamps (end before start)
SELECT 'Invalid Timestamps Check' as check_name;
SELECT COUNT(*) as invalid_timestamp_count
FROM trips_raw
WHERE datetime(start_time) >= datetime(end_time);

-- ============================================================================
-- STEP 2: DATA CLEANING
-- ============================================================================

-- Clear any existing clean data
DELETE FROM trips_clean;

-- Insert cleaned and transformed data
INSERT INTO trips_clean (
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
    member_casual,
    gender,
    birthyear,
    ride_length_sec,
    ride_length_min,
    day_of_week,
    day_name,
    month,
    month_name,
    hour,
    year,
    date,
    day_type,
    quarter
)
SELECT
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
    -- Standardize user type: Subscriber -> member, Customer -> casual
    CASE
        WHEN usertype = 'Subscriber' THEN 'member'
        WHEN usertype = 'Customer' THEN 'casual'
        ELSE usertype
    END as member_casual,
    gender,
    birthyear,
    -- Calculate ride length in seconds (using julianday for difference)
    ROUND((julianday(end_time) - julianday(start_time)) * 86400, 2) as ride_length_sec,
    -- Calculate ride length in minutes
    ROUND(tripduration / 60.0, 2) as ride_length_min,
    -- Extract day of week (0=Sunday, 1=Monday, ..., 6=Saturday)
    CAST(strftime('%w', start_time) AS INTEGER) as day_of_week,
    -- Day name
    CASE CAST(strftime('%w', start_time) AS INTEGER)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END as day_name,
    -- Extract month (1-12)
    CAST(strftime('%m', start_time) AS INTEGER) as month,
    -- Month name
    CASE CAST(strftime('%m', start_time) AS INTEGER)
        WHEN 1 THEN 'January'
        WHEN 2 THEN 'February'
        WHEN 3 THEN 'March'
        WHEN 4 THEN 'April'
        WHEN 5 THEN 'May'
        WHEN 6 THEN 'June'
        WHEN 7 THEN 'July'
        WHEN 8 THEN 'August'
        WHEN 9 THEN 'September'
        WHEN 10 THEN 'October'
        WHEN 11 THEN 'November'
        WHEN 12 THEN 'December'
    END as month_name,
    -- Extract hour (0-23)
    CAST(strftime('%H', start_time) AS INTEGER) as hour,
    -- Extract year
    CAST(strftime('%Y', start_time) AS INTEGER) as year,
    -- Extract date
    DATE(start_time) as date,
    -- Classify as Weekend or Weekday
    CASE
        WHEN CAST(strftime('%w', start_time) AS INTEGER) IN (0, 6) THEN 'Weekend'
        ELSE 'Weekday'
    END as day_type,
    quarter
FROM trips_raw
WHERE
    -- Filter out invalid records
    tripduration >= 60                          -- At least 1 minute
    AND tripduration <= 86400                   -- At most 24 hours
    AND datetime(end_time) > datetime(start_time)  -- Valid time range
    AND trip_id IS NOT NULL;

-- ============================================================================
-- STEP 3: POST-CLEANING VERIFICATION
-- ============================================================================

-- Summary of cleaned data
SELECT 'Data Cleaning Summary' as summary;
SELECT
    'Raw records' as metric,
    COUNT(*) as value
FROM trips_raw
UNION ALL
SELECT
    'Clean records',
    COUNT(*)
FROM trips_clean
UNION ALL
SELECT
    'Records removed',
    (SELECT COUNT(*) FROM trips_raw) - (SELECT COUNT(*) FROM trips_clean);

-- User type distribution in clean data
SELECT 'User Type Distribution' as summary;
SELECT
    member_casual,
    COUNT(*) as total_rides,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM trips_clean), 2) as percentage
FROM trips_clean
GROUP BY member_casual;

-- Verify date range
SELECT 'Date Range' as summary;
SELECT
    MIN(date) as earliest_date,
    MAX(date) as latest_date,
    COUNT(DISTINCT date) as unique_days
FROM trips_clean;

-- Sample of clean data
SELECT 'Sample Clean Data (First 5 Records)' as summary;
SELECT
    trip_id,
    start_time,
    ride_length_min,
    member_casual,
    day_name,
    day_type,
    hour,
    from_station_name,
    to_station_name
FROM trips_clean
LIMIT 5;

-- ============================================================================
-- STEP 4: ANALYZE REMOVED RECORDS
-- ============================================================================

-- Analyze why records were removed
SELECT 'Records Removed - Reason Analysis' as analysis;

-- Short trips (< 1 minute)
SELECT
    'Short trips (< 1 min)' as reason,
    COUNT(*) as count
FROM trips_raw
WHERE tripduration < 60
UNION ALL
-- Long trips (> 24 hours)
SELECT
    'Long trips (> 24 hrs)',
    COUNT(*)
FROM trips_raw
WHERE tripduration > 86400
UNION ALL
-- Invalid timestamps
SELECT
    'Invalid timestamps (end before start)',
    COUNT(*)
FROM trips_raw
WHERE datetime(start_time) >= datetime(end_time)
UNION ALL
-- Multiple issues
SELECT
    'Valid records kept',
    COUNT(*)
FROM trips_clean;

-- ============================================================================
-- VACUUM DATABASE
-- ============================================================================
-- Optimize database after major changes
VACUUM;
