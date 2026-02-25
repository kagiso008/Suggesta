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
  int _optimisticVoteCount = 0;
  bool _optimisticHasVoted = false;
  bool _hasOptimisticUpdate = false;

  @override
  void initState() {
    super.initState();
    _optimisticVoteCount = widget.suggestion.voteCount;
  }

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

    // Get current vote state from provider
    final voteProvider = ref.read(suggestionVoteProvider.notifier);
    final currentHasVoted = voteProvider.hasVoted(widget.suggestion.id);

    // Calculate new vote count optimistically
    int newOptimisticCount = _optimisticVoteCount;
    bool newHasVoted = currentHasVoted;

    if (currentHasVoted) {
      // Removing vote
      newOptimisticCount = _optimisticVoteCount - 1;
      newHasVoted = false;
    } else {
      // Adding vote
      newOptimisticCount = _optimisticVoteCount + 1;
      newHasVoted = true;
    }

    // Optimistic update
    setState(() {
      _isVoting = true;
      _hasError = false;
      _hasOptimisticUpdate = true;
      _optimisticHasVoted = newHasVoted;
      _optimisticVoteCount = newOptimisticCount;
    });

    try {
      // Use the provider's toggleVote method
      await voteProvider.toggleVote(widget.suggestion.id, _optimisticVoteCount);

      // Refresh the suggestions provider to get updated vote count
      ref.invalidate(suggestionsProvider(widget.suggestion.topicId));
    } catch (e) {
      setState(() {
        _hasError = true;
        // Revert optimistic update on error
        _optimisticHasVoted = currentHasVoted;
        _optimisticVoteCount = widget.suggestion.voteCount;
        _hasOptimisticUpdate = false;
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
  void didUpdateWidget(SuggestionVoteButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the suggestion data changed (e.g., from real-time update),
    // reset optimistic values
    if (widget.suggestion.id != oldWidget.suggestion.id ||
        widget.suggestion.voteCount != oldWidget.suggestion.voteCount) {
      setState(() {
        _optimisticVoteCount = widget.suggestion.voteCount;
        _hasOptimisticUpdate = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final voteState = ref.watch(suggestionVoteProvider);
    final serverHasVoted = voteState.maybeWhen(
      data: (upvotedSuggestionIds) {
        // Check if user has upvoted this suggestion
        return upvotedSuggestionIds.contains(widget.suggestion.id);
      },
      orElse: () => false,
    );

    // Use optimistic values if available, otherwise server values
    final hasVoted = _hasOptimisticUpdate
        ? _optimisticHasVoted
        : serverHasVoted;
    final voteCount = _hasOptimisticUpdate
        ? _optimisticVoteCount
        : widget.suggestion.voteCount;

    if (widget.compact) {
      return _buildCompactVoteButton(voteCount, hasVoted);
    }

    return _buildFullVoteButton(voteCount, hasVoted);
  }

  Widget _buildCompactVoteButton(int voteCount, bool hasVoted) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Upvote button
        GestureDetector(
          onTap: _handleVote,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: hasVoted
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.arrow_upward,
              size: 16,
              color: hasVoted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        // Vote count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _formatCount(voteCount),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullVoteButton(int voteCount, bool hasVoted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Upvote button
        IconButton(
          onPressed: _handleVote,
          icon: Icon(
            Icons.arrow_upward,
            color: hasVoted
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            size: 24,
          ),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          tooltip: hasVoted ? 'Remove upvote' : 'Upvote',
        ),

        // Vote count
        Text(
          _formatCount(voteCount),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),

        // Loading indicator
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

        // Error indicator
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
