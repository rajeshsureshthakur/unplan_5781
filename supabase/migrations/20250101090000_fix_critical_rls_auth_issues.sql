-- CRITICAL: Fix RLS policy violations causing authentication failures
-- This migration addresses the root cause identified in runtime errors

-- Drop ALL existing problematic policies first
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "service_role_manage_user_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_manage_groups" ON public.groups;
DROP POLICY IF EXISTS "members_can_view_their_groups" ON public.groups;
DROP POLICY IF EXISTS "users_manage_group_members" ON public.group_members;
DROP POLICY IF EXISTS "group_members_access" ON public.group_members;
DROP POLICY IF EXISTS "group_members_manage_expenses" ON public.expenses;

-- CRITICAL FIX 1: User Profiles - Simple policies without complex subqueries
CREATE POLICY "enable_read_own_user_profile" 
ON public.user_profiles 
FOR SELECT 
TO authenticated 
USING (id = auth.uid());

CREATE POLICY "enable_insert_own_user_profile" 
ON public.user_profiles 
FOR INSERT 
TO authenticated 
WITH CHECK (id = auth.uid());

CREATE POLICY "enable_update_own_user_profile" 
ON public.user_profiles 
FOR UPDATE 
TO authenticated 
USING (id = auth.uid()) 
WITH CHECK (id = auth.uid());

-- CRITICAL: Allow service role full access for signup process
CREATE POLICY "service_role_full_access_user_profiles"
ON public.user_profiles
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- CRITICAL FIX 2: Groups - Simplified policies
CREATE POLICY "enable_read_member_groups"
ON public.groups
FOR SELECT
TO authenticated
USING (
  created_by = auth.uid() 
  OR EXISTS (
    SELECT 1 FROM public.group_members gm 
    WHERE gm.group_id = id 
    AND gm.user_id = auth.uid()
  )
);

CREATE POLICY "enable_insert_own_groups"
ON public.groups
FOR INSERT
TO authenticated
WITH CHECK (created_by = auth.uid());

CREATE POLICY "enable_update_admin_groups"
ON public.groups
FOR UPDATE
TO authenticated
USING (
  created_by = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.group_members gm 
    WHERE gm.group_id = id 
    AND gm.user_id = auth.uid() 
    AND gm.role IN ('admin', 'manager')
  )
)
WITH CHECK (
  created_by = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.group_members gm 
    WHERE gm.group_id = id 
    AND gm.user_id = auth.uid() 
    AND gm.role IN ('admin', 'manager')
  )
);

-- CRITICAL FIX 3: Group Members - Allow viewing and management
CREATE POLICY "enable_read_group_members"
ON public.group_members
FOR SELECT
TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.groups g 
    WHERE g.id = group_id 
    AND g.created_by = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.group_members gm2 
    WHERE gm2.group_id = group_id 
    AND gm2.user_id = auth.uid()
  )
);

CREATE POLICY "enable_insert_group_members"
ON public.group_members
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM public.groups g 
    WHERE g.id = group_id 
    AND g.created_by = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.group_members gm 
    WHERE gm.group_id = group_id 
    AND gm.user_id = auth.uid() 
    AND gm.role IN ('admin', 'manager')
  )
);

CREATE POLICY "enable_update_group_members"
ON public.group_members
FOR UPDATE
TO authenticated
USING (
  user_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.groups g 
    WHERE g.id = group_id 
    AND g.created_by = auth.uid()
  )
  OR EXISTS (
    SELECT 1 FROM public.group_members gm 
    WHERE gm.group_id = group_id 
    AND gm.user_id = auth.uid() 
    AND gm.role IN ('admin', 'manager')
  )
);

-- CRITICAL FIX 4: Expenses - Allow group members to manage expenses
CREATE POLICY "enable_read_group_expenses"
ON public.expenses
FOR SELECT
TO authenticated
USING (
  payer_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM public.group_members gm 
    WHERE gm.group_id = expenses.group_id 
    AND gm.user_id = auth.uid()
  )
);

CREATE POLICY "enable_insert_group_expenses"
ON public.expenses
FOR INSERT
TO authenticated
WITH CHECK (
  payer_id = auth.uid()
  AND EXISTS (
    SELECT 1 FROM public.group_members gm 
    WHERE gm.group_id = expenses.group_id 
    AND gm.user_id = auth.uid()
  )
);

CREATE POLICY "enable_update_own_expenses"
ON public.expenses
FOR UPDATE
TO authenticated
USING (payer_id = auth.uid())
WITH CHECK (payer_id = auth.uid());

-- CRITICAL: Ensure demo user email is confirmed (FIXED - removed confirmed_at update)
UPDATE auth.users 
SET 
  email_confirmed_at = COALESCE(email_confirmed_at, NOW())
