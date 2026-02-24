import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/topics_provider.dart';
import '../providers/suggestions_provider.dart';
import '../widgets/suggestion_card.dart';
import '../../models/topic_model.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final String topicId;

  const TopicDetailScreen({super.key, required this.topicId});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreSuggestions();
    }
  }

  Future<void> _loadMoreSuggestions() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    // TODO: Implement pagination for suggestions
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isLoadingMore = false;
    });
  }

  void _showCreateSuggestionSheet() {
    // TODO: Implement CreateSuggestionSheet
    // For now, show a placeholder dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Suggestion'),
        content: const Text(
          'CreateSuggestionSheet widget will be implemented in the next step.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    final suggestionsAsync = ref.watch(suggestionsProvider(widget.topicId));

    // Find the topic from the topics list
    TopicModel? topic;
    if (topicsAsync is AsyncData) {
      topic = topicsAsync.value?.firstWhere(
        (t) => t.id == widget.topicId,
        orElse: () => TopicModel(
          id: widget.topicId,
          title: 'Loading...',
          description: '',
          category: 'general',
          tags: [],
          voteCount: 0,
          viewCount: 0,
          milestoneBadge: null,
          createdAt: DateTime.now(),
          userId: '',
          author: null,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Topic'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(topicsProvider.notifier).refresh();
          await ref
              .read(suggestionsProvider(widget.topicId).notifier)
              .refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Topic header
            SliverToBoxAdapter(
              child: topic != null
                  ? _buildTopicHeader(topic)
                  : const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
            ),

            // Suggestions header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Suggestions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      suggestionsAsync.maybeWhen(
                        data: (suggestions) => '${suggestions.length}',
                        orElse: () => '0',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Suggestions list
            suggestionsAsync.when(
              data: (suggestions) {
                if (suggestions.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No suggestions yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Be the first to suggest an idea!',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _showCreateSuggestionSheet,
                            child: const Text('Add Suggestion'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final suggestion = suggestions[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        index == suggestions.length - 1 ? 24 : 8,
                      ),
                      child: SuggestionCard(
                        suggestion: suggestion,
                        rank: index + 1,
                        onTap: () {
                          // TODO: Navigate to suggestion detail if needed
                        },
                      ),
                    );
                  }, childCount: suggestions.length),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load suggestions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(suggestionsProvider(widget.topicId));
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading more indicator
            if (_isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateSuggestionSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTopicHeader(TopicModel topic) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author and time
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: topic.author?.avatarUrl != null
                    ? NetworkImage(topic.author!.avatarUrl!)
                    : null,
                child: topic.author?.avatarUrl == null
                    ? Text(topic.author?.username.substring(0, 1) ?? '?')
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic.author?.username ?? 'Anonymous',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formatTimeAgo(topic.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              if (topic.milestoneBadge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getBadgeColor(topic.milestoneBadge!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getBadgeText(topic.milestoneBadge!),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            topic.title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Description
          if (topic.description != null && topic.description!.isNotEmpty)
            Column(
              children: [
                Text(
                  topic.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
              ],
            ),

          // Category and tags
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              if (topic.category != null)
                Chip(
                  label: Text(topic.category!),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ...topic.tags.take(3).map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(fontSize: 12, color: Colors.grey[700]),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.arrow_upward,
                value: topic.voteCount.toString(),
                label: 'Votes',
              ),
              _buildStatItem(
                icon: Icons.lightbulb_outline,
                value:
                    '0', // Placeholder - we don't have suggestionCount in TopicModel
                label: 'Suggestions',
              ),
              _buildStatItem(
                icon: Icons.remove_red_eye,
                value: topic.viewCount.toString(),
                label: 'Views',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case 'rising':
        return Colors.orange;
      case 'hot':
        return Colors.red;
      case 'viral':
        return Colors.purple;
      case 'trending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getBadgeText(String badge) {
    switch (badge) {
      case 'rising':
        return '📈 Rising';
      case 'hot':
        return '🔥 Hot';
      case 'viral':
        return '🦠 Viral';
      case 'trending':
        return '📊 Trending';
      default:
        return badge;
    }
  }
}
