import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../providers/notification_provider.dart';
import '../../data/models/notification_model.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => _markAllAsRead(ref),
            tooltip: 'Mark all as read',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteAllNotifications(ref, context),
            tooltip: 'Delete all notifications',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshNotifications(ref),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: notifications.when(
        data: (items) => _buildNotificationsList(items, ref),
        loading: () => _buildLoadingState(),
        error: (error, stackTrace) => _buildErrorState(error, ref),
      ),
    );
  }

  Widget _buildNotificationsList(
    List<NotificationModel> notifications,
    WidgetRef ref,
  ) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _refreshNotifications(ref),
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationItem(notification, context, ref);
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    NotificationModel notification,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) => _deleteNotification(notification.id, ref),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              notification.icon,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead
                      ? FontWeight.normal
                      : FontWeight.bold,
                ),
              ),
            ),
            if (!notification.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              notification.timeAgo,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            notification.isRead
                ? Icons.mark_email_read
                : Icons.mark_email_unread,
            color: notification.isRead ? Colors.grey : Colors.blue,
          ),
          onPressed: () => _markAsRead(notification.id, ref),
          tooltip: notification.isRead ? 'Mark as unread' : 'Mark as read',
        ),
        onTap: () => _handleNotificationTap(notification, context, ref),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading notifications...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Failed to load notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _refreshNotifications(ref),
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No notifications yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'When you get notifications, they\'ll appear here',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.topicVote:
        return Colors.green.withOpacity(0.2);
      case NotificationType.suggestionVote:
        return Colors.blue.withOpacity(0.2);
      case NotificationType.comment:
        return Colors.orange.withOpacity(0.2);
      case NotificationType.message:
        return Colors.purple.withOpacity(0.2);
      case NotificationType.milestone:
        return Colors.yellow.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Future<void> _refreshNotifications(WidgetRef ref) async {
    final notifier = ref.read(notificationsProvider.notifier);
    await notifier.refresh();
  }

  Future<void> _markAsRead(String notificationId, WidgetRef ref) async {
    final notifier = ref.read(notificationsProvider.notifier);
    await notifier.markAsRead(notificationId);
  }

  Future<void> _markAllAsRead(WidgetRef ref) async {
    final notifier = ref.read(notificationsProvider.notifier);
    await notifier.markAllAsRead();
  }

  Future<void> _deleteNotification(String notificationId, WidgetRef ref) async {
    final notifier = ref.read(notificationsProvider.notifier);
    await notifier.deleteNotification(notificationId);
  }

  Future<void> _deleteAllNotifications(
    WidgetRef ref,
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Notifications'),
        content: const Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final notifier = ref.read(notificationsProvider.notifier);
      await notifier.deleteAllNotifications();
    }
  }

  void _handleNotificationTap(
    NotificationModel notification,
    BuildContext context,
    WidgetRef ref,
  ) {
    // Mark as read when tapped
    _markAsRead(notification.id, ref);

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.topicVote:
        // Navigate to topic
        if (notification.refId != null) {
          // context.go('/topic/${notification.refId}');
        }
        break;
      case NotificationType.suggestionVote:
        // Navigate to suggestion
        if (notification.refId != null) {
          // context.go('/suggestion/${notification.refId}');
        }
        break;
      case NotificationType.comment:
        // Navigate to comment thread
        if (notification.refId != null) {
          // context.go('/comment/${notification.refId}');
        }
        break;
      case NotificationType.message:
        // Navigate to chat
        if (notification.refId != null) {
          // context.go('/chat/${notification.refId}');
        }
        break;
      case NotificationType.milestone:
        // Navigate to profile or achievements
        // context.go('/profile/achievements');
        break;
    }

    // Show a snackbar for demo purposes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to ${notification.type}...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// Helper widget to show notification badge in app bar
class NotificationBadge extends ConsumerWidget {
  const NotificationBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    if (unreadCount == 0) {
      return IconButton(
        icon: const Icon(Icons.notifications_none),
        onPressed: () => _navigateToNotifications(context),
      );
    }

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () => _navigateToNotifications(context),
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  void _navigateToNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
    );
  }
}
