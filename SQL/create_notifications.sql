CREATE TABLE public.notifications (
    id uuid NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    title text NOT NULL,
    message text NOT NULL,
    type text NOT NULL DEFAULT 'system_message'::text,
    related_id uuid, -- Optional reference to a meet, route, etc.
    is_read boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now()
);

CREATE INDEX notifications_user_id_idx ON public.notifications (user_id);
CREATE INDEX notifications_is_read_idx ON public.notifications (is_read);
CREATE INDEX notifications_created_at_idx ON public.notifications (created_at);

-- Set up RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Allow users to view their own notifications
CREATE POLICY view_own_notifications ON public.notifications
    FOR SELECT
    USING (auth.uid()::text = user_id::text);

-- Allow the service role to create notifications for any user
CREATE POLICY create_notifications ON public.notifications
    FOR INSERT
    WITH CHECK (auth.uid()::text = user_id::text OR auth.role() = 'service_role');

-- Allow users to update (mark as read) their own notifications
CREATE POLICY update_own_notifications ON public.notifications
    FOR UPDATE
    USING (auth.uid()::text = user_id::text);

-- Allow users to delete their own notifications
CREATE POLICY delete_own_notifications ON public.notifications
    FOR DELETE
    USING (auth.uid()::text = user_id::text); 