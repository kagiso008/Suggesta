import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/topics_repository.dart';
import 'topics_provider.dart';

class TopicVoteNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {};

    try {
      final repository = ref.read(topicsRepositoryProvider);
      // We'll fetch all topic_votes for the current user
      // For simplicity, we'll fetch a limited set (first 1000)
      final response = await Supabase.instance.client
          .from('topic_votes')
          .select('topic_id')
          .eq('user_id', user.id)
          .limit(1000);

      final votedTopicIds = <String>{};
      for (final item in response) {
        final topicId = item['topic_id'] as String;
        votedTopicIds.add(topicId);
      }
      return votedTopicIds;
    } catch (e) {
      // If we can't fetch votes, return empty set
      print('Failed to fetch topic votes: $e');
      return {};
    }
  }

  bool hasVoted(String topicId) {
    final state = this.state;
    if (state is! AsyncData) return false;
    return state.value?.contains(topicId) ?? false;
  }

  Future<void> toggleVote(String topicId, int currentCount) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to vote');
    }

    final state = this.state;
    if (state is! AsyncData) return;

    final currentVotes = state.value ?? {};
    final hasVoted = currentVotes.contains(topicId);

    // Optimistic update
    final newVotes = Set<String>.from(currentVotes);
    if (hasVoted) {
      newVotes.remove(topicId);
    } else {
      newVotes.add(topicId);
    }

    this.state = AsyncValue.data(newVotes);

    try {
      final repository = ref.read(topicsRepositoryProvider);
      await repository.toggleTopicVote(topicId);
    } catch (e) {
      // Revert on error
      this.state = AsyncValue.data(currentVotes);
      rethrow;
    }
  }

  Future<void> refresh() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = const AsyncValue.data({});
      return;
    }

    state = const AsyncValue.loading();
    try {
      final response = await Supabase.instance.client
          .from('topic_votes')
          .select('topic_id')
          .eq('user_id', user.id)
          .limit(1000);

      final votedTopicIds = <String>{};
      for (final item in response) {
        final topicId = item['topic_id'] as String;
        votedTopicIds.add(topicId);
      }
      state = AsyncValue.data(votedTopicIds);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// Manages which topic IDs the current user has voted on
final topicVoteProvider = AsyncNotifierProvider<TopicVoteNotifier, Set<String>>(
  TopicVoteNotifier.new,
);
