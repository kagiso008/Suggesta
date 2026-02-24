import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/topic_model.dart';
import 'topic_vote_button.dart';

class TopicCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: topic.author?.avatarUrl != null
                        ? NetworkImage(topic.author!.avatarUrl!)
                        : null,
                    child: topic.author?.avatarUrl == null
                        ? Icon(Icons.person, color: Colors.grey[600], size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.author?.username ?? 'Anonymous',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _getTimeAgo(topic.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildMilestoneBadge(topic.milestoneBadge),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                topic.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Description (if available)
              if (topic.description != null && topic.description!.isNotEmpty)
                Text(
                  topic.description!,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (topic.description != null && topic.description!.isNotEmpty)
                const SizedBox(height: 12),

              // Category and tags
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (topic.category != null)
                    Chip(
                      label: Text(topic.category!),
                      backgroundColor: Colors.blue[50],
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    ),
                  ...topic.tags.take(3).map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor: Colors.grey[100],
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),

              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Vote button and count
                  Consumer(
                    builder: (context, ref, child) {
                      return TopicVoteButton(topic: topic, compact: true);
                    },
                  ),

                  // Suggestions count
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '💡 0', // Placeholder - we'll need to fetch suggestion count
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // View count
                  Row(
                    children: [
                      Icon(
                        Icons.remove_red_eye_outlined,
                        size: 20,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '👁 ${topic.viewCount}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
