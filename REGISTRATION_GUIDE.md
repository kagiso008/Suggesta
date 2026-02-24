# Suggesta Registration & Authentication Guide

## Overview

The Suggesta app now has a complete user registration and authentication system powered by Supabase. Users can sign up, log in, and complete their profile setup.

## Architecture

### Components

#### 1. **Auth Repository** (`lib/features/auth/data/auth_repository.dart`)
- Handles all Supabase authentication operations
- Methods:
  - `signUp()` - Register new user with email and password
  - `signIn()` - Login existing user
  - `signOut()` - Logout user
  - `isUsernameAvailable()` - Check username availability
  - `updateProfile()` - Update user profile information
  - `getProfile()` - Retrieve user profile
  - `resetPassword()` - Send password reset email
  - `updatePassword()` - Change user password

#### 2. **Auth Provider** (`lib/features/auth/presentation/providers/auth_provider.dart`)
- Riverpod state management for authentication
- Providers:
  - `supabaseProvider` - Supabase client instance
  - `authRepositoryProvider` - Auth repository instance
  - `authStateProvider` - Stream of auth state changes
  - `currentSessionProvider` - Current user session
  - `currentUserProvider` - Current authenticated user
  - `currentUserIdProvider` - Current user ID
  - `authNotifierProvider` - State notifier for auth operations

#### 3. **Screens**

**Splash Screen** (`splash_screen.dart`)
- Displays on app launch
- Checks current auth session
- Routes to `/welcome` (no session) or `/home` (authenticated)

**Welcome Screen** (`welcome_screen.dart`)
- Entry point for unauthenticated users
- Shows app features overview
- Buttons to navigate to Login or Sign Up

**Sign Up Screen** (`signup_screen.dart`)
- User registration form
- Features:
  - Email validation
  - Username validation (3-20 chars, alphanumeric + underscore)
  - Password strength requirement (min 6 chars)
  - Password confirmation
  - Username availability check
  - Real-time error feedback
  - Loading state during submission

**Login Screen** (`login_screen.dart`)
- User login form
- Features:
  - Email validation
  - Password input with visibility toggle
  - Loading state during submission
  - Error message display
  - "Forgot Password" link (coming soon)

**Setup Profile Screen** (`setup_profile_screen.dart`)
- Post-registration profile setup
- Features:
  - Profile picture upload (coming soon)
  - Bio field (optional, max 500 chars)
  - Skip option to go directly to home
  - Loading state during update

## Registration Flow

### Step 1: Welcome
User launches app → Splash screen → Welcome screen

### Step 2: Sign Up
1. User enters email, username, password, confirm password
2. Frontend validates all fields
3. Check if username is available
4. Call `Supabase.auth.signUp()` with email and password
5. Supabase automatically creates auth user
6. Supabase trigger `handle_new_user()` auto-creates profile row
7. Update profile with username and other details
8. Navigate to setup profile screen

### Step 3: Setup Profile
1. User can optionally upload profile picture
2. User can add bio
3. User clicks "Complete Setup" or "Skip for now"
4. Navigate to home screen

### Step 4: Logged In
- User can access main app features
- Auth state is persisted via Supabase session

## Database Schema

### Profiles Table
```sql
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE NOT NULL,
    avatar_url TEXT,
    bio TEXT,
    created_at TIMESTAMPTZ DEFAULT now()
);
```

### Auto-create Profile Trigger
When a user signs up via Supabase Auth, a PostgreSQL trigger automatically creates a profile row:
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

## Validation Rules

### Email
- Must be valid email format (user@domain.ext)

### Username
- Required
- 3-20 characters
- Only letters, numbers, and underscores
- Must be unique in database

### Password
- Required
- Minimum 6 characters
- Must match confirmation password

### Bio
- Optional
- Maximum 500 characters

## Error Handling

All screens include comprehensive error handling:
- Display error messages in red alert boxes
- Show specific error reasons to user
- Allow retry without losing form data
- Disable form during submission to prevent duplicate requests

## Security Features

1. **Row Level Security (RLS)**
   - Users can only update their own profile
   - RLS policies enforce data access rules

2. **Secure Password Storage**
   - Passwords stored securely via Supabase Auth
   - Never transmitted or exposed in app

3. **Session Management**
   - Supabase manages auth sessions securely
   - Sessions are persisted locally on device

4. **Input Validation**
   - Frontend validation for UX
   - Backend validation via database constraints
   - SQL injection protection via parameterized queries

## Testing the Registration

### Manual Testing Steps

1. **Test Sign Up**
   ```
   1. Navigate to Welcome screen
   2. Tap "Create Account"
   3. Enter valid email (e.g., test@example.com)
   4. Enter username (e.g., john_doe)
   5. Enter password (e.g., password123)
   6. Confirm password
   7. Tap "Sign Up"
   8. Should navigate to "Setup Profile"
   ```

2. **Test Login**
   ```
   1. Navigate to Welcome screen
   2. Tap "Login"
   3. Enter registered email
   4. Enter password
   5. Tap "Login"
   6. Should navigate to Home screen
   ```

3. **Test Validation**
   ```
   - Invalid email → Error message
   - Username < 3 chars → Error message
   - Username with special chars → Error message
   - Password < 6 chars → Error message
   - Passwords don't match → Error message
   - Existing username → Error message
   ```

## Environment Variables Required

Add to `.env` file:
```
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
```

Get these from [Supabase Dashboard](https://supabase.com/dashboard)

## Next Steps

- [ ] Implement profile picture upload
- [ ] Add email verification
- [ ] Implement password reset flow
- [ ] Add social login (Google, GitHub)
- [ ] Add phone authentication
- [ ] Implement 2FA

## Troubleshooting

### Sign Up Fails
- Check Supabase project is running
- Verify `.env` file has correct credentials
- Check network connectivity
- Review Supabase logs in dashboard

### Username Not Updating
- Ensure profile is created first
- Check RLS policies allow update
- Verify username is not taken

### Login Fails
- Verify correct email/password combination
- Check user account exists in Supabase
- Verify auth credentials in `.env`

## Code Structure

```
lib/features/auth/
├── data/
│   └── auth_repository.dart          # Supabase operations
├── presentation/
│   ├── providers/
│   │   └── auth_provider.dart        # Riverpod state management
│   └── screens/
│       ├── splash_screen.dart        # App launch
│       ├── welcome_screen.dart       # Entry point
│       ├── signup_screen.dart        # Registration form
│       ├── login_screen.dart         # Login form
│       └── setup_profile_screen.dart # Profile setup
```

## References

- [Supabase Flutter Guide](https://supabase.com/docs/guides/getting-started/quickstarts/flutter)
- [Supabase Auth](https://supabase.com/docs/guides/auth)
- [Riverpod Documentation](https://riverpod.dev/)
- [Go Router Documentation](https://pub.dev/packages/go_router)
