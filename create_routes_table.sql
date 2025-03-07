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
  updated_at timestamp with time zone
);

-- Create an index for improved query performance
CREATE INDEX IF NOT EXISTS routes_creator_id_idx ON public.routes (creator_id);
CREATE INDEX IF NOT EXISTS routes_meet_id_idx ON public.routes (meet_id);

-- Enable Row-Level Security
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Policy for viewing public routes
CREATE POLICY route_select_policy ON public.routes
    FOR SELECT USING (true);

-- Policy for inserting/updating routes (only your own)
CREATE POLICY route_insert_policy ON public.routes
    FOR INSERT WITH CHECK (creator_id::text = auth.uid()::text);

CREATE POLICY route_update_policy ON public.routes
    FOR UPDATE USING (creator_id::text = auth.uid()::text);

-- Policy for deleting routes (only your own)
CREATE POLICY route_delete_policy ON public.routes
    FOR DELETE USING (creator_id::text = auth.uid()::text);

-- Now add the foreign key constraint to meets table if it doesn't exist
ALTER TABLE meets
ADD CONSTRAINT IF NOT EXISTS fk_meets_routes 
FOREIGN KEY (primary_route_id) 
REFERENCES routes(id) 
ON DELETE SET NULL; 