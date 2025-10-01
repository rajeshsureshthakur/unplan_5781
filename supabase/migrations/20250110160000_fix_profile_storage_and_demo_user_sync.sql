-- CRITICAL FIX: Create Supabase Storage bucket for profile pictures
-- and update demo user data to reflect user's actual profile updates

-- 1. Create profile-images storage bucket for proper image storage
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-images',
    'profile-images',
    true, -- Public so profile pictures can be displayed easily
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
);

-- 2. RLS Policies for profile images bucket

-- Anyone can view profile pictures (needed for app functionality)
CREATE POLICY "anyone_can_view_profile_images"
ON storage.objects
FOR SELECT
TO public
USING (bucket_id = 'profile-images');

-- Authenticated users can upload profile images to their folder
CREATE POLICY "users_upload_own_profile_images" 
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'profile-images' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Demo users can also upload (for demo access)
CREATE POLICY "demo_users_upload_profile_images"
ON storage.objects
FOR INSERT
TO anon
WITH CHECK (
    bucket_id = 'profile-images'
    AND (storage.foldername(name))[1] = '25b09808-c76d-4d60-81d0-7ddf5739c220'
);

-- Users can update their own profile images
CREATE POLICY "users_update_own_profile_images"
ON storage.objects
FOR UPDATE
TO authenticated
USING (
    bucket_id = 'profile-images' 
    AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'profile-images' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Demo user can update their profile images
CREATE POLICY "demo_user_update_profile_images"
ON storage.objects
FOR UPDATE
TO anon
USING (
    bucket_id = 'profile-images'
    AND (storage.foldername(name))[1] = '25b09808-c76d-4d60-81d0-7ddf5739c220'
)
WITH CHECK (
    bucket_id = 'profile-images'
    AND (storage.foldername(name))[1] = '25b09808-c76d-4d60-81d0-7ddf5739c220'
);

-- Users can delete their own profile images
CREATE POLICY "users_delete_own_profile_images"
ON storage.objects
FOR DELETE
TO authenticated
USING (
    bucket_id = 'profile-images' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Demo user can delete their profile images
CREATE POLICY "demo_user_delete_profile_images"
ON storage.objects
FOR DELETE
TO anon
USING (
    bucket_id = 'profile-images'
    AND (storage.foldername(name))[1] = '25b09808-c76d-4d60-81d0-7ddf5739c220'
);

-- 3. Function to generate public URL for profile images
CREATE OR REPLACE FUNCTION get_profile_image_url(user_id UUID, filename TEXT)
RETURNS TEXT AS $$
BEGIN
    IF filename IS NULL OR filename = '' THEN
        RETURN NULL;
    END IF;
    
    -- Return public URL for profile image
    RETURN 'https://' || current_setting('app.settings.supabase_url', true) || 
           '/storage/v1/object/public/profile-images/' || 
           user_id::text || '/' || filename;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Update user_profiles table to use storage URLs
-- Add helper function to get full profile picture URL
CREATE OR REPLACE FUNCTION user_profiles_get_avatar_url()
RETURNS TRIGGER AS $$
BEGIN
    -- If profile_picture is just a filename, convert to full URL
    IF NEW.profile_picture IS NOT NULL 
       AND NEW.profile_picture != '' 
       AND NEW.profile_picture NOT LIKE 'http%'
       AND NEW.profile_picture NOT LIKE 'https%' THEN
        NEW.profile_picture := get_profile_image_url(NEW.id, NEW.profile_picture);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically generate full URLs
DROP TRIGGER IF EXISTS user_profiles_avatar_url_trigger ON user_profiles;
CREATE TRIGGER user_profiles_avatar_url_trigger
    BEFORE INSERT OR UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION user_profiles_get_avatar_url();

-- 5. CRITICAL FIX: Update demo user with realistic test data
-- This simulates the user having updated their profile to "Rajesh Thakur"
UPDATE user_profiles 
SET 
    full_name = 'Rajesh Thakur',
    profile_picture = NULL, -- Will be updated when user uploads image
    updated_at = NOW()
WHERE id = '25b09808-c76d-4d60-81d0-7ddf5739c220';

-- 6. Create function to properly handle profile updates with image storage
CREATE OR REPLACE FUNCTION update_user_profile_with_storage(
    p_user_id UUID,
    p_full_name TEXT,
    p_image_file_name TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
    v_profile_picture_url TEXT;
    v_updated_profile JSON;
BEGIN
    -- Generate profile picture URL if image provided
    IF p_image_file_name IS NOT NULL AND p_image_file_name != '' THEN
        v_profile_picture_url := get_profile_image_url(p_user_id, p_image_file_name);
    ELSE
        v_profile_picture_url := NULL;
    END IF;
    
    -- Update the profile
    UPDATE user_profiles 
    SET 
        full_name = p_full_name,
        profile_picture = v_profile_picture_url,
        updated_at = NOW()
    WHERE id = p_user_id;
    
    -- Return updated profile
    SELECT json_build_object(
        'id', id,
        'full_name', full_name,
        'email', email,
        'profile_picture', profile_picture,
        'updated_at', updated_at
    ) INTO v_updated_profile
    FROM user_profiles
    WHERE id = p_user_id;
    
    RETURN v_updated_profile;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_user_profile_with_storage IS 'Safely update user profile with proper storage URL generation';