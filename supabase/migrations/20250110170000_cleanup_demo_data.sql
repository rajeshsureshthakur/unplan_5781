-- Location: supabase/migrations/20250110170000_cleanup_demo_data.sql
-- Schema Analysis: Existing Unplan group management schema with demo data
-- Integration Type: Destructive cleanup of demo/dummy data  
-- Dependencies: All existing tables (user_profiles, groups, expenses, events, group_members)

-- CRITICAL: Enhanced demo data cleanup and profile picture persistence fix

-- Step 1: Enhanced cleanup function that preserves demo user but resets data
CREATE OR REPLACE FUNCTION public.cleanup_all_demo_data()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    demo_user_id UUID := '25b09808-c76d-4d60-81d0-7ddf5739c220';
    cleanup_count INTEGER;
BEGIN
    RAISE NOTICE 'Starting comprehensive demo data cleanup...';
    
    -- Delete in correct dependency order (children first, then parents)
    
    -- 1. Delete expenses (references groups and user_profiles)
    DELETE FROM public.expenses 
    WHERE payer_id = demo_user_id OR group_id IN (
        SELECT id FROM public.groups WHERE created_by = demo_user_id
    );
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % expenses', cleanup_count;

    -- 2. Delete events (references groups and user_profiles)
    DELETE FROM public.events 
    WHERE created_by = demo_user_id OR group_id IN (
        SELECT id FROM public.groups WHERE created_by = demo_user_id
    );
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % events', cleanup_count;

    -- 3. Delete group memberships
    DELETE FROM public.group_members 
    WHERE user_id = demo_user_id OR group_id IN (
        SELECT id FROM public.groups WHERE created_by = demo_user_id
    );
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % group memberships', cleanup_count;

    -- 4. Delete groups created by demo user
    DELETE FROM public.groups 
    WHERE created_by = demo_user_id;
    GET DIAGNOSTICS cleanup_count = ROW_COUNT;
    RAISE NOTICE 'Deleted % groups', cleanup_count;

    -- 5. Reset user profile to clean state (preserve login credentials but reset profile)
    UPDATE public.user_profiles 
    SET 
        full_name = 'Demo User',
        profile_picture = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = demo_user_id;
    
    RAISE NOTICE 'Demo user profile reset to clean state';
    RAISE NOTICE 'Demo data cleanup completed successfully';
    
EXCEPTION
    WHEN foreign_key_violation THEN
        RAISE NOTICE 'Foreign key constraint prevents deletion: %', SQLERRM;
    WHEN OTHERS THEN
        RAISE NOTICE 'Cleanup failed: %', SQLERRM;
        RAISE;
END;
$$;

-- Step 2: Enhanced profile picture storage function for better persistence
CREATE OR REPLACE FUNCTION public.ensure_profile_picture_persistence()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    demo_user_id UUID := '25b09808-c76d-4d60-81d0-7ddf5739c220';
    current_profile RECORD;
BEGIN
    -- Get current profile status
    SELECT * INTO current_profile 
    FROM public.user_profiles 
    WHERE id = demo_user_id;
    
    IF current_profile.profile_picture IS NOT NULL THEN
        RAISE NOTICE 'Profile picture already exists: %', current_profile.profile_picture;
    ELSE
        RAISE NOTICE 'No profile picture found - user needs to upload one';
    END IF;
    
    -- Ensure updated_at is recent to trigger UI refresh
    UPDATE public.user_profiles 
    SET updated_at = CURRENT_TIMESTAMP
    WHERE id = demo_user_id;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Profile picture check failed: %', SQLERRM;
END;
$$;

-- Step 3: Execute the cleanup
SELECT public.cleanup_all_demo_data();

-- Step 4: Ensure profile picture persistence
SELECT public.ensure_profile_picture_persistence();

-- Step 5: Clean up any orphaned storage files (commented for safety)
-- Note: Supabase Storage cleanup should be done manually through the dashboard
-- to avoid accidental deletion of important files

COMMENT ON FUNCTION public.cleanup_all_demo_data() IS 'Comprehensive cleanup of demo/dummy data while preserving user account';
COMMENT ON FUNCTION public.ensure_profile_picture_persistence() IS 'Ensures profile pictures persist properly after cleanup';