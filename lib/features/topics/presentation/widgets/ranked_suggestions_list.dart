import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/suggestion_model.dart';
import 'suggestion_card.dart';

class RankedSuggestionsList extends ConsumerStatefulWidget {
  final List<SuggestionModel> suggestions;
  final bool isLoadingMore;
  final bool hasMore;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRefresh;
  final String? errorMessage;
  final bool showEmptyState;

  const RankedSuggestionsList({
    super.key,
    required this.suggestions,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onRefresh,
    this.errorMessage,
    this.showEmptyState = false,
  });

  @override
  ConsumerState<RankedSuggestionsList> createState() =>
      _RankedSuggestionsListState();
}

class _RankedSuggestionsListState extends ConsumerState<RankedSuggestionsList> {
  final _scrollController = ScrollController();

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
            _scrollController.position.maxScrollExtent - 200 &&
        widget.hasMore &&
        !widget.isLoadingMore &&
        widget.onLoadMore != null) {
      widget.onLoadMore!();
    }
  }

  List<SuggestionModel> _getRankedSuggestions() {
    // Sort suggestions by vote count (descending), then by creation date (newest first)
    final sorted = List<SuggestionModel>.from(widget.suggestions)
      ..sort((a, b) {
        // First by vote count
        final voteDiff = b.voteCount.compareTo(a.voteCount);
        if (voteDiff != 0) return voteDiff;

        // Then by creation date (newest first)
        return b.createdAt.compareTo(a.createdAt);
      });

    return sorted;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No suggestions yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to share your idea!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load suggestions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.errorMessage ?? 'An unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.onRefresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.showEmptyState && widget.suggestions.isEmpty) {
      return _buildEmptyState();
    }

    if (widget.errorMessage != null && widget.suggestions.isEmpty) {
      return _buildErrorState();
    }

    final rankedSuggestions = _getRankedSuggestions();

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < rankedSuggestions.length) {
                  final suggestion = rankedSuggestions[index];
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      index == rankedSuggestions.length - 1 ? 24 : 8,
                    ),
                    child: SuggestionCard(
                      suggestion: suggestion,
                      rank: index + 1,
                      onTap: () {
                        // TODO: Navigate to suggestion detail if needed
                      },
                    ),
                  );
                }

                // Loading more indicator
                if (widget.hasMore || widget.isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                // End of list
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No more suggestions',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              },
              childCount:
                  rankedSuggestions.length +
                  (widget.hasMore || widget.isLoadingMore ? 1 : 0) +
                  (rankedSuggestions.isNotEmpty ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }
}
