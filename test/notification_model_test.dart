import 'package:flutter_test/flutter_test.dart';
import 'package:suggesta/features/notifications/data/models/notification_model.dart';

void main() {
  group('NotificationModel', () {
    test('should create NotificationModel from JSON', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-id',
        'type': 'comment',
        'title': 'New Comment',
        'body': 'Someone commented on your suggestion',
        'ref_id': 'comment-id',
        'is_read': false,
        'created_at': '2024-01-01T12:00:00Z',
      };

      final notification = NotificationModel.fromJson(json);

      expect(notification.id, 'test-id');
      expect(notification.userId, 'user-id');
      expect(notification.type, NotificationType.comment);
      expect(notification.title, 'New Comment');
      expect(notification.body, 'Someone commented on your suggestion');
      expect(notification.refId, 'comment-id');
      expect(notification.isRead, false);
      expect(notification.createdAt, isA<DateTime>());
    });

    test('should convert NotificationModel to JSON', () {
      final notification = NotificationModel(
        id: 'test-id',
        userId: 'user-id',
        type: NotificationType.message,
        title: 'New Message',
        body: 'You received a new message',
        refId: 'message-id',
        isRead: false,
        createdAt: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final json = notification.toJson();

      expect(json['id'], 'test-id');
      expect(json['user_id'], 'user-id');
      expect(json['type'], 'message');
      expect(json['title'], 'New Message');
      expect(json['body'], 'You received a new message');
      expect(json['ref_id'], 'message-id');
      expect(json['is_read'], false);
      expect(json['created_at'], '2024-01-01T12:00:00.000');
    });

    test('should create copy with updated values', () {
      final original = NotificationModel(
        id: 'test-id',
        userId: 'user-id',
        type: NotificationType.comment,
        title: 'Original Title',
        body: 'Original Body',
        isRead: false,
        createdAt: DateTime(2024, 1, 1),
      );

      final copy = original.copyWith(title: 'Updated Title', isRead: true);

      expect(copy.id, 'test-id');
      expect(copy.userId, 'user-id');
      expect(copy.type, NotificationType.comment);
      expect(copy.title, 'Updated Title');
      expect(copy.body, 'Original Body');
      expect(copy.isRead, true);
      expect(copy.createdAt, DateTime(2024, 1, 1));
    });

    test('should mark as read', () {
      final original = NotificationModel(
        id: 'test-id',
        userId: 'user-id',
        type: NotificationType.comment,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: DateTime(2024, 1, 1),
      );

      final markedAsRead = original.markAsRead();

      expect(markedAsRead.id, 'test-id');
      expect(markedAsRead.isRead, true);
      expect(markedAsRead.title, 'Title');
    });

    test('should compare notifications for equality', () {
      final notification1 = NotificationModel(
        id: 'test-id',
        userId: 'user-id',
        type: NotificationType.comment,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: DateTime(2024, 1, 1),
      );

      final notification2 = NotificationModel(
        id: 'test-id',
        userId: 'user-id',
        type: NotificationType.comment,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: DateTime(2024, 1, 1),
      );

      final notification3 = NotificationModel(
        id: 'different-id',
        userId: 'user-id',
        type: NotificationType.comment,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(notification1, notification2);
      expect(notification1, isNot(notification3));
    });

    test('should get correct icon for notification type', () {
      final commentNotification = NotificationModel(
        id: 'test-1',
        userId: 'user-id',
        type: NotificationType.comment,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final messageNotification = NotificationModel(
        id: 'test-2',
        userId: 'user-id',
        type: NotificationType.message,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final topicVoteNotification = NotificationModel(
        id: 'test-3',
        userId: 'user-id',
        type: NotificationType.topicVote,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final suggestionVoteNotification = NotificationModel(
        id: 'test-4',
        userId: 'user-id',
        type: NotificationType.suggestionVote,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: DateTime.now(),
      );

      final milestoneNotification = NotificationModel(
        id: 'test-5',
        userId: 'user-id',
        type: NotificationType.milestone,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: DateTime.now(),
      );

      expect(commentNotification.icon, '💬');
      expect(messageNotification.icon, '✉️');
      expect(topicVoteNotification.icon, '👍');
      expect(suggestionVoteNotification.icon, '💡');
      expect(milestoneNotification.icon, '🏆');
    });

    test('should format time ago correctly', () {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      final oneDayAgo = now.subtract(const Duration(days: 1));
      final oneWeekAgo = now.subtract(const Duration(days: 7));

      final notification1 = NotificationModel(
        id: 'test-1',
        userId: 'user-id',
        type: NotificationType.comment,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: oneHourAgo,
      );

      final notification2 = NotificationModel(
        id: 'test-2',
        userId: 'user-id',
        type: NotificationType.comment,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: oneDayAgo,
      );

      final notification3 = NotificationModel(
        id: 'test-3',
        userId: 'user-id',
        type: NotificationType.comment,
        title: 'Title',
        body: 'Body',
        isRead: false,
        createdAt: oneWeekAgo,
      );

      // Note: timeAgo uses relative time formatting
      // We can't test exact strings as they depend on current time
      expect(notification1.timeAgo, isNotEmpty);
      expect(notification2.timeAgo, isNotEmpty);
      expect(notification3.timeAgo, isNotEmpty);
    });
  });

  group('NotificationType', () {
    test('should parse string to NotificationType', () {
      expect(NotificationType.fromString('comment'), NotificationType.comment);
      expect(NotificationType.fromString('message'), NotificationType.message);
      expect(
        NotificationType.fromString('topic_vote'),
        NotificationType.topicVote,
      );
      expect(
        NotificationType.fromString('suggestion_vote'),
        NotificationType.suggestionVote,
      );
      expect(
        NotificationType.fromString('milestone'),
        NotificationType.milestone,
      );
      expect(
        () => NotificationType.fromString('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should convert NotificationType to string', () {
      expect(NotificationType.comment.toString(), 'comment');
      expect(NotificationType.message.toString(), 'message');
      expect(NotificationType.topicVote.toString(), 'topic_vote');
      expect(NotificationType.suggestionVote.toString(), 'suggestion_vote');
      expect(NotificationType.milestone.toString(), 'milestone');
    });
  });
}
