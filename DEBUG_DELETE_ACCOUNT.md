# Delete Account Feature - Debug Logging Guide

## Overview
Comprehensive logging has been added to the delete account feature to help debug issues. The logging covers both Flutter client-side and the Supabase Edge Function server-side.

## Where to Find Logs

### Flutter Client Logs
1. Open VS Code Debug Console or Xcode console
2. Look for logs starting with `[PROFILE-SCREEN]` and `[AUTH-REPO]`
3. Run the app with `flutter run` to see logs in real-time

### Supabase Edge Function Logs
1. Go to Supabase Dashboard
2. Navigate to: **Edge Functions → delete-account → Logs**
3. Look for logs starting with `[DELETE-ACCOUNT]`

## Log Flow & What Each Message Means

### 1. Profile Screen Handler Initiated
```
[PROFILE-SCREEN] ========== DELETE ACCOUNT HANDLER CALLED ==========
[PROFILE-SCREEN] Current user ID: <user-id>
[PROFILE-SCREEN] Current user email: <email>
```
**Meaning:** User tapped the delete button. These logs show the authenticated user.

### 2. Delete Confirmation Dialog
```
[PROFILE-SCREEN] Showing delete confirmation dialog...
[PROFILE-SCREEN] Delete confirmed: true/false
```
**Meaning:** Dialog shown to confirm deletion. `true` = user confirmed, `false` = cancelled.

### 3. Auth Repository Session Check
```
[AUTH-REPO] ========== DELETE ACCOUNT INITIATED ==========
[AUTH-REPO] User ID to delete: <user-id>
[AUTH-REPO] Current session: Present/MISSING
```
**Meaning:** Checking if user has a valid session. **If MISSING here, that's the problem!**

### 4. Session & Token Details
```
[AUTH-REPO] Session user ID: <user-id>
[AUTH-REPO] Access token present: true/false
[AUTH-REPO] Token preview: eyJhbGciOiJIUzI1NiIs...
[AUTH-REPO] Token expires at: <timestamp>
```
**Meaning:** Token validity info. Check if token is expired!

### 5. Edge Function Invocation
```
[AUTH-REPO] Invoking delete-account Edge Function...
```
**Meaning:** About to call the Edge Function.

### 6. Edge Function Receives Request
```
[DELETE-ACCOUNT] ========== REQUEST RECEIVED ==========
[DELETE-ACCOUNT] Method: POST
[DELETE-ACCOUNT] Headers: {...}
```
**Meaning:** Edge Function received the request. Check if auth header is present.

### 7. Request Body & User ID Validation
```
[DELETE-ACCOUNT] Request body: {"userId":"..."}
[DELETE-ACCOUNT] User ID from request: <user-id>
```
**Meaning:** Parsing the request. If user ID is missing, error will follow.

### 8. Authorization Header Check
```
[DELETE-ACCOUNT] Authorization header: Present/Missing
[DELETE-ACCOUNT] Auth header value: Bearer eyJhbGc...
```
**Meaning:** Checking if Authorization header was sent. **If Missing here, that's your 401 error!**

### 9. User Authentication Verification
```
[DELETE-ACCOUNT] Creating Supabase client with auth header...
[DELETE-ACCOUNT] ✅ Supabase client created
[DELETE-ACCOUNT] Verifying user authentication...
[DELETE-ACCOUNT] Auth verification result:
[DELETE-ACCOUNT]   - Error: None/Some error message
[DELETE-ACCOUNT]   - User found: true/false
[DELETE-ACCOUNT]   - User ID: <user-id>
```
**Meaning:** Validating the JWT token. If Error shows "Invalid token" → check token expiry in Flutter logs.

### 10. Account Ownership Verification
```
[DELETE-ACCOUNT] Checking account ownership...
[DELETE-ACCOUNT]   - Authenticated user ID: <id>
[DELETE-ACCOUNT]   - Requested delete user ID: <id>
[DELETE-ACCOUNT]   - Match: true/false
```
**Meaning:** Making sure user isn't trying to delete someone else's account.

### 11. Deletion Process
```
[DELETE-ACCOUNT] Creating admin Supabase client...
[DELETE-ACCOUNT] ✅ Admin client created
[DELETE-ACCOUNT] Attempting to delete user from auth.users...
[DELETE-ACCOUNT] ❌ Error deleting user from auth: <error-message>
```
**Meaning:** Performing the actual deletion. If error here, check database permissions.

