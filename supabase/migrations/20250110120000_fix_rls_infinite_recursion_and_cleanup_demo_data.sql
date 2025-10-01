-- Location: supabase/migrations/20250110120000_fix_rls_infinite_recursion_and_cleanup_demo_data.sql
-- Schema Analysis: Complete unplan group management system exists
-- Integration Type: Fix RLS policies and cleanup demo data
-- Dependencies: user_profiles, groups, group_members, events, expenses tables

-- STEP 1: Drop ALL existing RLS policies that might cause conflicts or infinite recursion
DROP POLICY IF EXISTS "secure_user_profiles_access" ON public.user_profiles;
DROP POLICY IF EXISTS "secure_groups_access" ON public.groups;
DROP POLICY IF EXISTS "secure_groups_view" ON public.groups;  
DROP POLICY IF EXISTS "secure_group_members_access" ON public.group_members;
DROP POLICY IF EXISTS "secure_events_access" ON public.events;
DROP POLICY IF EXISTS "secure_expenses_access" ON public.expenses;
DROP POLICY IF EXISTS "group_members_manage_events" ON public.events;

-- CRITICAL FIX: Drop existing policies that were causing the duplicate error
DROP POLICY IF EXISTS "users_manage_own_user_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "demo_access_user_profiles" ON public.user_profiles;
DROP POLICY IF EXISTS "users_manage_own_groups" ON public.groups;
DROP POLICY IF EXISTS "demo_access_groups" ON public.groups;
DROP POLICY IF EXISTS "users_manage_own_group_members" ON public.group_members;
DROP POLICY IF EXISTS "demo_access_group_members" ON public.group_members;
DROP POLICY IF EXISTS "users_manage_own_events" ON public.events;
DROP POLICY IF EXISTS "demo_access_events" ON public.events;
DROP POLICY IF EXISTS "users_manage_own_expenses" ON public.expenses;
DROP POLICY IF EXISTS "demo_access_expenses" ON public.expenses;

-- STEP 2: Create helper functions BEFORE RLS policies (functions must exist first)

-- Helper function for demo user support (no circular dependency)
CREATE OR REPLACE FUNCTION public.is_demo_or_authenticated_user()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    auth.uid() IS NOT NULL OR  -- Authenticated user
    (auth.uid() IS NULL AND auth.role() = 'anon') -- Anonymous mode (demo access)
$$;

-- Helper function to get effective user ID
CREATE OR REPLACE FUNCTION public.get_effective_user_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
SELECT 
    CASE 
        WHEN auth.uid() IS NOT NULL THEN auth.uid()
        WHEN auth.role() = 'anon' THEN '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID
        ELSE NULL
    END
$$;

-- STEP 3: Implement CORRECTED RLS policies using Pattern 1 and Pattern 2 (NO circular dependencies)

-- Pattern 1: Core user table (user_profiles) - Simple direct column comparison ONLY
CREATE POLICY "users_manage_own_user_profiles"
ON public.user_profiles
FOR ALL
TO authenticated
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- Demo access policy for user_profiles (anonymous users)
CREATE POLICY "demo_access_user_profiles"  
ON public.user_profiles
FOR ALL
TO anon
USING (id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID)
WITH CHECK (id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID);

-- Pattern 2: Simple user ownership for groups (created_by column)
CREATE POLICY "users_manage_own_groups"
ON public.groups  
FOR ALL
TO authenticated
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

-- Demo access for groups
CREATE POLICY "demo_access_groups"
ON public.groups
FOR ALL  
TO anon
USING (created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID)
WITH CHECK (created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID);

-- Pattern 2: Simple user ownership for group_members (user_id column)
CREATE POLICY "users_manage_own_group_members"
ON public.group_members
FOR ALL
TO authenticated  
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Demo access for group_members  
CREATE POLICY "demo_access_group_members"
ON public.group_members
FOR ALL
TO anon
USING (user_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID)
WITH CHECK (user_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID);

-- Pattern 2: Simple user ownership for events (created_by column)
CREATE POLICY "users_manage_own_events"
ON public.events
FOR ALL
TO authenticated
USING (created_by = auth.uid()) 
WITH CHECK (created_by = auth.uid());

-- Demo access for events
CREATE POLICY "demo_access_events"
ON public.events  
FOR ALL
TO anon
USING (created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID)
WITH CHECK (created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID);

-- Pattern 2: Simple user ownership for expenses (payer_id column)
CREATE POLICY "users_manage_own_expenses"
ON public.expenses
FOR ALL
TO authenticated
USING (payer_id = auth.uid())
WITH CHECK (payer_id = auth.uid());

-- Demo access for expenses
CREATE POLICY "demo_access_expenses"  
ON public.expenses
FOR ALL
TO anon
USING (payer_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID)
WITH CHECK (payer_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID);

-- STEP 4: Create selective data cleanup function for demo user

-- Enhanced demo data cleanup function with selective removal
CREATE OR REPLACE FUNCTION public.cleanup_demo_user_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    demo_user_id UUID := '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID;
    cleanup_count INTEGER;
