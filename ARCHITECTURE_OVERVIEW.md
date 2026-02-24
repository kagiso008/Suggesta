# Suggesta Registration System - Visual Overview

## User Flow Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        APP LAUNCHED                             │
└──────────────────────────┬──────────────────────────────────────┘
                           │
                    ┌──────▼──────┐
                    │  Splash     │
                    │  Screen     │
                    │  (1.5 sec)  │
                    └──────┬──────┘
                           │
          ┌────────────────┴────────────────┐
          │                                 │
    ┌─────▼─────┐                    ┌─────▼─────┐
    │ No Session│                    │  Session  │
    │  Exists   │                    │   Exists  │
    └─────┬─────┘                    └─────┬─────┘
          │                                 │
    ┌─────▼──────────┐              ┌──────▼──────────┐
    │ Welcome Screen │              │  Home Screen    │
    │                │              │ (Main Features) │
    └─────┬──────────┘              └─────────────────┘
          │
    ┌─────┴──────────┬──────────────┐
    │                │              │
┌───▼────┐      ┌────▼────┐   ┌────▼────┐
│ Sign Up│      │  Login  │   │  Other  │
│ Screen │      │  Screen │   │ Options │
└───┬────┘      └────┬────┘   └─────────┘
    │                │
    └────────┬───────┘
             │
      ┌──────▼──────────────┐
      │ Auth with Supabase  │
      │ (Email + Password)  │
      └──────┬──────────────┘
             │
      ┌──────▼──────────────────────┐
      │ Session Created             │
      │ Profile Auto-Created (RLS)  │
      └──────┬──────────────────────┘
             │
      ┌──────▼──────────────┐
      │ Setup Profile Screen│
      │ (Optional Details)  │
      └──────┬──────────────┘
             │
      ┌──────▼──────────────┐
      │  Home Screen        │
      │ (Fully Logged In)   │
      └─────────────────────┘
```

---

## Screen Wireframes

### 1. Welcome Screen
```
┌────────────────────────────────────────┐
│  ┌──────────────────────────────────┐  │
│  │         💡 SUGGESTA             │  │
│  │   Share ideas. Vote. Decide.     │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 📱 Share Topics                  │  │
│  │    Discuss topics that matter    │  │
│  │                                  │  │
│  │ 👍 Vote & Engage                │  │
│  │    Support ideas & be heard      │  │
│  │                                  │  │
│  │ 📈 Discover Trends              │  │
│  │    Find what's trending          │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │     [Login Button]               │  │
│  └──────────────────────────────────┘  │
│  ┌──────────────────────────────────┐  │
│  │  [Create Account Button]         │  │
│  └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

### 2. Sign Up Screen
```
┌────────────────────────────────────────┐
│  < Create Account                      │
├────────────────────────────────────────┤
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 📧 Email                         │  │
│  │ [you@example.com________________]│  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 👤 Username                      │  │
│  │ [john_doe________________]       │  │
│  │ 3-20 chars, letters/numbers/_    │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 🔒 Password                      │  │
│  │ [••••••••••••••••••] 👁         │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 🔒 Confirm Password              │  │
│  │ [••••••••••••••••••] 👁         │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │   [Sign Up] (with spinner)       │  │
│  └──────────────────────────────────┘  │
│                                        │
│  Already have account? Login           │
└────────────────────────────────────────┘
```

### 3. Login Screen
```
┌────────────────────────────────────────┐
│  < Login                               │
├────────────────────────────────────────┤
│                                        │
│  Welcome Back                          │
│  Sign in to your account               │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 📧 Email                         │  │
│  │ [you@example.com________________]│  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 🔒 Password                      │  │
│  │ [••••••••••••••••••] 👁         │  │
│  └──────────────────────────────────┘  │
│                                        │
│  Forgot Password?                      │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │  [Login] (with spinner)          │  │
│  └──────────────────────────────────┘  │
│                                        │
│  Don't have account? Sign up           │
└────────────────────────────────────────┘
```