### 12. Success or Failure
```
[DELETE-ACCOUNT] ✅ User successfully deleted!
[DELETE-ACCOUNT] Returning success response: {...}
[DELETE-ACCOUNT] ========== REQUEST COMPLETED SUCCESSFULLY ==========
```
**Meaning:** Account deleted successfully!

Or:

```
[AUTH-REPO] ❌ Non-200 status code: 401
[AUTH-REPO] Error in deleteAccount: Failed to delete account: Unauthorized: Invalid or expired token
```
**Meaning:** Request failed. Check the status code and error message.

## Common Issues & Solutions

### Issue: 401 Unauthorized / Invalid JWT

**Symptoms:**
```
[DELETE-ACCOUNT] Auth verification result:
[DELETE-ACCOUNT]   - Error: Unauthorized: Invalid or expired token
```

**Solution:**
1. Check token expiry time in Flutter logs: `Token expires at: <timestamp>`
2. If expired, user needs to sign in again
3. Check if Bearer prefix is correct in auth header
4. Verify SUPABASE_ANON_KEY is set in Edge Function environment

### Issue: Missing Authorization Header

**Symptoms:**
```
[DELETE-ACCOUNT] Authorization header: Missing
```

**Solution:**
1. Check Flutter logs show token is present:
   ```
   [AUTH-REPO] Access token present: true
   [AUTH-REPO] Token preview: eyJhbGc...
   ```
2. Verify headers are being passed: Look for `Authorization: Bearer ...` in request
3. Restart the app to refresh session

### Issue: Account Not Deleted

**Symptoms:**
```
[DELETE-ACCOUNT] ❌ Error deleting user from auth: ...
```

**Solution:**
1. Check SUPABASE_SERVICE_ROLE_KEY is set correctly in Edge Function
2. Verify database has CASCADE delete rules on foreign keys
3. Check Supabase RLS (Row Level Security) policies allow deletion
4. Look at error message for specific database issue

### Issue: User Not Signed Out After Deletion

**Symptoms:**
```
[AUTH-REPO] ❌ User signed out successfully (but app still shows user)
```

**Solution:**
1. App should navigate to `/welcome` after deletion
2. Check if navigation is being triggered: `[PROFILE-SCREEN] Navigating to /welcome route`
3. Verify Go Router is set up correctly
4. Check if `mounted` check is passing

## How to Use Logs for Debugging

1. **Reproduce the error:**
   - Open app
   - Navigate to Profile
   - Tap "Delete Account" button
   - Confirm deletion

2. **Capture logs:**
   - Watch Flutter console for `[PROFILE-SCREEN]` and `[AUTH-REPO]` logs
   - Watch Supabase Dashboard for `[DELETE-ACCOUNT]` logs
   - Take screenshots of any error messages

3. **Follow the flow:**
   - Start with the `========== DELETE ACCOUNT INITIATED ==========` marker
   - Follow logs in order to see where it fails
   - Look for ❌ symbols indicating errors

4. **Compare with successful flow:**
   - A successful deletion should show:
     - ✅ All auth checks pass
     - ✅ `[DELETE-ACCOUNT] ✅ User successfully deleted!`
     - ✅ Navigation to /welcome

## Debug Checklist

- [ ] Session is present: `Current session: Present`
- [ ] Token is not expired: Check `Token expires at` vs current time
- [ ] Authorization header sent: `Authorization header: Present`
- [ ] User authenticated: `User found: true`
- [ ] Account ownership verified: `Match: true`
- [ ] Admin client created: `✅ Admin client created`
- [ ] Deletion succeeded: `✅ User successfully deleted!`
- [ ] Sign out successful: `✅ User signed out successfully`
- [ ] Navigation triggered: `Navigating to /welcome route`

## Next Steps

If you're still seeing errors:
1. Share the complete log output (both Flutter and Edge Function)
2. Note the specific error message (e.g., "Invalid token", "User not found")
3. Check the corresponding "Common Issues" section above
4. Verify environment variables are set correctly in Supabase

---

**Debug session timestamp:** February 19, 2026
