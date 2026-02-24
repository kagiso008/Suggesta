# Delete Account - Debugging Checklist

## 🔴 Current Issue
**Error:** "Invalid JWT / Unauthorized (401)"

This means the Edge Function is not accepting the JWT token. Common causes:

1. ❌ **Edge Function NOT deployed** (Most likely)
2. ❌ **Token is expired**
3. ❌ **Authorization header not being sent properly**
4. ❌ **Edge Function can't access Supabase environment variables**

---

## ✅ Step-by-Step Debugging

### Step 1: Check if Edge Function is Deployed

**In terminal:**
```bash
cd /Users/kagiso/Documents/Projects/Suggesta
supabase functions list
```

**Expected output:**
```
delete-account
```

**If NOT listed:**
→ See **DEPLOY_EDGE_FUNCTION.md** to deploy it first!

---

### Step 2: Check Flutter Logs While Deleting Account

**Do this:**
1. Make sure app is running: `flutter run`
2. Open Profile screen
3. Tap "Delete Account" button
4. Watch the terminal for logs starting with `[AUTH-REPO]`

**Look for:**
```
[AUTH-REPO] Current session: Present       ✅ Good
[AUTH-REPO] Access token present: true     ✅ Good
[AUTH-REPO] Token expires at: <future>    ✅ Check if in future!
```

**If you see:**
```
[AUTH-REPO] Current session: MISSING       ❌ User not logged in!
[AUTH-REPO] Access token present: false    ❌ No token!
```
→ User needs to sign in again

---

### Step 3: Check Edge Function Logs

**Do this:**
1. Go to Supabase Dashboard
2. Select your project
3. Navigate to **Edge Functions**
4. Click **delete-account**
5. Click **Logs** tab
6. Scroll to bottom for latest logs

**When you tap delete button, you should see:**
```
[DELETE-ACCOUNT] ========== REQUEST RECEIVED ==========
[DELETE-ACCOUNT] Method: POST
[DELETE-ACCOUNT] Authorization header: Present
```

**If you DON'T see any logs:**
→ Function not deployed or request isn't reaching it

**If you see:**
```
[DELETE-ACCOUNT] Authorization header: Missing
```
→ Headers aren't being sent from Flutter

---

### Step 4: Check Token Expiry

**In Flutter logs, look for:**
```
[AUTH-REPO] Token expires at: 2026-02-20T15:30:45.123456Z
```

**Compare with current time:**
- If expiry is in the PAST → Token expired
- If expiry is in the FUTURE → Token should be valid

**If token expired:**
1. Sign out user completely
2. Sign in again
3. Try delete again

---

### Step 5: Manual Test via Supabase Dashboard

**Do this:**
1. Go to Supabase Dashboard → Edge Functions → delete-account
2. Click **Send a test request**
3. Choose **POST** method
4. Click **Auth** tab
5. Select **User** from dropdown (should show current user)
6. In body, add:
```json
{
  "userId": "YOUR-USER-ID"
}
```
7. Click **Send**

**What this tests:**
- ✅ Edge Function is deployed
- ✅ Function can read auth headers
- ✅ Function can access Supabase

**Result should be:**
```json
{
  "success": true,
  "message": "Account and all associated data have been successfully deleted",
  "deletedAt": "2026-02-19T..."
}
```

Or account already deleted error if already deleted.

---

## 🔧 Common Fixes

### Fix 1: Deploy Edge Function
```bash
cd /Users/kagiso/Documents/Projects/Suggesta
supabase functions deploy delete-account
```

### Fix 2: Refresh Token (Sign In Again)
1. In app, tap Sign Out
2. Sign in again
3. Try delete again

### Fix 3: Clear App State
```bash
flutter clean
flutter pub get
flutter run
```

### Fix 4: Check Environment Variables in Supabase
1. Go to Supabase Dashboard → Settings → API
2. Copy your project URL
3. Go to Edge Functions → delete-account
4. Verify environment variables are set (if any needed)

### Fix 5: Restart Flutter App
```bash
# In flutter run terminal, press 'r' then 'R' for hot restart
R
```

---

## 📊 Decision Tree

```
Delete Account Returns 401
│
├─ Is Edge Function Deployed?
│  ├─ NO → Deploy it (DEPLOY_EDGE_FUNCTION.md)
│  └─ YES → Continue
│
├─ Can you see logs in Supabase?
│  ├─ NO → Function not deployed OR not being called
│  └─ YES → Continue
│
├─ Does Flutter log show "Current session: Present"?
│  ├─ NO → User not logged in, sign in again
│  └─ YES → Continue
│
├─ Does Flutter log show "Authorization header: Present" in Supabase logs?
│  ├─ NO → Header not being sent, check CORS/headers
│  └─ YES → Continue
│
└─ Is token expired?
   ├─ YES → Sign in again
   └─ NO → Check Supabase project settings/permissions
```

---

## 🧪 Test Checklist

Before trying delete again, verify:

- [ ] Supabase CLI installed: `which supabase`
- [ ] Logged in to CLI: `supabase projects list` shows projects
- [ ] Function deployed: `supabase functions list` shows delete-account
- [ ] User is logged in to app
- [ ] Flutter logs show "Current session: Present"
- [ ] Flutter logs show "Access token present: true"
- [ ] Can see Edge Function logs in Supabase Dashboard
- [ ] Token not expired: Check date in "Token expires at"

---

## 🆘 Still Not Working?

**Collect this information and share:**

1. **Output of:** `supabase functions list`
2. **Flutter logs** when trying to delete (full output from `[AUTH-REPO]` start to end)
3. **Supabase Edge Function logs** when trying to delete (full output)
4. **Screenshot** of Supabase Dashboard → Edge Functions → delete-account
5. **Error message** shown in app

With this info, we can diagnose the exact issue!

---

## Quick Debugging Flow

1. Is function deployed? `supabase functions list`
2. Are logs appearing? Check Supabase Dashboard Logs
3. Does app show errors? Check Flutter console logs
4. Is token valid? Check expiry date in logs
5. Test manually? Use Supabase Dashboard test request

---

**Next Action:**
1. Check if function is deployed
2. If not, deploy it using DEPLOY_EDGE_FUNCTION.md
3. If yes, try deleting again and share logs

Let's get this fixed! 🚀
