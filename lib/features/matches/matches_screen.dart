import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/match_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../chat/conversation_thread_screen.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'matches_provider.dart';

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
    final heroDescription = switch (matchesState) {
      AsyncData(:final value) when value.matches.isEmpty =>
        'New mutual likes will appear here.',
      AsyncData(:final value) =>
        '${value.matches.length} ${value.matches.length == 1 ? 'match' : 'matches'} so far',
      _ => 'Your matches',
    };

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShellHero(
            compact: true,
            eyebrowLabel: 'Connections',
            header: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Refresh matches',
                  onPressed: () => ref.invalidate(matchesProvider),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            title: 'Your matches',
            description: heroDescription,
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
                      padding: AppTheme.screenPadding(),
                      children: [
                        AppAsyncState.empty(
                          message: _emptyMatchesMessage(_selectedFilter),
                          onRefresh: controller.refresh,
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppTheme.screenPadding(),
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
                  padding: AppTheme.screenPadding(),
                  children: const [
                    AppAsyncState.loading(message: 'Loading matches...'),
                  ],
                ),
                error: (error, stackTrace) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppTheme.screenPadding(),
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

class _MatchFilterRow extends StatelessWidget {
  const _MatchFilterRow({
    required this.selectedFilter,
    required this.onSelected,
  });

  final _MatchFilter selectedFilter;
  final ValueChanged<_MatchFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
    return Material(
      color: selected
          ? AppTheme.matchAccent(context).withValues(alpha: 0.12)
          : Theme.of(context).colorScheme.surface,
      borderRadius: AppTheme.chipRadius,
      child: InkWell(
        borderRadius: AppTheme.chipRadius,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: AppTheme.chipRadius,
            border: Border.all(
              color: selected
                  ? AppTheme.matchAccent(context).withValues(alpha: 0.36)
                  : Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? AppTheme.matchAccent(context)
                    : AppTheme.matchTextSecondary(context),
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
  static const double _matchActionHeight = 44;

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

    return ClipRRect(
      borderRadius: AppTheme.cardRadius,
      child: DecoratedBox(
        decoration: AppTheme.surfaceDecoration(context),
        child: Stack(
          children: [
            if (isNew)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppTheme.accentGradient(context),
                    ),
                    child: const SizedBox(width: 3),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(AppTheme.cardPadding),
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
                                  const SizedBox(width: 14),
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
                        dimension: 32,
                        child: SafetyActionsButton(
                          targetUserId: match.otherUserId,
                          targetUserName: match.otherUserName,
                          canUnmatch: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _GradientActionButton(
                          height: _matchActionHeight,
                          icon: Icons.forum_rounded,
                          label: 'Message',
                          onTap: () => _openConversation(context),
                        ),
                      ),
                      SizedBox(width: AppTheme.cardGap),
                      Expanded(
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
                              foregroundColor: AppTheme.matchAccent(context),
                              side: BorderSide(
                                color: AppTheme.matchAccent(
                                  context,
                                ).withValues(alpha: 0.4),
                              ),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(999),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
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
            gradient: AppTheme.accentGradient(context),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: UserAvatar(
              name: match.otherUserName,
              photoUrl: photoUrl,
              radius: 45,
            ),
          ),
        ),
        if (isActive)
          Positioned(
            right: 4,
            bottom: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.activeColor(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 2,
                ),
              ),
              child: const SizedBox(width: 12, height: 12),
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
            if (isNew) ...[const SizedBox(width: 8), const _NewBadge()],
          ],
        ),
        const SizedBox(height: 4),
        _FadedBio(
          text:
              match.summaryLine ??
              match.approximateLocation ??
              'Matched ${_formatRelativeMatchDate(match.createdAt)}',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              Icons.favorite_rounded,
              color: AppTheme.matchAccent(context),
              size: 17,
              shadows: const [
                Shadow(
                  color: Color(0x33E91E8C),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Matched ${_formatRelativeMatchDate(match.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.matchTextTertiary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 7,
          runSpacing: 4,
          children: [
            if (location != null) ...[
              Icon(
                Icons.location_on_rounded,
                color: AppTheme.matchTextTertiary(context),
                size: 15,
              ),
              Text(
                location,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.matchTextTertiary(context),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              Text(
                '·',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.matchTextTertiary(context),
                ),
              ),
            ],
            if (isActive)
              const _InlineDot()
            else
              Icon(
                Icons.circle_outlined,
                color: AppTheme.matchTextTertiary(context),
                size: 10,
              ),
            Text(
              isActive ? 'Active now' : formatDisplayLabel(match.state),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isActive
                    ? AppTheme.activeColor(context)
                    : AppTheme.matchTextTertiary(context),
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
              ),
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
    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.82, 1],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppTheme.matchTextSecondary(context),
          fontSize: 13,
          height: 1.28,
          letterSpacing: 0,
        ),
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
        gradient: AppTheme.accentGradient(context),
        borderRadius: AppTheme.chipRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          'NEW',
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

class _InlineDot extends StatelessWidget {
  const _InlineDot();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.activeColor(context),
        shape: BoxShape.circle,
      ),
      child: const SizedBox(width: 8, height: 8),
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
        gradient: AppTheme.accentGradient(context),
        borderRadius: AppTheme.chipRadius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.matchAccent(context).withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 5),
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

String _emptyMatchesMessage(_MatchFilter filter) {
  return switch (filter) {
    _MatchFilter.all =>
      'No matches yet — keep liking profiles you connect with.',
    _MatchFilter.newMatches => 'No new matches right now.',
  };
}

bool _isNewMatch(MatchSummary match) {
  final elapsed = DateTime.now().difference(match.createdAt.toLocal());
  return !elapsed.isNegative && elapsed.inHours < 24;
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
