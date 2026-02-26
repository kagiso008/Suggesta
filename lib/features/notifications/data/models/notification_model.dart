enum NotificationType {
  topicVote('topic_vote'),
  suggestionVote('suggestion_vote'),
  comment('comment'),
  message('message'),
  milestone('milestone');

  final String value;
  const NotificationType(this.value);

  factory NotificationType.fromString(String value) {
    switch (value) {
      case 'topic_vote':
        return NotificationType.topicVote;
      case 'suggestion_vote':
        return NotificationType.suggestionVote;
      case 'comment':
        return NotificationType.comment;
      case 'message':
        return NotificationType.message;
      case 'milestone':
        return NotificationType.milestone;
      default:
        throw ArgumentError('Unknown notification type: $value');
    }
  }

  @override
  String toString() => value;
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final bool isRead;
  final String? refId;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.refId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: NotificationType.fromString(json['type'] as String),
      title: json['title'] as String,
      body: json['body'] as String,
      isRead: json['is_read'] as bool,
      refId: json['ref_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'is_read': isRead,
      'ref_id': refId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? body,
    bool? isRead,
    String? refId,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      isRead: isRead ?? this.isRead,
      refId: refId ?? this.refId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  NotificationModel markAsRead() {
    return copyWith(isRead: true);
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  String get icon {
    switch (type) {
      case NotificationType.topicVote:
        return '👍';
      case NotificationType.suggestionVote:
        return '💡';
      case NotificationType.comment:
        return '💬';
      case NotificationType.message:
        return '✉️';
      case NotificationType.milestone:
        return '🏆';
      default:
        return '🔔';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NotificationModel &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.title == title &&
        other.body == body &&
        other.isRead == isRead &&
        other.refId == refId &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        type.hashCode ^
        title.hashCode ^
        body.hashCode ^
        isRead.hashCode ^
        refId.hashCode ^
        createdAt.hashCode;
  }

  @override
  String toString() {
    return 'NotificationModel(id: $id, userId: $userId, type: $type, title: $title, isRead: $isRead, createdAt: $createdAt)';
  }
}
