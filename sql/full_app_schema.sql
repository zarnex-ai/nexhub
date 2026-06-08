-- Full Supabase SQL schema for the NexHub Flutter app
-- Organized by functional area / screen
-- Run this script in Supabase Studio (SQL editor) or via the `run_sql` RPC.

-- =============================================================
-- 1. Extensions
-- =============================================================
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";  -- UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- for default passwords if needed

-- =============================================================
-- 2. Auth (Supabase provides auth tables automatically)
-- No custom tables needed for login screen, but we add a profile table
-- to store additional user info.
-- =============================================================

-- -------------------------------------------------------------
-- Profiles table (linked to auth.users)
-- -------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT NOT NULL UNIQUE,
    avatar_url TEXT,
    display_name TEXT,
    invite_code TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profile_select"
    ON public.profiles
    FOR SELECT USING (TRUE);

CREATE POLICY "profile_update"
    ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "profile_insert"
    ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- =============================================================
-- 3. Channels (used on Home / Channel screens)
-- =============================================================

CREATE TABLE IF NOT EXISTS public.channels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    owner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.channels ENABLE ROW LEVEL SECURITY;

CREATE POLICY "channel_select"
    ON public.channels
    FOR SELECT USING (TRUE);  -- Public read, adjust as needed

CREATE POLICY "channel_insert"
    ON public.channels
    FOR INSERT WITH CHECK (auth.uid() = owner_id);  -- ✅ Fixed: USING → WITH CHECK

CREATE POLICY "channel_update"
    ON public.channels
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "channel_delete"
    ON public.channels
    FOR DELETE USING (auth.uid() = owner_id);

-- =============================================================
-- 4. Messages (used on Channel screen)
-- =============================================================

CREATE TABLE IF NOT EXISTS public.messages (
    id BIGSERIAL PRIMARY KEY,
    channel_id UUID NOT NULL REFERENCES public.channels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    parent_id BIGINT REFERENCES public.messages(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "message_select"
    ON public.messages
    FOR SELECT USING (TRUE);  -- Public read of channel messages

CREATE POLICY "message_insert"
    ON public.messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =============================================================
-- 5. Attachments (optional, for file uploads)
-- =============================================================

CREATE TABLE IF NOT EXISTS public.attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id BIGINT NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    mime_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "attachment_select"
    ON public.attachments
    FOR SELECT USING (TRUE);

CREATE POLICY "attachment_insert"
    ON public.attachments
    FOR INSERT WITH CHECK (auth.uid() = (SELECT user_id FROM public.messages WHERE id = message_id));

-- =============================================================
-- 6. Reactions (optional, for message reactions)
-- =============================================================

CREATE TABLE IF NOT EXISTS public.reactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id BIGINT NOT NULL REFERENCES public.messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL,  -- e.g., 'like', 'thumbs_up'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.reactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "reaction_select"
    ON public.reactions
    FOR SELECT USING (TRUE);

CREATE POLICY "reaction_insert"
    ON public.reactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);  -- ✅ Fixed: USING → WITH CHECK

-- =============================================================
-- 7. Code Snippets (Code Bucket Screen)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.code_snippets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    code TEXT NOT NULL,
    language TEXT NOT NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

ALTER TABLE public.code_snippets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "snippets_select"
    ON public.code_snippets
    FOR SELECT USING (TRUE);

CREATE POLICY "snippets_insert"
    ON public.code_snippets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "snippets_delete"
    ON public.code_snippets
    FOR DELETE USING (auth.uid() = user_id);

-- =============================================================
-- 8. Storage Configuration for Avatars / Profiles
-- =============================================================

-- Create avatars bucket if not exists
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Allow public read access to avatars
CREATE POLICY "Public Read Access"
ON storage.objects FOR SELECT
USING ( bucket_id = 'avatars' );

-- Allow users to upload their own avatar named after their user ID
CREATE POLICY "Allow users to upload own avatar"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'avatars' AND (split_part(name, '.', 1)) = auth.uid()::text );

-- Allow users to update their own avatar
CREATE POLICY "Allow users to update own avatar"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'avatars' AND (split_part(name, '.', 1)) = auth.uid()::text );

-- Allow users to delete their own avatar
CREATE POLICY "Allow users to delete own avatar"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'avatars' AND (split_part(name, '.', 1)) = auth.uid()::text );

-- End of schema
