import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/topics_provider.dart';
import '../providers/user_topics_provider.dart';
import '../widgets/topic_card.dart';
import '../../../../shared/widgets/app_toast.dart';

class UserTopicsScreen extends ConsumerWidget {
  const UserTopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Topics')),
        body: const Center(child: Text('You must be logged in.')),
      );
    }

    final topicsAsync = ref.watch(userTopicsProvider(user.id));

    return Scaffold(
      appBar: AppBar(title: const Text('My Topics')),
      body: topicsAsync.when(
        data: (topics) {
          if (topics.isEmpty) {
            return const Center(
              child: Text('You have not created any topics.'),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hint for delete action
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                child: Row(
                  children: [
                    Icon(Icons.swipe_left, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Swipe left to delete a topic',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    final topic = topics[index];
                    return Dismissible(
                      key: ValueKey(topic.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        final shouldDelete =
                            await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Topic'),
                                content: const Text(
                                  'Are you sure you want to delete this topic?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ) ??
                            false;

                        if (!shouldDelete) return false;

                        try {
                          // Perform deletion
                          await ref
                              .read(topicsRepositoryProvider)
                              .deleteTopic(topic.id);

                          // Invalidate providers to refresh data
                          final user =
                              Supabase.instance.client.auth.currentUser;
                          if (user != null) {
                            ref.invalidate(userTopicsProvider(user.id));
                          }
                          ref.invalidate(topicsProvider);

                          // Show success message
                          if (context.mounted) {
                            AppToast.showSuccess(
                              context: context,
                              message: 'Topic deleted',
                            );
                          }

                          return true; // Dismiss the widget
                        } catch (e) {
                          // Show error message
                          if (context.mounted) {
                            AppToast.showError(
                              context: context,
                              message: 'Failed to delete topic: $e',
                            );
                          }
                          return false; // Don't dismiss the widget
                        }
                      },
                      onDismissed: (direction) {
                        // Widget will be automatically removed since we returned true from confirmDismiss
                        // No need to do anything here
                      },
                      child: TopicCard(
                        topic: topic,
                        onTap: () {
                          // Navigate to topic detail using GoRouter
                          context.push('/topic/${topic.id}');
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
