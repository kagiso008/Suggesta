# Delete Account Feature - Quick Start Guide

## 🚀 What You Need to Do

The delete account feature is fully implemented. Here's what to do next:

### Step 1: Deploy the Edge Function (Required)

#### Via Supabase Dashboard (Easiest)

1. **Open Supabase Dashboard**
   - Go to https://app.supabase.com
   - Sign in to your account
   - Select your Suggesta project

2. **Navigate to Edge Functions**
   - Click on **Edge Functions** in the left sidebar
   - Click **Create a new function**

3. **Create the Function**
   - Function name: `delete-account`
   - Click **Create function**

4. **Add the Code**
   - A code editor will open
   - Copy ALL content from this file:
     ```
     /Users/kagiso/Documents/Projects/Suggesta/supabase/functions/delete-account/index.ts
     ```
   - Paste it into the editor
   - Click **Save**

5. **Deploy**
   - Click the **Deploy** button
   - Wait for the green checkmark
   - Done! ✅

#### Via Supabase CLI

```bash
# Navigate to project
cd /Users/kagiso/Documents/Projects/Suggesta

# Deploy the function
supabase functions deploy delete-account

# Verify it worked
supabase functions list
# You should see: delete-account    | public
```

---

### Step 2: Test the Feature (Verify It Works)

#### Test in the Flutter App

1. **Run the app**
   ```bash
   cd /Users/kagiso/Documents/Projects/Suggesta
   flutter run
   ```

2. **Create a test account**
   - Tap "Get Started"
   - Sign up with email: `test@example.com` (or any test email)
   - Create password: `password123`
   - Create username: `testuser`
   - Complete profile setup

3. **Test delete account**
   - Tap profile icon (bottom right)
   - Scroll down to "Delete Account" button
   - Tap it
   - Read the warning
   - Confirm deletion by tapping "Delete Account"
   - **Expected:** 
     - Loading spinner appears
     - Account is deleted
     - Signed out automatically
     - Redirected to Welcome screen

4. **Verify deletion**
   - Try to sign in with the deleted email
   - **Expected:** Should get "Invalid login credentials" error

---

### Step 3: Monitor (Optional but Recommended)

#### Check Function Logs in Dashboard

1. Go to **Edge Functions** → **delete-account**
2. Click **Invocations** tab
3. You should see your test function call
4. Click on it to see:
   - Request details
   - Response data
   - Execution time
   - Any errors

#### Use cURL to Test Directly (Advanced)

```bash
# First, get your JWT token from the app
# (You can see it in the debug console)

# Then test the function:
curl -X POST \
  https://<your-project-id>.functions.supabase.co/delete-account \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"userId":"YOUR_USER_ID"}'

# You should get:
# {
#   "success": true,
#   "message": "Account and all associated data have been successfully deleted",
#   "deletedAt": "2026-02-19T..."
# }
```

---

## 📋 Deployment Checklist

Before considering it done, verify:

- [ ] Edge Function deployed to Supabase
- [ ] Function shows in Supabase Dashboard
- [ ] Flutter app runs without errors
- [ ] Can create test account in app
- [ ] Delete account button appears in profile
- [ ] Clicking delete shows confirmation dialog
- [ ] Confirming deletion shows loading indicator
- [ ] User is signed out after deletion
- [ ] App navigates to Welcome screen
- [ ] Deleted account cannot be logged back in
- [ ] Function invocations appear in dashboard
- [ ] No errors in function logs

---

## 🎯 What Happens When User Deletes Account

### In the App (User Sees)
1. Warning dialog: "This action cannot be undone"
2. Loading spinner while processing
3. Success: Signed out and redirected to Welcome

