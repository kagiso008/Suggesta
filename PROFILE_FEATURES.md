# 👤 Profile Screen - Complete Features

## Overview

The Profile Screen provides users with a complete profile management interface where they can:
- ✅ View their account details
- ✅ Edit their username and bio
- ✅ Sign out of their account
- ✅ Delete their account permanently

---

## 📋 Features

### 1. View Profile Details

Users can see their current profile information:
- **Email** (read-only) - The email they registered with
- **Username** - Their chosen username
- **Bio** - Personal biography/description

```
┌─────────────────────────────┐
│ Profile                     │
├─────────────────────────────┤
│                             │
│ Email                       │
│ user@example.com (readonly) │
│                             │
│ Username                    │
│ john_doe                    │
│                             │
│ Bio                         │
│ Software developer...       │
│                             │
└─────────────────────────────┘
```

### 2. Edit Profile

Users can click "Edit Profile" to modify their username and bio:

**Features:**
- ✅ Inline editing with text fields
- ✅ Bio character limit: 500 characters
- ✅ Real-time character count display
- ✅ Save or Cancel buttons
- ✅ Success message on save

**Editable Fields:**
- Username (alphanumeric + underscore, 3-20 characters)
- Bio (optional, max 500 characters)

```
┌─────────────────────────────┐
│ Profile                Save  │
├─────────────────────────────┤
│                             │
│ Email                       │
│ user@example.com (readonly) │
│                             │
│ Username                    │
│ [john_doe____________]      │ ← Editable input
│                             │
│ Bio                         │
│ [Tell us about yourself...] │ ← Editable textarea
│ [Counter: 45/500]           │
│                             │
│ [Cancel]                    │
│                             │
└─────────────────────────────┘
```

### 3. Sign Out

Secure sign-out functionality:

**Features:**
- ✅ Confirmation dialog before signing out
- ✅ User-friendly message
- ✅ Loading indicator during sign-out
- ✅ Redirects to Welcome screen after logout
- ✅ Clears session from Supabase

**Dialog:**
```
┌─────────────────────────────┐
│ Sign Out                    │
├─────────────────────────────┤
│ Are you sure you want to    │
│ sign out?                   │
│                             │
│  [Cancel]  [Sign Out]       │
└─────────────────────────────┘
```

**After Signing Out:**
- User is redirected to `/welcome` screen
- Session is cleared
- User must log in again to access the app

### 4. Delete Account

Permanent account deletion with safety confirmations:

**Features:**
- ✅ Warning dialog with clear message
- ✅ User must confirm deletion
- ✅ Deletes profile from database
- ✅ Signs out user automatically
- ✅ Redirects to Welcome screen
- ✅ Cannot be undone

**Dialog:**
```
┌─────────────────────────────────────┐
│ Delete Account                      │
├─────────────────────────────────────┤
│ This action cannot be undone. Your  │
│ account and all data will be        │
│ permanently deleted.                │
│                                     │
│  [Cancel]  [Delete Account]         │
└─────────────────────────────────────┘
```

**Process:**
1. User clicks "Delete Account"
2. Confirmation dialog appears
3. User confirms deletion
4. Profile data is deleted from database
5. User is automatically signed out
6. App navigates to Welcome screen

---

## 🎨 UI Design

