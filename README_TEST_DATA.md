# MeetSpot Test Data Generation

This document explains how to use the `test_data.sql` script to create test data for the MeetSpot application.

## Overview

The test data script will generate:
- 5 test meet entries with varied attributes (car, bike, mixed types)
- 5 corresponding routes with realistic waypoints and coordinates
- Uses an existing user from your database as the creator (no test user is created)

## Prerequisites

Before running the script:
1. Ensure you have at least one user in your Supabase auth system
2. The script will use the first user it finds as the creator for all test data

## How to Run the Script

### Using Supabase Dashboard

1. Log in to your Supabase dashboard at https://app.supabase.io
2. Select your project
3. Go to the SQL Editor
4. Create a new query
5. Copy the entire contents of the `test_data.sql` file into the editor
6. Click "Run" to execute the script

### Using Command Line (psql)

If you have direct database access with psql:

```bash
# Using psql (replace with your connection details)
psql -h YOUR_SUPABASE_HOST -d postgres -U postgres -f test_data.sql
```

## What Data Is Created

### Meets

The script creates 5 diverse meets:

1. **SF Car Enthusiasts Meetup** - A car meetup in San Francisco
2. **Coastal Highway Ride** - A motorcycle ride along Highway 1
3. **Mountain Drive Adventure** - A mixed vehicles mountain drive (premium)
4. **Luxury & Exotic Car Show** - A premium car show in Los Angeles
5. **Countryside Scenic Drive** - A mixed vehicles scenic drive in Napa Valley

### Routes

Each meet gets a corresponding route:

1. **Downtown SF Explorer** - Urban exploration through San Francisco
2. **Pacific Coast Highway** - Coastal ride along Highway 1
3. **Mount Evans Summit** - Challenging mountain route
4. **LA Luxury Drive** - Tour of luxury spots in Los Angeles
5. **Napa Valley Wine Tour** - Scenic drive through wine country

## Technical Notes

- All meets and routes use realistic coordinates and addresses
- Routes include proper waypoints with different types (start, end, checkpoint, scenic, rest, food)
- Each route is automatically linked to its corresponding meet via the `primary_route_id` field
- JSON data structures match the expected format from the app models
- A test user is created with email `test@example.com` if it doesn't already exist

## Troubleshooting

If you encounter errors:

1. Ensure your Supabase database has the required tables (`users`, `meets`, `routes`)
2. Check that the UUID extension is enabled (`CREATE EXTENSION IF NOT EXISTS "uuid-ossp";`)
3. Verify that your database has the proper foreign key constraints set up
4. If specific inserts fail, you may need to adjust the data format to match your schema
5. For SQL syntax errors with special characters:
   - PostgreSQL uses doubled single quotes to escape apostrophes (e.g., `'John''s Car'`)
   - Do not use backslash escaping for apostrophes as this will cause syntax errors
   - Double quotes (`"`) are used for identifiers (column names, table names) not for string literals
6. Foreign key constraint errors:
   - Ensure you have at least one user in your auth system before running the script
   - If you get an error like "violates foreign key constraint" for the user ID, create a user through Supabase Auth UI first
   - The script cannot create users directly due to Supabase's authentication security model
7. If you receive a notice that "No users found", sign up or create a user through your app or Supabase dashboard first

## Cleaning Up

If you want to remove the test data later, you can run:

```sql
-- WARNING: This will delete ALL test data associated with the first user in your system
-- The exact user ID will be different in your database
DELETE FROM public.routes WHERE creator_id = (SELECT id FROM auth.users LIMIT 1);
DELETE FROM public.meets WHERE organizer_id = (SELECT id FROM auth.users LIMIT 1);
``` 