### In the Database (What Gets Deleted)
```
User ID: 550e8400-e29b-41d4-a716-446655440000

Deleted immediately:
✅ auth.users record
✅ profiles record

Automatically cascaded (deleted by database):
✅ topics (all created by user)
✅ suggestions (all created by user)
✅ comments (all created by user)
✅ topic_votes (all votes by user)
✅ suggestion_votes (all votes by user)
✅ topic_follows (all follows by user)
✅ messages (all messages from user)
✅ conversations (all conversations with user)

Result: ZERO data left in database ✅
```

---

## 🔒 Security Features Included

✅ **User Authentication**
- Only logged-in users can delete accounts
- JWT token validation required
- Expired tokens rejected

✅ **User Authorization**
- Users can only delete their own account
- Cannot delete other users' accounts
- Service role key used safely

✅ **Data Safety**
- Cascading deletes prevent orphaned data
- Transaction support ensures consistency
- No data recovery possible (by design)

✅ **Error Protection**
- Invalid user IDs rejected
- Missing tokens rejected
- Database errors caught and reported
- No sensitive information leaked

---

## 📞 If Something Goes Wrong

### Issue: "Function not found" error

**Problem:** Edge Function not deployed

**Solution:**
1. Go to Supabase Dashboard
2. Check **Edge Functions** section
3. If `delete-account` not there, deploy it (see Step 1)

### Issue: "Unauthorized" error

**Problem:** User not authenticated

**Solution:**
1. Ensure user is signed in
2. Check JWT token is valid
3. Verify token hasn't expired
4. Try signing out and back in

### Issue: Delete button appears but nothing happens

**Problem:** Function call failed

**Solution:**
1. Check Supabase logs:
   - Go to **Edge Functions** → **delete-account** → **Invocations**
   - Look for error messages
2. Verify function is deployed correctly
3. Check user is authenticated

### Issue: Account still exists after deletion

**Problem:** Edge Function didn't work properly

**Solution:**
1. Check Supabase logs for errors
2. Verify user ID is correct
3. Check database manually:
   ```sql
   SELECT * FROM profiles WHERE id = 'user-id-here';
   -- Should return: no results
   ```

---

## 📊 Testing Scenarios

### ✅ Success Case
1. Sign up → Create account
2. Complete profile
3. Go to Profile screen
4. Tap "Delete Account"
5. Confirm
6. **Result:** Account deleted, signed out

### ✅ Error Cases
1. No internet → Error message shown
2. Wrong user ID → Forbidden error
3. Already deleted → "User not found" error
4. Database error → Generic error message

### ✅ Edge Cases
1. Delete, then try to sign in → "Invalid credentials"
2. Delete, then try to view profile → Redirects to welcome
3. Network interruption → Retry option or error message

---

## 📚 Documentation

For more detailed information, see:

1. **DELETE_ACCOUNT_SUMMARY.md**
   - Overview of feature
   - What gets deleted
   - Architecture explanation

2. **DELETE_ACCOUNT_FEATURE.md**
   - Complete feature documentation
   - Security considerations
   - Testing procedures
   - Troubleshooting guide

3. **EDGE_FUNCTION_DEPLOYMENT.md**
   - Step-by-step deployment
   - Multiple deployment options
   - Monitoring and logging
   - Rollback procedures

---

## 🎉 You're Done!

Once you've completed these steps, the delete account feature is fully operational:

✅ Users can safely delete their accounts
✅ All data is completely removed
✅ Feature is secure and well-documented
✅ Monitoring is available in Supabase Dashboard
✅ Error handling is comprehensive

---

## 💬 Quick Reference

**To Deploy:**
```bash
supabase functions deploy delete-account
```

**To Test:**
1. Run: `flutter run`
2. Create test account
3. Delete account from profile screen
4. Verify it's gone

**To Monitor:**
- Go to Supabase Dashboard
- Click Edge Functions → delete-account
- Check Invocations tab

**To Troubleshoot:**
- Check function logs in dashboard
- Review error messages in app
- Verify function is deployed

---

**Last Updated:** February 19, 2026
**Status:** ✅ Ready to Deploy and Test
