import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/notification_repository.dart';
import '../../data/models/notification_model.dart';

// Repository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final supabase = Supabase.instance.client;
  return NotificationRepository(supabase: supabase);
});

// Notifications list provider
class NotificationsNotifier extends AsyncNotifier<List<NotificationModel>> {
  StreamSubscription<List<NotificationModel>>? _subscription;

  @override
  Future<List<NotificationModel>> build() async {
    final repository = ref.read(notificationRepositoryProvider);

    // Start real-time subscription
    _subscription?.cancel();
    _subscription = repository.watchNotifications().listen((notifications) {
      state = AsyncValue.data(notifications);
    });

    // Load initial data
    try {
      return await repository.getNotifications();
    } catch (e) {
      // Return empty list if user is not authenticated
      return [];
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(notificationRepositoryProvider);
      final notifications = await repository.getNotifications();
      state = AsyncValue.data(notifications);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! AsyncData) return;

    final currentNotifications = currentState.value;
    if (currentNotifications == null) return;

    try {
      final repository = ref.read(notificationRepositoryProvider);
      final moreNotifications = await repository.getNotifications(
        from: currentNotifications.length,
        to: currentNotifications.length + 19,
      );

      final updatedNotifications = [
        ...currentNotifications,
        ...moreNotifications,
      ];
      state = AsyncValue.data(updatedNotifications);
    } catch (e) {
      // Don't update state on error for loadMore - keep existing data
      print('Failed to load more notifications: $e');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final currentState = state;
    if (currentState is! AsyncData) return;

    final currentNotifications = currentState.value;
    if (currentNotifications == null) return;

    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.markAsRead(notificationId);

      // Update local state
      final updatedNotifications = currentNotifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.markAsRead();
        }
        return notification;
      }).toList();

      state = AsyncValue.data(updatedNotifications);
    } catch (e) {
      print('Failed to mark notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is! AsyncData) return;

    final currentNotifications = currentState.value;
    if (currentNotifications == null) return;

    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.markAllAsRead();

      // Update local state
      final updatedNotifications = currentNotifications
          .map((notification) => notification.markAsRead())
          .toList();

      state = AsyncValue.data(updatedNotifications);
    } catch (e) {
      print('Failed to mark all notifications as read: $e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    final currentState = state;
    if (currentState is! AsyncData) return;

    final currentNotifications = currentState.value;
    if (currentNotifications == null) return;

    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.deleteNotification(notificationId);

      // Update local state
      final updatedNotifications = currentNotifications
          .where((notification) => notification.id != notificationId)
          .toList();

      state = AsyncValue.data(updatedNotifications);
    } catch (e) {
      print('Failed to delete notification: $e');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.deleteAllNotifications();
      state = const AsyncValue.data([]);
    } catch (e) {
      print('Failed to delete all notifications: $e');
    }
  }
}

final notificationsProvider =
    AsyncNotifierProvider<NotificationsNotifier, List<NotificationModel>>(
      NotificationsNotifier.new,
    );

// Unread count provider
class UnreadCountNotifier extends Notifier<int> {
  StreamSubscription<int>? _subscription;

  @override
  int build() {
    final repository = ref.read(notificationRepositoryProvider);

    // Start real-time subscription
    _subscription?.cancel();
    _subscription = repository.watchUnreadCount().listen((count) {
      state = count;
    });

    // Load initial count
    _loadInitialCount();

    return 0;
  }

  Future<void> _loadInitialCount() async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      final count = await repository.getUnreadCount();
      state = count;
    } catch (e) {
      // If user is not authenticated, count is 0
      state = 0;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
  }

  Future<void> refresh() async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      final count = await repository.getUnreadCount();
      state = count;
    } catch (e) {
      state = 0;
    }
  }

  void increment() {
    state = state + 1;
  }

  void decrement() {
    if (state > 0) {
      state = state - 1;
    }
  }

  void reset() {
    state = 0;
  }
}

final unreadCountProvider = NotifierProvider<UnreadCountNotifier, int>(
  UnreadCountNotifier.new,
);

// FCM token provider
class FCMTokenNotifier extends Notifier<String?> {
  @override
  String? build() {
    // Initial state is null - token will be set when available
    return null;
  }

  Future<void> storeToken(String token) async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.storeFCMToken(token);
      state = token;
    } catch (e) {
      print('Failed to store FCM token: $e');
    }
  }

  Future<void> removeToken() async {
    try {
      final repository = ref.read(notificationRepositoryProvider);
      await repository.removeFCMToken();
      state = null;
    } catch (e) {
      print('Failed to remove FCM token: $e');
    }
  }
}

final fcmTokenProvider = NotifierProvider<FCMTokenNotifier, String?>(
  FCMTokenNotifier.new,
);

// Helper provider to check if user has notifications
final hasNotificationsProvider = Provider<bool>((ref) {
  final notifications = ref.watch(notificationsProvider);
  return notifications.maybeWhen(
    data: (items) => items.isNotEmpty,
    orElse: () => false,
  );
});

// Helper provider to check if user has unread notifications
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final unreadCount = ref.watch(unreadCountProvider);
  return unreadCount > 0;
});
