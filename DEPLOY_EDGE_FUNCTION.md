# Deploy Delete Account Edge Function to Supabase

## ⚠️ Critical: Function Must Be Deployed

The `delete-account` Edge Function is currently only on your local machine. It must be deployed to Supabase before it can be used.

## Option 1: Deploy via Supabase CLI (Recommended)

### Step 1: Install Supabase CLI
```bash
brew install supabase/tap/supabase
```

### Step 2: Login to Supabase
```bash
supabase login
```
- Opens browser to authenticate
- Follow the prompts
- Copy the access token when prompted

### Step 3: Link to Your Project
```bash
cd /Users/kagiso/Documents/Projects/Suggesta
supabase link
```
- Select your project from the list
- Choose the project created in Supabase Dashboard

### Step 4: Deploy the Function
```bash
supabase functions deploy delete-account
```

**Expected output:**
```
✓ Function deleted successfully
✓ Function created successfully
✓ Deployment completed
```

### Step 5: Verify Deployment
```bash
supabase functions list
```

Should show:
```
delete-account
```

---

## Option 2: Deploy via Supabase Dashboard (Manual)

### Step 1: Open Supabase Dashboard
1. Go to https://app.supabase.com
2. Select your project
3. Navigate to **Edge Functions**

### Step 2: Create Function
1. Click **Create a new function**
2. Name: `delete-account`
3. Click **Create**

### Step 3: Copy Code
1. Open `/Users/kagiso/Documents/Projects/Suggesta/supabase/functions/delete-account/index.ts`
2. Copy all the content
3. Paste into the Supabase dashboard editor
4. Click **Deploy**

### Step 4: Set Environment Variables
If the function needs them (check dashboard after deployment):
1. Go to **Settings** → **Edge Functions**
2. Scroll to your function
3. Set any required environment variables

---

## Option 3: Deploy via GitHub Actions (If Connected)

If your GitHub repo is connected to Supabase:

1. Push your changes to GitHub
2. Supabase automatically detects `supabase/functions/delete-account/`
3. Deploys automatically

**Check deployment status:**
- Go to Supabase Dashboard → Edge Functions → delete-account
- Look for recent deployment in logs

---

## Verify Function is Working

After deployment, test it:

### Via Supabase Dashboard:
1. Go to Edge Functions → delete-account
2. Click **Send a test request**
3. Choose **POST** method
4. Add body:
```json
{
  "userId": "test-user-id"
}
```
5. Click **Send**

Expected response:
```json
{
  "success": false,
  "message": "Authorization header is required"
}
```

(This is expected since we're not sending auth header in test)

### Via cURL:
```bash
curl -X POST \
  https://your-project.supabase.co/functions/v1/delete-account \
  -H "Content-Type: application/json" \
  -d '{"userId":"test-user-id"}'
```

---

## Troubleshooting

### Issue: Function Not Found (404)
**Solution:** Ensure you've deployed the function. Run `supabase functions list` to verify.

### Issue: "Service Role Key" Error
**Solution:** Environment variable not set. Check Supabase project settings.

### Issue: "ANON_KEY" Error
**Solution:** Environment variable not set. The function should have access to these automatically.

### Issue: Deployment Fails
**Solution:**
1. Check TypeScript syntax: `deno check supabase/functions/delete-account/index.ts`
2. Check file exists: `ls -la supabase/functions/delete-account/`
3. Check deno.json: `cat supabase/functions/delete-account/deno.json`

---

## After Deployment

1. **Your Flutter app will work** - Once deployed, the delete account button will send requests to the Edge Function
2. **Logs will appear** - Check Supabase Dashboard → Edge Functions → delete-account → Logs
3. **Test deletion** - Try deleting account from app
4. **Monitor logs** - Watch for any errors in Edge Function logs

---

## Quick Reference

**Deployed?**
```bash
supabase functions list
```

**Deploy now:**
```bash
supabase functions deploy delete-account
```

**View logs:**
Go to Supabase Dashboard → Edge Functions → delete-account → Logs tab

**Test function:**
Go to Supabase Dashboard → Edge Functions → delete-account → Send test request

---

**Status:** 🔴 NOT DEPLOYED (Function exists locally only)

**Next Step:** Follow Option 1 or 2 above to deploy!
