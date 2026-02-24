# Quick Start Testing Guide for Registration

## Prerequisites

Before testing, ensure:
1. Supabase project is created and running
2. `.env` file has valid Supabase credentials:
   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
   ```
3. Database schema is applied (run `supabase/schema.sql`)
4. Flutter dependencies are installed: `flutter pub get`

## Running the App

```bash
cd /Users/kagiso/Documents/Projects/Suggesta
flutter clean
flutter run
```

The app will launch on your iOS simulator or connected device.

## Test Scenario 1: Successful Registration

### Objective
Register a new user and verify profile creation

### Steps
1. ✅ App opens → Shows Splash screen (1.5 seconds)
2. ✅ Redirects to Welcome screen
3. ✅ Tap "Create Account" button
4. ✅ Fill in Sign Up form:
   - Email: `test.user@example.com`
   - Username: `testuser123`
   - Password: `Password@123`
   - Confirm Password: `Password@123`
5. ✅ Tap "Sign Up" button
6. ✅ Loading spinner appears
7. ✅ User is redirected to Setup Profile screen

### Expected Results
- ✅ No error messages
- ✅ Form data is cleared
- ✅ User profile created in Supabase

### Verification
In Supabase Dashboard:
1. Go to Authentication → Users
2. Find user with email `test.user@example.com`
3. Go to Database → profiles table
4. Verify row exists with username `testuser123`

---

## Test Scenario 2: Login with Registered User

### Objective
Login with previously created account

### Steps
1. ✅ From Setup Profile screen, tap "Skip for now"
2. ✅ You're on Home screen (logout first to test login)
3. ✅ Logout (if implemented) or restart app
4. ✅ On Welcome screen, tap "Login" button
5. ✅ Enter credentials:
   - Email: `test.user@example.com`
   - Password: `Password@123`
6. ✅ Tap "Login" button
7. ✅ Loading spinner appears
8. ✅ Redirected to Home screen

### Expected Results
- ✅ No error messages
- ✅ User session is established
- ✅ Can access protected features

---

## Test Scenario 3: Email Validation

### Objective
Verify email validation works correctly

### Steps
1. ✅ Go to Sign Up screen
2. ✅ Enter invalid email: `notanemail`
3. ✅ Tap "Sign Up" button
4. ✅ Form should not submit

### Expected Results
- ✅ Error message: "Please enter a valid email"
- ✅ Form stays on Sign Up screen

### Test Cases
| Email | Expected Outcome |
|-------|-----------------|
| `user@example.com` | ✅ Valid |
| `user.name@example.co.uk` | ✅ Valid |
| `notanemail` | ❌ Invalid |
| `@example.com` | ❌ Invalid |
| `user@` | ❌ Invalid |

---

## Test Scenario 4: Username Validation

### Objective
Verify username validation and uniqueness

### Steps
1. ✅ Go to Sign Up screen
2. ✅ Try each username and observe validation

### Test Cases
| Username | Expected Outcome |
|----------|-----------------|
| `john` | ✅ Valid (4 chars) |
| `jo` | ❌ Too short |
| `a_valid_username_123` | ✅ Valid |
| `user@name` | ❌ Invalid chars |
| `user name` | ❌ Invalid chars |
| `user!` | ❌ Invalid chars |
| `testuser123` | ❌ Already taken |

---

## Test Scenario 5: Password Validation

### Objective
Verify password requirements

### Test Cases
| Password | Confirm | Expected Outcome |
|----------|---------|-----------------|
| `pass123` | `pass123` | ✅ Valid |
| `123` | `123` | ❌ Too short |
| `password123` | `password456` | ❌ Don't match |
| (empty) | (empty) | ❌ Required |

---

## Test Scenario 6: Complete Profile Setup

### Objective
Test profile completion flow

### Steps
1. ✅ Complete Sign Up successfully
2. ✅ On Setup Profile screen:
   - Leave picture empty (coming soon)
   - Enter Bio: "I love technology and innovation!"
   - Tap "Complete Setup"
3. ✅ Redirected to Home screen

### Expected Results
- ✅ Profile updated in database
- ✅ Bio saved to profiles table

---

## Test Scenario 7: Skip Profile Setup

### Objective
Test ability to skip profile completion

### Steps
1. ✅ Complete Sign Up successfully
2. ✅ On Setup Profile screen, tap "Skip for now"
3. ✅ Redirected to Home screen

### Expected Results
- ✅ No error
- ✅ User can still use app
- ✅ Can edit profile later

---

## Test Scenario 8: Logout and Re-login

### Objective
Test session persistence and logout

### Steps
1. ✅ Logged in on Home screen
2. ✅ Logout (implement logout button)
3. ✅ Redirected to Welcome screen
4. ✅ Login again with same credentials
5. ✅ Should return to Home screen

### Expected Results
- ✅ Session is properly cleared
- ✅ Can re-login successfully

---

## Test Scenario 9: Error Messages

### Objective
Verify proper error handling and messages

### Test Cases
| Action | Expected Error |
|--------|----------------|
| Sign up with taken username | "Username is already taken" |
| Sign up with invalid email | "Please enter a valid email" |
| Login with wrong password | Clear Supabase error message |
| Login with non-existent account | Clear Supabase error message |

### How to Trigger Errors
1. Try signing up with same email twice
2. Try signing up with invalid credentials
3. Try logging in with wrong password

---

## Debugging Tips

### Enable Debug Logging
Add this to `main.dart`:
```dart
Supabase.initialize(
  url: SupabaseConstants.supabaseUrl,
  anonKey: SupabaseConstants.supabaseAnonKey,
  debug: true,  // Enable debug logging
);
```

### Check Console Output
- Look for Flutter DevTools output
- Check terminal for error messages
- Use VS Code debugging tools

### Supabase Dashboard Checks
1. Go to Authentication tab
   - See all registered users
   - Check creation timestamps
   - Verify email addresses

2. Go to Database → profiles table
   - See all created profiles
   - Verify username uniqueness
   - Check bio and avatar_url

### Network Issues
- Check internet connectivity
- Verify Supabase project is running
- Check if .env credentials are correct
- Look for CORS or API key errors

---

## Common Issues & Solutions

### Issue: Sign up fails with "Unexpected error"
**Solution**:
- Verify Supabase credentials in `.env`
- Check Supabase project status in dashboard
- Check network connectivity
- Review Supabase logs

### Issue: Username not updating
**Solution**:
- Ensure profile exists first
- Check RLS policies in Supabase
- Verify username field in profiles table
- Check for database constraints

### Issue: Can't login after signup
**Solution**:
- Verify user exists in Supabase Auth
- Check email/password are correct
- Verify Supabase project is live
- Check auth email confirmation requirements

### Issue: App crashes on signup
**Solution**:
- Check for null values
- Verify all form fields are filled
- Check Flutter DevTools console
- Look for Riverpod state issues

---

## Performance Testing

### Metrics to Monitor
- Sign up time: < 3 seconds
- Login time: < 2 seconds
- Form validation: instant (< 100ms)
- Error display: immediate

### Load Testing
- Test with slow network (throttle in DevTools)
- Test with poor signal
- Test with network interruption

---

## Security Testing

### Password Testing
- ✅ Passwords are not logged
- ✅ Passwords are not shown in plaintext (unless toggle enabled)
- ✅ Password field uses proper input type

### Session Testing
- ✅ Session is cleared on logout
- ✅ Can't access protected routes without login
- ✅ Session persists on app restart

### Data Privacy
- ✅ User data is not logged
- ✅ Only profile info is stored locally
- ✅ Sensitive data not in Riverpod debugger

---

## Success Criteria

✅ All tests pass
✅ No console errors
✅ No compilation warnings
✅ Smooth navigation between screens
✅ Proper error messages displayed
✅ Data persists in database
✅ Session management works
✅ UI is responsive and professional

---

## Reporting Issues

If you encounter issues, note:
1. Exact error message
2. Steps to reproduce
3. Device/simulator type
4. Network conditions
5. Supabase project status
6. Console output/logs

---

**Last Updated**: February 19, 2026
**Status**: Ready for Testing
