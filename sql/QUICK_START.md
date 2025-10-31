# Quick Start Guide - SQL Analysis

## One-Command Complete Analysis

```bash
cd sql
./run_analysis.sh
```

That's it! The script will automatically:
1. Check prerequisites ✓
2. Create database ✓
3. Import 3.8M records ✓
4. Clean data ✓
5. Run all analyses ✓
6. Export results ✓

**Time:** ~5-10 minutes total

## Individual Commands

If you want to run steps separately:

```bash
# 1. Create database and schema
sqlite3 cyclistic.db < 01_create_schema.sql

# 2. Import CSV data
sqlite3 cyclistic.db < 02_import_data.sql

# 3. Clean and transform
sqlite3 cyclistic.db < 03_data_cleaning.sql

# 4. Run analysis
sqlite3 cyclistic.db < 04_analysis_queries.sql

# 5. Export results (optional)
mkdir -p ../data/results
sqlite3 cyclistic.db < 05_export_results.sql

# 6. Data quality check (optional)
sqlite3 cyclistic.db < 06_data_quality_analysis.sql
```

## Interactive Queries

```bash
# Open database interactively
sqlite3 cyclistic.db

# Run specific queries
sqlite> SELECT * FROM v_user_type_summary;
sqlite> SELECT member_casual, COUNT(*) FROM trips_clean GROUP BY member_casual;
sqlite> .exit
```

## Common Tasks

### View Analysis Results
```bash
# Latest results file
cat analysis_results_*.txt | less
```

### Check Database Status
```bash
sqlite3 cyclistic.db "
SELECT
    'Raw Records' as table_name, COUNT(*) as count FROM trips_raw
UNION ALL
SELECT 'Clean Records', COUNT(*) FROM trips_clean;
"
```

### Quick Stats
```bash
sqlite3 cyclistic.db "SELECT * FROM v_user_type_summary;" -header -column
```

### Export Specific Query
```bash
sqlite3 cyclistic.db -csv -header \
  "SELECT * FROM v_daily_patterns" > daily_patterns.csv
```

## Troubleshooting

### Error: Database is locked
```bash
# Kill any existing connections
killall sqlite3
```

### Error: File not found
```bash
# Make sure you're in the sql/ directory
pwd
# Should show: .../google-data-analytics-capstone-cyclistic-bike/sql
```

### Error: CSV files missing
```bash
# Check if data files exist
ls -lh ../data/Divvy_Trips_2019_*.csv
# If not, download from: https://divvy-tripdata.s3.amazonaws.com/index.html
```

### Start Fresh
```bash
# Remove database and start over
rm cyclistic.db
./run_analysis.sh
```

## Output Files

After running the analysis, you'll have:

```
sql/
├── cyclistic.db                      # SQLite database (~1.5 GB)
├── analysis_results_[timestamp].txt  # Analysis output
└── test_output.txt                   # Latest test run

data/results/ (after export)
├── daily_patterns.csv
├── hourly_patterns.csv
├── monthly_patterns.csv
├── day_type_patterns.csv
├── top_start_stations.csv
├── duration_distribution.csv
├── summary_statistics.csv
└── daily_rides.csv
```

## SQLite Useful Commands

```sql
-- Show all tables
.tables

-- Show table structure
.schema trips_clean

-- Show indexes
.indexes

-- Enable headers and column mode
.headers on
.mode column

-- Output to CSV
.mode csv
.output myfile.csv
SELECT * FROM trips_clean LIMIT 100;
.output stdout

-- Show query execution time
.timer on

-- Get database info
.dbinfo

-- Backup database
.backup cyclistic_backup.db
```

## Quick Analysis Examples

### Compare Weekend vs Weekday
```sql
SELECT
    member_casual,
    day_type,
    COUNT(*) as rides,
    ROUND(AVG(ride_length_min), 2) as avg_minutes
FROM trips_clean
GROUP BY member_casual, day_type;
```

### Find Peak Hours
```sql
SELECT
    hour,
    COUNT(*) as total_rides
FROM trips_clean
GROUP BY hour
ORDER BY total_rides DESC
LIMIT 5;
```

### Top Stations for Casual Riders
```sql
SELECT
    from_station_name,
    COUNT(*) as rides
FROM trips_clean
WHERE member_casual = 'casual'
  AND from_station_name IS NOT NULL
GROUP BY from_station_name
ORDER BY rides DESC
LIMIT 10;
```

## Data Quality Check

```bash
# Run comprehensive data quality analysis
sqlite3 cyclistic.db < 06_data_quality_analysis.sql
```

This will show:
- Duration outliers
- Missing data patterns
- Timestamp anomalies
- Station statistics
- Why records were removed

## Performance Tips

```sql
-- Run these if queries are slow
ANALYZE;
VACUUM;

-- Check query plan
EXPLAIN QUERY PLAN SELECT * FROM trips_clean WHERE member_casual = 'casual';
```

## Get Help

- Full documentation: [README.md](README.md)
- Implementation notes: [NOTES.md](NOTES.md)
- Main project README: [../README.md](../README.md)
- Claude Code guidance: [../CLAUDE.md](../CLAUDE.md)

## Estimated Time Requirements

| Task | Time |
|------|------|
| Complete automated run | 5-10 min |
| Database creation | < 10 sec |
| Data import | 2-3 min |
| Data cleaning | 1-2 min |
| Run analyses | < 10 sec |
| Export results | < 30 sec |
| Interactive queries | Instant |

---

**Need to start fresh?**
```bash
rm cyclistic.db analysis_results_*.txt test_output.txt
./run_analysis.sh
```

**Ready to visualize?**
```bash
sqlite3 cyclistic.db < 05_export_results.sql
# Import CSV files from ../data/results/ into Tableau, Excel, or R
```
