import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/topic_model.dart';
import 'topics_provider.dart';

class BookmarksNotifier extends AsyncNotifier<List<TopicModel>> {
  @override
  Future<List<TopicModel>> build() async {
    final repository = ref.read(topicsRepositoryProvider);
    return await repository.fetchBookmarkedTopics();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(topicsRepositoryProvider);
      final bookmarks = await repository.fetchBookmarkedTopics();
      state = AsyncValue.data(bookmarks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> toggleBookmark(String topicId) async {
    try {
      final repository = ref.read(topicsRepositoryProvider);
      final isNowBookmarked = await repository.toggleBookmark(topicId);

      // Refresh the bookmarks list to reflect the change
      await refresh();

      return isNowBookmarked;
    } catch (e) {
      // Re-throw the error
      throw Exception('Failed to toggle bookmark: $e');
    }
  }

  Future<bool> isBookmarked(String topicId) async {
    try {
      final repository = ref.read(topicsRepositoryProvider);
      return await repository.isBookmarked(topicId);
    } catch (e) {
      // If we can't check, assume not bookmarked
      return false;
    }
  }

  Future<void> clearAllBookmarks() async {
    try {
      final repository = ref.read(topicsRepositoryProvider);
      await repository.clearAllBookmarks();
      // After clearing, refresh the list
      await refresh();
    } catch (e) {
      throw Exception('Failed to clear all bookmarks: $e');
    }
  }
}

final bookmarksProvider =
    AsyncNotifierProvider<BookmarksNotifier, List<TopicModel>>(
      BookmarksNotifier.new,
    );
