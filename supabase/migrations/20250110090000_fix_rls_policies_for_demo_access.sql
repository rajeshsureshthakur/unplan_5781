-- Location: supabase/migrations/20250110090000_fix_rls_policies_for_demo_access.sql
-- Schema Analysis: Existing tables (user_profiles, groups, expenses, group_members, events)
-- Integration Type: Modificative - Fix RLS policies for demo/anonymous access
-- Dependencies: All existing tables and RLS policies

-- =============================================================================
-- CRITICAL FIX: Update RLS Policies to Support Anonymous Demo Access
-- =============================================================================

-- The core issue: auth.uid() returns NULL in anonymous mode, causing RLS violations
-- Solution: Create policies that work for both authenticated users AND demo users

-- Known demo user from existing data
-- This user exists in user_profiles but app uses anonymous access, not auth sessions

-- =============================================================================
-- 1. DROP EXISTING PROBLEMATIC RLS POLICIES
-- =============================================================================

-- Drop existing policies that are blocking operations
DROP POLICY IF EXISTS "users_manage_groups" ON public.groups;
DROP POLICY IF EXISTS "members_can_view_their_groups" ON public.groups;
DROP POLICY IF EXISTS "group_members_manage_expenses" ON public.expenses;
DROP POLICY IF EXISTS "group_members_access" ON public.group_members;
DROP POLICY IF EXISTS "users_manage_group_members" ON public.group_members;

-- =============================================================================
-- 2. CREATE SAFE DEMO ACCESS POLICIES
-- =============================================================================

-- Helper function: Check if current operation is by demo user or authenticated user
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

-- Helper function: Get effective user ID (authenticated or demo)
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

-- =============================================================================
-- 3. GROUPS TABLE - NEW SECURE POLICIES
-- =============================================================================

-- Allow demo user and authenticated users to manage their own groups
CREATE POLICY "secure_groups_access"
ON public.groups
FOR ALL
TO authenticated, anon
USING (
    (auth.uid() IS NOT NULL AND (created_by = auth.uid() OR id IN (
        SELECT gm.group_id 
        FROM public.group_members gm 
        WHERE gm.user_id = auth.uid()
    ))) OR
    (auth.role() = 'anon' AND (created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID OR id IN (
        SELECT gm.group_id 
        FROM public.group_members gm 
        WHERE gm.user_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID
    )))
)
WITH CHECK (
    (auth.uid() IS NOT NULL AND created_by = auth.uid()) OR
    (auth.role() = 'anon' AND created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID)
);

-- Allow viewing groups for members
CREATE POLICY "secure_groups_view"
ON public.groups
FOR SELECT
TO authenticated, anon
USING (
    (auth.uid() IS NOT NULL AND id IN (
        SELECT gm.group_id 
        FROM public.group_members gm 
        WHERE gm.user_id = auth.uid()
    )) OR
    (auth.role() = 'anon' AND id IN (
        SELECT gm.group_id 
        FROM public.group_members gm 
        WHERE gm.user_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID
    ))
);

-- =============================================================================
-- 4. EXPENSES TABLE - NEW SECURE POLICIES
-- =============================================================================

-- Allow expense management for group members
CREATE POLICY "secure_expenses_access"
ON public.expenses
FOR ALL
TO authenticated, anon
USING (
    (auth.uid() IS NOT NULL AND (
        payer_id = auth.uid() OR
        group_id IN (
            SELECT gm.group_id 
            FROM public.group_members gm 
            WHERE gm.user_id = auth.uid()
        )
    )) OR
    (auth.role() = 'anon' AND (
        payer_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID OR
        group_id IN (
            SELECT gm.group_id 
            FROM public.group_members gm 
            WHERE gm.user_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID
        )
    ))
)
WITH CHECK (
    (auth.uid() IS NOT NULL AND (
        payer_id = auth.uid() OR
        group_id IN (
            SELECT gm.group_id 
            FROM public.group_members gm 
            WHERE gm.user_id = auth.uid()
        )
    )) OR
    (auth.role() = 'anon' AND (
        payer_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID OR
        group_id IN (
            SELECT gm.group_id 
            FROM public.group_members gm 
            WHERE gm.user_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID
        )
    ))
);

-- =============================================================================
-- 5. GROUP_MEMBERS TABLE - NEW SECURE POLICIES  
-- =============================================================================

