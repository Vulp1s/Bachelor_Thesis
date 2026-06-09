#!/bin/bash

# Check if a query file was provided as an argument
if [ -z "$1" ]; then
  echo "Usage: ./run_codeql.sh <query_file.ql>"
  exit 1
fi

# Define the database path
DB_PATH="/home/till/thesis/hantro-db"
# Dynamically name the output CSV based on the query name
OUTPUT_CSV="${1%.ql}.csv"
BQRS_FILE="temp_results.bqrs"

echo "Running query: $1 on database $DB_PATH..."

# 1. Run the query and output to a temporary BQRS file
codeql query run "$1" --database="$DB_PATH" --output="$BQRS_FILE" --ram=6144

echo "Decoding results to $OUTPUT_CSV..."

# 2. Decode the BQRS file directly into a CSV
codeql bqrs decode "$BQRS_FILE" --format=csv --output="$OUTPUT_CSV"

# 3. Clean up the temporary binary file
rm "$BQRS_FILE"

echo "Done! Results saved in $OUTPUT_CSV"
