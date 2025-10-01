-- Location: supabase/migrations/20250110150000_cleanup_demo_user_data.sql
-- Schema Analysis: Existing complete group management system with user_profiles, groups, group_members, events, expenses
-- Integration Type: Data cleanup for demo user
-- Dependencies: All existing tables remain unchanged

-- Create comprehensive cleanup function for demo user data
CREATE OR REPLACE FUNCTION public.cleanup_demo_user_data()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    demo_user_id UUID := '25b09808-c76d-4d60-81d0-7ddf5739c220';
    cleanup_count INTEGER;
BEGIN
    -- Delete in dependency order (children first, then parents)
    
    -- 1. Delete expenses (references groups and user_profiles)
    DELETE FROM public.expenses 
    WHERE payer_id = demo_user_id;
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % expenses for demo user', cleanup_count;

    -- 2. Delete events (references groups and user_profiles)
    DELETE FROM public.events 
    WHERE created_by = demo_user_id;
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % events for demo user', cleanup_count;

    -- 3. Delete group memberships
    DELETE FROM public.group_members 
    WHERE user_id = demo_user_id;
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % group memberships for demo user', cleanup_count;

    -- 4. Delete groups created by demo user
    DELETE FROM public.groups 
    WHERE created_by = demo_user_id;
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % groups created by demo user', cleanup_count;

    -- 5. Reset user profile to clean state (preserve login credentials)
    UPDATE public.user_profiles 
    SET 
        full_name = 'Demo User',
        profile_picture = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = demo_user_id;
    
    -- 6. Clean up any orphaned data that might reference the demo user
    DELETE FROM public.expenses 
    WHERE group_id IN (
        SELECT id FROM public.groups 
        WHERE created_by = demo_user_id
    );

    DELETE FROM public.events 
    WHERE group_id IN (
        SELECT id FROM public.groups 
        WHERE created_by = demo_user_id
    );

    DELETE FROM public.group_members 
    WHERE group_id IN (
        SELECT id FROM public.groups 
        WHERE created_by = demo_user_id
    );

    RAISE NOTICE 'Demo user data cleanup completed successfully';
    
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
        RAISE;
END;
$$;

-- Execute the cleanup function immediately
SELECT public.cleanup_demo_user_data();

-- Create a function to verify cleanup status
CREATE OR REPLACE FUNCTION public.verify_demo_user_cleanup()
RETURNS TABLE(
    table_name TEXT,
    record_count BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    demo_user_id UUID := '25b09808-c76d-4d60-81d0-7ddf5739c220';
BEGIN
    RETURN QUERY
    SELECT 'expenses'::TEXT, COUNT(*)::BIGINT FROM public.expenses WHERE payer_id = demo_user_id
    UNION ALL
    SELECT 'events'::TEXT, COUNT(*)::BIGINT FROM public.events WHERE created_by = demo_user_id
    UNION ALL
    SELECT 'group_members'::TEXT, COUNT(*)::BIGINT FROM public.group_members WHERE user_id = demo_user_id
    UNION ALL
    SELECT 'groups'::TEXT, COUNT(*)::BIGINT FROM public.groups WHERE created_by = demo_user_id
    UNION ALL
    SELECT 'user_profiles'::TEXT, COUNT(*)::BIGINT FROM public.user_profiles WHERE id = demo_user_id;
END;
$$;

-- Display cleanup verification results
SELECT * FROM public.verify_demo_user_cleanup();

-- Drop the cleanup function after use (optional, can be kept for future use)
-- DROP FUNCTION IF EXISTS public.cleanup_demo_user_data();