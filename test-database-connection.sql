-- Test script to verify MCP connection with Supabase

-- List all tables in the public schema
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- Examine RLS policies (if any)
SELECT * FROM pg_policies;

-- Check table columns for a few key tables
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'meets', 'vehicles')
ORDER BY table_name, ordinal_position; 