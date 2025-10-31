# Cyclistic Bike-Share Analysis - SQL Implementation

This directory contains the complete SQL analysis of the Cyclistic bike-share data using SQLite. This analysis mirrors the R-based analysis but uses SQL for all data processing and analysis tasks.

## Overview

As a junior data analyst on the Cyclistic marketing team, this SQL-based analysis helps answer the key business question:

**"How do annual members and casual riders use Cyclistic bikes differently?"**

## Project Structure

```
sql/
├── README.md                      # This file
├── 01_create_schema.sql          # Database schema and table creation
├── 02_import_data.sql            # Data import from CSV files
├── 03_data_cleaning.sql          # Data cleaning and transformation
├── 04_analysis_queries.sql       # Main analysis queries
├── 05_export_results.sql         # Export results to CSV for visualization
├── 06_data_quality_analysis.sql  # Deep dive into data quality issues
└── run_analysis.sh               # Automated pipeline script
```

## Prerequisites

### Software Requirements
- **SQLite3** (version 3.8.0 or higher)
- Terminal/Command Line access

### Data Requirements
Download the 2019 Divvy trip data from [Divvy Trip Data](https://divvy-tripdata.s3.amazonaws.com/index.html):
- Divvy_Trips_2019_Q1.csv
- Divvy_Trips_2019_Q2.csv
- Divvy_Trips_2019_Q3.csv
- Divvy_Trips_2019_Q4.csv

Place these files in a `data/` directory at the project root:
```
google-data-analytics-capstone-cyclistic-bike/
├── data/
│   ├── Divvy_Trips_2019_Q1.csv
│   ├── Divvy_Trips_2019_Q2.csv
│   ├── Divvy_Trips_2019_Q3.csv
│   ├── Divvy_Trips_2019_Q4.csv
│   └── results/  (will be created for exports)
├── sql/
│   └── ...
```

## Quick Start

### Step 1: Create the Database

```bash
# Navigate to the sql directory
cd sql

# Create a new SQLite database and initialize schema
sqlite3 cyclistic.db < 01_create_schema.sql
```

### Step 2: Import Data

```bash
# Import all quarterly CSV files
sqlite3 cyclistic.db < 02_import_data.sql
```

**Note**: The import script handles the different column naming convention in Q2 data automatically.

### Step 3: Clean and Transform Data

```bash
# Clean data and create analysis-ready dataset
sqlite3 cyclistic.db < 03_data_cleaning.sql
```

This step:
- Removes invalid records (trips < 1 min or > 24 hours)
- Standardizes user types (Subscriber → member, Customer → casual)
- Creates temporal features (day of week, hour, month, etc.)
- Filters out records with invalid timestamps

### Step 4: Run Analysis

```bash
# Run all analysis queries
sqlite3 cyclistic.db < 04_analysis_queries.sql
```

Or run interactively:
```bash
sqlite3 cyclistic.db
sqlite> .read 04_analysis_queries.sql
```

### Step 5: Export Results (Optional)

```bash
# Create results directory
mkdir -p ../data/results

# Export analysis results to CSV files
sqlite3 cyclistic.db < 05_export_results.sql
```

## Analysis Components

### 1. Overview Statistics
- Total rides by user type
- Percentage distribution
- Average, min, max ride lengths

### 2. Temporal Analysis

#### Day of Week Patterns
- Number of rides per day
- Average ride length per day
- Weekend vs weekday behavior

#### Hourly Patterns
- Peak usage hours for each user type
- Commute hour analysis (7-9 AM, 4-7 PM)
- Average ride duration by hour

#### Monthly/Seasonal Patterns
- Seasonal usage trends
- Quarterly comparisons
- Weather impact analysis

### 3. Ride Duration Analysis
- Duration statistics (mean, median, min, max)
- Duration distribution buckets
- Short vs long trip patterns

### 4. Location Analysis
- Top 10 start stations by user type
- Top 10 end stations by user type
- Round trip analysis
- Geographic usage patterns

### 5. Combined Insights
- Weekend afternoon patterns (leisure time)
- Weekday commute patterns
- Behavior differences by context

## Database Schema

### Tables

#### `trips_raw`
Raw imported data from all four quarters. Includes a `quarter` column to track data source.

#### `trips_clean`
Cleaned and transformed data ready for analysis. Includes calculated fields:
- `member_casual`: Standardized user type ('member' or 'casual')
- `ride_length_min`: Trip duration in minutes
- `day_of_week`: Day of week (0=Sunday through 6=Saturday)
- `day_name`: Full day name
- `day_type`: 'Weekend' or 'Weekday'
- `hour`: Hour of day (0-23)
- `month`: Month (1-12)
- `month_name`: Full month name

### Views

Pre-built views for common queries:
- `v_user_type_summary`: Quick statistics by user type
- `v_daily_patterns`: Daily usage patterns
- `v_monthly_patterns`: Monthly usage patterns
- `v_hourly_patterns`: Hourly usage patterns
- `v_day_type_patterns`: Weekend vs weekday patterns

## Running Individual Queries

You can run specific queries interactively:

```bash
sqlite3 cyclistic.db

# Example: Check overview statistics
sqlite> SELECT * FROM v_user_type_summary;

# Example: Get rides by day of week
sqlite> SELECT
   ...>   member_casual,
   ...>   day_name,
   ...>   COUNT(*) as rides
   ...> FROM trips_clean
   ...> GROUP BY member_casual, day_name, day_of_week
   ...> ORDER BY day_of_week;

# Exit
sqlite> .quit
```

## Useful SQLite Commands

```bash
# Show all tables
.tables

# Show schema for a table
.schema trips_clean

# Enable column headers
.headers on

# Change output format
.mode column    # Columnar output
.mode csv       # CSV output
.mode markdown  # Markdown table output

# Execute SQL file
.read 04_analysis_queries.sql

# Export query to CSV
.mode csv
.output results.csv
SELECT * FROM trips_clean LIMIT 100;
.output stdout
```

## Data Cleaning Rules

The following records are excluded during cleaning:

1. **Short trips**: Duration < 60 seconds (< 1 minute)
2. **Long trips**: Duration > 86,400 seconds (> 24 hours)
   - Note: The dataset contains many long-duration trips (some up to 11+ days)
   - These are likely bikes that weren't returned properly or data errors
   - This accounts for ~35% of records being removed
3. **Invalid timestamps**: End time before or equal to start time
4. **Null trip IDs**: Records without a valid trip identifier

**Expected data retention**: ~65% of raw records (2.5M out of 3.8M)

The high removal rate is primarily due to trips over 24 hours. To investigate this further:
```bash
sqlite3 cyclistic.db < 06_data_quality_analysis.sql
```

## Key Findings

Based on the SQL analysis, you should expect to find:

1. **Ride Frequency**: Members take more total rides than casual riders
2. **Ride Duration**: Casual riders take longer trips on average
3. **Day Patterns**: Casual riders peak on weekends; members peak on weekdays
4. **Time Patterns**: Members show commute hour peaks; casual riders peak midday
5. **Locations**: Different popular stations suggest different use cases

## Troubleshooting

### Import Issues

**Problem**: "Error: no such table"
```bash
# Solution: Run schema creation first
sqlite3 cyclistic.db < 01_create_schema.sql
```

**Problem**: "Error: file not found" during import
```bash
# Solution: Check file paths in 02_import_data.sql
# Make sure CSV files are in ../data/ directory
```

### Performance Issues

**Problem**: Queries running slowly
```bash
# Solution: Make sure indexes are created
sqlite3 cyclistic.db "VACUUM; ANALYZE;"
```

## Comparison with R Analysis

This SQL analysis produces the same results as the R-based analysis but with different approaches:

| Aspect | R (Tidyverse) | SQL (SQLite) |
|--------|---------------|--------------|
| Data Import | `read_csv()` | `.import` command |
| Data Cleaning | `filter()`, `mutate()` | `WHERE`, `CASE WHEN` |
| Grouping | `group_by()`, `summarise()` | `GROUP BY` with aggregates |
| Date Functions | `lubridate` package | `strftime()` functions |
| Visualization | `ggplot2` | Export to CSV → external tools |

## Next Steps

After running the SQL analysis:

1. **Export results** using [05_export_results.sql](05_export_results.sql)
2. **Create visualizations** in:
   - Tableau
   - Excel/Google Sheets
   - R (import CSV results)
   - Python (pandas + matplotlib)
3. **Develop recommendations** based on findings
4. **Create presentation** for stakeholders

## License

This analysis uses publicly available data from Divvy, provided by Motivate International Inc. under their [data license agreement](https://www.divvybikes.com/data-license-agreement).

## Contact

For questions about this SQL analysis implementation, refer to the main project README or CLAUDE.md file.
