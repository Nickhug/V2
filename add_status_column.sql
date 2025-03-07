-- Migration script to add status column to meets table
-- This enables tracking of meet lifecycle stages

-- Add status column with DEFAULT value and constraints
ALTER TABLE public.meets 
ADD COLUMN status text NOT NULL DEFAULT 'upcoming'::text;

-- Add check constraint to ensure valid status values
ALTER TABLE public.meets
ADD CONSTRAINT meets_status_check 
CHECK (status IN ('upcoming', 'active', 'completed', 'canceled'));

-- Update existing records to have 'upcoming' status if date is in the future,
-- 'completed' if date is in the past
UPDATE public.meets
SET status = CASE 
    WHEN date > NOW() THEN 'upcoming'
    ELSE 'completed'
    END;

-- Create index on status column for faster filtering
CREATE INDEX idx_meets_status ON public.meets(status);

-- Add comment to column for documentation
COMMENT ON COLUMN public.meets.status IS 'Current status of the meet: upcoming, active, completed, or canceled'; 