-- ============================================================================
-- Cyclistic Bike-Share Analysis - SQLite Schema Creation
-- ============================================================================
-- Purpose: Create database schema for storing Divvy trip data
-- Author: Junior Data Analyst
-- Date: 2024
-- ============================================================================

-- Drop existing tables if they exist
DROP TABLE IF EXISTS trips_raw;
DROP TABLE IF EXISTS trips_clean;

-- ============================================================================
-- RAW DATA TABLE
-- ============================================================================
-- This table stores the raw imported data from CSV files
-- Note: Q2 data has different column names that need to be standardized during import

CREATE TABLE trips_raw (
    trip_id INTEGER PRIMARY KEY,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    bikeid INTEGER NOT NULL,
    tripduration REAL NOT NULL,
    from_station_id INTEGER,
    from_station_name TEXT,
    to_station_id INTEGER,
    to_station_name TEXT,
    usertype TEXT NOT NULL,
    gender TEXT,
    birthyear INTEGER,
    quarter TEXT NOT NULL  -- 'Q1', 'Q2', 'Q3', 'Q4' to track source
);

-- Create indexes on raw data for faster processing
CREATE INDEX idx_trips_raw_usertype ON trips_raw(usertype);
CREATE INDEX idx_trips_raw_start_time ON trips_raw(start_time);
CREATE INDEX idx_trips_raw_quarter ON trips_raw(quarter);

-- ============================================================================
-- CLEAN DATA TABLE
-- ============================================================================
-- This table stores cleaned and transformed data ready for analysis

CREATE TABLE trips_clean (
    trip_id INTEGER PRIMARY KEY,
    start_time TEXT NOT NULL,
    end_time TEXT NOT NULL,
    bikeid INTEGER NOT NULL,
    tripduration REAL NOT NULL,
    from_station_id INTEGER,
    from_station_name TEXT,
    to_station_id INTEGER,
    to_station_name TEXT,
    usertype TEXT NOT NULL,
    member_casual TEXT NOT NULL,  -- Standardized: 'member' or 'casual'
    gender TEXT,
    birthyear INTEGER,
    -- Calculated fields
    ride_length_sec REAL NOT NULL,
    ride_length_min REAL NOT NULL,
    day_of_week INTEGER NOT NULL,  -- 0=Sunday, 1=Monday, ..., 6=Saturday
    day_name TEXT NOT NULL,
    month INTEGER NOT NULL,
    month_name TEXT NOT NULL,
    hour INTEGER NOT NULL,
    year INTEGER NOT NULL,
    date TEXT NOT NULL,
    day_type TEXT NOT NULL,  -- 'Weekend' or 'Weekday'
    quarter TEXT NOT NULL
);

-- Create indexes for faster queries
CREATE INDEX idx_trips_clean_member_casual ON trips_clean(member_casual);
CREATE INDEX idx_trips_clean_day_of_week ON trips_clean(day_of_week);
CREATE INDEX idx_trips_clean_day_type ON trips_clean(day_type);
CREATE INDEX idx_trips_clean_month ON trips_clean(month);
CREATE INDEX idx_trips_clean_hour ON trips_clean(hour);
CREATE INDEX idx_trips_clean_date ON trips_clean(date);
CREATE INDEX idx_trips_clean_from_station ON trips_clean(from_station_name);
CREATE INDEX idx_trips_clean_to_station ON trips_clean(to_station_name);

-- ============================================================================
-- VIEWS FOR ANALYSIS
-- ============================================================================

-- View: Quick summary statistics by user type
CREATE VIEW v_user_type_summary AS
SELECT
    member_casual,
    COUNT(*) as total_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_minutes,
    ROUND(MIN(ride_length_min), 2) as min_ride_minutes,
    ROUND(MAX(ride_length_min), 2) as max_ride_minutes,
    ROUND(AVG(CAST(strftime('%H', start_time) AS REAL)), 2) as avg_start_hour
FROM trips_clean
GROUP BY member_casual;

-- View: Daily patterns by user type
CREATE VIEW v_daily_patterns AS
SELECT
    member_casual,
    day_name,
    day_of_week,
    COUNT(*) as number_of_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
GROUP BY member_casual, day_name, day_of_week
ORDER BY day_of_week, member_casual;

-- View: Monthly patterns by user type
CREATE VIEW v_monthly_patterns AS
SELECT
    member_casual,
    month_name,
    month,
    COUNT(*) as number_of_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
GROUP BY member_casual, month_name, month
ORDER BY month, member_casual;

-- View: Hourly patterns by user type
CREATE VIEW v_hourly_patterns AS
SELECT
    member_casual,
    hour,
    COUNT(*) as number_of_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min
FROM trips_clean
GROUP BY member_casual, hour
ORDER BY hour, member_casual;

-- View: Weekend vs Weekday patterns
CREATE VIEW v_day_type_patterns AS
SELECT
    member_casual,
    day_type,
    COUNT(*) as number_of_rides,
    ROUND(AVG(ride_length_min), 2) as avg_ride_length_min,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY member_casual), 2) as pct_of_user_type
FROM trips_clean
GROUP BY member_casual, day_type
ORDER BY member_casual, day_type;

-- ============================================================================
-- DATA QUALITY FUNCTIONS
-- ============================================================================

-- These are saved as comments since SQLite doesn't support stored procedures
-- Run these queries to check data quality:

/*
-- Check for duplicate trip IDs
SELECT trip_id, COUNT(*) as count
FROM trips_raw
GROUP BY trip_id
HAVING COUNT(*) > 1;

-- Check for missing station information
SELECT
    COUNT(*) as total_missing,
    SUM(CASE WHEN from_station_name IS NULL THEN 1 ELSE 0 END) as missing_from_station,
    SUM(CASE WHEN to_station_name IS NULL THEN 1 ELSE 0 END) as missing_to_station
FROM trips_raw;

-- Check for invalid durations
SELECT
    COUNT(*) as invalid_duration_count,
    MIN(tripduration) as min_duration,
    MAX(tripduration) as max_duration
FROM trips_raw
WHERE tripduration < 60 OR tripduration > 86400;

-- Check for invalid timestamps
SELECT COUNT(*)
FROM trips_raw
WHERE start_time >= end_time;
*/