### 4. Setup Profile Screen
```
┌────────────────────────────────────────┐
│  Setup Profile                         │
├────────────────────────────────────────┤
│                                        │
│  Complete Your Profile                 │
│  Add details to personalize account    │
│                                        │
│         ┌─────────────────┐           │
│         │  👤           │            │
│         │  📷           │            │
│         └─────────────────┘           │
│  [Upload Profile Picture]             │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ 📝 Bio                           │  │
│  │ [Tell us about yourself...______│  │
│  │ ________________________________│  │
│  │ ________________________________│  │
│  │ (500 chars max)                 │  │
│  └──────────────────────────────────┘  │
│                                        │
│  ┌──────────────────────────────────┐  │
│  │ [Complete Setup] (with spinner)  │  │
│  └──────────────────────────────────┘  │
│                                        │
│  [Skip for now]                        │
└────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────────┐
│                      User Input (Form)                           │
├──────────────────────────────────────────────────────────────────┤
│  • Email                                                         │
│  • Username                                                      │
│  • Password                                                      │
│  • Confirm Password                                             │
│  • Bio (optional)                                               │
└──────────────────────┬───────────────────────────────────────────┘
                       │
           ┌───────────▼────────────┐
           │  Frontend Validation   │
           │  (Riverpod + Dart)     │
           │  • Email format        │
           │  • Username rules      │
           │  • Password length     │
           │  • Password match      │
           └───────────┬────────────┘
                       │
           ┌───────────▼──────────────┐
           │  Supabase Auth.signUp()  │
           │  or Auth.signInWithPwd() │
           └───────────┬──────────────┘
                       │
       ┌───────────────┴───────────────┐
       │                               │
   ┌───▼──────┐                 ┌─────▼──────┐
   │ Auth User│                 │ RLS Policy │
   │ Created  │                 │ Verified   │
   └───┬──────┘                 └────────────┘
       │
   ┌───▼─────────────────────┐
   │ Trigger: handle_new_user│
   └───┬─────────────────────┘
       │
   ┌───▼────────────────────────┐
   │ Profile Row Auto-Created    │
   │ • id (from auth user)       │
   │ • username (from metadata)  │
   │ • created_at (timestamp)    │
   └───┬────────────────────────┘
       │
   ┌───▼──────────────────────────┐
   │ updateProfile() Call          │
   │ • Set username if not set     │
   │ • Set bio (optional)          │
   │ • Set avatar_url (optional)   │
   └───┬──────────────────────────┘
       │
   ┌───▼──────────────────────┐
   │ RLS Policy Check         │
   │ auth.uid() = id          │
   └───┬──────────────────────┘
       │
   ┌───▼──────────────────────────────┐
   │ Profile Updated Successfully      │
   └───┬──────────────────────────────┘
       │
   ┌───▼──────────────┐
   │ Session Created  │
   └───┬──────────────┘
       │
   ┌───▼──────────────┐
   │ Navigate to Home │
   │ (User Logged In) │
   └──────────────────┘
```

---

## Database Schema Diagram

```
┌─────────────────────────────────────────────────────┐
│                  auth.users (Supabase Built-in)    │
├─────────────────────────────────────────────────────┤
│ • id (UUID) - PRIMARY KEY                          │
│ • email (TEXT) - UNIQUE                            │
│ • password (encrypted) - NOT SHOWN                 │
│ • created_at (TIMESTAMPTZ)                         │
│ • updated_at (TIMESTAMPTZ)                         │
└────────────────┬────────────────────────────────────┘
                 │ REFERENCES
                 │ ON DELETE CASCADE
                 │
┌────────────────▼────────────────────────────────────┐
│                    profiles                         │
├─────────────────────────────────────────────────────┤
│ • id (UUID) - PRIMARY KEY - FK(auth.users.id)      │
│ • username (TEXT) - UNIQUE NOT NULL                │
│ • avatar_url (TEXT) - NULL                         │
│ • bio (TEXT) - NULL                                │
│ • created_at (TIMESTAMPTZ) - DEFAULT now()         │
└─────────────────────────────────────────────────────┘

RELATIONSHIPS:
- Each auth.user has ONE profile
- Each profile has ONE auth.user
- When auth.user deleted → profile auto-deleted
- Username must be unique across all profiles
- RLS Policy: Users can only read all profiles
                  but can only UPDATE their own
```

---

## API Call Sequence

### Sign Up Flow
```
1. User fills form
   ↓
2. Frontend validates input
   ↓
3. Call Supabase.auth.signUp(email, password)
   ↓
4. Supabase creates auth.user
   ↓
5. Trigger fires: handle_new_user()
   ↓
6. Create profiles row with auto-generated username
   ↓
7. Call authRepository.updateProfile(username, bio)
   ↓
8. Supabase verifies RLS policy
   ↓
9. Profile updated
   ↓
10. Return to app with session
```

### Login Flow
```
1. User fills email & password
   ↓
2. Frontend validates input
   ↓
3. Call Supabase.auth.signInWithPassword(email, password)
   ↓
4. Supabase verifies credentials
   ↓
5. Session created and returned
   ↓
6. App stores session locally
   ↓
7. authStateProvider updates
   ↓
8. Navigation to Home
```

---

## State Management Tree (Riverpod)

```
authNotifierProvider (StateNotifier<AsyncValue<void>>)
├── signUp(email, password)
│   ├── Check username availability
│   ├── Call authRepository.signUp()
│   ├── Call authRepository.updateProfile()
│   └── Update state: AsyncValue.data(null)
├── signIn(email, password)
│   ├── Call authRepository.signIn()
│   └── Update state: AsyncValue.data(null)
├── signOut()
│   ├── Call authRepository.signOut()
│   └── Update state: AsyncValue.data(null)
└── updateProfile(username, bio)
    ├── Call authRepository.updateProfile()
    └── Update state: AsyncValue.data(null)

authStateProvider (StreamProvider<AuthState>)
└── Listens to authRepository.authStateChanges

currentUserProvider (Provider<User?>)
└── Gets currentUser from authRepository

currentSessionProvider (Provider<Session?>)
└── Gets currentSession from authRepository

currentUserIdProvider (Provider<String?>)
└── Extracts userId from currentUser
```

