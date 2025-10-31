-- ============================================================================
-- Cyclistic Bike-Share Analysis - Export Results for Visualization
-- ============================================================================
-- Purpose: Export query results to CSV for visualization in Tableau/Excel/R
-- Run these queries and save output to CSV files
-- ============================================================================

-- ============================================================================
-- EXPORT 1: Daily Patterns
-- ============================================================================
-- File: daily_patterns.csv

.mode csv
.headers on
.output ../data/results/daily_patterns.csv

SELECT
    member_casual,
    day_name,
    day_of_week,
    COUNT(*) as number_of_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
GROUP BY member_casual, day_name, day_of_week
ORDER BY day_of_week, member_casual;

.output stdout

-- ============================================================================
-- EXPORT 2: Hourly Patterns
-- ============================================================================
-- File: hourly_patterns.csv

.output ../data/results/hourly_patterns.csv

SELECT
    member_casual,
    hour,
    COUNT(*) as number_of_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
GROUP BY member_casual, hour
ORDER BY hour, member_casual;

.output stdout

-- ============================================================================
-- EXPORT 3: Monthly Patterns
-- ============================================================================
-- File: monthly_patterns.csv

.output ../data/results/monthly_patterns.csv

SELECT
    member_casual,
    month,
    month_name,
    COUNT(*) as number_of_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
GROUP BY member_casual, month, month_name
ORDER BY month, member_casual;

.output stdout

-- ============================================================================
-- EXPORT 4: Weekend vs Weekday
-- ============================================================================
-- File: day_type_patterns.csv

.output ../data/results/day_type_patterns.csv

SELECT
    member_casual,
    day_type,
    COUNT(*) as number_of_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 2) as pct_of_user_rides
FROM trips_clean
GROUP BY member_casual, day_type
ORDER BY member_casual, day_type;

.output stdout

-- ============================================================================
-- EXPORT 5: Top Stations
-- ============================================================================
-- File: top_start_stations.csv

.output ../data/results/top_start_stations.csv

SELECT
    member_casual,
    from_station_name,
    COUNT(*) as trips_started,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
WHERE from_station_name IS NOT NULL
GROUP BY member_casual, from_station_name
ORDER BY member_casual, trips_started DESC;

.output stdout

-- ============================================================================
-- EXPORT 6: Ride Duration Distribution
-- ============================================================================
-- File: duration_distribution.csv

.output ../data/results/duration_distribution.csv

SELECT
    member_casual,
    CASE
        WHEN ride_length_min < 5 THEN '< 5 min'
        WHEN ride_length_min < 10 THEN '5-10 min'
        WHEN ride_length_min < 20 THEN '10-20 min'
        WHEN ride_length_min < 30 THEN '20-30 min'
        WHEN ride_length_min < 60 THEN '30-60 min'
        ELSE '60+ min'
    END as duration_bucket,
    COUNT(*) as rides,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 2) as pct_of_user_rides
FROM trips_clean
GROUP BY member_casual, duration_bucket
ORDER BY member_casual,
    CASE duration_bucket
        WHEN '< 5 min' THEN 1
        WHEN '5-10 min' THEN 2
        WHEN '10-20 min' THEN 3
        WHEN '20-30 min' THEN 4
        WHEN '30-60 min' THEN 5
        WHEN '60+ min' THEN 6
    END;

.output stdout

-- ============================================================================
-- EXPORT 7: Summary Statistics
-- ============================================================================
-- File: summary_statistics.csv

.output ../data/results/summary_statistics.csv

SELECT
    member_casual,
    COUNT(*) as total_rides,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM trips_clean), 2) as percentage_of_total,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min,
    ROUND(MIN(ride_length_min), 2) as min_ride_length_min,
    ROUND(MAX(ride_length_min), 2) as max_ride_length_min
FROM trips_clean
GROUP BY member_casual;

.output stdout

-- ============================================================================
-- EXPORT 8: Date-level aggregation (for time series visualization)
-- ============================================================================
-- File: daily_rides.csv

.output ../data/results/daily_rides.csv

SELECT
    date,
    member_casual,
    COUNT(*) as rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
GROUP BY date, member_casual
ORDER BY date, member_casual;

.output stdout

-- ============================================================================
-- COMPLETION MESSAGE
-- ============================================================================

SELECT '============================================' as message
UNION ALL SELECT 'All results exported successfully!'
UNION ALL SELECT 'Files saved to: ../data/results/'
UNION ALL SELECT '============================================';
