import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

      final upvotedSuggestionIds = <String>{};
      for (final item in response) {
        final suggestionId = item['suggestion_id'] as String;
        upvotedSuggestionIds.add(suggestionId);
      }
      return upvotedSuggestionIds;
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
    print(
      '[DEBUG] toggleVote called for suggestion: $suggestionId, currentCount: $currentCount',
    );
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[ERROR] toggleVote failed: User not authenticated');
      throw Exception('User must be authenticated to vote');
    }

    final state = this.state;
    if (state is! AsyncData) {
      print('[WARN] toggleVote: State is not AsyncData, skipping');
      return;
    }

    final currentUpvotes = state.value ?? {};
    final hasUpvoted = currentUpvotes.contains(suggestionId);
    print('[DEBUG] toggleVote: User ${user.id} hasUpvoted: $hasUpvoted');

    // Optimistic update
    final newUpvotes = Set<String>.from(currentUpvotes);
    if (hasUpvoted) {
      newUpvotes.remove(suggestionId);
      print('[DEBUG] toggleVote: Removing vote optimistically');
    } else {
      newUpvotes.add(suggestionId);
      print('[DEBUG] toggleVote: Adding vote optimistically');
    }

    this.state = AsyncValue.data(newUpvotes);
    print(
      '[DEBUG] toggleVote: Optimistic update applied, new upvotes count: ${newUpvotes.length}',
    );

    try {
      final repository = ref.read(topicsRepositoryProvider);
      print('[DEBUG] toggleVote: Calling repository.toggleSuggestionLike');
      // Use the new RPC function which returns updated vote count and has_voted status
      final result = await repository.toggleSuggestionLike(suggestionId);
      print('[DEBUG] toggleVote: Repository call successful, result: $result');
      // Note: The RPC function returns the new vote count and has_voted status,
      // but we don't need to use them here since the optimistic update already
      // updated the UI and the real-time updates will sync the actual state
    } catch (e, stackTrace) {
      print('[ERROR] toggleVote failed for suggestion $suggestionId: $e');
      print('[ERROR] Stack trace: $stackTrace');
      // Revert on error
      this.state = AsyncValue.data(currentUpvotes);
      print('[DEBUG] toggleVote: Reverted optimistic update due to error');
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

      final upvotedSuggestionIds = <String>{};
      for (final item in response) {
        final suggestionId = item['suggestion_id'] as String;
        upvotedSuggestionIds.add(suggestionId);
      }
      state = AsyncValue.data(upvotedSuggestionIds);
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
