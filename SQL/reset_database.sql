-- Script to reset the database completely
-- WARNING: This will DELETE ALL DATA

-- Drop all tables
DROP TABLE IF EXISTS public.meet_attendees CASCADE;
DROP TABLE IF EXISTS public.route_points CASCADE;
DROP TABLE IF EXISTS public.routes CASCADE;
DROP TABLE IF EXISTS public.meets CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;

-- Install required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Run the creation scripts
\i create_users.sql
\i create_meets.sql
\i create_meet_attendees.sql
\i create_routes.sql
\i create_route_points.sql
\i create_notifications.sql 