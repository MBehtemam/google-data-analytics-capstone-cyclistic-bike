# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Google Data Analytics Professional Certificate capstone project analyzing bike-share usage data from Cyclistic (using real Divvy bike-share data from Chicago). The goal is to identify behavioral differences between casual riders and annual members to inform marketing strategies for converting casual riders into members.

**Business Question**: How do annual members and casual riders use Cyclistic bikes differently?

## Project Structure

This repository contains an R-based data analysis workflow following the six-step data analysis process:
1. **Ask** - Define the business question
2. **Prepare** - Collect and organize data
3. **Process** - Clean and transform data
4. **Analyze** - Identify patterns and insights
5. **Share** - Create visualizations and present findings
6. **Act** - Develop actionable recommendations

## Key Files

- **[divvy-cyclistic-bike-trip-data-analysis-with-r.r](divvy-cyclistic-bike-trip-data-analysis-with-r.r)**: The main analysis file. Note that despite the `.r` extension, this is actually a Jupyter notebook exported as JSON from Kaggle. It contains both markdown documentation and R code cells.
- **[README.md](README.md)**: Project overview and objectives

## Data Architecture

### Data Source
- **Provider**: Divvy/Motivate International Inc. (publicly available)
- **Period**: 2019 Q1-Q4 (four quarterly CSV files)
- **Size**: ~3.8 million total trip records
  - Q1: 365,069 rows (~50 MB)
  - Q2: 1,108,163 rows (~153 MB)
  - Q3: 1,640,718 rows (~225 MB)
  - Q4: 704,054 rows (~97 MB)

### Data Schema

**Q1, Q3, Q4 columns:**
- `trip_id`: Unique trip identifier
- `start_time`, `end_time`: Trip timestamps
- `bikeid`: Bike identifier
- `tripduration`: Trip duration in seconds
- `from_station_id`, `from_station_name`: Starting station
- `to_station_id`, `to_station_name`: Ending station
- `usertype`: "Subscriber" (annual member) or "Customer" (casual rider)
- `gender`: Rider gender
- `birthyear`: Birth year

**Q2 columns** (different naming convention):
- `01 - Rental Details Rental ID` → maps to `trip_id`
- `01 - Rental Details Local Start Time` → maps to `start_time`
- `01 - Rental Details Local End Time` → maps to `end_time`
- `01 - Rental Details Bike ID` → maps to `bikeid`
- `01 - Rental Details Duration In Seconds Uncapped` → maps to `tripduration`
- `03 - Rental Start Station ID` → maps to `from_station_id`
- `03 - Rental Start Station Name` → maps to `from_station_name`
- `02 - Rental End Station ID` → maps to `to_station_id`
- `02 - Rental End Station Name` → maps to `to_station_name`
- `User Type` → maps to `usertype`
- `Member Gender` → maps to `gender`
- `05 - Member Details Member Birthday Year` → maps to `birthyear`

**Critical Note**: Q2 data requires column renaming before merging with other quarters.

### Key Data Terminology
- **Subscriber** = Annual member (target user type)
- **Customer** = Casual rider (single-ride or full-day pass users)

## Technology Stack

### Core Tools
- **R** (version compatible with tidyverse 2.0.0)
- **Tidyverse packages**:
  - `dplyr` - Data manipulation
  - `tidyr` - Data tidying
  - `readr` - Data import
  - `ggplot2` - Visualization
  - `lubridate` - Date/time handling
  - `stringr` - String manipulation
- **conflicted** - Package conflict resolution

### Execution Environment
The analysis was originally developed and run on Kaggle notebooks, which explains:
- File paths like `/kaggle/input/trip-data/`
- The notebook JSON format with execution metadata
- Pre-installed R packages in the Kaggle environment

## Development Workflow

### Working with the Notebook File

Since [divvy-cyclistic-bike-trip-data-analysis-with-r.r](divvy-cyclistic-bike-trip-data-analysis-with-r.r) is a JSON-formatted Jupyter notebook:
- **To view/edit**: Convert to `.ipynb` or open in a JSON editor
- **To run locally**: Either convert to `.ipynb` or extract R code from the JSON `source` fields
- **To extract R code**: Parse the JSON and concatenate code cell sources

### Data Processing Pipeline

The analysis follows this sequence:
1. **Library Setup**: Install and load tidyverse, conflicted packages
2. **Data Import**: Read four quarterly CSV files
3. **Data Inspection**: Use `str()` to verify structure
4. **Column Standardization**: Rename Q2 columns to match Q1/Q3/Q4
5. **Data Merging**: Combine all quarters into a single dataset
6. **Data Cleaning**: Handle missing values, duplicates, outliers
7. **Feature Engineering**: Extract temporal features (day of week, hour, season)
8. **Analysis**: Compare Subscriber vs Customer behavior across:
   - Temporal patterns (when they ride)
   - Duration patterns (how long they ride)
   - Frequency patterns (how often they ride)
   - Location patterns (where they ride)
9. **Visualization**: Create plots using ggplot2
10. **Recommendations**: Develop actionable insights

### Data Quality Considerations

Known issues to address during processing:
- **Inconsistent column names** between Q2 and other quarters
- **Missing values** in gender and birthyear (especially for Customer records)
- **Outliers** in trip duration (extremely short or long trips)
- **Invalid timestamps** (trips where end_time < start_time)
- **Missing station information** for some trips

## Running the Analysis

### If Using Kaggle
1. Upload the notebook JSON to Kaggle
2. Ensure Divvy 2019 trip data is available as input
3. Run all cells sequentially

### If Running Locally with R
```r
# Install required packages
install.packages("tidyverse")
install.packages("conflicted")

# Load libraries
library(tidyverse)
library(conflicted)

# Set conflict preferences
conflict_prefer("filter", "dplyr")
conflict_prefer("lag", "dplyr")

# Import data (adjust paths to local data files)
q1_2019 <- read_csv("path/to/Divvy_Trips_2019_Q1.csv")
q2_2019 <- read_csv("path/to/Divvy_Trips_2019_Q2.csv")
q3_2019 <- read_csv("path/to/Divvy_Trips_2019_Q3.csv")
q4_2019 <- read_csv("path/to/Divvy_Trips_2019_Q4.csv")

# Continue with analysis...
```

## Key Analysis Questions

The analysis investigates four main areas:

1. **Temporal Patterns**: Day of week, time of day, seasonal differences
2. **Ride Duration**: Average trip length, distribution differences
3. **Frequency & Volume**: Total rides, percentage split, temporal frequency
4. **Location Patterns**: Popular stations, geographic patterns (tourist vs residential)

## Important Conventions

### Code Style
- Uses tidyverse conventions (pipe operator `%>%`)
- Uses conflict resolution for `filter()` and `lag()` functions
- Column names use snake_case in standardized data

### Data Privacy
- No personally identifiable information (PII) in dataset
- Cannot track individual casual riders across trips
- Cannot connect rides to specific addresses or payment methods
- Analysis focuses on aggregate behavioral patterns

## SQL Analysis

The README mentions an SQL analysis component using SQLite that is in progress. This may involve:
- Importing the cleaned R dataset into SQLite
- Running SQL queries for analysis
- Comparing SQL-based insights with R-based findings
