import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/match_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../chat/conversation_thread_screen.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'matches_provider.dart';

const _matchRose = Color(0xFFD95F84);
const _matchViolet = Color(0xFF8E6DE8);
const _matchMint = Color(0xFF16A871);
const _matchSlate = Color(0xFF667085);

enum _MatchFilter { all, newMatches }

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  _MatchFilter _selectedFilter = _MatchFilter.all;

  @override
  Widget build(BuildContext context) {
    final matchesState = ref.watch(matchesProvider);
    final controller = ref.read(matchesControllerProvider);
    final totalMatches = matchesState.maybeWhen(
      data: (value) => value.matches.length,
      orElse: () => null,
    );
    final newMatchCount = matchesState.maybeWhen(
      data: (value) => value.matches.where(_isNewMatch).length,
      orElse: () => null,
    );

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MatchesIntroCard(
            totalMatches: totalMatches,
            newMatchCount: newMatchCount,
            onRefresh: () => ref.invalidate(matchesProvider),
          ),
          _MatchFilterRow(
            selectedFilter: _selectedFilter,
            onSelected: (filter) => setState(() => _selectedFilter = filter),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: matchesState.when(
                data: (response) {
                  final visibleMatches = _filteredMatches(
                    response.matches,
                    _selectedFilter,
                  );

                  if (visibleMatches.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppTheme.shellScrollPadding(),
                      children: [
                        _MatchesEmptyState(
                          filter: _selectedFilter,
                          onRefresh: controller.refresh,
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppTheme.shellScrollPadding(),
                    itemCount: visibleMatches.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: AppTheme.cardGap),
                    itemBuilder: (context, index) => _MatchCard(
                      currentUser: widget.currentUser,
                      match: visibleMatches[index],
                    ),
                  );
                },
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppTheme.shellScrollPadding(),
                  children: const [
                    AppAsyncState.loading(message: 'Loading matches...'),
                  ],
                ),
                error: (error, stackTrace) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppTheme.shellScrollPadding(),
                  children: [
                    AppAsyncState.error(
                      message: error is ApiError
                          ? error.message
                          : 'Unable to load matches right now.',
                      onRetry: () => ref.invalidate(matchesProvider),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchesIntroCard extends StatelessWidget {
  const _MatchesIntroCard({
    required this.totalMatches,
    required this.newMatchCount,
    required this.onRefresh,
  });

  final int? totalMatches;
  final int? newMatchCount;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final totalLabel = switch (totalMatches) {
      null => 'Checking your connections',
      0 => 'No matches yet',
      final total => '$total ${total == 1 ? 'match' : 'matches'} ready',
    };
    final summaryLabel = switch ((totalMatches, newMatchCount)) {
      (null, _) || (_, null) => 'Refresh when you want the latest view.',
      (0, _) =>
        'Keep liking people you genuinely connect with and matches will show up here.',
      (final total, final fresh) =>
        '$total ${total == 1 ? 'match' : 'matches'} ready · $fresh new today',
    };

    return Padding(
      padding: AppTheme.screenPadding(compact: true),
      child: DecoratedBox(
        decoration: AppTheme.surfaceDecoration(
          context,
          color: Color.alphaBlend(
            _matchRose.withValues(alpha: isDark ? 0.16 : 0.05),
            colorScheme.surfaceContainerLow,
          ),
          prominent: true,
        ),
        child: Padding(
          padding: AppTheme.sectionPadding(compact: true),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: _matchRose.withValues(alpha: isDark ? 0.18 : 0.10),
                      borderRadius: const BorderRadius.all(Radius.circular(14)),
                    ),
                    child: SizedBox.square(
                      dimension: 40,
                      child: Icon(
                        Icons.favorite_rounded,
                        color: isDark ? const Color(0xFFF5C1CF) : _matchRose,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your matches',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          summaryLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: 'Refresh matches',
                    onPressed: onRefresh,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _MatchesInfoPill(
                    icon: Icons.favorite_rounded,
                    label: totalLabel,
                    color: _matchRose,
                  ),
                  _MatchesInfoPill(
                    icon: Icons.mark_chat_unread_rounded,
                    label: switch (newMatchCount) {
                      null => 'Live status loading',
                      0 => '0 new today',
                      final count when count == 1 => '1 new today',
                      final count => '$count new today',
                    },
                    color: _matchViolet,
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

class _MatchesInfoPill extends StatelessWidget {
  const _MatchesInfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.10,
        ),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchesEmptyState extends StatelessWidget {
  const _MatchesEmptyState({required this.filter, required this.onRefresh});

  final _MatchFilter filter;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _matchViolet.withValues(alpha: isDark ? 0.16 : 0.05),
          theme.colorScheme.surfaceContainerLow,
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MatchesInfoPill(
              icon: Icons.favorite_border_rounded,
              label: filter == _MatchFilter.all
                  ? 'Waiting for mutual likes'
                  : 'No fresh matches today',
              color: _matchRose,
            ),
            const SizedBox(height: 14),
            Text(
              filter == _MatchFilter.all
                  ? 'Keep liking profiles you genuinely connect with and your conversations will appear here.'
                  : 'You are caught up for now. Check back after a few more likes or refresh later.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () async {
                await onRefresh();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh matches'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchFilterRow extends StatelessWidget {
  const _MatchFilterRow({
    required this.selectedFilter,
    required this.onSelected,
  });

  final _MatchFilter selectedFilter;
  final ValueChanged<_MatchFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pagePadding,
        0,
        AppTheme.pagePadding,
        8,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'All',
              selected: selectedFilter == _MatchFilter.all,
              onTap: () => onSelected(_MatchFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'New',
              selected: selectedFilter == _MatchFilter.newMatches,
              onTap: () => onSelected(_MatchFilter.newMatches),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final selectedColor = selected ? _matchRose : colorScheme.onSurfaceVariant;

    return Material(
      color: selected
          ? _matchRose.withValues(alpha: isDark ? 0.18 : 0.10)
          : colorScheme.surfaceContainerLow,
      borderRadius: AppTheme.chipRadius,
      child: InkWell(
        borderRadius: AppTheme.chipRadius,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppTheme.chipRadius,
            border: Border.all(
              color: selected
                  ? _matchRose.withValues(alpha: 0.34)
                  : colorScheme.outlineVariant.withValues(alpha: 0.42),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selectedColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  static const double _matchActionHeight = 38;

  const _MatchCard({required this.currentUser, required this.match});

  final UserSummary currentUser;
  final MatchSummary match;

  void _openConversation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ConversationThreadScreen(
          currentUser: currentUser,
          conversation: ConversationSummary(
            // Stage A backend contract: matchId is the live conversation id.
            id: match.matchId,
            otherUserId: match.otherUserId,
            otherUserName: match.otherUserName,
            messageCount: 0,
            lastMessageAt: match.createdAt,
          ),
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileScreen.otherUser(
          userId: match.otherUserId,
          userName: match.otherUserName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = _primaryPhotoUrl(match.primaryPhotoUrl, match.photoUrls);
    final isActive = _isActive(match.state);
    final isNew = _isNewMatch(match);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = Color.alphaBlend(
      (isNew ? _matchRose : _matchViolet).withValues(
        alpha: isDark ? (isNew ? 0.18 : 0.12) : (isNew ? 0.07 : 0.03),
      ),
      colorScheme.surfaceContainerLow,
    );

    return ClipRRect(
      borderRadius: AppTheme.cardRadius,
      child: DecoratedBox(
        decoration: AppTheme.surfaceDecoration(
          context,
          color: cardColor,
          prominent: isNew,
        ),
        child: Stack(
          children: [
            if (isNew)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _matchPrimaryGradient(context),
                    ),
                    child: const SizedBox(width: 4),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: ValueKey('match-profile-${match.matchId}'),
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _openProfile(context),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _MatchAvatar(
                                    match: match,
                                    photoUrl: photoUrl,
                                    isActive: isActive,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _MatchSummaryBlock(
                                      match: match,
                                      isActive: isActive,
                                      isNew: isNew,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox.square(
                        dimension: 36,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(
                              alpha: isDark ? 0.72 : 0.92,
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.18),
                            ),
                          ),
                          child: SafetyActionsButton(
                            targetUserId: match.otherUserId,
                            targetUserName: match.otherUserName,
                            canUnmatch: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 6,
                        child: _GradientActionButton(
                          height: _matchActionHeight,
                          icon: Icons.forum_rounded,
                          label: 'Message',
                          onTap: () => _openConversation(context),
                        ),
                      ),
                      SizedBox(width: AppTheme.cardGap),
                      Expanded(
                        flex: 5,
                        child: SizedBox(
                          height: _matchActionHeight,
                          child: OutlinedButton.icon(
                            onPressed: () => _openProfile(context),
                            icon: const Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('View profile'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  theme.colorScheme.onSurfaceVariant,
                              side: BorderSide(
                                color: theme.colorScheme.outlineVariant
                                    .withValues(alpha: isDark ? 0.42 : 0.58),
                              ),
                              backgroundColor: Colors.transparent,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(999),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchAvatar extends StatelessWidget {
  const _MatchAvatar({
    required this.match,
    required this.photoUrl,
    required this.isActive,
  });

  final MatchSummary match;
  final String? photoUrl;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _matchPrimaryGradient(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: UserAvatar(
              name: match.otherUserName,
              photoUrl: photoUrl,
              radius: 30,
            ),
          ),
        ),
        if (isActive)
          Positioned(
            right: 4,
            bottom: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _matchMint,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: const SizedBox(width: 10, height: 10),
            ),
          ),
      ],
    );
  }
}

class _MatchSummaryBlock extends StatelessWidget {
  const _MatchSummaryBlock({
    required this.match,
    required this.isActive,
    required this.isNew,
  });

  final MatchSummary match;
  final bool isActive;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final location = match.approximateLocation;
    final activityLabel = isActive
        ? 'Active now'
        : formatDisplayLabel(match.state);
    final fallbackSummary =
        match.summaryLine ??
        match.approximateLocation ??
        'Say hi to start your first conversation.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                match.otherUserName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.matchTextPrimary(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (isNew) ...[const SizedBox(width: 6), const _NewBadge()],
          ],
        ),
        const SizedBox(height: 3),
        _FadedBio(text: fallbackSummary),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _MatchSignalPill(
              icon: Icons.favorite_rounded,
              label: 'Matched ${_formatRelativeMatchDate(match.createdAt)}',
              color: _matchRose,
            ),
            if (location != null)
              _MatchSignalPill(
                icon: Icons.location_on_outlined,
                label: location,
                color: _matchViolet,
              ),
            _MatchSignalPill(
              icon: isActive ? Icons.circle_rounded : Icons.schedule_rounded,
              label: activityLabel,
              color: isActive ? _matchMint : _matchSlate,
            ),
          ],
        ),
      ],
    );
  }
}

class _FadedBio extends StatelessWidget {
  const _FadedBio({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: AppTheme.matchTextSecondary(context),
        fontSize: 13,
        height: 1.3,
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _matchPrimaryGradient(context),
        borderRadius: AppTheme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          'NEW MATCH',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _MatchSignalPill extends StatelessWidget {
  const _MatchSignalPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.09),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.height,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final double height;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: _matchPrimaryGradient(context),
        borderRadius: AppTheme.chipRadius,
        boxShadow: [
          BoxShadow(
            color: _matchRose.withValues(alpha: 0.20),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.chipRadius,
          onTap: onTap,
          child: SizedBox(
            height: height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String? _primaryPhotoUrl(String? primaryPhotoUrl, List<String> photoUrls) {
  if (primaryPhotoUrl != null && primaryPhotoUrl.trim().isNotEmpty) {
    return primaryPhotoUrl;
  }

  return photoUrls.isEmpty ? null : photoUrls.first;
}

bool _isActive(String state) => state.trim().toUpperCase() == 'ACTIVE';

List<MatchSummary> _filteredMatches(
  List<MatchSummary> matches,
  _MatchFilter filter,
) {
  return switch (filter) {
    _MatchFilter.all => matches,
    _MatchFilter.newMatches => matches.where(_isNewMatch).toList(),
  };
}

bool _isNewMatch(MatchSummary match) {
  final elapsed = DateTime.now().difference(match.createdAt.toLocal());
  return !elapsed.isNegative && elapsed.inHours < 24;
}

LinearGradient _matchPrimaryGradient(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const LinearGradient(
          colors: [Color(0xFF5F8FB8), Color(0xFF8E6DE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : const LinearGradient(
          colors: [_matchRose, _matchViolet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
}

String _formatRelativeMatchDate(DateTime value) {
  final elapsed = DateTime.now().difference(value.toLocal());
  if (elapsed.isNegative) {
    return 'today';
  }

  if (elapsed.inDays >= 2) {
    return '${elapsed.inDays} days ago';
  }

  if (elapsed.inDays == 1) {
    return 'yesterday';
  }

  if (elapsed.inHours >= 1) {
    return '${elapsed.inHours}h ago';
  }

  return 'just now';
}
