#!/bin/bash

# Check if a query file was provided as an argument
if [ -z "$1" ]; then
  echo "Usage: ./run_codeql.sh <query_file.ql>"
  exit 1
fi

# Define the database path
DB_PATH="/home/till/thesis/hantro-core-kernel-db"

# Run the CodeQL command
echo "Running query: $1 on database $DB_PATH..."
codeql query run "$1" --database="$DB_PATH" --ram=6144
