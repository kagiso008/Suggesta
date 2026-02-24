class ProfileModel {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;

  ProfileModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'bio': bio,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    String? bio,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
    );
  }

  @override
  String toString() {
    return 'ProfileModel(id: $id, username: $username, avatarUrl: $avatarUrl, bio: $bio)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProfileModel &&
        other.id == id &&
        other.username == username &&
        other.avatarUrl == avatarUrl &&
        other.bio == bio;
  }

  @override
  int get hashCode {
    return id.hashCode ^ username.hashCode ^ avatarUrl.hashCode ^ bio.hashCode;
  }
}
