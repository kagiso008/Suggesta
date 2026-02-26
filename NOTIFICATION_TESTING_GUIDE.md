# Notification System Testing Guide

## Overview
This guide provides instructions for testing the comprehensive notification system implemented in the Suggesta Flutter app. The system includes:
- In-app notifications (Supabase real-time)
- Push notifications (Firebase Cloud Messaging)
- Automatic triggers for user actions
- Database triggers for automatic notification creation

## Prerequisites

### 1. Firebase Setup
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add Android and iOS apps to your Firebase project
3. Download configuration files:
   - `google-services.json` for Android (place in `android/app/`)
   - `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)
4. Enable Firebase Cloud Messaging in your Firebase project

### 2. Supabase Setup
1. Ensure you have a Supabase project with the following tables:
   - `notifications` (already created)
   - `profiles` (with `fcm_token` column added by triggers)
   - `comments`, `messages`, `topic_votes`, `suggestion_votes`
2. Deploy the notification triggers:
   ```sql
   -- Run the entire notification_triggers.sql file in Supabase SQL Editor
   psql -h your-db-host -U postgres -d your-db -f supabase/notification_triggers.sql
   ```
3. Deploy the edge function:
   ```bash
   supabase functions deploy send-push-notification
   ```

### 3. Environment Variables
Ensure your `.env` file contains:
```
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
FCM_SERVER_KEY=your_firebase_server_key  # For edge function
```

## Testing Steps

### Step 1: Build and Run the App
```bash
flutter pub get
flutter run
```

### Step 2: Verify Firebase Initialization
1. Check console logs for "Firebase Messaging initialized successfully"
2. Verify FCM token is generated and stored in user profile

### Step 3: Test In-App Notifications

#### Manual Test Cases:

1. **Comment Notification**
   - User A creates a suggestion
   - User B comments on User A's suggestion
   - Verify User A receives an in-app notification
   - Check notification appears in NotificationsScreen

2. **Message Notification**
   - User A sends a message to User B
   - Verify User B receives an in-app notification
   - Check notification type is 'message'

3. **Vote Notifications**
   - User A creates a topic
   - User B votes on the topic
   - Verify User A receives a 'topic_vote' notification
   - User C creates a suggestion
   - User D votes on the suggestion
   - Verify User C receives a 'suggestion_vote' notification

### Step 4: Test Push Notifications

#### Using Supabase Edge Function:
```bash
curl -X POST https://your-project.supabase.co/functions/v1/send-push-notification \
  -H "Authorization: Bearer your-supabase-anon-key" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user-uuid-here",
    "type": "test",
    "title": "Test Push",
    "body": "This is a test push notification",
    "ref_id": null
  }'
```

#### Expected Results:
1. User receives push notification on device
2. Notification is also stored in database
3. In-app notification count updates in real-time

### Step 5: Test Real-time Updates

1. Open NotificationsScreen on two devices
2. Create a notification on device A
3. Verify device B updates automatically via Supabase real-time subscription

### Step 6: Test Notification Actions

1. **Mark as Read**
   - Tap on a notification
   - Verify it's marked as read
   - Check unread count decreases

2. **Swipe to Delete**
   - Swipe left on a notification
   - Confirm deletion
   - Verify notification is removed from list

3. **Mark All as Read**
   - Use the "Mark all as read" button
   - Verify all notifications are marked as read
   - Check unread count shows 0

## Automated Tests

### Unit Tests
Run existing tests:
```bash
flutter test
```

### Integration Tests
Create test files in `test/` directory:
- `notification_repository_test.dart`
- `notification_provider_test.dart`
- `firebase_messaging_service_test.dart`

## Troubleshooting

### Common Issues:

1. **Firebase not initializing**
   - Check Firebase configuration files are in correct locations
   - Verify Firebase dependencies in pubspec.yaml
   - Check console for initialization errors

2. **No notifications appearing**
   - Verify database triggers are deployed
   - Check Supabase real-time is enabled for notifications table
   - Verify user is authenticated

3. **Push notifications not working**
   - Check FCM server key in environment variables
   - Verify edge function is deployed
   - Check device has notification permissions

4. **Real-time updates not working**
   - Verify Supabase real-time is enabled
   - Check network connectivity
   - Verify subscription is properly set up

## Database Verification

### Check Triggers:
```sql
-- List all triggers
SELECT trigger_name, event_manipulation, event_object_table 
FROM information_schema.triggers 
WHERE trigger_schema = 'public';

-- Test trigger manually
INSERT INTO comments (suggestion_id, user_id, content) 
VALUES ('suggestion-uuid', 'user-uuid', 'Test comment');
```

### Check Notifications Table:
```sql
-- View recent notifications
SELECT * FROM notifications ORDER BY created_at DESC LIMIT 10;

-- Check unread counts
SELECT user_id, COUNT(*) as unread_count 
FROM notifications 
WHERE is_read = false 
GROUP BY user_id;
```

## Performance Testing

1. **Load Testing**
   - Create 100+ notifications for a user
   - Verify UI performance remains smooth
   - Check pagination works correctly

2. **Memory Testing**
   - Monitor memory usage with many notifications
   - Verify proper disposal of streams and subscriptions

## Success Criteria

The notification system is considered successfully implemented when:

1. ✅ In-app notifications appear for all trigger events
2. ✅ Push notifications are received on devices
3. ✅ Real-time updates work across multiple devices
4. ✅ Notification actions (read, delete, mark all) function correctly
5. ✅ Error states are handled gracefully
6. ✅ Performance is acceptable with large notification volumes

## Next Steps After Testing

1. Deploy to production environment
2. Monitor error logs and analytics
3. Gather user feedback on notification preferences
4. Consider adding notification preferences/settings
5. Implement notification categories and filtering