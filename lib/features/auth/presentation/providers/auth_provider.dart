import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/auth_repository.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return AuthRepository(supabase: supabase);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

final currentSessionProvider = Provider<Session?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.currentSession;
});

final currentUserProvider = Provider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.currentUser;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id;
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;
  final AuthRepository _authRepository;

  AuthNotifier(this.ref, this._authRepository)
    : super(const AsyncValue.data(null));

  /// Sign up with email and password
  Future<void> signUp({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signUp(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signIn(email: email, password: password);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      return await _authRepository.isUsernameAvailable(username);
    } catch (error) {
      return false;
    }
  }

  /// Update user profile
  Future<void> updateProfile({String? username, String? bio}) async {
    state = const AsyncValue.loading();
    try {
      // Get the current user - may need to refresh the session
      final currentUser = _authRepository.currentUser;

      if (currentUser == null) {
        // Try to get the user from the Supabase client directly
        final supabaseUser = Supabase.instance.client.auth.currentUser;
        if (supabaseUser == null) {
          throw Exception('No user logged in');
        }

        await _authRepository.updateProfile(
          userId: supabaseUser.id,
          username: username,
          bio: bio,
        );
      } else {
        await _authRepository.updateProfile(
          userId: currentUser.id,
          username: username,
          bio: bio,
        );
      }

      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.resetPassword(email);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.updatePassword(newPassword);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteAccount(String userId) async {
    developer.log(
      '[AUTH-PROVIDER] ========== DELETE ACCOUNT INITIATED ==========',
    );
    developer.log('[AUTH-PROVIDER] User ID to delete: $userId');

    state = const AsyncValue.loading();
    try {
      await _authRepository.deleteAccount(userId);
      state = const AsyncValue.data(null);
      developer.log('[AUTH-PROVIDER] ✅ Delete account completed successfully');
    } catch (error, stackTrace) {
      developer.log('[AUTH-PROVIDER] ❌ Error in deleteAccount: $error');
      developer.log('[AUTH-PROVIDER] Stack trace: $stackTrace');
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return AuthNotifier(ref, authRepository);
    });