WHERE email = 'demo@unplan.app';

-- CRITICAL: Create demo user profile if missing
INSERT INTO public.user_profiles (id, email, full_name, role, created_at, updated_at)
SELECT 
  au.id,
  'demo@unplan.app',
  'Demo User',
  'member'::public.user_role,
  NOW(),
  NOW()
FROM auth.users au
WHERE au.email = 'demo@unplan.app'
ON CONFLICT (id) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = EXCLUDED.full_name,
  updated_at = NOW();

-- CRITICAL: Fix the ensure_user_profile function to be more robust
CREATE OR REPLACE FUNCTION public.ensure_user_profile()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    current_user_id UUID := auth.uid();
    user_email TEXT;
    user_name TEXT;
BEGIN
    -- Validate we have a user ID
    IF current_user_id IS NULL THEN
        RAISE WARNING 'No authenticated user found';
        RETURN FALSE;
    END IF;

    -- Check if profile already exists
    IF EXISTS (SELECT 1 FROM public.user_profiles WHERE id = current_user_id) THEN
        RETURN TRUE;
    END IF;

    -- Get user details from auth.users
    SELECT 
        COALESCE(au.email, 'demo@unplan.app'),
        COALESCE(au.raw_user_meta_data->>'full_name', 'Demo User')
    INTO user_email, user_name
    FROM auth.users au
    WHERE au.id = current_user_id;
    
    -- Create the profile
    INSERT INTO public.user_profiles (id, email, full_name, role, created_at, updated_at)
    VALUES (
        current_user_id,
        user_email,
        user_name,
        'member'::public.user_role,
        NOW(),
        NOW()
    );
    
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Failed to ensure user profile for %: %', current_user_id, SQLERRM;
        RETURN FALSE;
END;
$$;

-- CRITICAL: Update the group update function to handle the new policies
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
    v_user_id UUID := auth.uid();
    v_result JSON;
    v_can_update BOOLEAN := FALSE;
BEGIN
    -- Validate user is authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'User not authenticated';
    END IF;

    -- Check if user can update this group
    SELECT EXISTS (
        SELECT 1 FROM public.groups g
        WHERE g.id = p_group_id 
        AND (
            g.created_by = v_user_id
            OR EXISTS (
                SELECT 1 FROM public.group_members gm 
                WHERE gm.group_id = p_group_id 
                AND gm.user_id = v_user_id 
                AND gm.role IN ('admin', 'manager')
            )
        )
    ) INTO v_can_update;

    IF NOT v_can_update THEN
        RAISE EXCEPTION 'Permission denied: Only group creators and admins can update group info';
    END IF;

    -- Perform the update
    UPDATE public.groups
    SET 
        name = COALESCE(p_name, name),
        description = COALESCE(p_description, description),
        profile_picture = COALESCE(p_profile_picture, profile_picture),
        updated_at = NOW()
    WHERE id = p_group_id;

    -- Get the updated result
    SELECT to_json(g.*) INTO v_result
    FROM public.groups g
    WHERE g.id = p_group_id;

    RETURN v_result;
END;
$$;

-- Create a trigger to ensure user profiles are created on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Create user profile automatically
    INSERT INTO public.user_profiles (id, email, full_name, role, created_at, updated_at)
    VALUES (
        NEW.id,
        COALESCE(NEW.email, 'demo@unplan.app'),
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Demo User'),
        'member'::public.user_role,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$;

-- Drop existing trigger and recreate
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Grant proper permissions
GRANT USAGE ON SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO authenticated, service_role;

-- CRITICAL: Add some sample data for testing if demo group doesn't exist
DO $$
DECLARE
    demo_user_id UUID;
    demo_group_id UUID;
BEGIN
    -- Get the demo user ID
    SELECT id INTO demo_user_id 
    FROM public.user_profiles 
    WHERE email = 'demo@unplan.app' 
    LIMIT 1;
    
    IF demo_user_id IS NOT NULL THEN
        -- Create a demo group if none exists
        IF NOT EXISTS (SELECT 1 FROM public.groups WHERE created_by = demo_user_id) THEN
            INSERT INTO public.groups (id, name, description, created_by, created_at, updated_at)
            VALUES (
                gen_random_uuid(),
                'Demo Group',
                'A sample group for testing',
                demo_user_id,
                NOW(),
                NOW()
            )
            RETURNING id INTO demo_group_id;
            
            -- Add the demo user as admin member
            INSERT INTO public.group_members (group_id, user_id, role)
            VALUES (demo_group_id, demo_user_id, 'admin'::public.user_role);
        END IF;
    END IF;
END $$;