---

## Component Interaction Diagram

```
┌────────────────────────────────────────────────────┐
│         SignUp/Login/SetupProfile Screen           │
│         (ConsumerStatefulWidget)                   │
└────────────────────┬───────────────────────────────┘
                     │ calls
                     │
                     ▼
        ┌────────────────────────────┐
        │  ref.read(authNotifier)    │
        │      .signUp()/.signIn()   │
        │      .updateProfile()      │
        └────────────┬───────────────┘
                     │ calls
                     │
                     ▼
        ┌────────────────────────────────┐
        │  AuthNotifier                  │
        │  (StateNotifier)               │
        └────────────┬───────────────────┘
                     │ calls
                     │
                     ▼
        ┌────────────────────────────────┐
        │  AuthRepository                │
        │  (Repository Pattern)          │
        └────────────┬───────────────────┘
                     │ calls
                     │
                     ▼
        ┌────────────────────────────────┐
        │  Supabase Client               │
        │  • auth.signUp()               │
        │  • auth.signInWithPassword()   │
        │  • database.upsert()           │
        │  • database.select().eq()      │
        └────────────┬───────────────────┘
                     │
                     ▼
        ┌────────────────────────────────┐
        │  Supabase Backend              │
        │  • PostgreSQL                  │
        │  • Auth Service                │
        │  • RLS Policies                │
        │  • Triggers                    │
        └────────────────────────────────┘
```

---

## Error Handling Flow

```
┌──────────────────┐
│  User Action     │
└────────┬─────────┘
         │
    ┌────▼────────────────────┐
    │  Form Validation        │
    │  (Synchronous)          │
    └────┬───────────┬────────┘
         │           │
      ✅ Valid    ❌ Invalid
         │           │
         │    ┌──────▼─────────┐
         │    │ Show Error:    │
         │    │ • Invalid Email│
         │    │ • Short Pass   │
         │    │ • etc.         │
         │    └────────────────┘
         │
    ┌────▼──────────────────────┐
    │  API Call to Supabase     │
    │  (Async)                  │
    └────┬──────────────┬────────┘
         │              │
      ✅ Success    ❌ Error
         │              │
    ┌────▼────────┐  ┌──▼────────────────────┐
    │ Update State│  │ Catch Exception       │
    │ Navigate    │  │ • Network error       │
    │ Home        │  │ • Auth error          │
    └─────────────┘  │ • DB error            │
                     │ • Constraint error    │
                     └───┬──────────────────┘
                         │
                    ┌────▼─────────────┐
                    │ Show Error Alert │
                    │ • Specific msg   │
                    │ • Allow Retry    │
                    │ • Keep Form Data │
                    └──────────────────┘
```

---

## Security Architecture

```
┌─────────────────────────────────────────────────────┐
│                 Frontend (Flutter)                  │
├─────────────────────────────────────────────────────┤
│ • Input Validation (RegEx, Length)                 │
│ • Password visibility toggle (UX)                  │
│ • Form state management (Riverpod)                │
│ • No password logging                             │
│ • Secure error messages (no info leakage)         │
└────────────────────┬────────────────────────────────┘
                     │ HTTPS
                     │ API Key in .env
                     │
┌────────────────────▼────────────────────────────────┐
│              Supabase Edge (HTTPS)                 │
├─────────────────────────────────────────────────────┤
│ • SSL/TLS Encryption                              │
│ • API Key Authentication                          │
│ • Rate Limiting                                   │
│ • DDoS Protection                                 │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│             Supabase Auth Service                  │
├─────────────────────────────────────────────────────┤
│ • Password Hashing (bcrypt)                       │
│ • Session Tokens (JWT)                            │
│ • Email Verification (optional)                   │
│ • Token Refresh Logic                             │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│            PostgreSQL Database                     │
├─────────────────────────────────────────────────────┤
│ • Row Level Security (RLS) Policies                │
│ • Encrypted Password Storage                      │
│ • Unique Constraints (username, email)            │
│ • Foreign Key Constraints                         │
│ • Audit Logs                                      │
└─────────────────────────────────────────────────────┘

SECURITY FEATURES:
✅ Passwords never transmitted in plaintext
✅ RLS prevents unauthorized data access
✅ Input validation (frontend + backend)
✅ Session management (Supabase)
✅ Token-based authentication (JWT)
✅ HTTPS for all communications
✅ Environment variables for secrets
✅ No sensitive data in logs
```

---

## Summary

This visual overview shows:
- ✅ Complete user flow from app launch to logged-in state
- ✅ Screen layouts and components
- ✅ Data flow through the system
- ✅ Database relationships
- ✅ API call sequences
- ✅ Riverpod state management structure
- ✅ Error handling process
- ✅ Security architecture

All components are implemented and working correctly! 🎉
