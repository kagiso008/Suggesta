# Avatar Storage Setup for Suggesta

## Prerequisites
- Supabase project with the existing schema already deployed
- Supabase CLI installed (optional)

## Steps to Enable Avatar Uploads

### 1. Create Storage Bucket

You need to create a storage bucket named `avatars` in your Supabase project. You can do this via:

#### Option A: Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to **Storage** → **Create new bucket**
3. Name: `avatars`
4. Public: ✅ **Enable** (so images can be accessed without authentication)
5. File size limit: 5MB (recommended)
6. Click **Create bucket**

#### Option B: SQL Command
Run this SQL in the Supabase SQL Editor:

```sql
-- Create the avatars bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars', 'avatars', true);

-- Set up Row Level Security (RLS) policies
CREATE POLICY "Public avatars are accessible by everyone"
ON storage.objects FOR SELECT
USING (bucket_id = 'avatars');

CREATE POLICY "Authenticated users can upload avatars"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.role() = 'authenticated'
);

CREATE POLICY "Users can update their own avatars"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own avatars"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'avatars' 
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

### 2. Update Existing Profiles (Optional)

If you want to migrate existing profiles to have avatar URLs, you can update the `avatar_url` column:

```sql
-- Example: Set default avatar for users who don't have one
UPDATE profiles 
SET avatar_url = 'https://api.dicebear.com/7.x/initials/svg?seed=' || username
WHERE avatar_url IS NULL;
```

### 3. Test the Feature

1. Run the app: `flutter run`
2. Navigate to Profile screen
3. Tap "Edit Profile"
4. You should see a camera icon on the avatar
5. Tap the camera icon to select an image from your gallery
6. The image will upload to Supabase Storage and update your profile

## Troubleshooting

### "Bucket not found" error
Ensure the bucket `avatars` exists and is public.

### "Permission denied" error
Check that the RLS policies are correctly set up. The SQL above should handle this.

### Image not displaying
- Check that the `avatar_url` is being saved correctly in the profiles table
- Verify the URL is accessible (open in browser)
- Ensure `cached_network_image` package is properly installed

## Code Changes Made

The following files were modified to implement the profile picture feature:

1. **`lib/features/profile/presentation/screens/profile_screen.dart`**
   - Added avatar upload UI with camera button
   - Added image display using `CachedNetworkImage`
   - Implemented `_pickAndUploadAvatar()` method
   - Added loading states and error handling

2. **`lib/features/auth/data/auth_repository.dart`**
   - Added `supabaseClient` getter
   - Updated `updateProfile()` method to accept `avatarUrl` parameter

3. **Dependencies** (already present in `pubspec.yaml`)
   - `image_picker: ^1.1.2`
   - `cached_network_image: ^3.3.1`
   - `supabase_flutter: ^2.5.0`

## Notes

- The avatar upload only works when in edit mode (tap "Edit Profile")
- Images are stored with filename format: `{user_id}_{timestamp}.{extension}`
- Existing avatars are overwritten (upsert) when a new image is uploaded
- The feature includes fallback to initials if no avatar is set
- Loading indicators show during upload and image loading