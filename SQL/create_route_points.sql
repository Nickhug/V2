CREATE TABLE public.route_points (
    id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    route_id uuid NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
    coordinates jsonb NOT NULL,
    order_index integer NOT NULL,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    UNIQUE(route_id, order_index)
);

CREATE INDEX route_points_route_id_idx ON public.route_points (route_id);
CREATE INDEX route_points_order_idx ON public.route_points (order_index);

-- Set up RLS
ALTER TABLE public.route_points ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to view points for routes they can see
CREATE POLICY view_route_points ON public.route_points
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.routes
            WHERE routes.id = route_points.route_id
            AND (routes.is_public OR auth.uid()::text = routes.creator_id::text)
        )
    );

-- Allow users to add points to their own routes
CREATE POLICY add_points_to_own_route ON public.route_points
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.routes
            WHERE routes.id = route_points.route_id
            AND auth.uid()::text = routes.creator_id::text
        )
    );

-- Allow users to update points on their own routes
CREATE POLICY update_points_on_own_route ON public.route_points
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.routes
            WHERE routes.id = route_points.route_id
            AND auth.uid()::text = routes.creator_id::text
        )
    );

-- Allow users to delete points from their own routes
CREATE POLICY delete_points_from_own_route ON public.route_points
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM public.routes
            WHERE routes.id = route_points.route_id
            AND auth.uid()::text = routes.creator_id::text
        )
    ); 