-- Location: supabase/migrations/20241216120000_groups_with_auth.sql
-- Schema Analysis: CRITICAL FIX for column "role" does not exist error
-- Integration Type: Initial setup with authentication and groups module
-- Dependencies: None - fresh start with proper schema resolution

-- 1. Enable required extensions first
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Types and Core Tables in proper order
-- Fix: Use DROP TYPE IF EXISTS to handle existing types
DROP TYPE IF EXISTS public.user_role CASCADE;
CREATE TYPE public.user_role AS ENUM ('admin', 'manager', 'member');

-- Critical intermediary table - user_profiles FIRST
DROP TABLE IF EXISTS public.user_profiles CASCADE;
CREATE TABLE public.user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    role public.user_role DEFAULT 'member'::public.user_role,
    phone TEXT,
    profile_picture TEXT,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Groups table for the unplan app
DROP TABLE IF EXISTS public.groups CASCADE;
CREATE TABLE public.groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    profile_picture TEXT,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Group memberships table - MUST BE CREATED BEFORE FUNCTIONS REFERENCE IT
DROP TABLE IF EXISTS public.group_members CASCADE;
CREATE TABLE public.group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID NOT NULL REFERENCES public.groups(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    role public.user_role NOT NULL DEFAULT 'member'::public.user_role,
    joined_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(group_id, user_id)
);

-- Events table
DROP TABLE IF EXISTS public.events CASCADE;
CREATE TABLE public.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    event_date TIMESTAMPTZ NOT NULL,
    venue TEXT,
    notes TEXT,
    approval_status TEXT DEFAULT 'pending',
    approval_count INTEGER DEFAULT 0,
    total_members INTEGER DEFAULT 0,
    created_by UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Expenses table
DROP TABLE IF EXISTS public.expenses CASCADE;
CREATE TABLE public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE,
    event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    payer_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
    split_members JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Essential Indexes (recreate all)
DROP INDEX IF EXISTS idx_user_profiles_email;
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);

DROP INDEX IF EXISTS idx_groups_created_by;
CREATE INDEX idx_groups_created_by ON public.groups(created_by);

DROP INDEX IF EXISTS idx_group_members_group_id;
CREATE INDEX idx_group_members_group_id ON public.group_members(group_id);

DROP INDEX IF EXISTS idx_group_members_user_id;
CREATE INDEX idx_group_members_user_id ON public.group_members(user_id);

DROP INDEX IF EXISTS idx_group_members_role;
CREATE INDEX idx_group_members_role ON public.group_members(role);

DROP INDEX IF EXISTS idx_events_group_id;
CREATE INDEX idx_events_group_id ON public.events(group_id);

DROP INDEX IF EXISTS idx_expenses_group_id;
CREATE INDEX idx_expenses_group_id ON public.expenses(group_id);

DROP INDEX IF EXISTS idx_expenses_payer_id;
CREATE INDEX idx_expenses_payer_id ON public.expenses(payer_id);