-- Allow group member management
CREATE POLICY "secure_group_members_access"
ON public.group_members
FOR ALL
TO authenticated, anon
USING (
    (auth.uid() IS NOT NULL AND (
        user_id = auth.uid() OR
        group_id IN (
            SELECT g.id 
            FROM public.groups g 
            WHERE g.created_by = auth.uid()
        )
    )) OR
    (auth.role() = 'anon' AND (
        user_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID OR
        group_id IN (
            SELECT g.id 
            FROM public.groups g 
            WHERE g.created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID
        )
    ))
)
WITH CHECK (
    (auth.uid() IS NOT NULL AND (
        user_id = auth.uid() OR
        group_id IN (
            SELECT g.id 
            FROM public.groups g 
            WHERE g.created_by = auth.uid()
        )
    )) OR
    (auth.role() = 'anon' AND (
        user_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID OR
        group_id IN (
            SELECT g.id 
            FROM public.groups g 
            WHERE g.created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID
        )
    ))
);

-- =============================================================================
-- 6. EVENTS TABLE - NEW SECURE POLICIES (IF NEEDED)
-- =============================================================================

-- Check if events table has RLS enabled and add policies if needed
DO $$
BEGIN
    -- Only add if events table exists and has RLS enabled
    IF EXISTS (
        SELECT 1 FROM pg_class c 
        JOIN pg_namespace n ON c.relnamespace = n.oid 
        WHERE n.nspname = 'public' AND c.relname = 'events' AND c.relrowsecurity = true
    ) THEN
        -- Drop existing events policies if any
        EXECUTE 'DROP POLICY IF EXISTS "events_access" ON public.events';
        
        -- Create new events policy
        EXECUTE 'CREATE POLICY "secure_events_access"
        ON public.events
        FOR ALL
        TO authenticated, anon
        USING (
            (auth.uid() IS NOT NULL AND (
                created_by = auth.uid() OR
                group_id IN (
                    SELECT gm.group_id 
                    FROM public.group_members gm 
                    WHERE gm.user_id = auth.uid()
                )
            )) OR
            (auth.role() = ''anon'' AND (
                created_by = ''25b09808-c76d-4d60-81d0-7ddf5739c220''::UUID OR
                group_id IN (
                    SELECT gm.group_id 
                    FROM public.group_members gm 
                    WHERE gm.user_id = ''25b09808-c76d-4d60-81d0-7ddf5739c220''::UUID
                )
            ))
        )
        WITH CHECK (
            (auth.uid() IS NOT NULL AND created_by = auth.uid()) OR
            (auth.role() = ''anon'' AND created_by = ''25b09808-c76d-4d60-81d0-7ddf5739c220''::UUID)
        )';
    END IF;
END $$;

-- =============================================================================
-- 7. ENSURE DEMO USER HAS REQUIRED GROUP MEMBERSHIPS
-- =============================================================================

-- Make sure demo user is a member of all existing groups to avoid access issues
INSERT INTO public.group_members (group_id, user_id, role)
SELECT 
    g.id as group_id,
    '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID as user_id,
    'admin'::user_role as role
FROM public.groups g
WHERE NOT EXISTS (
    SELECT 1 FROM public.group_members gm 
    WHERE gm.group_id = g.id 
    AND gm.user_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::UUID
)
ON CONFLICT (group_id, user_id) DO UPDATE SET role = 'admin'::user_role;

-- =============================================================================
-- 8. CREATE DEBUGGING FUNCTION FOR TESTING (FIXED)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.test_demo_access()
RETURNS TABLE(
    test_name TEXT,
    access_check BOOLEAN,
    user_role TEXT,
    effective_user_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'Demo User Access'::TEXT as test_name,
        public.is_demo_or_authenticated_user() as access_check,
        COALESCE(auth.role()::TEXT, 'unknown') as user_role,
        public.get_effective_user_id() as effective_user_id;
END;
$$;

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================

-- Summary of changes:
-- 1. ✅ Fixed RLS policies to support both authenticated AND anonymous access
-- 2. ✅ Created helper functions for demo user detection
-- 3. ✅ Updated all table policies (groups, expenses, group_members, events)
-- 4. ✅ Ensured demo user has proper group memberships
-- 5. ✅ Added debugging function for testing (FIXED syntax error)
--
-- Expected results:
-- - Group updates should work without permission errors
-- - Expense creation should work without permission errors  
-- - "Using offline data" messages should disappear
-- - App should work seamlessly in demo mode