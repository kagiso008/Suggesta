import '../../../shared/models/profile_model.dart';

class TopicModel {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? category;
  final List<String> tags;
  final int viewCount;
  final int voteCount;
  final int suggestionCount;
  final String? milestoneBadge; // 'rising' | 'hot' | 'viral' | null
  final DateTime createdAt;
  final ProfileModel? author; // joined from profiles

  TopicModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.category,
    required this.tags,
    required this.viewCount,
    required this.voteCount,
    required this.suggestionCount,
    this.milestoneBadge,
    required this.createdAt,
    this.author,
  });

  factory TopicModel.fromJson(Map<String, dynamic> json) {
    return TopicModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      viewCount: (json['view_count'] as num).toInt(),
      voteCount: (json['vote_count'] as num).toInt(),
      suggestionCount: (json['suggestion_count'] as num?)?.toInt() ?? 0,
      milestoneBadge: json['milestone_badge'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      author: json['profiles'] != null
          ? ProfileModel.fromJson(json['profiles'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'view_count': viewCount,
      'vote_count': voteCount,
      'suggestion_count': suggestionCount,
      'milestone_badge': milestoneBadge,
      'created_at': createdAt.toIso8601String(),
      'profiles': author?.toJson(),
    };
  }

  TopicModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    int? viewCount,
    int? voteCount,
    int? suggestionCount,
    String? milestoneBadge,
    DateTime? createdAt,
    ProfileModel? author,
  }) {
    return TopicModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      viewCount: viewCount ?? this.viewCount,
      voteCount: voteCount ?? this.voteCount,
      suggestionCount: suggestionCount ?? this.suggestionCount,
      milestoneBadge: milestoneBadge ?? this.milestoneBadge,
      createdAt: createdAt ?? this.createdAt,
      author: author ?? this.author,
    );
  }

  @override
  String toString() {
    return 'TopicModel(id: $id, title: $title, voteCount: $voteCount, suggestionCount: $suggestionCount, milestoneBadge: $milestoneBadge)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TopicModel &&
        other.id == id &&
        other.userId == userId &&
        other.title == title &&
        other.description == description &&
        other.category == category &&
        other.tags == tags &&
        other.viewCount == viewCount &&
        other.voteCount == voteCount &&
        other.suggestionCount == suggestionCount &&
        other.milestoneBadge == milestoneBadge &&
        other.createdAt == createdAt &&
        other.author == author;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        title.hashCode ^
        description.hashCode ^
        category.hashCode ^
        tags.hashCode ^
        viewCount.hashCode ^
        voteCount.hashCode ^
        suggestionCount.hashCode ^
        milestoneBadge.hashCode ^
        createdAt.hashCode ^
        author.hashCode;
  }
}
