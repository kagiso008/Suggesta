import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/topic_model.dart';
import '../../../shared/models/suggestion_model.dart';

class TopicsRepository {
  // Delete a topic by id
  Future<void> deleteTopic(String topicId) async {
    try {
      await _supabase.from('topics').delete().eq('id', topicId);
    } catch (e) {
      throw Exception('Failed to delete topic: $e');
    }
  }

  final SupabaseClient _supabase;

  TopicsRepository({required SupabaseClient supabase}) : _supabase = supabase;

  // Fetch paginated topics for home feed, joined with author profile
  Future<List<TopicModel>> fetchTopics({int from = 0, int to = 19}) async {
    try {
      final response = await _supabase
          .from('topics')
          .select('*, profiles!topics_user_id_fkey(*)')
          .order('created_at', ascending: false)
          .range(from, to);

      final List<TopicModel> topics = [];
      for (final item in response) {
        topics.add(TopicModel.fromJson(item));
      }

      // Fetch suggestion counts for all topics
      if (topics.isNotEmpty) {
        final topicIds = topics.map((t) => t.id).toList();
        final suggestionCounts = await _fetchSuggestionCounts(topicIds);

        // Update topics with suggestion counts
        for (final topic in topics) {
          final count = suggestionCounts[topic.id] ?? 0;
          // Create a new topic with the correct suggestion count
          final index = topics.indexOf(topic);
          topics[index] = topic.copyWith(suggestionCount: count);
        }
      }

      return topics;
    } catch (e) {
      throw Exception('Failed to fetch topics: $e');
    }
  }

  // Fetch suggestion counts for a list of topic IDs
  Future<Map<String, int>> _fetchSuggestionCounts(List<String> topicIds) async {
    try {
      // We'll fetch all suggestions for these topics and count manually
      // This is inefficient but works for now
      final response = await _supabase
          .from('suggestions')
          .select('topic_id')
          .inFilter('topic_id', topicIds);

      final Map<String, int> counts = {};
      for (final item in response) {
        final topicId = item['topic_id'] as String;
        counts[topicId] = (counts[topicId] ?? 0) + 1;
      }
      return counts;
    } catch (e) {
      // If we can't fetch counts, return empty map
      print('Failed to fetch suggestion counts: $e');
      return {};
    }
  }

  // Fetch a single topic by id with author profile
  Future<TopicModel> fetchTopic(String topicId) async {
    try {
      final response = await _supabase
          .from('topics')
          .select('*, profiles!topics_user_id_fkey(*)')
          .eq('id', topicId)
          .single();

      final topic = TopicModel.fromJson(response);

      // Fetch suggestion count for this topic
      final suggestionCounts = await _fetchSuggestionCounts([topicId]);
      final count = suggestionCounts[topicId] ?? 0;

      return topic.copyWith(suggestionCount: count);
    } catch (e) {
      throw Exception('Failed to fetch topic: $e');
    }
  }

