-- Create user_activities table
CREATE TABLE IF NOT EXISTS public.user_activities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create followers table
CREATE TABLE IF NOT EXISTS public.followers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id UUID NOT NULL REFERENCES auth.users(id),
    following_id UUID NOT NULL REFERENCES auth.users(id),
    status TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(follower_id, following_id)
);

-- Create achievements table
CREATE TABLE IF NOT EXISTS public.achievements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id),
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    icon TEXT NOT NULL,
    earned_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create indexes
CREATE INDEX IF NOT EXISTS user_activities_user_id_idx ON public.user_activities(user_id);
CREATE INDEX IF NOT EXISTS user_activities_timestamp_idx ON public.user_activities(timestamp);
CREATE INDEX IF NOT EXISTS followers_follower_id_idx ON public.followers(follower_id);
CREATE INDEX IF NOT EXISTS followers_following_id_idx ON public.followers(following_id);
CREATE INDEX IF NOT EXISTS achievements_user_id_idx ON public.achievements(user_id);

-- Enable Row Level Security
ALTER TABLE public.user_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.achievements ENABLE ROW LEVEL SECURITY;

-- Create policies for user_activities
CREATE POLICY "Users can read own activities" ON public.user_activities
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own activities" ON public.user_activities
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create policies for followers
CREATE POLICY "Users can read own followers" ON public.followers
    FOR SELECT USING (auth.uid() = follower_id OR auth.uid() = following_id);

CREATE POLICY "Users can insert own follow requests" ON public.followers
    FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can update own follow requests" ON public.followers
    FOR UPDATE USING (auth.uid() = following_id);

-- Create policies for achievements
CREATE POLICY "Users can read own achievements" ON public.achievements
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own achievements" ON public.achievements
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Grant necessary permissions
GRANT ALL ON public.user_activities TO authenticated;
GRANT ALL ON public.followers TO authenticated;
GRANT ALL ON public.achievements TO authenticated; 