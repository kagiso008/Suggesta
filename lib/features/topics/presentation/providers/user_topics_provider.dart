import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'topics_provider.dart';
import '../../models/topic_model.dart';

final userTopicsProvider = FutureProvider.family<List<TopicModel>, String>((
  ref,
  userId,
) async {
  final repo = ref.read(topicsRepositoryProvider);
  return await repo.fetchTopicsByUserId(userId);
});
