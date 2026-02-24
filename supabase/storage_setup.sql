-- ============================================================
-- AVATAR STORAGE SETUP FOR SUGGESTA
-- Run this entire file in the Supabase SQL Editor
-- ============================================================

-- 1. Create the avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  public = EXCLUDED.public;

-- 2. Enable Row Level Security (RLS) for storage.objects
-- (RLS is usually enabled by default, but we ensure it's on)
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies for the avatars bucket to avoid conflicts
DROP POLICY IF EXISTS "Public avatars are accessible by everyone" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars" ON storage.objects;

-- 4. Create new policies for the avatars bucket

-- Policy 1: Anyone can view avatars (public bucket)
CREATE POLICY "Public avatars are accessible by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Policy 2: Authenticated users can upload avatars
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

-- Policy 3: Users can update their own avatars
-- This policy checks that the user ID matches the first part of the filename
-- Filename format: {user_id}_{timestamp}.{extension}
CREATE POLICY "Users can update their own avatars"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = split_part(name, '_', 1)
)
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.uid()::text = split_part(name, '_', 1)
);

-- Policy 4: Users can delete their own avatars
CREATE POLICY "Users can delete their own avatars"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = split_part(name, '_', 1)
);

-- 5. Optional: Create a function to help with avatar management
CREATE OR REPLACE FUNCTION delete_old_avatar()
RETURNS TRIGGER AS $$
BEGIN
  -- Delete old avatar when a new one is uploaded
  IF OLD.avatar_url IS NOT NULL AND NEW.avatar_url IS NOT NULL AND OLD.avatar_url != NEW.avatar_url THEN
    -- Extract filename from URL (simplified)
    -- This would need to be adapted based on your actual URL structure
    NULL; -- For now, we don't auto-delete old avatars
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- TEST THE SETUP
-- ============================================================

-- After running this script, you can test with:
-- 1. Check if bucket exists:
-- SELECT * FROM storage.buckets WHERE id = 'avatars';

-- 2. Check policies:
-- SELECT * FROM pg_policies WHERE tablename = 'objects' AND schemaname = 'storage';

-- 3. Test upload permission (run in your app):
-- - Login as a user
-- - Try uploading an avatar image
-- - Check if it appears in the storage.objects table:
-- SELECT * FROM storage.objects WHERE bucket_id = 'avatars' LIMIT 5;

-- ============================================================
-- TROUBLESHOOTING
-- ============================================================

-- If you still get RLS errors:
-- 1. Make sure the user is authenticated (has a valid JWT)
-- 2. Check that the bucket_id is exactly 'avatars' (case-sensitive)
-- 3. Verify that RLS is enabled on storage.objects:
-- SELECT relname, relrowsecurity FROM pg_class 
-- WHERE relname = 'objects' AND relnamespace = 'storage'::regnamespace;

-- 4. Temporarily disable RLS for testing (NOT RECOMMENDED FOR PRODUCTION):
-- ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
-- Then re-enable after testing:
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;