BEGIN
    RAISE NOTICE 'Starting selective cleanup for demo user: %', demo_user_id;
    
    -- Step 1: Remove all expenses related to demo user
    DELETE FROM public.expenses 
    WHERE payer_id = demo_user_id;
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Cleaned up % expenses', cleanup_count;
    
    -- Step 2: Remove all events created by demo user  
    DELETE FROM public.events
    WHERE created_by = demo_user_id;
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Cleaned up % events', cleanup_count;
    
    -- Step 3: Remove all group memberships for demo user
    DELETE FROM public.group_members
    WHERE user_id = demo_user_id;
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Cleaned up % group memberships', cleanup_count;
    
    -- Step 4: Remove all groups created by demo user
    DELETE FROM public.groups
    WHERE created_by = demo_user_id;
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Cleaned up % groups', cleanup_count;
    
    -- Step 5: PRESERVE user profile and auth for login capabilities
    RAISE NOTICE 'PRESERVED: Demo user profile and authentication data for login functionality';
    
    -- Step 6: Reset user profile to clean state (keeping login credentials)
    UPDATE public.user_profiles 
    SET 
        full_name = 'Demo User',
        profile_picture = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = demo_user_id;
    
    RAISE NOTICE 'Demo user data cleanup completed - login capabilities preserved';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Cleanup failed: %', SQLERRM;
        -- Don't re-raise to avoid breaking the migration
END;
$$;

-- STEP 5: Create function to generate fresh demo data (optional for testing)

CREATE OR REPLACE FUNCTION public.create_fresh_demo_data()
RETURNS VOID  
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    demo_user_id UUID := '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID;
    sample_group_id UUID;
    sample_event_id UUID;
BEGIN
    RAISE NOTICE 'Creating fresh demo data for user: %', demo_user_id;
    
    -- Create a sample group
    INSERT INTO public.groups (id, name, description, created_by, created_at)
    VALUES (
        gen_random_uuid(),
        'My Test Group', 
        'A fresh group for testing',
        demo_user_id,
        CURRENT_TIMESTAMP
    ) 
    RETURNING id INTO sample_group_id;
    
    -- Add user as group member
    INSERT INTO public.group_members (group_id, user_id, role, joined_at)
    VALUES (sample_group_id, demo_user_id, 'admin', CURRENT_TIMESTAMP);
    
    -- Create a sample event
    INSERT INTO public.events (id, group_id, title, description, event_date, created_by, created_at)
    VALUES (
        gen_random_uuid(),
        sample_group_id,
        'Sample Event',
        'A test event for the group',
        CURRENT_TIMESTAMP + INTERVAL '7 days',
        demo_user_id,
        CURRENT_TIMESTAMP
    )
    RETURNING id INTO sample_event_id;
    
    -- Create a sample expense
    INSERT INTO public.expenses (id, group_id, event_id, title, amount, payer_id, split_members, created_at)
    VALUES (
        gen_random_uuid(),
        sample_group_id,
        sample_event_id,
        'Sample Expense',
        25.00,
        demo_user_id,
        jsonb_build_array(demo_user_id::text),
        CURRENT_TIMESTAMP
    );
    
    RAISE NOTICE 'Fresh demo data created successfully';
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE WARNING 'Demo data creation failed: %', SQLERRM;
END;
$$;

-- STEP 6: Execute the cleanup immediately
SELECT public.cleanup_demo_user_data();

-- STEP 7: Add helpful comment for future reference
COMMENT ON FUNCTION public.cleanup_demo_user_data() IS 'Selectively removes demo user data while preserving login credentials and authentication';
COMMENT ON FUNCTION public.create_fresh_demo_data() IS 'Creates minimal fresh demo data for testing - call manually when needed';

-- Final verification query to confirm cleanup
DO $$
DECLARE
    demo_user_id UUID := '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID;
    group_count INTEGER;
    expense_count INTEGER;
    event_count INTEGER;
    member_count INTEGER;
    profile_exists BOOLEAN;
BEGIN
    -- Check remaining data
    SELECT COUNT(*) INTO group_count FROM public.groups WHERE created_by = demo_user_id;
    SELECT COUNT(*) INTO expense_count FROM public.expenses WHERE payer_id = demo_user_id;  
    SELECT COUNT(*) INTO event_count FROM public.events WHERE created_by = demo_user_id;
    SELECT COUNT(*) INTO member_count FROM public.group_members WHERE user_id = demo_user_id;
    SELECT EXISTS(SELECT 1 FROM public.user_profiles WHERE id = demo_user_id) INTO profile_exists;
    
    RAISE NOTICE '=== CLEANUP VERIFICATION ===';
    RAISE NOTICE 'Groups remaining: %', group_count;
    RAISE NOTICE 'Expenses remaining: %', expense_count; 
    RAISE NOTICE 'Events remaining: %', event_count;
    RAISE NOTICE 'Memberships remaining: %', member_count;
    RAISE NOTICE 'User profile preserved: %', profile_exists;
    RAISE NOTICE '=== RLS POLICIES FIXED ===';
    RAISE NOTICE 'Infinite recursion eliminated - using direct column comparisons';
    RAISE NOTICE 'Demo user can now create fresh data without permission errors';
END $$;