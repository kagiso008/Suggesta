# Supabase Edge Function Deployment Guide

## Quick Start

The `delete-account` Edge Function is ready to deploy to your Supabase project.

### What is an Edge Function?

Supabase Edge Functions are TypeScript/JavaScript functions that run on Deno runtime at the edge. They're perfect for:
- Secure operations using the service role key
- Operations that require admin privileges
- Complex business logic
- API endpoints

### Prerequisites

1. **Supabase CLI** installed
   ```bash
   brew install supabase
   ```

2. **Supabase Project** created (you already have one)

3. **Project linked locally**
   ```bash
   supabase link --project-ref <your-project-ref>
   ```

---

## Deployment Options

### Option 1: Using Supabase Dashboard (Recommended for Beginners)

1. **Go to Supabase Dashboard**
   - Navigate to https://app.supabase.com
   - Select your Suggesta project

2. **Create Edge Function**
   - Go to **Edge Functions** in the left sidebar
   - Click **Create a new function**
   - Name: `delete-account`
   - Click **Create function**

3. **Add Function Code**
   - Copy all content from `supabase/functions/delete-account/index.ts`
   - Paste into the editor
   - Click **Save**

4. **Deploy**
   - Click **Deploy** button
   - Wait for confirmation

5. **Test**
   - Click **Invoke with cURL** to see example request
   - You can test using the provided cURL command

### Option 2: Using Supabase CLI (Recommended for Developers)

1. **Link Your Project** (if not already linked)
   ```bash
   cd /Users/kagiso/Documents/Projects/Suggesta
   supabase link --project-ref your_project_ref
   ```

2. **Deploy Function**
   ```bash
   supabase functions deploy delete-account
   ```

3. **Verify Deployment**
   ```bash
   supabase functions list
   # Should show:
   # delete-account    | public
   ```

### Option 3: Using GitHub Actions (For CI/CD)

1. **Set up GitHub secrets** with:
   - `SUPABASE_ACCESS_TOKEN`
   - `SUPABASE_PROJECT_ID`

2. **Create `.github/workflows/deploy-functions.yml`**
   ```yaml
   name: Deploy Supabase Functions
   
   on:
     push:
       branches: [main]
       paths:
         - 'supabase/functions/**'
   
   jobs:
     deploy:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v3
         - uses: supabase/setup-cli@v1
           with:
             version: latest
         - run: supabase functions deploy delete-account
           env:
             SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
             SUPABASE_PROJECT_ID: ${{ secrets.SUPABASE_PROJECT_ID }}
   ```

---

## Function Details

### File Structure
```
supabase/
└── functions/
    └── delete-account/
        ├── index.ts          # Function code
        └── deno.json         # Configuration
```

### Configuration (deno.json)
```json
{
  "version": "1",
  "runtime": "deno",
  "entrypoint": "index.ts"
}
```

### Function Endpoint
- **URL**: `https://<project-id>.functions.supabase.co/delete-account`
- **Method**: POST
- **Authentication**: Required (Bearer token)

---

## Testing the Function

### Using cURL

```bash
# 1. Get your user's JWT token
# First, sign in to the app and copy the token from the client

# 2. Test the function
curl -X POST https://<project-id>.functions.supabase.co/delete-account \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"userId":"YOUR_USER_ID"}'
```

### Using Supabase Dashboard

1. Go to **Edge Functions** → **delete-account**
2. Click **Invoke with cURL**
3. Copy the example cURL command
4. Add your JWT token: `-H "Authorization: Bearer YOUR_JWT_TOKEN"`
5. Run the command

### Expected Response

**Success:**
```json
{
  "success": true,
  "message": "Account and all associated data have been successfully deleted",
  "deletedAt": "2026-02-19T10:30:45.123Z"
}
```

---

## Environment Variables

The function automatically has access to:

| Variable | Value | Used For |
|----------|-------|----------|
| `SUPABASE_URL` | Your project URL | Client initialization |
| `SUPABASE_ANON_KEY` | Anonymous key | Public operations |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key | Admin operations |

These are automatically injected by Supabase.

---

