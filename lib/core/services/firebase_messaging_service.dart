import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/supabase_constants.dart';
import '../../features/notifications/data/notification_repository.dart';
import '../../features/notifications/presentation/providers/notification_provider.dart';

class FirebaseMessagingService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final NotificationRepository _notificationRepository;
  StreamSubscription<String>? _tokenRefreshSubscription;

  FirebaseMessagingService({
    required NotificationRepository notificationRepository,
  }) : _notificationRepository = notificationRepository;

  // Initialize Firebase Messaging
  Future<void> initialize() async {
    try {
      // Request notification permissions
      await _requestPermissions();

      // Configure message handlers
      await _configureMessageHandlers();

      // Get and store FCM token
      await _getAndStoreFCMToken();

      // Listen for token refresh
      _tokenRefreshSubscription = _firebaseMessaging.onTokenRefresh.listen(
        _storeFCMToken,
      );

      if (kDebugMode) {
        print('Firebase Messaging initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize Firebase Messaging: $e');
      }
    }
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print(
          'Notification permission status: ${settings.authorizationStatus}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to request notification permissions: $e');
      }
    }
  }

  // Configure message handlers
  Future<void> _configureMessageHandlers() async {
    // Handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when the app is in the background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

    // Handle notification when app is terminated (cold start)
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Foreground message received: ${message.notification?.title}');
    }

    // Show local notification
    _showLocalNotification(message);

    // Update notification count
    _updateNotificationCount();
  }

  // Handle background/opened messages
  void _handleBackgroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('Background message received: ${message.notification?.title}');
    }

    // Navigate to appropriate screen based on message data
    _handleMessageNavigation(message);
  }

  // Get and store FCM token
  Future<void> _getAndStoreFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          print('FCM token retrieved: $token');
        }
        await _storeFCMToken(token);
      } else {
        if (kDebugMode) {
          print('FCM token is null');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get FCM token: $e');
      }
    }
  }

  // Store FCM token in Supabase
  Future<void> _storeFCMToken(String token) async {
    try {
      await _notificationRepository.storeFCMToken(token);
      if (kDebugMode) {
        print('FCM token stored successfully: $token');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to store FCM token: $e');
      }
    }
  }

  // Show local notification using flutter_local_notifications
  void _showLocalNotification(RemoteMessage message) {
    // This would integrate with flutter_local_notifications package
    // For now, we'll just log it
    if (kDebugMode) {
      print('Should show local notification: ${message.notification?.title}');
      print('Notification body: ${message.notification?.body}');
      print('Notification data: ${message.data}');
    }

    // TODO: Integrate with flutter_local_notifications
    // final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    // flutterLocalNotificationsPlugin.show(...);
  }

  // Update notification count in provider
  void _updateNotificationCount() {
    // This would typically be handled by the notification provider
    // For now, we'll just log it
    if (kDebugMode) {
      print('Notification count should be updated');
    }
  }

  // Handle message navigation
  void _handleMessageNavigation(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    if (kDebugMode) {
      print('Handling message navigation with data: $data');
    }

    // Extract navigation parameters from message data
    final type = data['type'];
    final refId = data['ref_id'];

    // TODO: Implement navigation logic based on notification type
    // This would typically use a navigation service or provider
    switch (type) {
      case 'topic_vote':
        // Navigate to topic detail
        break;
      case 'suggestion_vote':
        // Navigate to suggestion detail
        break;
      case 'comment':
        // Navigate to comment thread
        break;
      case 'message':
        // Navigate to chat
        break;
      case 'milestone':
        // Navigate to profile or achievement screen
        break;
      default:
        // Navigate to notifications screen
        break;
    }
  }

  // Get current FCM token
  Future<String?> getCurrentToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get current FCM token: $e');
      }
      return null;
    }
  }

  // Delete FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      await _notificationRepository.removeFCMToken();
      if (kDebugMode) {
        print('FCM token deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete FCM token: $e');
      }
    }
  }

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to subscribe to topic $topic: $e');
      }
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to unsubscribe from topic $topic: $e');
      }
    }
  }

  // Get APNs token (iOS only)
  Future<String?> getAPNsToken() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }

    try {
      return await _firebaseMessaging.getAPNSToken();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get APNs token: $e');
      }
      return null;
    }
  }

  // Clean up resources
  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}

// Provider for FirebaseMessagingService
final firebaseMessagingServiceProvider = Provider<FirebaseMessagingService>((
  ref,
) {
  final notificationRepository = ref.read(notificationRepositoryProvider);
  return FirebaseMessagingService(
    notificationRepository: notificationRepository,
  );
});

// Provider to initialize Firebase Messaging
final initializeFirebaseMessagingProvider = FutureProvider<void>((ref) async {
  final service = ref.read(firebaseMessagingServiceProvider);
  await service.initialize();
});

// Helper function to send test notification
Future<void> sendTestNotification({
  required String userId,
  required String title,
  required String body,
  String type = 'test',
  String? refId,
}) async {
  // This would typically call a Supabase edge function
  // For now, we'll just log it
  if (kDebugMode) {
    print('Test notification would be sent:');
    print('  User ID: $userId');
    print('  Title: $title');
    print('  Body: $body');
    print('  Type: $type');
    print('  Ref ID: $refId');
  }

  // TODO: Implement actual notification sending via Supabase edge function
  // await supabase.functions.invoke('send-push-notification', body: {
  //   'userId': userId,
  //   'title': title,
  //   'body': body,
  //   'type': type,
  //   'refId': refId,
  // });
}