-- 4. Functions for automatic profile creation (AFTER ALL TABLES ARE CREATED)
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name, role)
  VALUES (
    NEW.id, 
    NEW.email, 
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    COALESCE((NEW.raw_user_meta_data->>'role')::public.user_role, 'member'::public.user_role)
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$;

-- Trigger for new user creation (drop and recreate to avoid conflicts)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 5. RLS Setup
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- 6. RLS POLICIES - Using Pattern System (drop existing first to avoid conflicts)

-- Pattern 1: Core user table (user_profiles) - Simple only, no functions
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Pattern 2: Simple user ownership for groups
-- Drop existing policies to recreate them
DROP POLICY IF EXISTS "users_manage_own_groups" ON public.groups;
DROP POLICY IF EXISTS "members_can_view_their_groups" ON public.groups;

-- New policy: Allow creators and admin members to manage groups
CREATE POLICY "users_manage_own_groups" ON public.groups
FOR ALL
USING (
  created_by = auth.uid() OR 
  id IN (
    SELECT gm.group_id 
    FROM public.group_members gm
    WHERE gm.user_id = auth.uid() 
    AND gm.role IN ('admin'::public.user_role, 'manager'::public.user_role)
  )
)
WITH CHECK (
  created_by = auth.uid() OR 
  id IN (
    SELECT gm.group_id 
    FROM public.group_members gm
    WHERE gm.user_id = auth.uid() 
    AND gm.role IN ('admin'::public.user_role, 'manager'::public.user_role)
  )
);

-- Pattern 2: Group members can view groups they belong to
CREATE POLICY "members_can_view_their_groups"
ON public.groups
FOR SELECT
TO authenticated
USING (
    id IN (
        SELECT gm.group_id FROM public.group_members gm
        WHERE gm.user_id = auth.uid()
    )
);

-- Pattern 2: Group membership management
DROP POLICY IF EXISTS "users_manage_group_members" ON public.group_members;
CREATE POLICY "users_manage_group_members"
ON public.group_members
FOR ALL
TO authenticated
USING (
    group_id IN (
        SELECT g.id FROM public.groups g
        WHERE g.created_by = auth.uid()
    )
    OR user_id = auth.uid()
)
WITH CHECK (
    group_id IN (
        SELECT g.id FROM public.groups g
        WHERE g.created_by = auth.uid()
    )
    OR user_id = auth.uid()
);

-- Pattern 2: Events access by group membership
DROP POLICY IF EXISTS "group_members_manage_events" ON public.events;
CREATE POLICY "group_members_manage_events"
ON public.events
FOR ALL
TO authenticated
USING (
    group_id IN (
        SELECT gm.group_id FROM public.group_members gm
        WHERE gm.user_id = auth.uid()
    )
    OR created_by = auth.uid()
)
WITH CHECK (
    group_id IN (
        SELECT gm.group_id FROM public.group_members gm
        WHERE gm.user_id = auth.uid()
    )
    OR created_by = auth.uid()
);

-- Pattern 2: Expenses access by group membership
DROP POLICY IF EXISTS "group_members_manage_expenses" ON public.expenses;
CREATE POLICY "group_members_manage_expenses"
ON public.expenses
FOR ALL
TO authenticated
USING (
    group_id IN (
        SELECT gm.group_id FROM public.group_members gm
        WHERE gm.user_id = auth.uid()
    )
    OR payer_id = auth.uid()
)
WITH CHECK (
    group_id IN (
        SELECT gm.group_id FROM public.group_members gm
        WHERE gm.user_id = auth.uid()
    )
    OR payer_id = auth.uid()
);

-- 7. CRITICAL FIX: Add function with explicit schema and column references
-- Drop existing function first
DROP FUNCTION IF EXISTS public.update_group_safely(UUID, TEXT, TEXT, TEXT);

-- Create function with fully qualified table references and explicit column casting
CREATE OR REPLACE FUNCTION public.update_group_safely(
  p_group_id UUID,
  p_name TEXT,
  p_description TEXT DEFAULT NULL,
  p_profile_picture TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id UUID;
  v_user_role TEXT;  -- FIXED: Use TEXT instead of enum type
  v_is_creator BOOLEAN := FALSE;
  v_result JSON;
BEGIN
  -- Get current user ID
  v_user_id := auth.uid();
  
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'User not authenticated';
  END IF;

  -- Check if user is creator (explicit table reference)
  SELECT (g.created_by = v_user_id) INTO v_is_creator
  FROM public.groups g
  WHERE g.id = p_group_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Group not found';
  END IF;

  -- If not creator, check if user is admin/manager (explicit column reference)
  IF NOT v_is_creator THEN
    -- FIXED: Cast enum to text for comparison and use fully qualified references
    SELECT gm.role::TEXT INTO v_user_role
    FROM public.group_members gm
    WHERE gm.group_id = p_group_id 
    AND gm.user_id = v_user_id;

    IF v_user_role IS NULL OR v_user_role NOT IN ('admin', 'manager') THEN
      RAISE EXCEPTION 'Permission denied: Only group creators and admins can update group info';
    END IF;
  END IF;

  -- Perform the update with explicit table reference
  UPDATE public.groups
  SET 
    name = p_name,
    description = COALESCE(p_description, description),
    profile_picture = COALESCE(p_profile_picture, profile_picture),
    updated_at = CURRENT_TIMESTAMP
  WHERE id = p_group_id;

  -- Return the updated group with explicit table reference
  SELECT row_to_json(g.*) INTO v_result
  FROM public.groups g
  WHERE g.id = p_group_id;

  RETURN v_result;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.update_group_safely(UUID, TEXT, TEXT, TEXT) TO authenticated;

-- 8. Complete Mock Data (only insert if data doesn't exist)
DO $$
DECLARE
    admin_uuid UUID := '11111111-1111-1111-1111-111111111111';
    user1_uuid UUID := '22222222-2222-2222-2222-222222222222';
    user2_uuid UUID := '33333333-3333-3333-3333-333333333333';
    user3_uuid UUID := '44444444-4444-4444-4444-444444444444';
    user4_uuid UUID := '55555555-5555-5555-5555-555555555555';
    user5_uuid UUID := '66666666-6666-6666-6666-666666666666';
    group_uuid UUID := '77777777-7777-7777-7777-777777777777';
    event1_uuid UUID := '88888888-8888-8888-8888-888888888888';
    event2_uuid UUID := '99999999-9999-9999-9999-999999999999';
    user_count INTEGER;
BEGIN
    -- Check if users already exist to avoid duplicates
    SELECT COUNT(*) INTO user_count FROM auth.users WHERE email LIKE '%@weekend.com';
    
    -- Only create mock data if it doesn't exist
    IF user_count = 0 THEN
        -- Create auth users with all required fields
        INSERT INTO auth.users (
            id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
            created_at, updated_at, raw_user_meta_data, raw_app_meta_data,
            is_sso_user, is_anonymous, confirmation_token, confirmation_sent_at,
            recovery_token, recovery_sent_at, email_change_token_new, email_change,
            email_change_sent_at, email_change_token_current, email_change_confirm_status,
            reauthentication_token, reauthentication_sent_at, phone, phone_change,
            phone_change_token, phone_change_sent_at
        ) VALUES
            (admin_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
             'alex@weekend.com', crypt('weekend123', gen_salt('bf', 10)), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
             '{"full_name": "Alex Johnson"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
             false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
            (user1_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
             'sarah@weekend.com', crypt('weekend123', gen_salt('bf', 10)), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
             '{"full_name": "Sarah Chen"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
             false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
            (user2_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
             'mike@weekend.com', crypt('weekend123', gen_salt('bf', 10)), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
             '{"full_name": "Mike Rodriguez"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
             false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
            (user3_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
             'emma@weekend.com', crypt('weekend123', gen_salt('bf', 10)), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
             '{"full_name": "Emma Wilson"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
             false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
            (user4_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
             'david@weekend.com', crypt('weekend123', gen_salt('bf', 10)), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
             '{"full_name": "David Kim"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
             false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null),
            (user5_uuid, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
             'lisa@weekend.com', crypt('weekend123', gen_salt('bf', 10)), CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
             '{"full_name": "Lisa Thompson"}'::jsonb, '{"provider": "email", "providers": ["email"]}'::jsonb,
             false, false, '', null, '', null, '', '', null, '', 0, '', null, null, '', '', null);

        -- Create the Weekend Warriors group
        INSERT INTO public.groups (id, name, description, profile_picture, created_by) VALUES
            (group_uuid, 'Weekend Warriors', 'A group for weekend adventures and activities', 
             'https://images.unsplash.com/photo-1511632765486-a01980e01a18?w=300&h=300&fit=crop', admin_uuid);

        -- Add all users as group members with explicit enum casting
        INSERT INTO public.group_members (group_id, user_id, role) VALUES
            (group_uuid, admin_uuid, 'admin'::public.user_role),
            (group_uuid, user1_uuid, 'member'::public.user_role),
            (group_uuid, user2_uuid, 'member'::public.user_role),
            (group_uuid, user3_uuid, 'member'::public.user_role),
            (group_uuid, user4_uuid, 'member'::public.user_role),
            (group_uuid, user5_uuid, 'member'::public.user_role);

        -- Create events
        INSERT INTO public.events (id, group_id, title, description, event_date, venue, notes, approval_status, approval_count, total_members, created_by) VALUES
            (event1_uuid, group_uuid, 'Beach Volleyball Tournament', 'Fun volleyball tournament at the beach', 
             CURRENT_TIMESTAMP + interval '3 days', 'Santa Monica Beach', 'Bring sunscreen and water bottles!', 'pending', 4, 6, admin_uuid),
            (event2_uuid, group_uuid, 'Movie Night - Dune Part Two', 'Group movie watching experience',
             CURRENT_TIMESTAMP + interval '7 days', 'AMC Century City', '7:30 PM showing, get tickets early', 'approved', 6, 6, user1_uuid);

        -- Create expenses
        INSERT INTO public.expenses (group_id, event_id, title, amount, payer_id, split_members) VALUES
            (group_uuid, event1_uuid, 'Uber to Beach Volleyball', 45.50, admin_uuid, 
             '["Alex Johnson", "Sarah Chen", "Mike Rodriguez", "Emma Wilson"]'::jsonb),
            (group_uuid, event2_uuid, 'Movie Tickets', 84.00, user1_uuid,
             '["Alex Johnson", "Sarah Chen", "Mike Rodriguez", "Emma Wilson", "David Kim", "Lisa Thompson"]'::jsonb),
            (group_uuid, event1_uuid, 'Beach Snacks and Water', 200.00, admin_uuid,
             '["Alex Johnson", "Sarah Chen", "Mike Rodriguez"]'::jsonb),
            (group_uuid, null, 'Hiking Snacks & Water', 28.75, user2_uuid,
             '["Alex Johnson", "Sarah Chen", "Mike Rodriguez", "Emma Wilson", "David Kim"]'::jsonb),
            (group_uuid, null, 'Brunch Bill', 156.80, user4_uuid,
             '["Alex Johnson", "Sarah Chen", "Mike Rodriguez", "Emma Wilson", "David Kim", "Lisa Thompson"]'::jsonb);

        RAISE NOTICE 'Mock data created successfully - Weekend Warriors group with 6 members and sample expenses';
    ELSE
        RAISE NOTICE 'Mock data already exists, skipping creation';
    END IF;

EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key error during mock data creation: %', SQLERRM;
    WHEN unique_violation THEN
        RAISE NOTICE 'Unique constraint error during mock data creation: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Unexpected error during mock data creation: %', SQLERRM;
END $$;