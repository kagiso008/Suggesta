class SupabaseConstants {
  // These values will be set from main.dart after loading .env
  static String supabaseUrl = '';
  static String supabaseAnonKey = '';
  static String supabaseServiceRoleKey = '';

  // Table names
  static const String profilesTable = 'profiles';
  static const String topicsTable = 'topics';
  static const String topicVotesTable = 'topic_votes';
  static const String topicFollowsTable = 'topic_follows';
  static const String suggestionsTable = 'suggestions';
  static const String suggestionVotesTable = 'suggestion_votes';
  static const String commentsTable = 'comments';
  static const String conversationsTable = 'conversations';
  static const String messagesTable = 'messages';
  static const String notificationsTable = 'notifications';
  static const String trendingView = 'trending_topics';

  // Realtime channel names
  static const String topicsChannel = 'topics';
  static const String suggestionsChannel = 'suggestions';
  static const String commentsChannel = 'comments';
  static const String messagesChannel = 'messages';
  static const String notificationsChannel = 'notifications';

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String suggestionImagesBucket = 'suggestion-images';
}
