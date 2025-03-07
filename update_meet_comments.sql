-- Add the replies column to the meet_comments table
ALTER TABLE public.meet_comments ADD COLUMN IF NOT EXISTS replies JSONB DEFAULT '[]'::jsonb;

-- Create an index on the replies column for better performance
CREATE INDEX IF NOT EXISTS idx_meet_comments_replies ON public.meet_comments USING GIN (replies);

-- Add the timestamp column to the meet_comments table
ALTER TABLE public.meet_comments ADD COLUMN IF NOT EXISTS timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- Create an index on the timestamp column for better performance
CREATE INDEX IF NOT EXISTS idx_meet_comments_timestamp ON public.meet_comments (timestamp);

-- Add the meet_id column with foreign key constraint
ALTER TABLE public.meet_comments ADD COLUMN IF NOT EXISTS meet_id UUID NOT NULL REFERENCES public.meets(id) ON DELETE CASCADE;

-- Create an index on the meet_id column for better performance
CREATE INDEX IF NOT EXISTS idx_meet_comments_meet_id ON public.meet_comments (meet_id); 