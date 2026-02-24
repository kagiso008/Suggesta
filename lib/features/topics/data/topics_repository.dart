import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/topic_model.dart';
import '../../../shared/models/suggestion_model.dart';

class TopicsRepository {
  final SupabaseClient _supabase;

  TopicsRepository({required SupabaseClient supabase}) : _supabase = supabase;

  // Fetch paginated topics for home feed, joined with author profile
  Future<List<TopicModel>> fetchTopics({int from = 0, int to = 19}) async {
    try {
      final response = await _supabase
          .from('topics')
          .select('*, profiles(*)')
          .order('created_at', ascending: false)
          .range(from, to);

      final List<TopicModel> topics = [];
      for (final item in response) {
        topics.add(TopicModel.fromJson(item));
      }
      return topics;
    } catch (e) {
      throw Exception('Failed to fetch topics: $e');
    }
  }

  // Fetch a single topic by id with author profile
  Future<TopicModel> fetchTopic(String topicId) async {
    try {
      final response = await _supabase
          .from('topics')
          .select('*, profiles(*)')
          .eq('id', topicId)
          .single();

      return TopicModel.fromJson(response);
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
          .select('*, profiles(*)')
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
          .select('*, profiles(*)')
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
          .select('*, profiles(*)')
          .single();

      return SuggestionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add suggestion: $e');
    }
  }

  // Check if current user has voted on a topic
  Future<bool> hasVotedOnTopic(String topicId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('topic_votes')
          .select('id')
          .eq('user_id', user.id)
          .eq('topic_id', topicId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check topic vote: $e');
    }
  }

  // Check if current user has voted on a suggestion
  Future<bool> hasVotedOnSuggestion(String suggestionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('suggestion_votes')
          .select('id')
          .eq('user_id', user.id)
          .eq('suggestion_id', suggestionId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      throw Exception('Failed to check suggestion vote: $e');
    }
  }

  // Toggle topic vote — insert if not voted, delete if already voted
  Future<bool> toggleTopicVote(String topicId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to vote');
      }

      final hasVoted = await hasVotedOnTopic(topicId);

      if (!hasVoted) {
        // Insert vote
        await _supabase.from('topic_votes').insert({
          'user_id': user.id,
          'topic_id': topicId,
        });
        return true; // Now voted
      } else {
        // Delete vote
        await _supabase
            .from('topic_votes')
            .delete()
            .eq('user_id', user.id)
            .eq('topic_id', topicId);
        return false; // Vote removed
      }
    } catch (e) {
      throw Exception('Failed to toggle topic vote: $e');
    }
  }

  // Toggle suggestion vote — same pattern as toggleTopicVote
  Future<bool> toggleSuggestionVote(String suggestionId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to vote');
      }

      final hasVoted = await hasVotedOnSuggestion(suggestionId);

      if (!hasVoted) {
        // Insert vote
        await _supabase.from('suggestion_votes').insert({
          'user_id': user.id,
          'suggestion_id': suggestionId,
        });
        return true; // Now voted
      } else {
        // Delete vote
        await _supabase
            .from('suggestion_votes')
            .delete()
            .eq('user_id', user.id)
            .eq('suggestion_id', suggestionId);
        return false; // Vote removed
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