## Debugging

### View Function Logs

```bash
# Using Supabase CLI
supabase functions logs delete-account

# Or in Dashboard
# Go to Edge Functions → delete-account → Invocations tab
```

### Common Issues

**Issue: "Function not found" error**
- Verify function is deployed: `supabase functions list`
- Check function name matches: `delete-account`
- Verify Supabase URL is correct in Flutter app

**Issue: "Unauthorized" error**
- Verify JWT token is valid
- Check token hasn't expired
- Ensure user is authenticated before calling

**Issue: "Forbidden" error**
- Verify authenticated user ID matches userId parameter
- Check RLS policies aren't blocking access

**Issue: Deletion doesn't work**
- Check service role key has correct permissions
- Verify database constraints are set up
- Review Supabase logs for detailed errors

---

## Security Best Practices

✅ **Already Implemented:**
- Authorization validation (bearer token check)
- User ownership verification (can only delete own account)
- Service role key for admin operations
- Proper error messages (no sensitive info leakage)
- HTTPS only (automatic with Supabase)

✅ **Additional Measures:**
- Keep service role key secret (never expose in client code)
- Use environment variables for configuration
- Monitor function invocations for suspicious activity
- Set rate limits if needed

---

## Monitoring

### Function Metrics

Monitor in Supabase Dashboard:
1. **Invocations** tab → View all function calls
2. **Errors** tab → See failed requests
3. **Performance** tab → Check execution time

### Recommended Alerts

Set up monitoring for:
- High error rate (> 5%)
- Slow execution (> 5 seconds)
- Unusual deletion patterns
- Failed authentication attempts

---

## Updating the Function

### If you need to update the function:

1. **Modify code** in `supabase/functions/delete-account/index.ts`

2. **Redeploy**
   ```bash
   supabase functions deploy delete-account
   ```

3. **Verify**
   - Test in dashboard
   - Check logs for errors
   - Monitor for any issues

---

## Rollback

If you need to rollback:

1. **Keep previous version** in git
   ```bash
   git revert <commit-hash>
   ```

2. **Redeploy** previous version
   ```bash
   supabase functions deploy delete-account
   ```

---

## Function Timeout

Default timeout: **60 seconds**

For faster operations, the function typically completes in < 1 second.

If needed to adjust:
- Contact Supabase support for custom timeouts
- Or optimize function code

---

## Cost Considerations

Supabase Edge Functions pricing:
- **Free Tier**: 500k invocations per month
- **Pro Tier**: 2 million invocations per month (+ $0.00001 per additional)

Delete account operations are minimal, so cost should be negligible.

---

## Support & Troubleshooting

### Supabase Documentation
- https://supabase.com/docs/guides/functions

### Common Tasks

**View all functions:**
```bash
supabase functions list
```

**Delete a function:**
```bash
supabase functions delete delete-account
```

**Run locally:**
```bash
supabase functions serve
```

---

## Deployment Checklist

Before considering the feature complete:

- [ ] Edge Function created in Supabase
- [ ] Function deployed successfully
- [ ] Test function using cURL or dashboard
- [ ] Verify success response (200 OK)
- [ ] Test with actual user account
- [ ] Verify account is actually deleted
- [ ] Check cascade deletes work (profile, topics, etc.)
- [ ] Test error scenarios
- [ ] Monitor logs for any issues
- [ ] Update app to use function (already done in Flutter code)
- [ ] Test full flow in app (sign up → delete account)

---

## Next Steps

1. **Deploy the function** using one of the methods above
2. **Test** using the provided cURL examples
3. **Verify** in the Supabase dashboard
4. **Monitor** function invocations
5. **Use** in the Flutter app (code already integrated)

---

## Additional Resources

- Supabase Edge Functions: https://supabase.com/docs/guides/functions
- PostgreSQL ON DELETE CASCADE: https://www.postgresql.org/docs/current/ddl-constraints.html
- Deno Documentation: https://deno.land/manual
- TypeScript Guide: https://www.typescriptlang.org/docs/

---

**Status:** Ready to Deploy
**Last Updated:** February 19, 2026
