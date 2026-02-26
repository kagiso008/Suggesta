import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Provider for cached profile data
final profileProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) async {
      // Invalidate cache after 5 minutes
      final cacheTimer = Timer(const Duration(minutes: 5), () {
        ref.invalidateSelf();
      });
      ref.onDispose(() => cacheTimer.cancel());

      final authRepository = ref.watch(authRepositoryProvider);
      return await authRepository.getProfile(userId);
    });

/// Provider for current user's profile (auto-fetches from current user)
final currentProfileProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
      final currentUser = ref.watch(currentUserProvider);
      if (currentUser == null) return null;

      // Use the profileProvider with the current user's ID
      return ref.watch(profileProvider(currentUser.id).future);
    });

/// State notifier for profile operations
class ProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  final AuthRepository _authRepository;

  ProfileNotifier(this._ref, this._authRepository)
    : super(const AsyncValue.data(null));

  /// Refresh profile data for a user
  Future<void> refreshProfile(String userId) async {
    state = const AsyncValue.loading();
    try {
      // Invalidate the profile provider to force refetch
      _ref.invalidate(profileProvider(userId));
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Update profile and refresh cache
  Future<void> updateProfileWithRefresh({
    required String userId,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.updateProfile(
        userId: userId,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      // Invalidate cache to force refetch
      _ref.invalidate(profileProvider(userId));
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<void>>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return ProfileNotifier(ref, authRepository);
    });
