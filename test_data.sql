-- Test Data Generation Script for MeetSpot Application
-- Creates 5 test meets and 5 test routes with realistic data for testing

-- First, ensure we have the uuid extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Find an existing user to use as creator instead of creating one
DO $$
DECLARE
    test_user_id uuid;
BEGIN
    -- Try to find any existing user in the system
    SELECT id INTO test_user_id FROM auth.users LIMIT 1;
    
    -- If no users found, raise a notice
    IF test_user_id IS NULL THEN
        RAISE NOTICE 'No users found in the database. Please create a user through Supabase authentication first.';
        -- Assign a placeholder ID that will be replaced when test data is adjusted
        test_user_id := uuid_generate_v4();
    ELSE
        RAISE NOTICE 'Using existing user with ID: %', test_user_id;
    END IF;
    
    -- Store the user ID for future use
    PERFORM set_config('app.test_user_id', test_user_id::text, false);
END
$$;

-- Create 5 test meets with varied attributes
INSERT INTO public.meets (
    id,
    title,
    description,
    date,
    location,
    address,
    type,
    cover_image,
    rules,
    tags,
    is_premium,
    capacity,
    organizer_id,
    vehicle_type,
    route_type,
    status,
    created_at,
    updated_at
)
VALUES
-- Meet 1: Car meet in San Francisco
(
    uuid_generate_v4(),
    'SF Car Enthusiasts Meetup',
    'Join us for a gathering of car enthusiasts in the heart of San Francisco. All makes and models welcome!',
    (now() + interval '7 days'),
    jsonb_build_object('latitude', 37.7749, 'longitude', -122.4194),
    'Golden Gate Park, San Francisco, CA',
    'car',
    'https://images.unsplash.com/photo-1503376780353-7e6692767b70?q=80&w=1000',
    ARRAY['No burnouts', 'Respect other vehicles', 'Clean up after yourself'],
    ARRAY['cars', 'classics', 'modified', 'sf'],
    false,
    50,
    (SELECT current_setting('app.test_user_id')::uuid),
    'car',
    'city',
    'upcoming',
    now(),
    now()
),
-- Meet 2: Bike ride along coastal highway
(
    uuid_generate_v4(),
    'Coastal Highway Ride',
    'Scenic motorcycle ride along Highway 1. Experience breathtaking ocean views and winding roads.',
    (now() + interval '14 days'),
    jsonb_build_object('latitude', 36.3615, 'longitude', -121.8563),
    'Big Sur, CA',
    'bike',
    'https://images.unsplash.com/photo-1605001945280-80e3d2276342?q=80&w=1000',
    ARRAY['Helmet required', 'Group stays together', 'No excessive speed'],
    ARRAY['motorcycle', 'coastal', 'scenic', 'group ride'],
    false,
    25,
    (SELECT current_setting('app.test_user_id')::uuid),
    'bike',
    'coastal',
    'upcoming',
    now(),
    now()
),
-- Meet 3: Mixed vehicles mountain drive
(
    uuid_generate_v4(),
    'Mountain Drive Adventure',
    'Cars and bikes welcome for this mountain road adventure. Enjoy stunning views and challenging roads.',
    (now() + interval '21 days'),
    jsonb_build_object('latitude', 39.5501, 'longitude', -105.8705),
    'Mount Evans Scenic Byway, CO',
    'mixed',
    'https://images.unsplash.com/photo-1519681393784-d120267933ba?q=80&w=1000',
    ARRAY['Drive responsibly', 'Watch for wildlife', 'Bring water and snacks'],
    ARRAY['mountain', 'scenic', 'cars', 'bikes', 'drive'],
    true,
    30,
    (SELECT current_setting('app.test_user_id')::uuid),
    'mixed',
    'mountain',
    'upcoming',
    now(),
    now()
),
-- Meet 4: Premium car show
(
    uuid_generate_v4(),
    'Luxury & Exotic Car Show',
    'Exclusive gathering of luxury and exotic cars. Limited spots available for this premium event.',
    (now() + interval '30 days'),
    jsonb_build_object('latitude', 34.0522, 'longitude', -118.2437),
    'Downtown Los Angeles, CA',
    'car',
    'https://images.unsplash.com/photo-1603584173870-7f23fdae1b7a?q=80&w=1000',
    ARRAY['By invitation only', 'Professional photography allowed', 'Security present'],
    ARRAY['luxury', 'exotic', 'premium', 'show'],
    true,
    40,
    (SELECT current_setting('app.test_user_id')::uuid),
    'car',
    'city',
    'upcoming',
    now(),
    now()
),
-- Meet 5: Scenic countryside drive (set this one to active to demonstrate different statuses)
(
    uuid_generate_v4(),
    'Countryside Scenic Drive',
    'Relaxing drive through the countryside. Perfect for photography enthusiasts and nature lovers.',
    (now() - interval '2 hours'),
    jsonb_build_object('latitude', 38.5025, 'longitude', -122.2654),
    'Napa Valley, CA',
    'mixed',
    'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?q=80&w=1000',
    ARRAY['Respect private property', 'No littering', 'Drive safely'],
    ARRAY['scenic', 'countryside', 'relaxed', 'photography'],
    false,
    35,
    (SELECT current_setting('app.test_user_id')::uuid),
    'mixed',
    'scenic',
    'active',
    now(),
    now()
);

