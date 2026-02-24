import 'profile_model.dart';

class SuggestionModel {
  final String id;
  final String topicId;
  final String userId;
  final String content;
  final String? imageUrl;
  final int voteCount;
  final DateTime createdAt;
  final ProfileModel? author; // joined from profiles

  SuggestionModel({
    required this.id,
    required this.topicId,
    required this.userId,
    required this.content,
    this.imageUrl,
    required this.voteCount,
    required this.createdAt,
    this.author,
  });

  factory SuggestionModel.fromJson(Map<String, dynamic> json) {
    return SuggestionModel(
      id: json['id'] as String,
      topicId: json['topic_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      voteCount: (json['vote_count'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['profiles'] != null
          ? ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topic_id': topicId,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'vote_count': voteCount,
      'created_at': createdAt.toIso8601String(),
      'profiles': author?.toJson(),
    };
  }

  SuggestionModel copyWith({
    String? id,
    String? topicId,
    String? userId,
    String? content,
    String? imageUrl,
    int? voteCount,
    DateTime? createdAt,
    ProfileModel? author,
  }) {
    return SuggestionModel(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      voteCount: voteCount ?? this.voteCount,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
    );
  }

  @override
  String toString() {
    return 'SuggestionModel(id: $id, topicId: $topicId, userId: $userId, content: $content, voteCount: $voteCount, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SuggestionModel &&
        other.id == id &&
        other.topicId == topicId &&
        other.userId == userId &&
        other.content == content &&
        other.imageUrl == imageUrl &&
        other.voteCount == voteCount &&
        other.createdAt == createdAt &&
        other.author == author;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        topicId.hashCode ^
        userId.hashCode ^
        content.hashCode ^
        imageUrl.hashCode ^
        voteCount.hashCode ^
        createdAt.hashCode ^
        author.hashCode;
  }
}
