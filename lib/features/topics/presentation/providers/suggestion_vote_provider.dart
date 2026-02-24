import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/topics_repository.dart';
import 'topics_provider.dart';

class SuggestionVoteNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {};

    try {
      final response = await Supabase.instance.client
          .from('suggestion_votes')
          .select('suggestion_id')
          .eq('user_id', user.id)
          .limit(1000);

      final votedSuggestionIds = <String>{};
      for (final item in response) {
        final suggestionId = item['suggestion_id'] as String;
        votedSuggestionIds.add(suggestionId);
      }
      return votedSuggestionIds;
    } catch (e) {
      // If we can't fetch votes, return empty set
      print('Failed to fetch suggestion votes: $e');
      return {};
    }
  }

  bool hasVoted(String suggestionId) {
    final state = this.state;
    if (state is! AsyncData) return false;
    return state.value?.contains(suggestionId) ?? false;
  }

  Future<void> toggleVote(String suggestionId, int currentCount) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User must be authenticated to vote');
    }

    final state = this.state;
    if (state is! AsyncData) return;

    final currentVotes = state.value ?? {};
    final hasVoted = currentVotes.contains(suggestionId);

    // Optimistic update
    final newVotes = Set<String>.from(currentVotes);
    if (hasVoted) {
      newVotes.remove(suggestionId);
    } else {
      newVotes.add(suggestionId);
    }

    this.state = AsyncValue.data(newVotes);

    try {
      final repository = ref.read(topicsRepositoryProvider);
      await repository.toggleSuggestionVote(suggestionId);
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
          .from('suggestion_votes')
          .select('suggestion_id')
          .eq('user_id', user.id)
          .limit(1000);

      final votedSuggestionIds = <String>{};
      for (final item in response) {
        final suggestionId = item['suggestion_id'] as String;
        votedSuggestionIds.add(suggestionId);
      }
      state = AsyncValue.data(votedSuggestionIds);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final suggestionVoteProvider =
    AsyncNotifierProvider<SuggestionVoteNotifier, Set<String>>(
      SuggestionVoteNotifier.new,
      name: 'suggestionVoteProvider',
    );
