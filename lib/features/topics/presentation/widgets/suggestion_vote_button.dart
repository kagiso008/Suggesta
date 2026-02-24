import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/suggestion_vote_provider.dart';
import '../providers/suggestions_provider.dart';
import '../../../../shared/models/suggestion_model.dart';

class SuggestionVoteButton extends ConsumerStatefulWidget {
  final SuggestionModel suggestion;
  final bool compact;

  const SuggestionVoteButton({
    super.key,
    required this.suggestion,
    this.compact = false,
  });

  @override
  ConsumerState<SuggestionVoteButton> createState() =>
      _SuggestionVoteButtonState();
}

class _SuggestionVoteButtonState extends ConsumerState<SuggestionVoteButton> {
  bool _isVoting = false;
  bool _hasError = false;

  Future<void> _handleVote() async {
    if (_isVoting) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // Show auth dialog or snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to vote'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _isVoting = true;
      _hasError = false;
    });

    try {
      final voteProvider = ref.read(suggestionVoteProvider.notifier);
      await voteProvider.toggleVote(
        widget.suggestion.id,
        widget.suggestion.voteCount,
      );

      // Also refresh the suggestions provider to reflect the new vote count
      final suggestionsNotifier = ref.read(
        suggestionsProvider(widget.suggestion.topicId).notifier,
      );
      await suggestionsNotifier.refresh();
    } catch (e) {
      setState(() {
        _hasError = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to vote: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final voteState = ref.watch(suggestionVoteProvider);
    final hasVoted = voteState.maybeWhen(
      data: (votedSuggestionIds) =>
          votedSuggestionIds.contains(widget.suggestion.id),
      orElse: () => false,
    );

    final voteCount = widget.suggestion.voteCount;
    final isUpvoted = hasVoted;

    if (widget.compact) {
      return _buildCompactVoteButton(voteCount, isUpvoted);
    }

    return _buildFullVoteButton(voteCount, isUpvoted);
  }

  Widget _buildCompactVoteButton(int voteCount, bool isUpvoted) {
    return GestureDetector(
      onTap: _handleVote,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isUpvoted
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUpvoted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_upward,
              size: 16,
              color: isUpvoted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatCount(voteCount),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isUpvoted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullVoteButton(int voteCount, bool isUpvoted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _handleVote,
          icon: Icon(
            Icons.arrow_upward,
            color: isUpvoted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          tooltip: isUpvoted ? 'Remove vote' : 'Upvote',
        ),
        const SizedBox(height: 2),
        Text(
          _formatCount(voteCount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isUpvoted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (_isVoting)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        if (_hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.error_outline,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
