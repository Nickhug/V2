-- Ensure the achievements table exists with the correct structure
CREATE TABLE IF NOT EXISTS public.achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT NOT NULL,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT (now() AT TIME ZONE 'utc')
);

-- Update the users table to ensure it has an achievements column if not already present
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'users' 
        AND column_name = 'achievements'
    ) THEN
        ALTER TABLE public.users ADD COLUMN achievements JSONB NOT NULL DEFAULT '[]'::jsonb;
    END IF;
END
$$;

-- Create user_activities table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.user_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT (now() AT TIME ZONE 'utc'),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT (now() AT TIME ZONE 'utc')
);

-- Add indexes for better query performance
CREATE INDEX IF NOT EXISTS achievements_user_id_idx ON public.achievements (user_id);
CREATE INDEX IF NOT EXISTS achievements_type_idx ON public.achievements (type);
CREATE INDEX IF NOT EXISTS achievements_earned_at_idx ON public.achievements (earned_at);

CREATE INDEX IF NOT EXISTS user_activities_user_id_idx ON public.user_activities (user_id);
CREATE INDEX IF NOT EXISTS user_activities_type_idx ON public.user_activities (type);
CREATE INDEX IF NOT EXISTS user_activities_timestamp_idx ON public.user_activities (timestamp);

-- Set up proper Row Level Security (RLS) policies
-- Enable RLS on achievements table
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

-- Create policies for achievements table
DROP POLICY IF EXISTS "Users can view their own achievements" ON public.achievements;
CREATE POLICY "Users can view their own achievements" ON public.achievements 
    FOR SELECT 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own achievements" ON public.achievements;
CREATE POLICY "Users can insert their own achievements" ON public.achievements 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own achievements" ON public.achievements;
CREATE POLICY "Users can update their own achievements" ON public.achievements 
    FOR UPDATE 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service can manage all achievements" ON public.achievements;
CREATE POLICY "Service can manage all achievements" ON public.achievements 
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Enable RLS on user_activities table
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;

-- Create policies for user_activities table
DROP POLICY IF EXISTS "Users can view their own activities" ON public.user_activities;
CREATE POLICY "Users can view their own activities" ON public.user_activities 
    FOR SELECT 
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own activities" ON public.user_activities;
CREATE POLICY "Users can insert their own activities" ON public.user_activities 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service can manage all activities" ON public.user_activities;
CREATE POLICY "Service can manage all activities" ON public.user_activities 
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Create a trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = (now() AT TIME ZONE 'utc');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to achievements table
DROP TRIGGER IF EXISTS update_achievements_updated_at ON public.achievements;
CREATE TRIGGER update_achievements_updated_at
BEFORE UPDATE ON public.achievements
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to user_activities table
DROP TRIGGER IF EXISTS update_user_activities_updated_at ON public.user_activities;
CREATE TRIGGER update_user_activities_updated_at
BEFORE UPDATE ON public.user_activities
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Grant appropriate permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON public.achievements TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_activities TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.achievements_id_seq TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE public.user_activities_id_seq TO authenticated; 