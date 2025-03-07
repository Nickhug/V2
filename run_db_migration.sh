#!/bin/bash

# MeetSpot Database Migration Script
# This script helps you run the create_routes_table.sql script against your Supabase database

# Instructions:
# 1. Add your Supabase database connection details below
# 2. Make this script executable: chmod +x run_db_migration.sh
# 3. Run the script: ./run_db_migration.sh

# --------------- CONFIGURATION ---------------
# Replace these values with your Supabase database connection details
SUPABASE_DB_HOST="your-supabase-project.supabase.co"
SUPABASE_DB_PORT="5432"
SUPABASE_DB_NAME="postgres" 
SUPABASE_DB_USER="postgres"
SUPABASE_DB_PASSWORD="your-database-password"

# --------------- SCRIPT LOGIC ---------------
echo "MeetSpot Database Migration Script"
echo "=================================="
echo
echo "This script will run the create_routes_table.sql migration against your Supabase database."
echo
echo "Current configuration:"
echo "- Host: $SUPABASE_DB_HOST"
echo "- Port: $SUPABASE_DB_PORT"
echo "- Database: $SUPABASE_DB_NAME"
echo "- User: $SUPABASE_DB_USER"
echo
echo "Make sure you've updated this script with your actual Supabase credentials before proceeding."
echo

read -p "Continue with migration? (y/n): " confirm
if [[ $confirm != "y" && $confirm != "Y" ]]; then
    echo "Migration cancelled."
    exit 0
fi

echo "Running migration..."

# Run the SQL script against the database
PGPASSWORD=$SUPABASE_DB_PASSWORD psql -h $SUPABASE_DB_HOST -p $SUPABASE_DB_PORT -d $SUPABASE_DB_NAME -U $SUPABASE_DB_USER -f create_routes_table.sql

if [ $? -eq 0 ]; then
    echo "Migration completed successfully!"
    echo "The routes table has been created in your database."
    echo
    echo "You can now restart your app and the 'public.routes' relation error should be resolved."
else
    echo "Migration failed. Please check your connection details and try again."
    echo "If the problem persists, you may need to manually run the SQL from the Supabase dashboard."
fi

# Alternative instructions for using the Supabase dashboard
echo
echo "Alternatively, you can run the migration manually:"
echo "1. Go to your Supabase project dashboard"
echo "2. Click on 'SQL Editor'"
echo "3. Create a new query"
echo "4. Copy and paste the contents of create_routes_table.sql"
echo "5. Run the query"
echo
echo "This will create the necessary 'routes' table in your database." 