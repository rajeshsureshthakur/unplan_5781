-- Complete Final Data Cleanup Migration
-- Created: 2025-01-10 20:00:00
-- Purpose: Completely remove all dummy data for final release version

BEGIN;

-- ================================================================================
-- STEP 1: COMPREHENSIVE DATA CLEANUP - Remove ALL existing data
-- ================================================================================

-- Delete in proper dependency order to avoid foreign key violations
DELETE FROM public.poll_votes;
DELETE FROM public.poll_options;
DELETE FROM public.polls;
DELETE FROM public.reactions;
DELETE FROM public.notes;
DELETE FROM public.expenses;
DELETE FROM public.events;
DELETE FROM public.group_members;
DELETE FROM public.groups;

-- Clean ALL user profiles including the previous demo user
DELETE FROM public.user_profiles;

-- Also clean auth.users to ensure completely fresh start
DELETE FROM auth.users WHERE email LIKE '%@weekend.com' OR email LIKE '%@unplan.app';

-- ================================================================================
-- STEP 2: RECREATE DEMO USER WITH PROPER STRUCTURE
-- ================================================================================

-- Create fresh demo user profile for development/testing
INSERT INTO public.user_profiles (
    id,
    full_name,
    email,
    phone,
    profile_picture,
    role,
    created_at,
    updated_at
) VALUES (
    '25b09808-c76d-4d60-81d0-7ddf5739c220',
    'Demo User',
    'demo@unplan.app',
    NULL,
    NULL,
    'member'::user_role,
    NOW(),
    NOW()
) ON CONFLICT (id) DO UPDATE SET
    full_name = EXCLUDED.full_name,
    email = EXCLUDED.email,
    profile_picture = NULL, -- Reset profile picture
    updated_at = NOW();

-- ================================================================================
-- STEP 3: ADD DEMO ACCESS POLICIES FOR ANON USERS
-- ================================================================================

-- Add demo access policies to allow the app to work with demo user without authentication
-- This enables the app to function for demo/preview purposes

-- Demo access policy for user_profiles
DROP POLICY IF EXISTS "demo_access_user_profiles" ON public.user_profiles;
CREATE POLICY "demo_access_user_profiles"
ON public.user_profiles
FOR ALL
TO anon
USING (id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid)
WITH CHECK (id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid);

-- Demo access policy for groups
DROP POLICY IF EXISTS "demo_access_groups" ON public.groups;
CREATE POLICY "demo_access_groups"
ON public.groups
FOR ALL
TO anon
USING (created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid)
WITH CHECK (created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid);

-- Demo access policy for group_members
DROP POLICY IF EXISTS "demo_access_group_members" ON public.group_members;
CREATE POLICY "demo_access_group_members"
ON public.group_members
FOR ALL
TO anon
USING (user_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid)
WITH CHECK (user_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid);

-- Demo access policy for events
DROP POLICY IF EXISTS "demo_access_events" ON public.events;
CREATE POLICY "demo_access_events"
ON public.events
FOR ALL
TO anon
USING (created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid)
WITH CHECK (created_by = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid);

-- Demo access policy for expenses
DROP POLICY IF EXISTS "demo_access_expenses" ON public.expenses;
CREATE POLICY "demo_access_expenses"
ON public.expenses
FOR ALL
TO anon
USING (payer_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid)
WITH CHECK (payer_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid);

-- Demo access policy for notes
DROP POLICY IF EXISTS "demo_access_notes" ON public.notes;
CREATE POLICY "demo_access_notes"
ON public.notes
FOR ALL
TO anon
USING (author_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid)
WITH CHECK (author_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid);

-- Demo access policy for polls
DROP POLICY IF EXISTS "demo_access_polls" ON public.polls;
CREATE POLICY "demo_access_polls"
ON public.polls
FOR ALL
TO anon
USING (author_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid)
WITH CHECK (author_id = '25b09808-c76d-4d60-81d0-7ddf5739c220'::uuid);

-- ================================================================================
-- STEP 4: VERIFICATION FUNCTIONS
-- ================================================================================

-- Function to verify complete data cleanup
CREATE OR REPLACE FUNCTION verify_final_cleanup()
RETURNS TABLE(
    table_name text,
    row_count bigint,
    status text
) 
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        'user_profiles'::text,
        COUNT(*)::bigint,
        CASE 
            WHEN COUNT(*) = 1 THEN '✅ CLEAN - Demo user only'
            WHEN COUNT(*) = 0 THEN '❌ ERROR - No demo user'
            ELSE '⚠️ WARNING - Multiple users exist'
        END::text
    FROM public.user_profiles
    
    UNION ALL
    
    SELECT 'groups'::text, COUNT(*)::bigint, 
           CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN - No data' ELSE '⚠️ HAS DATA' END::text
    FROM public.groups
    
    UNION ALL
    
    SELECT 'events'::text, COUNT(*)::bigint,
           CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN - No data' ELSE '⚠️ HAS DATA' END::text
    FROM public.events
    
    UNION ALL
    
    SELECT 'expenses'::text, COUNT(*)::bigint,
           CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN - No data' ELSE '⚠️ HAS DATA' END::text
    FROM public.expenses
    
    UNION ALL
    
    SELECT 'auth_users'::text, COUNT(*)::bigint,
           CASE WHEN COUNT(*) = 0 THEN '✅ CLEAN - No auth users' ELSE '⚠️ HAS AUTH DATA' END::text
    FROM auth.users;
END;
$$;

-- ================================================================================
-- STEP 5: LOG FINAL CLEANUP COMPLETION
-- ================================================================================

DO $$
BEGIN
    RAISE NOTICE '============================================';
    RAISE NOTICE 'FINAL COMPLETE DATA CLEANUP COMPLETED';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Timestamp: %', NOW();
    RAISE NOTICE 'Demo User ID: 25b09808-c76d-4d60-81d0-7ddf5739c220';
    RAISE NOTICE 'Status: ALL dummy data removed';
    RAISE NOTICE 'Status: Database ready for fresh production data';
    RAISE NOTICE 'Status: Demo access policies enabled for preview';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Next Steps:';
    RAISE NOTICE '1. Test app with clean database';
    RAISE NOTICE '2. Verify no dummy data appears';
    RAISE NOTICE '3. Test user profile image updates';
    RAISE NOTICE '4. Verify group creation works';
    RAISE NOTICE '============================================';
END;
$$;

COMMIT;