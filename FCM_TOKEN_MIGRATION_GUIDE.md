# FCM Token Database Migration Guide

## Problem
The app is failing to store FCM tokens with the error:
```
Failed to store FCM token: PostgrestException(message: Could not find the 'fcm_token' column of 'profiles' in the schema cache
```

This error occurs because the `profiles` table doesn't have an `fcm_token` column for storing Firebase Cloud Messaging tokens.

## Solution
You need to run a SQL migration to add the `fcm_token` column to the `profiles` table.

## Migration Steps

### Option 1: Via Supabase Dashboard (Recommended)
1. Go to the [Supabase Dashboard](https://supabase.com/dashboard/project/tvmbdqkwxsnaaeaujbsd/sql)
2. Click on the "SQL Editor" tab
3. Paste the following SQL code:

```sql
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
```

4. Click "Run" to execute the SQL
5. After running, refresh the schema cache by clicking "Reload Schema" in the Supabase dashboard

### Option 2: Via Supabase CLI
If you have Docker running and Supabase CLI configured:

```bash
# Start Supabase local development
supabase start

# Run the migration
supabase db reset

# Or apply the specific migration file
supabase db push
```

### Option 3: Manual SQL Execution
If you have `psql` installed:

```bash
# Connect to your Supabase database
psql "postgresql://postgres:[YOUR_PASSWORD]@db.tvmbdqkwxsnaaeaujbsd.supabase.co:5432/postgres"

# Then run the SQL commands from the migration file
\i supabase/migrations/20260226_add_fcm_token_to_profiles.sql
```

## Verification
After applying the migration:

1. The app should stop showing the "Could not find the 'fcm_token' column" error
2. FCM tokens should be successfully stored in the database
3. Push notifications should work when triggered via the Supabase edge function

## Notes
- The migration file is already created at `supabase/migrations/20260226_add_fcm_token_to_profiles.sql`
- The migration is idempotent (safe to run multiple times)
- After adding the column, you may need to restart the app or wait for PostgREST to refresh its schema cache
- The `update_fcm_token` function is used by the `NotificationRepository` to store tokens

## Next Steps
After applying the migration:
1. Restart the Flutter app
2. Verify FCM tokens are being stored successfully
3. Test push notifications using the Supabase edge function
4. Test in-app notifications by creating comments, messages, or votes