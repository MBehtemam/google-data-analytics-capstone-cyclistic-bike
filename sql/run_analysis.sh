#!/bin/bash

# ============================================================================
# Cyclistic Bike-Share Analysis - Complete SQL Pipeline
# ============================================================================
# Purpose: Run the complete SQL analysis pipeline from start to finish
# Usage: ./run_analysis.sh
# ============================================================================

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Database file
DB_FILE="cyclistic.db"

echo -e "${BLUE}============================================================================${NC}"
echo -e "${BLUE}  Cyclistic Bike-Share Analysis - SQL Pipeline${NC}"
echo -e "${BLUE}============================================================================${NC}"
echo ""

# ============================================================================
# Step 1: Check Prerequisites
# ============================================================================

echo -e "${YELLOW}[1/6] Checking prerequisites...${NC}"

# Check if SQLite3 is installed
if ! command -v sqlite3 &> /dev/null; then
    echo -e "${RED}Error: SQLite3 is not installed.${NC}"
    echo "Please install SQLite3 first:"
    echo "  - macOS: brew install sqlite3"
    echo "  - Ubuntu/Debian: sudo apt-get install sqlite3"
    exit 1
fi

# Check SQLite version
SQLITE_VERSION=$(sqlite3 --version | awk '{print $1}')
echo -e "${GREEN}✓ SQLite3 found (version ${SQLITE_VERSION})${NC}"

# Check if data directory exists
if [ ! -d "../data" ]; then
    echo -e "${YELLOW}Warning: ../data directory not found. Creating it...${NC}"
    mkdir -p ../data
    echo -e "${RED}Please download the following files to ../data/:${NC}"
    echo "  - Divvy_Trips_2019_Q1.csv"
    echo "  - Divvy_Trips_2019_Q2.csv"
    echo "  - Divvy_Trips_2019_Q3.csv"
    echo "  - Divvy_Trips_2019_Q4.csv"
    echo ""
    echo "Download from: https://divvy-tripdata.s3.amazonaws.com/index.html"
    exit 1
fi

# Check if CSV files exist
MISSING_FILES=0
for quarter in Q1 Q2 Q3 Q4; do
    if [ ! -f "../data/Divvy_Trips_2019_${quarter}.csv" ]; then
        echo -e "${RED}Missing: ../data/Divvy_Trips_2019_${quarter}.csv${NC}"
        MISSING_FILES=1
    else
        FILE_SIZE=$(du -h "../data/Divvy_Trips_2019_${quarter}.csv" | cut -f1)
        echo -e "${GREEN}✓ Found Divvy_Trips_2019_${quarter}.csv (${FILE_SIZE})${NC}"
    fi
done

if [ $MISSING_FILES -eq 1 ]; then
    echo -e "${RED}Error: Missing required data files.${NC}"
    echo "Download from: https://divvy-tripdata.s3.amazonaws.com/index.html"
    exit 1
fi

echo ""

# ============================================================================
# Step 2: Create Database Schema
# ============================================================================

echo -e "${YELLOW}[2/6] Creating database schema...${NC}"

# Remove existing database if it exists
if [ -f "$DB_FILE" ]; then
    echo -e "${YELLOW}Removing existing database...${NC}"
    rm "$DB_FILE"
fi

# Create schema
sqlite3 "$DB_FILE" < 01_create_schema.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database schema created successfully${NC}"
else
    echo -e "${RED}Error creating database schema${NC}"
    exit 1
fi

echo ""

# ============================================================================
# Step 3: Import Data
# ============================================================================

echo -e "${YELLOW}[3/6] Importing data from CSV files...${NC}"
echo -e "${BLUE}This may take several minutes...${NC}"

sqlite3 "$DB_FILE" < 02_import_data.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Data imported successfully${NC}"

    # Show import statistics
    TOTAL_ROWS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM trips_raw;")
    echo -e "${GREEN}  Total records imported: ${TOTAL_ROWS}${NC}"
else
    echo -e "${RED}Error importing data${NC}"
    exit 1
fi

echo ""

# ============================================================================
# Step 4: Clean and Transform Data
# ============================================================================

echo -e "${YELLOW}[4/6] Cleaning and transforming data...${NC}"

sqlite3 "$DB_FILE" < 03_data_cleaning.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Data cleaned successfully${NC}"

    # Show cleaning statistics
    CLEAN_ROWS=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM trips_clean;")
    REMOVED=$((TOTAL_ROWS - CLEAN_ROWS))
    RETENTION=$(sqlite3 "$DB_FILE" "SELECT ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM trips_raw), 2) FROM trips_clean;")

    echo -e "${GREEN}  Clean records: ${CLEAN_ROWS}${NC}"
    echo -e "${GREEN}  Records removed: ${REMOVED}${NC}"
    echo -e "${GREEN}  Retention rate: ${RETENTION}%${NC}"
else
    echo -e "${RED}Error cleaning data${NC}"
    exit 1
fi

echo ""

# ============================================================================
# Step 5: Run Analysis
# ============================================================================

echo -e "${YELLOW}[5/6] Running analysis queries...${NC}"

# Run analysis and save to file
ANALYSIS_OUTPUT="analysis_results_$(date +%Y%m%d_%H%M%S).txt"
sqlite3 "$DB_FILE" < 04_analysis_queries.sql > "$ANALYSIS_OUTPUT"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Analysis completed successfully${NC}"
    echo -e "${GREEN}  Results saved to: ${ANALYSIS_OUTPUT}${NC}"
else
    echo -e "${RED}Error running analysis${NC}"
    exit 1
fi

echo ""

# ============================================================================
# Step 6: Export Results (Optional)
# ============================================================================

echo -e "${YELLOW}[6/6] Exporting results to CSV files...${NC}"

# Create results directory
mkdir -p ../data/results

# Run export script
sqlite3 "$DB_FILE" < 05_export_results.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Results exported successfully${NC}"
    echo -e "${GREEN}  Files saved to: ../data/results/${NC}"

    # List exported files
    echo -e "${BLUE}  Exported files:${NC}"
    ls -lh ../data/results/*.csv 2>/dev/null | awk '{print "    - " $9 " (" $5 ")"}'
else
    echo -e "${YELLOW}Warning: Some exports may have failed${NC}"
fi

echo ""

# ============================================================================
# Completion
# ============================================================================

echo -e "${GREEN}============================================================================${NC}"
echo -e "${GREEN}  Analysis Pipeline Completed Successfully!${NC}"
echo -e "${GREEN}============================================================================${NC}"
echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Review analysis results: ${ANALYSIS_OUTPUT}"
echo "  2. Create visualizations from CSV exports in ../data/results/"
echo "  3. Develop recommendations based on findings"
echo ""
echo -e "${BLUE}Database Location:${NC}"
echo "  ${DB_FILE} ($(du -h "$DB_FILE" | cut -f1))"
echo ""
echo -e "${BLUE}Interactive Mode:${NC}"
echo "  sqlite3 ${DB_FILE}"
echo ""

# Show quick statistics
echo -e "${BLUE}Quick Statistics:${NC}"
sqlite3 "$DB_FILE" "SELECT member_casual as 'User Type', COUNT(*) as 'Total Rides', ROUND(AVG(ride_length_min), 2) as 'Avg Ride (min)' FROM trips_clean GROUP BY member_casual;" -header -column

echo ""
echo -e "${GREEN}Analysis complete! 🎉${NC}"
