CREATE TABLE public.routes (
    id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    title text NOT NULL,
    description text NOT NULL,
    creator_id uuid NOT NULL REFERENCES public.users(id),
    coordinates jsonb NOT NULL DEFAULT '[]'::jsonb,
    distance integer NOT NULL DEFAULT 0,
    estimated_duration integer NOT NULL DEFAULT 0,
    is_public boolean NOT NULL DEFAULT false,
    cover_image text NOT NULL DEFAULT ''::text,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX routes_creator_id_idx ON public.routes (creator_id);
CREATE INDEX routes_is_public_idx ON public.routes (is_public);

-- Set up RLS
ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view public routes
CREATE POLICY view_public_routes ON public.routes
    FOR SELECT
    USING (is_public OR auth.uid()::text = creator_id::text);

-- Allow users to create their own routes
CREATE POLICY create_own_route ON public.routes
    FOR INSERT
    WITH CHECK (auth.uid()::text = creator_id::text);

-- Allow users to update their own routes
CREATE POLICY update_own_route ON public.routes
    FOR UPDATE
    USING (auth.uid()::text = creator_id::text);

-- Allow users to delete their own routes
CREATE POLICY delete_own_route ON public.routes
    FOR DELETE
    USING (auth.uid()::text = creator_id::text); 