-- Migration to add FCM token column to profiles table for push notifications
-- This column stores Firebase Cloud Messaging tokens for sending push notifications

-- Add FCM token column to profiles table if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' AND column_name = 'fcm_token'
    ) THEN
        ALTER TABLE profiles ADD COLUMN fcm_token TEXT;
        CREATE INDEX idx_profiles_fcm_token ON profiles(fcm_token) WHERE fcm_token IS NOT NULL;
        RAISE NOTICE 'Added fcm_token column to profiles table';
    ELSE
        RAISE NOTICE 'fcm_token column already exists in profiles table';
    END IF;
END $$;

-- Create or replace function to update FCM token
CREATE OR REPLACE FUNCTION update_fcm_token(
    user_id UUID,
    token TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE profiles 
    SET fcm_token = token 
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_fcm_token(UUID, TEXT) TO authenticated;