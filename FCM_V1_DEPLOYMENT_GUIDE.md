# FCM HTTP v1 API Deployment Guide

## Overview
The notification system has been updated to use Firebase Cloud Messaging HTTP v1 API with OAuth2 authentication using your Firebase service account.

## What's Been Implemented

### 1. **Updated Supabase Edge Function**
- `supabase/functions/send-push-notification/index.ts` now supports:
  - **FCM HTTP v1 API** (`https://fcm.googleapis.com/v1/projects/suggesta-c67a4/messages:send`)
  - **Legacy API fallback** for backward compatibility
  - **Automatic token selection** based on configuration

### 2. **Service Account Integration**
- Your Firebase service account key has been saved as `firebase-service-account.json`
- The edge function can authenticate using OAuth2 JWT tokens

## Deployment Steps

### Step 1: Set Environment Variables in Supabase

```bash
# Set your Firebase service account (use the JSON you provided)
supabase secrets set FIREBASE_SERVICE_ACCOUNT='{
  "type": "service_account",
  "project_id": "your-project-id",
  "private_key_id": "your-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\nYOUR_PRIVATE_KEY_HERE\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-xxx@your-project-id.iam.gserviceaccount.com",
  "client_id": "your-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-xxx%40your-project-id.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}'

# Set FCM server key (legacy API fallback)
supabase secrets set FCM_SERVER_KEY=your_fcm_server_key_here

# Set Supabase credentials
supabase secrets set SUPABASE_URL=your_supabase_url
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_supabase_service_role_key
```

### Step 2: Deploy the Edge Function

```bash
# Deploy to Supabase
supabase functions deploy send-push-notification

# Or deploy with specific environment
supabase functions deploy send-push-notification --no-verify-jwt
```

### Step 3: Test the FCM v1 API

#### Test using curl:
```bash
curl -X POST https://your-project.supabase.co/functions/v1/send-push-notification \
  -H "Authorization: Bearer your-supabase-anon-key" \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user-uuid-here",
    "type": "test",
    "title": "Test FCM v1",
    "body": "This is a test using FCM HTTP v1 API",
    "ref_id": null
  }'
```

#### Expected FCM v1 API call:
```
POST https://fcm.googleapis.com/v1/projects/suggesta-c67a4/messages:send
Authorization: Bearer ya29.c.b0ATv...
Content-Type: application/json

{
  "message": {
    "token": "fcm-device-token",
    "notification": {
      "title": "Test FCM v1",
      "body": "This is a test using FCM HTTP v1 API"
    },
    "data": {
      "type": "test",
      "ref_id": "",
      "click_action": "FLUTTER_NOTIFICATION_CLICK"
    },
    "android": {
      "priority": "HIGH",
      "notification": {
        "channel_id": "suggesta_notifications",
        "sound": "default",
        "icon": "ic_notification",
        "color": "#FF6B35"
      }
    },
    "apns": {
      "headers": {
        "apns-priority": "10"
      },
      "payload": {
        "aps": {
          "alert": {
            "title": "Test FCM v1",
            "body": "This is a test using FCM HTTP v1 API"
          },
          "sound": "default",
          "badge": 1
        }
      }
    }
  }
}
```

## Configuration Options

### Option A: Use FCM v1 API (Recommended)
- **Pros**: More features, better security, future-proof
- **Cons**: Requires service account setup
- **Setup**: Set `FIREBASE_SERVICE_ACCOUNT` environment variable

### Option B: Use Legacy FCM API
- **Pros**: Simpler, no OAuth2 required
- **Cons**: Limited features, deprecated
- **Setup**: Set `FCM_SERVER_KEY` environment variable

### Option C: Both (Fallback)
- The edge function automatically falls back to legacy API if service account is not configured
- Set both environment variables for maximum compatibility

## Troubleshooting

### Common Issues:

1. **"Failed to get OAuth2 access token"**
   - Verify service account JSON is correctly formatted
   - Check service account has "Firebase Cloud Messaging API" enabled
   - Ensure private key is valid

2. **"FCM v1 API error: 401"**
   - Authentication failed
   - Check OAuth2 token generation
   - Verify service account has proper permissions

3. **"FCM v1 API error: 403"**
   - Service account doesn't have FCM permissions
   - Go to Google Cloud Console → IAM & Admin → IAM
   - Add "Firebase Cloud Messaging API Admin" role to service account

4. **Legacy API still being used**
   - Check `FIREBASE_SERVICE_ACCOUNT` environment variable is set
   - Verify JSON parsing doesn't fail

### Testing JWT Generation:
The current implementation uses a simplified JWT creation. For production:

1. Install a JWT library for Deno:
```typescript
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";
```

2. Implement proper JWT signing with RSA private key

## Monitoring

### Check Edge Function Logs:
```bash
supabase functions logs send-push-notification
```

### Monitor FCM Delivery:
1. Go to Firebase Console → Cloud Messaging → Reports
2. Check delivery statistics
3. Monitor error rates

## Security Notes

1. **Service Account Key**: Keep secure, never commit to version control
2. **Environment Variables**: Use Supabase secrets for sensitive data
3. **JWT Tokens**: Implement proper JWT signing in production
4. **API Access**: Restrict edge function access with JWT verification

## Next Steps

1. **Implement proper JWT signing** with a Deno JWT library
2. **Add retry logic** for failed FCM deliveries
3. **Implement notification batching** for multiple recipients
4. **Add analytics** to track notification performance
5. **Set up monitoring alerts** for delivery failures

## Success Verification

The FCM v1 API is successfully configured when:

1. ✅ Edge function deploys without errors
2. ✅ Notifications are inserted into database
3. ✅ FCM v1 API calls return success (check logs)
4. ✅ Push notifications are received on devices
5. ✅ No "legacy API" warnings in logs (if using v1)