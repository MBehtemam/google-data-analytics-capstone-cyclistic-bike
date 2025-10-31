-- ============================================================================
-- Cyclistic Bike-Share Analysis - Main Analysis Queries
-- ============================================================================
-- Purpose: Answer key business questions comparing member vs casual riders
-- This mirrors the analysis done in the R notebook
-- ============================================================================

-- ============================================================================
-- OVERVIEW STATISTICS
-- ============================================================================

-- Overall ride statistics by user type
SELECT
    '=== OVERALL STATISTICS BY USER TYPE ===' as section;

SELECT
    member_casual,
    COUNT(*) as total_rides,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM trips_clean), 2) as percentage_of_total,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min,
    ROUND(MIN(ride_length_min), 2) as min_ride_length_min,
    ROUND(MAX(ride_length_min), 2) as max_ride_length_min,
    ROUND(AVG(ride_length_min), 2) as median_approx_ride_length_min
FROM trips_clean
GROUP BY member_casual
ORDER BY total_rides DESC;

-- ============================================================================
-- TEMPORAL ANALYSIS 1: DAY OF WEEK PATTERNS
-- ============================================================================

-- Question: What days of the week do members vs casual riders use bikes most?

SELECT
    '=== RIDES BY DAY OF WEEK ===' as section;

SELECT
    member_casual,
    day_name,
    COUNT(*) as number_of_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 2) as pct_of_user_rides
FROM trips_clean
GROUP BY member_casual, day_name, day_of_week
ORDER BY day_of_week, member_casual;

-- Average ride length by day of week
SELECT
    '=== AVERAGE RIDE LENGTH BY DAY ===' as section;

SELECT
    day_name,
    ROUND(AVG(CASE WHEN member_casual = 'member' THEN ride_length_min END), 2) as member_avg_min,
    ROUND(AVG(CASE WHEN member_casual = 'casual' THEN ride_length_min END), 2) as casual_avg_min,
    ROUND(
        AVG(CASE WHEN member_casual = 'casual' THEN ride_length_min END) -
        AVG(CASE WHEN member_casual = 'member' THEN ride_length_min END),
        2
    ) as difference_casual_minus_member
FROM trips_clean
GROUP BY day_name, day_of_week
ORDER BY day_of_week;

-- ============================================================================
-- TEMPORAL ANALYSIS 2: WEEKEND VS WEEKDAY
-- ============================================================================

-- Question: Do casual riders show different patterns on weekends vs weekdays?

SELECT
    '=== WEEKEND VS WEEKDAY PATTERNS ===' as section;

SELECT
    member_casual,
    day_type,
    COUNT(*) as number_of_rides,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 2) as pct_of_user_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
GROUP BY member_casual, day_type
ORDER BY member_casual, day_type;

-- ============================================================================
-- TEMPORAL ANALYSIS 3: HOURLY PATTERNS
-- ============================================================================

-- Question: What times of day are most popular for each group?

SELECT
    '=== RIDES BY HOUR OF DAY ===' as section;

SELECT
    hour,
    COUNT(*) as total_rides,
    SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) as member_rides,
    SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) as casual_rides,
    ROUND(AVG(CASE WHEN member_casual = 'member' THEN ride_length_min END), 2) as member_avg_min,
    ROUND(AVG(CASE WHEN member_casual = 'casual' THEN ride_length_min END), 2) as casual_avg_min
FROM trips_clean
GROUP BY hour
ORDER BY hour;

-- Peak hours by user type
SELECT
    '=== PEAK HOURS BY USER TYPE ===' as section;

-- Top 5 hours for members
SELECT
    'Member Peak Hours' as user_type,
    hour,
    COUNT(*) as rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_min
FROM trips_clean
WHERE member_casual = 'member'
GROUP BY hour
ORDER BY rides DESC
LIMIT 5;

-- Top 5 hours for casual riders
SELECT
    'Casual Peak Hours' as user_type,
    hour,
    COUNT(*) as rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_min
FROM trips_clean
WHERE member_casual = 'casual'
GROUP BY hour
ORDER BY rides DESC
LIMIT 5;

-- ============================================================================
-- TEMPORAL ANALYSIS 4: MONTHLY/SEASONAL PATTERNS
-- ============================================================================

-- Question: Are there seasonal differences between the two groups?

SELECT
    '=== RIDES BY MONTH ===' as section;

SELECT
    month_name,
    COUNT(*) as total_rides,
    SUM(CASE WHEN member_casual = 'member' THEN 1 ELSE 0 END) as member_rides,
    SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) as casual_rides,
    ROUND(SUM(CASE WHEN member_casual = 'casual' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as casual_percentage
FROM trips_clean
GROUP BY month_name, month
ORDER BY month;

-- Seasonal breakdown (Q1=Winter/Spring, Q2=Spring, Q3=Summer, Q4=Fall)
SELECT
    '=== RIDES BY QUARTER (SEASON) ===' as section;

SELECT
    quarter,
    member_casual,
    COUNT(*) as number_of_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY quarter), 2) as pct_of_quarter_rides
