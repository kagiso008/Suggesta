import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/topic_model.dart';
import '../providers/bookmarks_provider.dart';
import '../../../../shared/widgets/app_toast.dart';

class TopicCard extends ConsumerWidget {
  final TopicModel topic;
  final VoidCallback onTap;

  const TopicCard({super.key, required this.topic, required this.onTap});

  String _getTimeAgo(DateTime date) {
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

  Widget _buildMilestoneBadge(String? badge) {
    if (badge == null) return const SizedBox.shrink();

    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (badge) {
      case 'rising':
        badgeColor = Colors.orange;
        badgeText = '📈 Rising';
        badgeIcon = Icons.trending_up;
      case 'hot':
        badgeColor = Colors.red;
        badgeText = '🔥 Hot';
        badgeIcon = Icons.local_fire_department;
      case 'viral':
        badgeColor = Colors.purple;
        badgeText = '⚡ Viral';
        badgeIcon = Icons.bolt;
      default:
        badgeColor = Colors.grey;
        badgeText = badge;
        badgeIcon = Icons.star;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(
      bookmarksProvider.select(
        (bookmarks) => bookmarks.maybeWhen(
          data: (topics) => topics.any((t) => t.id == topic.id),
          orElse: () => false,
        ),
      ),
    );

    Future<void> toggleBookmark() async {
      try {
        final notifier = ref.read(bookmarksProvider.notifier);
        await notifier.toggleBookmark(topic.id);
      } catch (e) {
        // Show error toast
        AppToast.showError(
          context: context,
          message: 'Failed to toggle bookmark: $e',
        );
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile picture
              CircleAvatar(
                radius: 14,
                backgroundColor: Colors.grey[300],
                backgroundImage: topic.author?.avatarUrl != null
                    ? NetworkImage(topic.author!.avatarUrl!)
                    : null,
                child: topic.author?.avatarUrl == null
                    ? Icon(Icons.person, color: Colors.grey[600], size: 16)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author and time row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            topic.author?.username ?? 'Anonymous',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTimeAgo(topic.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                        if (topic.milestoneBadge != null) ...[
                          const SizedBox(width: 8),
                          _buildMilestoneBadge(topic.milestoneBadge),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Title
                    Text(
                      topic.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Description (if available)
                    if (topic.description != null &&
                        topic.description!.isNotEmpty)
                      Text(
                        topic.description!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (topic.description != null &&
                        topic.description!.isNotEmpty)
                      const SizedBox(height: 4),

                    // Category and tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (topic.category != null)
                          Chip(
                            label: Text(topic.category!),
                            backgroundColor: Colors.blue[50],
                            labelStyle: const TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                          ),
                        ...topic.tags.take(3).map((tag) {
                          return Chip(
                            label: Text(tag),
                            backgroundColor: Colors.grey[100],
                            labelStyle: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[700],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Suggestions count
                        Row(
                          children: [
                            Text(
                              '💡 ${topic.suggestionCount}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        // View count
                        Row(
                          children: [
                            Text(
                              '👁 ${topic.viewCount}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        // Bookmark button
                        IconButton(
                          onPressed: toggleBookmark,
                          icon: Icon(
                            isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            size: 16,
                            color: isBookmarked
                                ? Colors.amber
                                : Colors.grey[600],
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: isBookmarked
                              ? 'Remove bookmark'
                              : 'Bookmark topic',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
