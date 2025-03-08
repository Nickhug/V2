-- Comprehensive database fix for MeetSpot application
-- This script fixes both the missing tables and date formatting issues

-- ============================================
-- Create meet_participants table
-- ============================================
CREATE TABLE IF NOT EXISTS public.meet_participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meet_id UUID NOT NULL REFERENCES public.meets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vehicle_id UUID NOT NULL REFERENCES public.vehicles(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(meet_id, user_id)
);

-- Create indexes for meet_participants
CREATE INDEX IF NOT EXISTS meet_participants_meet_id_idx ON public.meet_participants(meet_id);
CREATE INDEX IF NOT EXISTS meet_participants_user_id_idx ON public.meet_participants(user_id);
CREATE INDEX IF NOT EXISTS meet_participants_vehicle_id_idx ON public.meet_participants(vehicle_id);

-- Enable Row Level Security for meet_participants
ALTER TABLE public.meet_participants ENABLE ROW LEVEL SECURITY;

-- Create policies for meet_participants
CREATE POLICY "Users can read all meet participants" ON public.meet_participants
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own participation" ON public.meet_participants
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own participation" ON public.meet_participants
    FOR DELETE USING (auth.uid() = user_id);

-- Grant permissions for meet_participants
GRANT ALL ON public.meet_participants TO authenticated;

-- ============================================
-- Create or fix routes table
-- ============================================
-- Create the routes table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.routes (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  meet_id uuid REFERENCES meets (id) NULL,
  creator_id uuid NOT NULL,
  title text NOT NULL,
  description text,
  route_data jsonb NOT NULL, -- Stores route coordinates, waypoints, etc.
  distance numeric DEFAULT 0,
  estimated_time integer DEFAULT 0, -- in minutes
  difficulty text DEFAULT 'moderate', -- 'easy', 'moderate', 'challenging'
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now()
);

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS routes_creator_id_idx ON public.routes (creator_id);
CREATE INDEX IF NOT EXISTS routes_meet_id_idx ON public.routes (meet_id);

-- Enable Row-Level Security
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

-- Create policies for routes
-- Policy for viewing public routes
CREATE POLICY IF NOT EXISTS route_select_policy ON public.routes
    FOR SELECT USING (true);

-- Policy for inserting/updating routes (only your own)
CREATE POLICY IF NOT EXISTS route_insert_policy ON public.routes
    FOR INSERT WITH CHECK (creator_id::text = auth.uid()::text);

CREATE POLICY IF NOT EXISTS route_update_policy ON public.routes
    FOR UPDATE USING (creator_id::text = auth.uid()::text);

-- Policy for deleting routes (only your own)
CREATE POLICY IF NOT EXISTS route_delete_policy ON public.routes
    FOR DELETE USING (creator_id::text = auth.uid()::text);

-- Fix date formatting in the routes table
UPDATE public.routes
SET created_at = created_at::timestamp at time zone 'UTC',
    updated_at = COALESCE(updated_at, now())::timestamp at time zone 'UTC';

-- ============================================
-- Verify database structure
-- ============================================
-- Just to verify that tables were created
SELECT 'Tables successfully created/fixed: ' || array_to_string(array_agg(table_name), ', ') as result
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN ('meet_participants', 'routes'); 