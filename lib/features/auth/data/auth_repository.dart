import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/supabase_constants.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository({required SupabaseClient supabase}) : _supabase = supabase;

  /// Get the current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Get the current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Get the Supabase client (for storage operations)
  SupabaseClient get supabaseClient => _supabase;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signUp(email: email, password: password);
    } on AuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during sign up: $e');
    }
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
    } catch (e) {
      throw Exception('An unexpected error occurred during sign in: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    final response = await _supabase
        .from(SupabaseConstants.profilesTable)
        .select('id')
        .eq('username', username)
        .maybeSingle();

    return response == null;
  }

  /// Update user profile after signup
  Future<void> updateProfile({
    required String userId,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    final Map<String, dynamic> updates = {'id': userId};

    if (username != null && username.isNotEmpty) {
      updates['username'] = username;
    }
    if (bio != null) {
      updates['bio'] = bio;
    }
    if (avatarUrl != null) {
      updates['avatar_url'] = avatarUrl;
    }

    await _supabase.from(SupabaseConstants.profilesTable).upsert(updates);
  }

  /// Update only the avatar URL
  Future<void> updateAvatar({
    required String userId,
    required String avatarUrl,
  }) async {
    await _supabase
        .from(SupabaseConstants.profilesTable)
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
  }

  /// Get user profile with only essential fields for performance
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    return await _supabase
        .from(SupabaseConstants.profilesTable)
        .select('id, username, bio, avatar_url, created_at')
        .eq('id', userId)
        .maybeSingle();
  }

  /// Get user profile with all fields (use only when needed)
  Future<Map<String, dynamic>?> getProfileFull(String userId) async {
    return await _supabase
        .from(SupabaseConstants.profilesTable)
        .select()
        .eq('id', userId)
        .maybeSingle();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Delete user account via Edge Function
  Future<void> deleteAccount(String userId) async {
    try {
      developer.log(
        '[AUTH-REPO] ========== DELETE ACCOUNT INITIATED ==========',
      );
      developer.log('[AUTH-REPO] User ID to delete: $userId');

      // Get the current session to ensure we have a valid JWT token
      final session = _supabase.auth.currentSession;
      developer.log(
        '[AUTH-REPO] Current session: ${session != null ? "Present" : "MISSING"}',
      );

      if (session == null) {
        developer.log('[AUTH-REPO] ❌ No active session');
        throw Exception('No active session. Please sign in again.');
      }

      developer.log('[AUTH-REPO] Session user ID: ${session.user.id}');
      developer.log(
        '[AUTH-REPO] Access token present: ${session.accessToken.isNotEmpty}',
      );
      developer.log(
        '[AUTH-REPO] Token preview: ${session.accessToken.substring(0, 20)}...',
      );
      developer.log('[AUTH-REPO] Token expires at: ${session.expiresAt}');

      // Method 1: Try with automatic header from Supabase client
      developer.log(
        '[AUTH-REPO] Invoking delete-account Edge Function (Method 1: Auto headers)...',
      );
      try {
        final response = await _supabase.functions.invoke(
          'delete-account',
          body: {'userId': userId},
        );

        developer.log('[AUTH-REPO] Edge Function response received');
        developer.log('[AUTH-REPO] Response status: ${response.status}');
        developer.log('[AUTH-REPO] Response data: ${response.data}');

        // Check if the response is successful
        if (response.status == 200) {
          developer.log(
            '[AUTH-REPO] ✅ Edge Function returned 200 OK (Method 1)',
          );
          developer.log('[AUTH-REPO] Signing out user...');
          await _supabase.auth.signOut();
          developer.log('[AUTH-REPO] ✅ User signed out successfully');
          developer.log(
            '[AUTH-REPO] ========== DELETE ACCOUNT COMPLETED SUCCESSFULLY ==========',
          );
          return;
        } else {
          developer.log(
            '[AUTH-REPO] ⚠️ Method 1 failed with status ${response.status}',
          );
          developer.log(
            '[AUTH-REPO] Method 1 error response data: ${response.data}',
          );
          developer.log(
            '[AUTH-REPO] Trying Method 2 with explicit Bearer token...',
          );
        }
      } catch (e) {
        developer.log('[AUTH-REPO] ⚠️ Method 1 error: $e');
        developer.log(
          '[AUTH-REPO] Trying Method 2 with explicit Bearer token...',
        );
      }

      // Method 2: Try with explicit Bearer token header
      developer.log(
        '[AUTH-REPO] Invoking delete-account Edge Function (Method 2: Explicit Bearer)...',
      );
      final response = await _supabase.functions.invoke(
        'delete-account',
        body: {'userId': userId},
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      developer.log('[AUTH-REPO] Edge Function response received');
      developer.log('[AUTH-REPO] Response status: ${response.status}');
      developer.log('[AUTH-REPO] Response data: ${response.data}');

      // Check if the response is successful
      if (response.status != 200) {
        developer.log('[AUTH-REPO] ❌ Non-200 status code: ${response.status}');
        developer.log(
          '[AUTH-REPO] ❌ Full error response data: ${response.data}',
        );
        throw Exception(
          'Failed to delete account: ${response.data?['message'] ?? 'Unknown error (Status: ${response.status})'}',
        );
      }

      developer.log('[AUTH-REPO] ✅ Edge Function returned 200 OK (Method 2)');
      developer.log('[AUTH-REPO] Signing out user...');

      // Sign out the user after account deletion
      await _supabase.auth.signOut();

      developer.log('[AUTH-REPO] ✅ User signed out successfully');
      developer.log(
        '[AUTH-REPO] ========== DELETE ACCOUNT COMPLETED SUCCESSFULLY ==========',
      );
    } catch (e, stackTrace) {
      developer.log('[AUTH-REPO] ❌ Error in deleteAccount: $e');
      developer.log('[AUTH-REPO] Stack trace: $stackTrace');

      // Extract cleaner error message from FunctionException
      String errorMessage = 'Failed to delete account';
      if (e is FunctionException) {
        final details = e.details as Map<String, dynamic>?;
        final message = details?['message']?.toString();
        if (message != null && message.isNotEmpty) {
          errorMessage = 'Failed to delete account: $message';
        } else {
          errorMessage =
              'Failed to delete account: ${e.reasonPhrase} (Status: ${e.status})';
        }
      } else {
        errorMessage = 'Failed to delete account: $e';
      }

      throw Exception(errorMessage);
    }
  }
}