### Color Scheme
- **Primary Indigo (#6366F1)** - Edit Profile button, focus borders
- **Success Green (#10B981)** - Sign Out button
- **Danger Red (#EF4444)** - Delete Account button
- **White (#FFFBFB)** - Background
- **Dark Gray (#1F2937)** - Text
- **Light Gray (#E5E7EB)** - Borders
- **Light Red (#FEE2E2)** - Warning message background

### Components

#### Info Field (Read-only Display)
```dart
_buildInfoField(
  label: 'Email',
  value: 'user@example.com',
  isReadOnly: true,
)
```
- Light gray background for read-only fields
- Shows label and value
- No interaction possible

#### Editable Field
```dart
_buildEditableField(
  label: 'Username',
  controller: _usernameController,
  hint: 'Enter your username',
)
```
- White background
- Focus border changes to indigo
- Support for maxLines and maxLength
- Character counter for long fields

#### Buttons
- **Edit Profile** - Indigo (#6366F1)
- **Sign Out** - Green (#10B981)
- **Delete Account** - Red (#EF4444)
- **Cancel** - Gray (#9CA3AF)

---

## 💻 Code Implementation

### Profile Screen Class
```dart
class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;
  const ProfileScreen({super.key, required this.userId});
}
```

### State Management
- Uses Riverpod for auth state
- Watches `authNotifierProvider` for loading/error states
- Watches `currentUserProvider` for user email
- Uses `authRepositoryProvider` to fetch profile data

### Key Methods

#### `_loadProfile()`
- Fetches current user profile from database
- Populates username and bio fields
- Called in `initState`

#### `_handleSaveProfile()`
- Calls `authNotifier.updateProfile()`
- Shows success/error messages
- Exits edit mode on success

#### `_handleSignOut()`
- Shows confirmation dialog
- Calls `authNotifier.signOut()`
- Navigates to `/welcome`

#### `_handleDeleteAccount()`
- Shows deletion confirmation dialog
- Calls `authNotifier.deleteAccount()`
- Redirects to `/welcome`

---

## 📡 Backend Integration

### Auth Repository Methods

#### `updateProfile()`
```dart
Future<void> updateProfile({
  required String userId,
  String? username,
  String? bio,
}) async
```
- Updates profile in Supabase
- Called after user edits profile
- Requires user ID

#### `deleteAccount()`
```dart
Future<void> deleteAccount(String userId) async
```
- Deletes profile from database
- Signs out the user
- Clears session

### Auth Provider Methods

#### `updateProfile()`
```dart
Future<void> updateProfile({
  String? username,
  String? bio,
}) async
```
- Sets state to loading
- Calls repository method
- Handles errors
- Updates UI state

#### `deleteAccount()`
```dart
Future<void> deleteAccount(String userId) async
```
- Sets state to loading
- Calls repository method
- Deletes profile and signs out
- Handles errors

---

## ✅ User Flow

### Edit Profile Flow
```
User navigates to Profile
         ↓
Sees current profile details
         ↓
Clicks "Edit Profile"
         ↓
Fields become editable
         ↓
User modifies username/bio
         ↓
Clicks "Save"
         ↓
Profile updates in database
         ↓
Success message shown
         ↓
Exit edit mode
```

### Sign Out Flow
```
User clicks "Sign Out"
         ↓
Confirmation dialog appears
         ↓
User confirms
         ↓
State set to loading
         ↓
Supabase signs out user
         ↓
Session cleared
         ↓
Navigate to /welcome
         ↓
User sees Welcome screen
```

### Delete Account Flow
```
User clicks "Delete Account"
         ↓
Warning dialog appears
         ↓
User confirms deletion
         ↓
State set to loading
         ↓
Profile deleted from database
         ↓
User signed out
         ↓
Session cleared
         ↓
Navigate to /welcome
         ↓
User sees Welcome screen
```

---

## 🔒 Security Features

✅ **Confirmation Dialogs**
- All destructive actions require confirmation
- Clear warnings for permanent actions

✅ **Session Management**
- User must be logged in to access profile
- Session cleared on sign out/delete
- Protected routes via Go Router

✅ **Database Queries**
- Profile only visible to logged-in user
- RLS policies prevent unauthorized access
- User can only edit their own profile

✅ **Error Handling**
- User-friendly error messages
- Validation on all inputs
- Error dialog on failures

---

## 🎯 Field Validation

### Username
- Length: 3-20 characters
- Characters: Letters, numbers, underscores only
- Required field
- Must be unique (checked during signup)

### Bio
- Maximum: 500 characters
- Optional field
- Character counter displayed while editing

### Email
- Read-only field
- Cannot be changed from profile
- Would require password verification if changeable

---

## 📱 Responsive Design

### Mobile (Current)
- Single column layout
- Full-width buttons
- Optimized for portrait orientation
- Padding: 24px horizontal

### Touch Targets
- Minimum 48x48 dp for buttons
- Large text fields for easy typing
- Clear tap areas

---

## 🚀 Future Enhancements

### Planned Features
- [ ] Profile picture upload and display
- [ ] Avatar preview/selection
- [ ] Social media links
- [ ] Privacy settings
- [ ] Notification preferences
- [ ] Account verification status
- [ ] Login history
- [ ] Connected devices list
- [ ] Two-factor authentication
- [ ] Export account data

---

## 🐛 Error Handling

### Possible Errors

**Update Profile Fails:**
- Display: "Failed to update profile: [error message]"
- Color: Red (#EF4444)
- Duration: 3 seconds

**Sign Out Fails:**
- Display: "Sign out failed: [error message]"
- Color: Red (#EF4444)
- Duration: 3 seconds

**Delete Account Fails:**
- Display: "Failed to delete account: [error message]"
- Color: Red (#EF4444)
- Duration: 3 seconds
- User remains on profile screen

---

## 📊 State Management

### Riverpod Providers Used

```dart
// Watch current user
final currentUser = ref.watch(currentUserProvider);

// Watch auth state for loading/error
final authState = ref.watch(authNotifierProvider);

// Access auth repository
final authRepository = ref.read(authRepositoryProvider);

// Access auth notifier for actions
final authNotifier = ref.read(authNotifierProvider.notifier);
```

### State Transitions

```
Initial → Loading → Success/Error
  ↓        ↓          ↓
Show UI  Spinner   Message
```

---

## 🧪 Testing Checklist

- [ ] Can view own profile details
- [ ] Email field is read-only
- [ ] Edit Profile button works
- [ ] Can edit username
- [ ] Can edit bio
- [ ] Character counter works for bio
- [ ] Save button updates profile
- [ ] Success message appears
- [ ] Exit edit mode on save
- [ ] Cancel button exits edit mode
- [ ] Sign Out dialog appears
- [ ] Can confirm sign out
- [ ] Redirects to Welcome after sign out
- [ ] Delete Account dialog appears
- [ ] Warning message is clear
- [ ] Can confirm deletion
- [ ] Profile deleted from database
- [ ] Redirects to Welcome after delete
- [ ] Error messages display correctly
- [ ] Loading indicators appear during operations

---

**Profile Screen Status:** ✅ **Complete**
**Build Status:** ✅ **No Errors**
**Features:** ✅ **View, Edit, Sign Out, Delete**
**Date:** February 19, 2026

