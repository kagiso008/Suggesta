import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/suggestion_vote_provider.dart';
import '../providers/suggestions_provider.dart';
import '../../../../shared/models/suggestion_model.dart';
import '../../../../shared/widgets/app_toast.dart';

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
    print('[DEBUG] _handleVote called for suggestion: ${widget.suggestion.id}');
    if (_isVoting) {
      print('[DEBUG] _handleVote: Already voting, skipping');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      print('[DEBUG] _handleVote: User not authenticated');
      // Show auth dialog or toast
      if (mounted) {
        AppToast.showInfo(
          context: context,
          message: 'Please sign in to upvote suggestions',
        );
      }
      return;
    }

    print('[DEBUG] _handleVote: User ${user.id} authenticated');
    // Get current vote state from provider
    final voteProvider = ref.read(suggestionVoteProvider.notifier);
    final currentHasVoted = voteProvider.hasVoted(widget.suggestion.id);
    print('[DEBUG] _handleVote: currentHasVoted: $currentHasVoted');

    // Calculate new vote count optimistically
    int newOptimisticCount = _optimisticVoteCount;
    bool newHasVoted = currentHasVoted;

    if (currentHasVoted) {
      // Removing vote
      newOptimisticCount = _optimisticVoteCount - 1;
      newHasVoted = false;
      print(
        '[DEBUG] _handleVote: Removing vote, new count: $newOptimisticCount',
      );
    } else {
      // Adding vote
      newOptimisticCount = _optimisticVoteCount + 1;
      newHasVoted = true;
      print('[DEBUG] _handleVote: Adding vote, new count: $newOptimisticCount');
    }

    // Optimistic update
    print('[DEBUG] _handleVote: Applying optimistic update');
    setState(() {
      _isVoting = true;
      _hasError = false;
      _hasOptimisticUpdate = true;
      _optimisticHasVoted = newHasVoted;
      _optimisticVoteCount = newOptimisticCount;
    });

    try {
      // Use the provider's toggleVote method
      print('[DEBUG] _handleVote: Calling voteProvider.toggleVote');
      await voteProvider.toggleVote(widget.suggestion.id, _optimisticVoteCount);

      // Refresh the suggestions provider to get updated vote count
      print('[DEBUG] _handleVote: Invalidating suggestions provider');
      ref.invalidate(suggestionsProvider(widget.suggestion.topicId));
      print('[DEBUG] _handleVote: Vote completed successfully');
    } catch (e, stackTrace) {
      print('[ERROR] _handleVote failed: $e');
      print('[ERROR] Stack trace: $stackTrace');
      setState(() {
        _hasError = true;
        // Revert optimistic update on error
        _optimisticHasVoted = currentHasVoted;
        _optimisticVoteCount = widget.suggestion.voteCount;
        _hasOptimisticUpdate = false;
      });
      if (mounted) {
        AppToast.showError(context: context, message: 'Failed to upvote: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVoting = false;
          print(
            '[DEBUG] _handleVote: Voting completed, _isVoting set to false',
          );
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
      data: (likedSuggestionIds) {
        // Check if user has liked this suggestion
        return likedSuggestionIds.contains(widget.suggestion.id);
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
    return GestureDetector(
      onTap: _handleVote,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: hasVoted
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasVoted
                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Arrow up icon
            Icon(
              hasVoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
              size: 16,
              color: hasVoted
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),

            const SizedBox(width: 6),

            // Vote count
            Text(
              _formatCount(voteCount),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: hasVoted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullVoteButton(int voteCount, bool hasVoted) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Upvote button with arrow_up icon
        IconButton(
          onPressed: _handleVote,
          icon: Icon(
            hasVoted ? Icons.arrow_upward : Icons.arrow_upward_outlined,
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
