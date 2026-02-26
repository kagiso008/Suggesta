# Send Push Notification Edge Function

This Supabase Edge Function handles sending push notifications to users via Firebase Cloud Messaging (FCM).

## Functionality

1. **Insert Notification**: Creates a notification record in the `notifications` table
2. **Fetch FCM Token**: Retrieves the user's FCM token from their profile
3. **Send Push Notification**: Sends a push notification via FCM if a token exists

## Environment Variables Required

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: Supabase service role key (for admin access)
- `FCM_SERVER_KEY`: Firebase Cloud Messaging server key

## Request Format

```json
{
  "userId": "user-uuid-here",
  "title": "Notification Title",
  "body": "Notification body text",
  "type": "topic_vote|suggestion_vote|comment|message|milestone|test",
  "refId": "optional-reference-id"
}
```

## Response Format

```json
{
  "success": true,
  "message": "Notification processed successfully",
  "notificationId": "generated-notification-id",
  "fcmSent": true
}
```

## Error Responses

- **400 Bad Request**: Missing or invalid required fields
- **500 Internal Server Error**: Server configuration or database error

## Database Schema Requirements

The function expects the following tables:

### `notifications` table
```sql
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('topic_vote', 'suggestion_vote', 'comment', 'message', 'milestone')),
  title TEXT,
  body TEXT,
  is_read BOOLEAN DEFAULT false,
  ref_id UUID,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### `profiles` table
Must have an `fcm_token` column:
```sql
ALTER TABLE profiles ADD COLUMN fcm_token TEXT;
```

## Deployment

1. Ensure environment variables are set in your Supabase project
2. Deploy the function:
   ```bash
   supabase functions deploy send-push-notification
   ```

## Usage Example

```javascript
// From your Flutter app
await supabase.functions.invoke('send-push-notification', {
  body: {
    userId: 'user-uuid',
    title: 'New Comment',
    body: 'Someone commented on your suggestion',
    type: 'comment',
    refId: 'comment-uuid'
  }
});
```

## Testing

You can test the function using curl:

```bash
curl -X POST https://your-project.supabase.co/functions/v1/send-push-notification \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "test-user-id",
    "title": "Test Notification",
    "body": "This is a test notification",
    "type": "test"
  }'