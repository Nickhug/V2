-- Add vehicle_type and route_type columns to the meets table if they don't exist
ALTER TABLE meets 
ADD COLUMN IF NOT EXISTS vehicle_type TEXT DEFAULT 'car',
ADD COLUMN IF NOT EXISTS route_type TEXT DEFAULT 'city';

-- Update existing records to have default values
UPDATE meets 
SET vehicle_type = 'car', route_type = 'city'
WHERE vehicle_type IS NULL OR route_type IS NULL;

-- Add primary_route_id column if it doesn't exist (without foreign key constraint)
ALTER TABLE meets
ADD COLUMN IF NOT EXISTS primary_route_id UUID NULL;

-- Note: If you need to add a foreign key constraint later when the routes table exists, use:
-- ALTER TABLE meets ADD CONSTRAINT fk_meets_routes FOREIGN KEY (primary_route_id) REFERENCES routes(id); 