-- Save the meet IDs for use with routes
DO $$
DECLARE
    meets_cursor CURSOR FOR 
        SELECT id FROM public.meets 
        ORDER BY created_at DESC 
        LIMIT 5;
    meet_record RECORD;
    meet_counter INTEGER := 1;
BEGIN
    OPEN meets_cursor;
    
    LOOP
        FETCH meets_cursor INTO meet_record;
        EXIT WHEN NOT FOUND;
        
        PERFORM set_config('app.meet_' || meet_counter || '_id', meet_record.id::text, false);
        meet_counter := meet_counter + 1;
    END LOOP;
    
    CLOSE meets_cursor;
END
$$;

-- Create 5 test routes with varied attributes
INSERT INTO public.routes (
    id,
    meet_id,
    creator_id,
    title,
    description,
    route_data,
    distance,
    estimated_time,
    difficulty,
    created_at,
    updated_at
)
VALUES
-- Route 1: Urban exploration route
(
    uuid_generate_v4(),
    (SELECT current_setting('app.meet_1_id')::uuid),
    (SELECT current_setting('app.test_user_id')::uuid),
    'Downtown SF Explorer',
    'A scenic route through downtown San Francisco hitting all the major landmarks',
    jsonb_build_object(
        'coordinates', jsonb_build_array(
            jsonb_build_object('latitude', 37.7749, 'longitude', -122.4194),
            jsonb_build_object('latitude', 37.7785, 'longitude', -122.4150),
            jsonb_build_object('latitude', 37.7835, 'longitude', -122.4089),
            jsonb_build_object('latitude', 37.7946, 'longitude', -122.3996),
            jsonb_build_object('latitude', 37.8020, 'longitude', -122.4060)
        ),
        'waypoints', jsonb_build_array(
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 37.7749, 'longitude', -122.4194),
                'title', 'Start Point',
                'subtitle', 'Golden Gate Park',
                'type', 'start'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 37.7785, 'longitude', -122.4150),
                'title', 'Union Square',
                'subtitle', 'Shopping district',
                'type', 'checkpoint'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 37.8020, 'longitude', -122.4060),
                'title', 'End Point',
                'subtitle', 'Fisherman''s Wharf',
                'type', 'end'
            )
        )
    ),
    15.7,
    45,
    'easy',
    now(),
    now()
),
-- Route 2: Coastal Highway
(
    uuid_generate_v4(),
    (SELECT current_setting('app.meet_2_id')::uuid),
    (SELECT current_setting('app.test_user_id')::uuid),
    'Pacific Coast Highway',
    'Breathtaking coastal ride along Highway 1',
    jsonb_build_object(
        'coordinates', jsonb_build_array(
            jsonb_build_object('latitude', 36.3615, 'longitude', -121.8563),
            jsonb_build_object('latitude', 36.2988, 'longitude', -121.8895),
            jsonb_build_object('latitude', 36.2384, 'longitude', -121.7756),
            jsonb_build_object('latitude', 36.1700, 'longitude', -121.6749),
            jsonb_build_object('latitude', 36.0988, 'longitude', -121.5890)
        ),
        'waypoints', jsonb_build_array(
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 36.3615, 'longitude', -121.8563),
                'title', 'Start Point',
                'subtitle', 'Big Sur Entrance',
                'type', 'start'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 36.2384, 'longitude', -121.7756),
                'title', 'Bixby Creek Bridge',
                'subtitle', 'Iconic viewpoint',
                'type', 'scenic'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 36.0988, 'longitude', -121.5890),
                'title', 'End Point',
                'subtitle', 'Pfeiffer Big Sur State Park',
                'type', 'end'
            )
        )
    ),
    42.3,
    120,
    'moderate',
    now(),
    now()
),
-- Route 3: Mountain Pass
(
    uuid_generate_v4(),
    (SELECT current_setting('app.meet_3_id')::uuid),
    (SELECT current_setting('app.test_user_id')::uuid),
    'Mount Evans Summit',
    'Challenging route to the summit of Mount Evans',
    jsonb_build_object(
        'coordinates', jsonb_build_array(
            jsonb_build_object('latitude', 39.5501, 'longitude', -105.8705),
            jsonb_build_object('latitude', 39.5982, 'longitude', -105.7899),
            jsonb_build_object('latitude', 39.6237, 'longitude', -105.6432),
            jsonb_build_object('latitude', 39.5879, 'longitude', -105.6018),
            jsonb_build_object('latitude', 39.5883, 'longitude', -105.6428)
        ),
        'waypoints', jsonb_build_array(
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 39.5501, 'longitude', -105.8705),
                'title', 'Start Point',
                'subtitle', 'Mount Evans Scenic Byway Entrance',
                'type', 'start'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 39.6237, 'longitude', -105.6432),
                'title', 'Summit Lake',
                'subtitle', 'Rest area with views',
                'type', 'rest'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 39.5883, 'longitude', -105.6428),
                'title', 'End Point',
                'subtitle', 'Mount Evans Summit',
                'type', 'end'
            )
        )
    ),
    28.9,
    90,
    'challenging',
    now(),
    now()
),
-- Route 4: City Tour
(
    uuid_generate_v4(),
    (SELECT current_setting('app.meet_4_id')::uuid),
    (SELECT current_setting('app.test_user_id')::uuid),
    'LA Luxury Drive',
    'Tour of Los Angeles showcasing iconic luxury spots',
    jsonb_build_object(
        'coordinates', jsonb_build_array(
            jsonb_build_object('latitude', 34.0522, 'longitude', -118.2437),
            jsonb_build_object('latitude', 34.0678, 'longitude', -118.4001),
            jsonb_build_object('latitude', 34.0932, 'longitude', -118.3827),
            jsonb_build_object('latitude', 34.1016, 'longitude', -118.3260),
            jsonb_build_object('latitude', 34.0672, 'longitude', -118.2539)
        ),
        'waypoints', jsonb_build_array(
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 34.0522, 'longitude', -118.2437),
                'title', 'Start Point',
                'subtitle', 'Downtown LA',
                'type', 'start'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 34.0678, 'longitude', -118.4001),
                'title', 'Rodeo Drive',
                'subtitle', 'Luxury shopping',
                'type', 'checkpoint'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 34.0932, 'longitude', -118.3827),
                'title', 'Sunset Boulevard',
                'subtitle', 'Scenic cruise',
                'type', 'scenic'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 34.0672, 'longitude', -118.2539),
                'title', 'End Point',
                'subtitle', 'Arts District',
                'type', 'end'
            )
        )
    ),
    22.5,
    75,
    'easy',
    now(),
    now()
),
-- Route 5: Wine Country
(
    uuid_generate_v4(),
    (SELECT current_setting('app.meet_5_id')::uuid),
    (SELECT current_setting('app.test_user_id')::uuid),
    'Napa Valley Wine Tour',
    'Scenic drive through Napa Valley wine country',
    jsonb_build_object(
        'coordinates', jsonb_build_array(
            jsonb_build_object('latitude', 38.5025, 'longitude', -122.2654),
            jsonb_build_object('latitude', 38.4275, 'longitude', -122.4040),
            jsonb_build_object('latitude', 38.4054, 'longitude', -122.3592),
            jsonb_build_object('latitude', 38.4921, 'longitude', -122.3576),
            jsonb_build_object('latitude', 38.5033, 'longitude', -122.3000)
        ),
        'waypoints', jsonb_build_array(
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 38.5025, 'longitude', -122.2654),
                'title', 'Start Point',
                'subtitle', 'Napa City',
                'type', 'start'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 38.4275, 'longitude', -122.4040),
                'title', 'Domaine Carneros',
                'subtitle', 'Winery stop',
                'type', 'food'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 38.4921, 'longitude', -122.3576),
                'title', 'Scenic Overlook',
                'subtitle', 'Valley views',
                'type', 'scenic'
            ),
            jsonb_build_object(
                'id', uuid_generate_v4(),
                'coordinate', jsonb_build_object('latitude', 38.5033, 'longitude', -122.3000),
                'title', 'End Point',
                'subtitle', 'Yountville',
                'type', 'end'
            )
        )
    ),
    32.7,
    110,
    'moderate',
    now(),
    now()
);

-- Update the primary route for each meet to link to its corresponding route
DO $$
DECLARE
    routes_cursor CURSOR FOR 
        SELECT id, meet_id FROM public.routes 
        ORDER BY created_at DESC 
        LIMIT 5;
    route_record RECORD;
BEGIN
    FOR route_record IN routes_cursor LOOP
        UPDATE public.meets
        SET primary_route_id = route_record.id
        WHERE id = route_record.meet_id;
    END LOOP;
END
$$;

-- Provide a success message
SELECT 'Successfully created 5 test meets and 5 test routes' as result; 