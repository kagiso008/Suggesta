import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/topics_repository.dart';
import '../../../../shared/models/suggestion_model.dart';
import 'topics_provider.dart';

class SuggestionsNotifier
    extends FamilyAsyncNotifier<List<SuggestionModel>, String> {
  String? _topicId;
  StreamSubscription? _subscription;

  String get topicId {
    assert(_topicId != null, 'topicId accessed before build');
    return _topicId!;
  }

  @override
  Future<List<SuggestionModel>> build(String arg) async {
    // Only set topicId if it hasn't been set yet
    _topicId ??= arg;

    // Fetch initial suggestions
    final repository = ref.read(topicsRepositoryProvider);
    final suggestions = await repository.fetchSuggestions(topicId);

    // Set up realtime subscription
    _setupRealtimeSubscription();

    return suggestions;
  }

  void _setupRealtimeSubscription() {
    // Cancel existing subscription
    _subscription?.cancel();

    final repository = ref.read(topicsRepositoryProvider);
    _subscription = repository
        .watchSuggestions(topicId)
        .listen(_handleRealtimeUpdate);
  }

  void _handleRealtimeUpdate(List<Map<String, dynamic>> rawList) {
    // 1. Parse raw list into List<SuggestionModel>
    final realtimeSuggestions = rawList.map((item) {
      return SuggestionModel.fromJson(item);
    }).toList();

    // 2. Merge with existing state to preserve author data
    final currentState = state;
    if (currentState is! AsyncData) return;

    final currentSuggestions = currentState.value;
    if (currentSuggestions == null) return;

    // Create a map of existing suggestions by id for quick lookup
    final existingSuggestionsMap = {
      for (final suggestion in currentSuggestions) suggestion.id: suggestion,
    };

    // Merge: for each realtime item, find matching suggestion in current state
    // and keep its .author, only update vote_count and other scalar fields
    final mergedSuggestions = realtimeSuggestions.map((realtimeSuggestion) {
      final existingSuggestion = existingSuggestionsMap[realtimeSuggestion.id];
      if (existingSuggestion != null) {
        // Preserve author data from existing suggestion
        return realtimeSuggestion.copyWith(author: existingSuggestion.author);
      }
      return realtimeSuggestion;
    }).toList();

    // 3. Sort: vote_count DESC, then created_at DESC (newer first for ties)
    mergedSuggestions.sort((a, b) {
      final voteCmp = b.voteCount.compareTo(a.voteCount);
      if (voteCmp != 0) return voteCmp;
      return b.createdAt.compareTo(a.createdAt); // tie-break: newer first
    });

    // 4. Update state with the sorted list
    state = AsyncValue.data(mergedSuggestions);
  }

  Future<SuggestionModel> addSuggestion({
    required String content,
    String? imageUrl,
  }) async {
    try {
      final repository = ref.read(topicsRepositoryProvider);
      final newSuggestion = await repository.addSuggestion(
        topicId: topicId,
        content: content,
        imageUrl: imageUrl,
      );

      // Update state with new suggestion
      final currentState = state;
      if (currentState is AsyncData) {
        final currentValue = currentState.value;
        if (currentValue != null) {
          final updatedSuggestions = [newSuggestion, ...currentValue];
          // Re-sort after adding
          updatedSuggestions.sort((a, b) {
            final voteCmp = b.voteCount.compareTo(a.voteCount);
            if (voteCmp != 0) return voteCmp;
            return b.createdAt.compareTo(a.createdAt); // tie-break: newer first
          });
          state = AsyncValue.data(updatedSuggestions);
        }
      }

      return newSuggestion;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(topicsRepositoryProvider);
      final suggestions = await repository.fetchSuggestions(topicId);
      state = AsyncValue.data(suggestions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

// Family provider — one per topicId
final suggestionsProvider =
    AsyncNotifierProviderFamily<
      SuggestionsNotifier,
      List<SuggestionModel>,
      String
    >(SuggestionsNotifier.new, name: 'suggestionsProvider');