FROM trips_clean
GROUP BY quarter, member_casual
ORDER BY quarter, member_casual;

-- ============================================================================
-- RIDE DURATION ANALYSIS
-- ============================================================================

-- Question: What is the distribution of ride lengths for each group?

SELECT
    '=== RIDE DURATION STATISTICS ===' as section;

SELECT
    member_casual,
    COUNT(*) as total_rides,
    ROUND(AVG(ride_length_min), 2) as mean_min,
    ROUND(MIN(ride_length_min), 2) as min_min,
    ROUND(MAX(ride_length_min), 2) as max_min
FROM trips_clean
GROUP BY member_casual;

-- Ride length distribution buckets
SELECT
    '=== RIDE LENGTH DISTRIBUTION ===' as section;

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

-- ============================================================================
-- LOCATION ANALYSIS: POPULAR STATIONS
-- ============================================================================

-- Question: Which stations are most popular for casual riders vs members?

SELECT
    '=== TOP 10 START STATIONS - MEMBERS ===' as section;

SELECT
    from_station_name,
    COUNT(*) as trips_started,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
WHERE member_casual = 'member'
    AND from_station_name IS NOT NULL
GROUP BY from_station_name
ORDER BY trips_started DESC
LIMIT 10;

SELECT
    '=== TOP 10 START STATIONS - CASUAL ===' as section;

SELECT
    from_station_name,
    COUNT(*) as trips_started,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
WHERE member_casual = 'casual'
    AND from_station_name IS NOT NULL
GROUP BY from_station_name
ORDER BY trips_started DESC
LIMIT 10;

SELECT
    '=== TOP 10 END STATIONS - MEMBERS ===' as section;

SELECT
    to_station_name,
    COUNT(*) as trips_ended,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
WHERE member_casual = 'member'
    AND to_station_name IS NOT NULL
GROUP BY to_station_name
ORDER BY trips_ended DESC
LIMIT 10;

SELECT
    '=== TOP 10 END STATIONS - CASUAL ===' as section;

SELECT
    to_station_name,
    COUNT(*) as trips_ended,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
WHERE member_casual = 'casual'
    AND to_station_name IS NOT NULL
GROUP BY to_station_name
ORDER BY trips_ended DESC
LIMIT 10;

-- ============================================================================
-- LOCATION ANALYSIS: ROUND TRIPS
-- ============================================================================

-- Round trips (same start and end station) by user type
SELECT
    '=== ROUND TRIPS ANALYSIS ===' as section;

SELECT
    member_casual,
    SUM(CASE WHEN from_station_name = to_station_name THEN 1 ELSE 0 END) as round_trips,
    COUNT(*) as total_trips,
    ROUND(SUM(CASE WHEN from_station_name = to_station_name THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as round_trip_pct,
    ROUND(AVG(CASE WHEN from_station_name = to_station_name THEN ride_length_min END), 2) as avg_round_trip_min
FROM trips_clean
WHERE from_station_name IS NOT NULL AND to_station_name IS NOT NULL
GROUP BY member_casual;

-- ============================================================================
-- COMBINED INSIGHTS: WEEKEND AFTERNOON ANALYSIS
-- ============================================================================

-- Question: How do usage patterns differ on weekend afternoons (popular leisure time)?

SELECT
    '=== WEEKEND AFTERNOON RIDES (12PM-6PM) ===' as section;

SELECT
    member_casual,
    COUNT(*) as rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM trips_clean
        WHERE day_type = 'Weekend' AND hour BETWEEN 12 AND 18
    ), 2) as pct_of_weekend_afternoon
FROM trips_clean
WHERE day_type = 'Weekend'
    AND hour BETWEEN 12 AND 18
GROUP BY member_casual;

-- ============================================================================
-- COMBINED INSIGHTS: WEEKDAY COMMUTE HOURS
-- ============================================================================

-- Question: How do usage patterns differ during typical commute hours?

SELECT
    '=== WEEKDAY MORNING COMMUTE (7AM-9AM) ===' as section;

SELECT
    member_casual,
    COUNT(*) as rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM trips_clean
        WHERE day_type = 'Weekday' AND hour BETWEEN 7 AND 9
    ), 2) as pct_of_morning_commute
FROM trips_clean
WHERE day_type = 'Weekday'
    AND hour BETWEEN 7 AND 9
GROUP BY member_casual;

SELECT
    '=== WEEKDAY EVENING COMMUTE (4PM-7PM) ===' as section;

SELECT
    member_casual,
    COUNT(*) as rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min,
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*) FROM trips_clean
        WHERE day_type = 'Weekday' AND hour BETWEEN 16 AND 19
    ), 2) as pct_of_evening_commute
FROM trips_clean
WHERE day_type = 'Weekday'
    AND hour BETWEEN 16 AND 19
GROUP BY member_casual;
