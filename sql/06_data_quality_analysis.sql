-- ============================================================================
-- Cyclistic Bike-Share Analysis - Data Quality Deep Dive
-- ============================================================================
-- Purpose: Investigate data quality issues and outliers
-- Run this to understand why records were removed during cleaning
-- ============================================================================

-- ============================================================================
-- DURATION OUTLIERS ANALYSIS
-- ============================================================================

SELECT '=== TRIP DURATION ANALYSIS ===' as section;

-- Overall duration statistics
SELECT
    COUNT(*) as total_records,
    ROUND(MIN(tripduration), 2) as min_seconds,
    ROUND(MAX(tripduration), 2) as max_seconds,
    ROUND(AVG(tripduration), 2) as avg_seconds,
    ROUND(AVG(tripduration) / 60, 2) as avg_minutes
FROM trips_raw;

-- Duration buckets
SELECT
    '=== DURATION DISTRIBUTION ===' as section;

SELECT
    CASE
        WHEN tripduration < 60 THEN '< 1 min (invalid)'
        WHEN tripduration < 600 THEN '1-10 min'
        WHEN tripduration < 1800 THEN '10-30 min'
        WHEN tripduration < 3600 THEN '30-60 min'
        WHEN tripduration < 7200 THEN '1-2 hours'
        WHEN tripduration < 14400 THEN '2-4 hours'
        WHEN tripduration < 86400 THEN '4-24 hours'
        ELSE '> 24 hours (invalid)'
    END as duration_bucket,
    COUNT(*) as records,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM trips_raw), 2) as percentage,
    ROUND(MIN(tripduration / 60.0), 2) as min_minutes,
    ROUND(MAX(tripduration / 60.0), 2) as max_minutes
FROM trips_raw
GROUP BY duration_bucket
ORDER BY MIN(tripduration);

-- Extreme outliers (> 24 hours)
SELECT
    '=== EXTREME OUTLIERS (> 24 HOURS) ===' as section;

SELECT
    usertype,
    COUNT(*) as count,
    ROUND(AVG(tripduration / 3600.0), 2) as avg_hours,
    ROUND(MAX(tripduration / 3600.0), 2) as max_hours,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM trips_raw WHERE tripduration > 86400), 2) as pct_of_outliers
FROM trips_raw
WHERE tripduration > 86400
GROUP BY usertype;

-- Top 20 longest trips
SELECT
    '=== TOP 20 LONGEST TRIPS ===' as section;

SELECT
    trip_id,
    usertype,
    ROUND(tripduration / 3600.0, 2) as hours,
    ROUND(tripduration / 86400.0, 2) as days,
    start_time,
    end_time,
    from_station_name,
    to_station_name,
    quarter
FROM trips_raw
ORDER BY tripduration DESC
LIMIT 20;

-- ============================================================================
-- MISSING DATA ANALYSIS
-- ============================================================================

SELECT '=== MISSING DATA ANALYSIS ===' as section;

SELECT
    quarter,
    COUNT(*) as total_records,
    SUM(CASE WHEN from_station_name IS NULL THEN 1 ELSE 0 END) as missing_from_station,
    SUM(CASE WHEN to_station_name IS NULL THEN 1 ELSE 0 END) as missing_to_station,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) as missing_gender,
    SUM(CASE WHEN birthyear IS NULL THEN 1 ELSE 0 END) as missing_birthyear,
    ROUND(SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as pct_missing_gender
FROM trips_raw
GROUP BY quarter
ORDER BY quarter;

-- Missing gender by user type
SELECT
    '=== MISSING GENDER BY USER TYPE ===' as section;

SELECT
    usertype,
    COUNT(*) as total,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) as missing_gender,
    ROUND(SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as pct_missing
FROM trips_raw
GROUP BY usertype;

-- ============================================================================
-- TIMESTAMP ANOMALIES
-- ============================================================================

SELECT '=== TIMESTAMP ANOMALIES ===' as section;

-- Trips where end time is before or equal to start time
SELECT
    COUNT(*) as invalid_timestamp_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM trips_raw), 4) as percentage
FROM trips_raw
WHERE datetime(start_time) >= datetime(end_time);

-- Sample of invalid timestamps
SELECT
    trip_id,
    start_time,
    end_time,
    tripduration,
    usertype,
    from_station_name,
    to_station_name
FROM trips_raw
WHERE datetime(start_time) >= datetime(end_time)
LIMIT 10;

-- ============================================================================
-- STATION DATA QUALITY
-- ============================================================================

SELECT '=== STATION STATISTICS ===' as section;

-- Unique stations
SELECT
    'Unique start stations' as metric,
    COUNT(DISTINCT from_station_name) as value
FROM trips_raw
WHERE from_station_name IS NOT NULL
UNION ALL
SELECT
    'Unique end stations',
    COUNT(DISTINCT to_station_name)
FROM trips_raw
WHERE to_station_name IS NOT NULL
UNION ALL
SELECT
    'Unique station IDs (start)',
    COUNT(DISTINCT from_station_id)
FROM trips_raw
WHERE from_station_id IS NOT NULL
UNION ALL
SELECT
    'Unique station IDs (end)',
    COUNT(DISTINCT to_station_id)
FROM trips_raw
WHERE to_station_id IS NOT NULL;

-- ============================================================================
-- BIKE USAGE ANALYSIS
-- ============================================================================

SELECT '=== BIKE USAGE PATTERNS ===' as section;

-- Number of unique bikes
SELECT
    'Total unique bikes' as metric,
    COUNT(DISTINCT bikeid) as value
FROM trips_raw;

-- Most used bikes
SELECT
    '=== TOP 10 MOST USED BIKES ===' as section;

SELECT
    bikeid,
    COUNT(*) as trips,
    ROUND(AVG(tripduration / 60.0), 2) as avg_trip_min,
    COUNT(DISTINCT DATE(start_time)) as days_active
FROM trips_raw
GROUP BY bikeid
ORDER BY trips DESC
LIMIT 10;

-- ============================================================================
-- DATA RETENTION SUMMARY
-- ============================================================================

SELECT '=== DATA CLEANING IMPACT SUMMARY ===' as section;

SELECT
    'Original records' as status,
    COUNT(*) as records,
    100.0 as percentage
FROM trips_raw
UNION ALL
SELECT
    'Valid records (kept)',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM trips_raw), 2)
FROM trips_raw
WHERE tripduration >= 60
    AND tripduration <= 86400
    AND datetime(end_time) > datetime(start_time)
UNION ALL
SELECT
    'Removed records',
    (SELECT COUNT(*) FROM trips_raw) - COUNT(*),
    ROUND(((SELECT COUNT(*) FROM trips_raw) - COUNT(*)) * 100.0 / (SELECT COUNT(*) FROM trips_raw), 2)
FROM trips_raw
WHERE tripduration >= 60
    AND tripduration <= 86400
    AND datetime(end_time) > datetime(start_time);

-- Breakdown of removed records
SELECT
    '=== WHY RECORDS WERE REMOVED ===' as section;

SELECT
    'Too short (< 1 min)' as reason,
    COUNT(*) as records,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM trips_raw), 2) as pct_of_total
FROM trips_raw
WHERE tripduration < 60
UNION ALL
SELECT
    'Too long (> 24 hours)',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM trips_raw), 2)
FROM trips_raw
WHERE tripduration > 86400
UNION ALL
SELECT
    'Invalid timestamp',
    COUNT(*),
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM trips_raw), 2)
FROM trips_raw
WHERE datetime(end_time) <= datetime(start_time);