  // Create a new topic — insert into topics table
  Future<TopicModel> createTopic({
    required String title,
    String? description,
    String? category,
    List<String> tags = const [],
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create a topic');
      }

      final response = await _supabase
          .from('topics')
          .insert({
            'user_id': user.id,
            'title': title,
            'description': description,
            'category': category,
            'tags': tags,
          })
          .select('*, profiles!topics_user_id_fkey(*)')
          .single();

      return TopicModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create topic: $e');
    }
  }

  // Fetch suggestions for a topic sorted by vote_count DESC, created_at ASC
  Future<List<SuggestionModel>> fetchSuggestions(String topicId) async {
    try {
      final response = await _supabase
          .from('suggestions')
          .select('*, profiles!suggestions_user_id_fkey(*)')
          .eq('topic_id', topicId)
          .order('vote_count', ascending: false)
          .order('created_at', ascending: true);

      final List<SuggestionModel> suggestions = [];
      for (final item in response) {
        suggestions.add(SuggestionModel.fromJson(item));
      }
      return suggestions;
    } catch (e) {
      throw Exception('Failed to fetch suggestions: $e');
    }
  }

  // Add a suggestion to a topic
  Future<SuggestionModel> addSuggestion({
    required String topicId,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to add a suggestion');
      }

      final response = await _supabase
          .from('suggestions')
          .insert({
            'topic_id': topicId,
            'user_id': user.id,
            'content': content,
            'image_url': imageUrl,
          })
          .select('*, profiles!suggestions_user_id_fkey(*)')
          .single();

      return SuggestionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add suggestion: $e');
    }
  }

  // Check if current user has voted on a suggestion and get vote type
  Future<int?> getSuggestionVote(String suggestionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('suggestion_votes')
          .select('vote_type')
          .eq('user_id', user.id)
          .eq('suggestion_id', suggestionId)
          .maybeSingle();

      return response != null ? response['vote_type'] as int : null;
    } catch (e) {
      throw Exception('Failed to get suggestion vote: $e');
    }
  }

  // Upvote a suggestion
  Future<void> upvoteSuggestion(String suggestionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to vote');
      }

      // Upsert with vote_type = 1 (upvote)
      await _supabase.from('suggestion_votes').upsert({
        'user_id': user.id,
        'suggestion_id': suggestionId,
        'vote_type': 1,
      }, onConflict: 'user_id,suggestion_id');
    } catch (e) {
      throw Exception('Failed to upvote suggestion: $e');
    }
  }

  // Downvote a suggestion
  Future<void> downvoteSuggestion(String suggestionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to vote');
      }

      // Upsert with vote_type = -1 (downvote)
      await _supabase.from('suggestion_votes').upsert({
        'user_id': user.id,
        'suggestion_id': suggestionId,
        'vote_type': -1,
      }, onConflict: 'user_id,suggestion_id');
    } catch (e) {
      throw Exception('Failed to downvote suggestion: $e');
    }
  }

  // Remove vote from a suggestion
  Future<void> removeSuggestionVote(String suggestionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to vote');
      }

      await _supabase
          .from('suggestion_votes')
          .delete()
          .eq('user_id', user.id)
          .eq('suggestion_id', suggestionId);
    } catch (e) {
      throw Exception('Failed to remove suggestion vote: $e');
    }
  }

  // Toggle suggestion vote — kept for backward compatibility (upvote/remove)
  Future<bool> toggleSuggestionVote(String suggestionId) async {
    try {
      final currentVote = await getSuggestionVote(suggestionId);
      if (currentVote == null) {
        await upvoteSuggestion(suggestionId);
        return true;
      } else {
        await removeSuggestionVote(suggestionId);
        return false;
      }
    } catch (e) {
      throw Exception('Failed to toggle suggestion vote: $e');
    }
  }

  // Realtime stream for suggestions on a topic
  Stream<List<Map<String, dynamic>>> watchSuggestions(String topicId) {
    return _supabase
        .from('suggestions')
        .stream(primaryKey: ['id'])
        .eq('topic_id', topicId);
  }

  // Realtime stream for a single topic's vote_count
  Stream<List<Map<String, dynamic>>> watchTopic(String topicId) {
    return _supabase
        .from('topics')
        .stream(primaryKey: ['id'])
        .eq('id', topicId);
  }

  // Check if current user has bookmarked a topic
  Future<bool> isBookmarked(String topicId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('topic_bookmarks')
          .select('user_id')
          .eq('user_id', user.id)
          .eq('topic_id', topicId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check bookmark status: $e');
    }
  }

  // Toggle bookmark — insert if not bookmarked, delete if already bookmarked
  Future<bool> toggleBookmark(String topicId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to bookmark topics');
      }

      final isBookmarked = await this.isBookmarked(topicId);

      if (!isBookmarked) {
        // Insert bookmark
        await _supabase.from('topic_bookmarks').insert({
          'user_id': user.id,
          'topic_id': topicId,
        });
        return true; // Now bookmarked
      } else {
        // Delete bookmark
        await _supabase
            .from('topic_bookmarks')
            .delete()
            .eq('user_id', user.id)
            .eq('topic_id', topicId);
        return false; // Bookmark removed
      }
    } catch (e) {
      throw Exception('Failed to toggle bookmark: $e');
    }
  }

  // Fetch topics by user ID
  Future<List<TopicModel>> fetchTopicsByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('topics')
          .select('*, profiles!topics_user_id_fkey(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (response.isEmpty) return [];

      final List<TopicModel> topics = [];
      for (final item in response) {
        topics.add(TopicModel.fromJson(item));
      }

      // Fetch suggestion counts for all topics
      if (topics.isNotEmpty) {
        final topicIds = topics.map((t) => t.id).toList();
        final suggestionCounts = await _fetchSuggestionCounts(topicIds);
        for (final topic in topics) {
          final count = suggestionCounts[topic.id] ?? 0;
          final index = topics.indexOf(topic);
          topics[index] = topic.copyWith(suggestionCount: count);
        }
      }

      return topics;
    } catch (e) {
      throw Exception('Failed to fetch topics by user ID: $e');
    }
  }

  // Fetch all bookmarked topics for current user
  Future<List<TopicModel>> fetchBookmarkedTopics() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to fetch bookmarks');
      }

      final response = await _supabase
          .from('topic_bookmarks')
          .select('topic_id')
          .eq('user_id', user.id);

      if (response.isEmpty) return [];

      final topicIds = response
          .map((item) => item['topic_id'] as String)
          .toList();

      // Fetch topics with their author profiles
      final topicsResponse = await _supabase
          .from('topics')
          .select('*, profiles!topics_user_id_fkey(*)')
          .inFilter('id', topicIds)
          .order('created_at', ascending: false);

      final List<TopicModel> topics = [];
      for (final item in topicsResponse) {
        topics.add(TopicModel.fromJson(item));
      }

      // Fetch suggestion counts for all topics
      if (topics.isNotEmpty) {
        final suggestionCounts = await _fetchSuggestionCounts(topicIds);
        for (final topic in topics) {
          final count = suggestionCounts[topic.id] ?? 0;
          final index = topics.indexOf(topic);
          topics[index] = topic.copyWith(suggestionCount: count);
        }
      }

      return topics;
    } catch (e) {
      throw Exception('Failed to fetch bookmarked topics: $e');
    }
  }

  // Call the increment_topic_view RPC function
  Future<void> incrementViewCount(String topicId) async {
    try {
      await _supabase.rpc(
        'increment_topic_view',
        params: {'topic_id': topicId},
      );
    } catch (e) {
      // Log but don't throw - view count increment is non-critical
      print('Failed to increment view count: $e');
    }
  }
}
