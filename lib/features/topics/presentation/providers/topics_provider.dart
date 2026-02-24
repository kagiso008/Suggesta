import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/topics_repository.dart';
import '../../models/topic_model.dart';

final topicsRepositoryProvider = Provider<TopicsRepository>((ref) {
  final supabase = Supabase.instance.client;
  return TopicsRepository(supabase: supabase);
});

class TopicsNotifier extends AsyncNotifier<List<TopicModel>> {
  @override
  Future<List<TopicModel>> build() async {
    final repository = ref.read(topicsRepositoryProvider);
    return await repository.fetchTopics();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(topicsRepositoryProvider);
      final topics = await repository.fetchTopics();
      state = AsyncValue.data(topics);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! AsyncData) return;

    final currentTopics = currentState.value;
    if (currentTopics == null) return;

    try {
      final repository = ref.read(topicsRepositoryProvider);
      final moreTopics = await repository.fetchTopics(
        from: currentTopics.length,
        to: currentTopics.length + 19,
      );

      final updatedTopics = [...currentTopics, ...moreTopics];
      state = AsyncValue.data(updatedTopics);
    } catch (e, st) {
      // Don't update state on error for loadMore - keep existing data
      print('Failed to load more topics: $e');
    }
  }

  Future<TopicModel> createTopic({
    required String title,
    String? description,
    String? category,
    List<String> tags = const [],
  }) async {
    try {
      final repository = ref.read(topicsRepositoryProvider);
      final newTopic = await repository.createTopic(
        title: title,
        description: description,
        category: category,
        tags: tags,
      );

      // Update state with new topic at the beginning
      final currentState = state;
      if (currentState is AsyncData) {
        final currentValue = currentState.value;
        if (currentValue != null) {
          final updatedTopics = [newTopic, ...currentValue];
          state = AsyncValue.data(updatedTopics);
        } else {
          // If current value is null, just set to list with new topic
          state = AsyncValue.data([newTopic]);
        }
      }

      return newTopic;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// Provides the list of topics for the home feed
final topicsProvider = AsyncNotifierProvider<TopicsNotifier, List<TopicModel>>(
  TopicsNotifier.new,
);
