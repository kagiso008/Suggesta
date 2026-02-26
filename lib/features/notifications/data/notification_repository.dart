import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import './models/notification_model.dart';

class NotificationRepository {
  final SupabaseClient _supabase;

  NotificationRepository({required SupabaseClient supabase})
    : _supabase = supabase;

  // Fetch notifications for current user with pagination
  Future<List<NotificationModel>> getNotifications({
    int from = 0,
    int to = 19,
    bool unreadOnly = false,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to fetch notifications');
      }

      var query = _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(from, to);

      if (unreadOnly) {
        query = _supabase
            .from('notifications')
            .select()
            .eq('user_id', user.id)
            .eq('is_read', false)
            .order('created_at', ascending: false)
            .range(from, to);
      }

      final response = await query;

      final List<NotificationModel> notifications = [];
      for (final item in response) {
        notifications.add(NotificationModel.fromJson(item));
      }

      return notifications;
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  // Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      print('Failed to get unread count: $e');
      return 0;
    }
  }

  // Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception(
          'User must be authenticated to mark notifications as read',
        );
      }

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception(
          'User must be authenticated to mark notifications as read',
        );
      }

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to delete notifications');
      }

      await _supabase
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to delete notifications');
      }

      await _supabase.from('notifications').delete().eq('user_id', user.id);
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Create a notification (for testing or manual creation)
  Future<NotificationModel> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? refId,
  }) async {
    try {
      final response = await _supabase
          .from('notifications')
          .insert({
            'user_id': userId,
            'type': type.value,
            'title': title,
            'body': body,
            'ref_id': refId,
            'is_read': false,
          })
          .select()
          .single();

      return NotificationModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Real-time stream for notifications
  Stream<List<NotificationModel>> watchNotifications() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .asyncMap((data) {
          final notifications = <NotificationModel>[];
          for (final item in data) {
            notifications.add(NotificationModel.fromJson(item));
          }
          return notifications;
        });
  }

  // Real-time stream for unread count
  Stream<int> watchUnreadCount() {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return Stream.value(0);
    }

    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .asyncMap((data) {
          // Filter unread notifications
          final unreadData = data
              .where((item) => item['is_read'] == false)
              .toList();
          return unreadData.length;
        });
  }

  // Store FCM token in user profile
  Future<void> storeFCMToken(String fcmToken) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to store FCM token');
      }

      await _supabase
          .from('profiles')
          .update({'fcm_token': fcmToken})
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to store FCM token: $e');
    }
  }

  // Get FCM token from user profile
  Future<String?> getFCMToken(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('fcm_token')
          .eq('id', userId)
          .single();

      return response['fcm_token'] as String?;
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  // Remove FCM token from user profile
  Future<void> removeFCMToken() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to remove FCM token');
      }

      await _supabase
          .from('profiles')
          .update({'fcm_token': null})
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to remove FCM token: $e');
    }
  }
}
