# Delete Account Feature - Testing & QA Guide

## 🧪 Comprehensive Testing Guide

This document provides detailed testing scenarios to verify the delete account feature works correctly.

---

## Pre-Testing Setup

### Environment Requirements
- ✅ Flutter app running on iOS simulator
- ✅ Supabase Edge Function deployed
- ✅ Internet connection available
- ✅ Test account ready (optional)

### Deployment Verification
```bash
# Verify Edge Function is deployed
supabase functions list

# Expected output:
# delete-account    | public
```

---

## Test Categories

## 1️⃣ UI/UX Testing

### Test 1.1: Delete Button Visibility

**Precondition:** User is signed in and on Profile screen

**Steps:**
1. Open app
2. Sign in with valid credentials
3. Navigate to Profile screen (tap profile icon)
4. Scroll to bottom of page

**Expected Result:**
- ✅ "Delete Account" button is visible
- ✅ Button is red (#EF4444) color
- ✅ Button has delete/trash icon
- ✅ Button is enabled and clickable

**Test Status:** [ ] Pass [ ] Fail

---

### Test 1.2: Confirmation Dialog Display

**Precondition:** User is on Profile screen

**Steps:**
1. Tap "Delete Account" button
2. Observe dialog that appears

**Expected Result:**
- ✅ Dialog appears with title "Delete Account"
- ✅ Warning message shown: "This action cannot be undone..."
- ✅ Two buttons: "Cancel" and "Delete Account"
- ✅ Delete button is red/danger colored
- ✅ Dialog blocks interaction with rest of app

**Test Status:** [ ] Pass [ ] Fail

---

### Test 1.3: Cancel Deletion

**Precondition:** Confirmation dialog is open

**Steps:**
1. Tap "Cancel" button
2. Observe result

**Expected Result:**
- ✅ Dialog closes
- ✅ User stays on Profile screen
- ✅ Account is NOT deleted
- ✅ User is still signed in
- ✅ Can navigate normally

**Test Status:** [ ] Pass [ ] Fail

---

### Test 1.4: Confirmation Dialog Dismissal

**Precondition:** Confirmation dialog is open

**Steps:**
1. Tap outside dialog (on dark overlay)
2. Or press back button
3. Observe result

**Expected Result:**
- ✅ Dialog closes
- ✅ Deletion is cancelled
- ✅ User stays on Profile screen

**Test Status:** [ ] Pass [ ] Fail

---

### Test 1.5: Loading Indicator During Deletion

**Precondition:** User confirmed deletion

**Steps:**
1. Confirm deletion by tapping "Delete Account"
2. Observe loading state

**Expected Result:**
- ✅ Loading spinner appears
- ✅ All buttons are disabled
- ✅ Cannot interact with UI
- ✅ Spinner shows for 1-3 seconds

**Test Status:** [ ] Pass [ ] Fail

---

## 2️⃣ Functional Testing

### Test 2.1: Successful Account Deletion (Happy Path)

**Precondition:** User is signed in on Profile screen

**Steps:**
1. Tap "Delete Account" button
2. Confirm deletion
3. Wait for deletion to complete
4. Observe final state

**Expected Result:**
- ✅ Loading spinner shows
- ✅ No errors displayed
- ✅ User is signed out
- ✅ Redirected to Welcome screen
- ✅ Cannot see previous user data

**Test Status:** [ ] Pass [ ] Fail

---

### Test 2.2: Verify Account Actually Deleted

**Precondition:** Account just deleted (from Test 2.1)

**Steps:**
1. Return to Welcome screen
2. Try to sign in with deleted account email
3. Observe result

**Expected Result:**
- ✅ Sign in page displayed
- ✅ Cannot sign in with deleted email
- ✅ Error: "Invalid login credentials" (or similar)
- ✅ Account is permanently gone

**Test Status:** [ ] Pass [ ] Fail

---

### Test 2.3: All Data Deleted From Database

**Precondition:** Account deleted

**Steps:**
1. Go to Supabase Dashboard
2. Open SQL Editor
3. Run query to check profile:
   ```sql
   SELECT * FROM profiles WHERE id = '<deleted-user-id>';
   ```
4. Check all related tables

**Expected Result:**
- ✅ No profile record found
- ✅ No topics for user
- ✅ No suggestions for user
- ✅ No comments for user
- ✅ No votes for user
- ✅ Zero related data left in database

**Test Status:** [ ] Pass [ ] Fail

---

### Test 2.4: New Account After Deletion

**Precondition:** Previous account deleted

**Steps:**
1. Use the same email to create new account
2. Complete signup and profile setup
3. Verify account works

**Expected Result:**
- ✅ Can use deleted email for new account
- ✅ Email is no longer "taken"
- ✅ New account created successfully
- ✅ Can sign in and use app normally

**Test Status:** [ ] Pass [ ] Fail

---

## 3️⃣ Error Handling Testing

### Test 3.1: Network Error During Deletion

**Precondition:** User ready to delete, network available

**Steps:**
1. Enable airplane mode (disable internet)
2. Tap "Delete Account"
3. Confirm deletion
4. Wait for error

**Expected Result:**
- ✅ Loading spinner shows
- ✅ No error immediately (app tries to send)
- ✅ After timeout, error dialog appears
- ✅ Error message is clear and helpful
- ✅ Can retry or dismiss
- ✅ User still logged in
- ✅ Account NOT deleted

**Test Status:** [ ] Pass [ ] Fail

---

### Test 3.2: Edge Function Not Found

**Precondition:** Edge Function not deployed

**Steps:**
1. Ensure delete-account function is NOT deployed
2. Try to delete account
3. Observe error

**Expected Result:**
- ✅ Error appears: "Function not found" or similar
- ✅ Clear error message shown
- ✅ User can dismiss error
- ✅ User still logged in
- ✅ Account NOT deleted

**Test Status:** [ ] Pass [ ] Fail

---

### Test 3.3: Server Error (500)

**Precondition:** Server error occurs

**Steps:**
1. Delete account (if server error occurs)
2. Or manually trigger error in logs
3. Observe error handling

**Expected Result:**
- ✅ Error message shown: "Server error..."
- ✅ No PII leaked in error
- ✅ User stays logged in
- ✅ Can try again
- ✅ Account NOT deleted

**Test Status:** [ ] Pass [ ] Fail

---

### Test 3.4: Expired Session

**Precondition:** User session expired

**Steps:**
1. Sign in and wait > 1 hour (or manually expire token)
2. Try to delete account
3. Observe result

**Expected Result:**
- ✅ Error: "Session expired"
- ✅ Redirected to login screen
- ✅ Must sign in again
- ✅ Can retry deletion after new sign in

**Test Status:** [ ] Pass [ ] Fail

---

### Test 3.5: Multiple Simultaneous Deletions

**Precondition:** Two users logged in (or simulated)

**Steps:**
1. Open app in two different simulators
2. User A: Start deletion process
3. User B: Try to delete account simultaneously
4. Observe behavior

**Expected Result:**
- ✅ Both deletions process independently
- ✅ Both accounts deleted successfully
- ✅ No conflicts or errors
- ✅ No data corruption

**Test Status:** [ ] Pass [ ] Fail

---

## 4️⃣ Security Testing

### Test 4.1: Authorization - Can't Delete Other Accounts

**Precondition:** Logged in as User A

**Steps:**
1. Modify request to try deleting User B's account
2. Or use User B's ID in deletion request
3. Observe result

**Expected Result:**
- ✅ Error: "Forbidden" or "Unauthorized"
- ✅ Cannot delete other user's account
- ✅ User A's account still exists
- ✅ User B's account NOT deleted

**Test Status:** [ ] Pass [ ] Fail

---

### Test 4.2: Invalid Token

**Precondition:** Expired or invalid JWT token

**Steps:**
1. Modify authorization token to be invalid
2. Try to delete account
3. Observe result

**Expected Result:**
- ✅ Error: "Unauthorized" or "Invalid token"
- ✅ Account NOT deleted
- ✅ User redirected to login

**Test Status:** [ ] Pass [ ] Fail

---

### Test 4.3: Missing Authorization Header

**Precondition:** Attempting to call function without auth

**Steps:**
1. Call Edge Function without Bearer token
2. Observe result

**Expected Result:**
- ✅ Error: "Unauthorized" or "Missing auth"
- ✅ Request rejected
- ✅ Function doesn't proceed

**Test Status:** [ ] Pass [ ] Fail

---

### Test 4.4: SQL Injection Protection

**Precondition:** Attempting SQL injection

**Steps:**
1. Try sending malicious SQL in user ID
2. E.g.: userId: "'; DROP TABLE profiles; --"
3. Observe result

**Expected Result:**
- ✅ No errors executing
- ✅ No tables dropped
- ✅ Data integrity maintained
- ✅ Request rejected safely

**Test Status:** [ ] Pass [ ] Fail

---

## 5️⃣ Data Integrity Testing

### Test 5.1: Cascade Delete - Topics Deleted

**Precondition:** User created topics, account deleted

**Steps:**
1. Create account and 2-3 topics
2. Delete account
3. Check database: `SELECT * FROM topics WHERE user_id = '<user-id>';`

**Expected Result:**
- ✅ All topics deleted
- ✅ No orphaned topics remain

**Test Status:** [ ] Pass [ ] Fail

---

### Test 5.2: Cascade Delete - Suggestions Deleted

**Precondition:** User created suggestions, account deleted

**Steps:**
1. Create account and add suggestions
2. Delete account
3. Check database: `SELECT * FROM suggestions WHERE user_id = '<user-id>';`

**Expected Result:**
- ✅ All suggestions deleted
- ✅ Related votes also deleted
- ✅ Related comments also deleted

**Test Status:** [ ] Pass [ ] Fail

---

### Test 5.3: Cascade Delete - Comments Deleted

**Precondition:** User created comments, account deleted

**Steps:**
1. Create account and add comments
2. Delete account
3. Check database: `SELECT * FROM comments WHERE user_id = '<user-id>';`

**Expected Result:**
- ✅ All comments deleted
- ✅ Related votes deleted
- ✅ Nested comments deleted

**Test Status:** [ ] Pass [ ] Fail

---

### Test 5.4: Cascade Delete - Messages Deleted

**Precondition:** User sent messages, account deleted

**Steps:**
1. Create account and send messages
2. Delete account
3. Check database: `SELECT * FROM messages WHERE sender_id = '<user-id>';`

**Expected Result:**
- ✅ All messages deleted
- ✅ Conversations cleaned up
- ✅ No orphaned data

**Test Status:** [ ] Pass [ ] Fail

---

### Test 5.5: No Orphaned References

**Precondition:** Account deleted

**Steps:**
1. Delete account
2. Run query: 
   ```sql
   SELECT * FROM topics WHERE user_id = '<deleted-id>';
   SELECT * FROM comments WHERE user_id = '<deleted-id>';
   SELECT * FROM topic_votes WHERE user_id = '<deleted-id>';
   -- ... check all tables
   ```

**Expected Result:**
- ✅ All queries return: 0 rows
- ✅ No references to deleted user
- ✅ Database fully consistent

**Test Status:** [ ] Pass [ ] Fail

---

## 6️⃣ Performance Testing

### Test 6.1: Deletion Speed - Small Profile

**Precondition:** User with minimal data (no topics/comments)

**Steps:**
1. Time deletion process
2. From button click to Welcome screen
3. Note time taken

**Expected Result:**
- ✅ Completes in < 2 seconds
- ✅ < 1 second typical
- ✅ No noticeable lag

**Test Status:** [ ] Pass [ ] Fail
**Time Taken:** _____ seconds

---

### Test 6.2: Deletion Speed - Large Profile

**Precondition:** User with lots of data (many topics, comments, votes)

**Steps:**
1. Create account with 10+ topics, 20+ comments, 50+ votes
2. Time deletion process
3. Note time taken

**Expected Result:**
- ✅ Completes in < 5 seconds
- ✅ Cascade deletes all data
- ✅ No timeout

**Test Status:** [ ] Pass [ ] Fail
**Time Taken:** _____ seconds

---

### Test 6.3: Function Execution Time

**Precondition:** Function deployed

**Steps:**
1. Check Supabase dashboard
2. Edge Functions → delete-account → Invocations
3. Note execution times in logs

**Expected Result:**
- ✅ Most deletions: < 500ms
- ✅ Large datasets: < 2000ms
- ✅ No timeout errors

**Test Status:** [ ] Pass [ ] Fail

---

## 7️⃣ Monitoring & Logging Testing

### Test 7.1: Function Invocations Logged

**Precondition:** Account deleted

**Steps:**
1. Go to Supabase Dashboard
2. Edge Functions → delete-account → Invocations
3. Check logs

**Expected Result:**
- ✅ Deletion appears in logs
- ✅ Timestamp recorded
- ✅ Status shows success
- ✅ Response body logged

**Test Status:** [ ] Pass [ ] Fail

---

### Test 7.2: Error Logging

**Precondition:** Deletion fails

**Steps:**
1. Trigger an error (network issue, auth error, etc)
2. Check Supabase logs
3. Verify error is logged

**Expected Result:**
- ✅ Error appears in logs
- ✅ Error details captured
- ✅ Helpful for debugging

**Test Status:** [ ] Pass [ ] Fail

---

## 8️⃣ Cross-Platform Testing

### Test 8.1: iOS Deletion

**Precondition:** Running on iOS simulator/device

**Steps:**
1. Run app on iPhone
2. Complete deletion flow
3. Verify success

**Expected Result:**
- ✅ All UI renders correctly
- ✅ Deletion works end-to-end
- ✅ Navigation works

**Test Status:** [ ] Pass [ ] Fail

---

### Test 8.2: Android Deletion

**Precondition:** Running on Android simulator/device

**Steps:**
1. Run app on Android
2. Complete deletion flow
3. Verify success

**Expected Result:**
- ✅ All UI renders correctly
- ✅ Deletion works end-to-end
- ✅ Navigation works

**Test Status:** [ ] Pass [ ] Fail

---

## 9️⃣ Edge Cases Testing

### Test 9.1: Rapid Deletion Attempts

**Precondition:** Deletion in progress

**Steps:**
1. Start deletion
2. While loading, tap delete again
3. Observe behavior

**Expected Result:**
- ✅ Buttons disabled during loading
- ✅ Cannot trigger multiple deletions
- ✅ Only processes once
- ✅ No duplicate requests

**Test Status:** [ ] Pass [ ] Fail

---

### Test 9.2: Back Button During Deletion

**Precondition:** Loading spinner showing

**Steps:**
1. Start deletion process
2. Press back button while loading
3. Observe result

**Expected Result:**
- ✅ Back button disabled during loading
- ✅ Cannot navigate away during deletion
- ✅ Deletion continues
- ✅ Either completes or shows error

**Test Status:** [ ] Pass [ ] Fail

---

### Test 9.3: App Quit During Deletion

**Precondition:** App quitting while deletion in progress

**Steps:**
1. Start deletion
2. Force quit app (remove from memory)
3. Restart app
4. Check account status

**Expected Result:**
- ✅ If deletion completed: account gone
- ✅ If deletion interrupted: account still exists (safe)
- ✅ No data corruption
- ✅ App restarts normally

**Test Status:** [ ] Pass [ ] Fail

---

### Test 9.4: Deletion with Profile Picture

**Precondition:** User uploaded profile picture

**Steps:**
1. Create account with profile picture
2. Delete account
3. Check if image is also deleted

**Expected Result:**
- ✅ Profile picture removed from Storage
- ✅ Database record deleted
- ✅ No orphaned images

**Test Status:** [ ] Pass [ ] Fail

---

## 🔟 Compliance Testing

### Test 10.1: GDPR "Right to be Forgotten"

**Precondition:** User requests deletion

**Steps:**
1. Delete account
2. Verify no data remains
3. Check backups (if applicable)

**Expected Result:**
- ✅ Immediate deletion of all data
- ✅ No residual PII
- ✅ Compliant with GDPR Article 17

**Test Status:** [ ] Pass [ ] Fail

---

### Test 10.2: Data Export Before Deletion (Future)

**Precondition:** Feature planning phase

**Notes:**
- [ ] Consider adding data export before deletion
- [ ] GDPR Article 20 compliance
- [ ] User right to data portability

---

## Test Results Summary

### Overall Results

| Category | Tests | Passed | Failed | Status |
|----------|-------|--------|--------|--------|
| UI/UX | 5 | | | |
| Functional | 4 | | | |
| Error Handling | 5 | | | |
| Security | 4 | | | |
| Data Integrity | 5 | | | |
| Performance | 3 | | | |
| Monitoring | 2 | | | |
| Cross-Platform | 2 | | | |
| Edge Cases | 4 | | | |
| Compliance | 2 | | | |
| **TOTAL** | **36** | | | |

### Pass Rate: _____ / 36 (_____ %)

### Critical Issues Found
- [ ] None
- [ ] _________________________
- [ ] _________________________

### Non-Critical Issues Found
- [ ] None
- [ ] _________________________
- [ ] _________________________

### Recommendations
- _________________________
- _________________________
- _________________________

---

## Sign-Off

**Tested By:** ____________________
**Date:** ____________________
**Status:** [ ] Approved [ ] Approved with Notes [ ] Rejected

**Notes:**
_________________________________________
_________________________________________

---

**Last Updated:** February 19, 2026
**Version:** 1.0
