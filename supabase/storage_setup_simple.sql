-- ============================================================
-- SIMPLE AVATAR STORAGE SETUP (For Testing)
-- Run this in Supabase SQL Editor to quickly fix RLS errors
-- ============================================================

-- 1. Create the avatars bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  public = EXCLUDED.public;

-- 2. Drop ALL existing policies for the avatars bucket
DROP POLICY IF EXISTS "Public avatars are accessible by everyone" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own avatars" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own avatars" ON storage.objects;

-- 3. Create SIMPLE policies that allow all operations for authenticated users
-- Policy 1: Anyone can view avatars
CREATE POLICY "Anyone can view avatars"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

-- Policy 2: Authenticated users can upload any file to avatars
CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

-- Policy 3: Authenticated users can update any file in avatars
CREATE POLICY "Authenticated users can update avatars"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
)
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

-- Policy 4: Authenticated users can delete any file in avatars
CREATE POLICY "Authenticated users can delete avatars"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

-- ============================================================
-- ALTERNATIVE: Disable RLS entirely for testing (NOT FOR PRODUCTION)
-- ============================================================
-- Uncomment below if you still get RLS errors:
/*
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;
*/

-- ============================================================
-- VERIFICATION
-- ============================================================

-- Check if bucket was created
SELECT * FROM storage.buckets WHERE id = 'avatars';

-- Check policies
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
  AND schemaname = 'storage'
ORDER BY policyname;

-- ============================================================
-- TROUBLESHOOTING TIPS
-- ============================================================

-- If you still get errors:
-- 1. Make sure you've run this SQL in the Supabase SQL Editor
-- 2. Wait a few seconds for changes to propagate
-- 3. Restart your app
-- 4. Check that the user is logged in (auth.role() = 'authenticated')
-- 5. Try uploading a small image file first

-- Common error messages and solutions:
-- "bucket not found" -> Run the INSERT statement above again
-- "new row violates row-level security policy" -> Policies are too restrictive, use the simple policies above
-- "permission denied for table storage.objects" -> RLS is blocking the operation, try disabling RLS temporarily