import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../topics/models/topic_model.dart';

class TrendingProvider extends AsyncNotifier<List<TopicModel>> {
  @override
  Future<List<TopicModel>> build() async {
    return fetchTrendingTopics();
  }

  Future<List<TopicModel>> fetchTrendingTopics() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.rpc(
        'get_trending_topics_by_views',
        params: {'hours': 1, 'limit_count': 10},
      );

      if (response == null) {
        return [];
      }

      final List<TopicModel> trendingTopics = [];
      for (final item in response) {
        trendingTopics.add(TopicModel.fromJson(item));
      }

      return trendingTopics;
    } catch (e) {
      throw Exception('Failed to fetch trending topics: $e');
    }
  }

  Future<void> refreshTrendingTopics() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => fetchTrendingTopics());
  }
}

final trendingProvider =
    AsyncNotifierProvider<TrendingProvider, List<TopicModel>>(
      TrendingProvider.new,
    );
