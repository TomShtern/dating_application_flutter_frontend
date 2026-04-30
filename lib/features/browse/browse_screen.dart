import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/browse_candidate.dart';
import '../../models/browse_response.dart';
import '../../models/conversation_summary.dart';
import '../../models/daily_pick.dart';
import '../../models/profile_presentation_context.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/developer_only_callout_card.dart';
import '../../shared/widgets/person_media_thumbnail.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/shell_hero.dart';
import '../chat/conversation_thread_screen.dart';
import '../home/backend_health_banner.dart';
import '../location/location_completion_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_provider.dart';
import '../safety/safety_action_sheet.dart';
import 'pending_likers_screen.dart';
import 'browse_provider.dart';
import 'standouts_screen.dart';

const _browseRose = Color(0xFFE24A68);
const _browseAmber = Color(0xFFD98914);
const _browseTeal = Color(0xFF009688);
const _browseSky = Color(0xFF188DC8);
const _browseMint = Color(0xFF16A871);
const _browseSlate = Color(0xFF596579);

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final browseState = ref.watch(browseProvider);
    final browseData = browseState.asData?.value;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 520;
            final sectionSpacing = compact ? 10.0 : 12.0;

            return Padding(
              padding: AppTheme.screenPadding(compact: compact),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BrowseIntroCard(
                    currentUserName: widget.currentUser.name,
                    candidateCount: browseData?.candidates.length,
                    hasDailyPick: browseData?.dailyPick != null,
                    locationMissing: browseData?.locationMissing ?? false,
                    onUndo: _handleUndo,
                    onRefresh: () =>
                        ref.read(browseControllerProvider).refresh(),
                    actionsDisabled: _isSubmitting,
                  ),
                  SizedBox(height: sectionSpacing),
                  Expanded(
                    child: browseState.when(
                      data: (browse) => _BrowseContent(
                        browse: browse,
                        developerPanel: _DeveloperSessionPanel(
                          user: widget.currentUser,
                        ),
                        isSubmitting: _isSubmitting,
                        onLike: (candidate) => _handleLike(candidate),
                        onPass: (candidate) => _handlePass(candidate),
                        onViewProfile: (candidate) =>
                            _openCandidateProfile(candidate),
                        onOpenPendingLikers: () => _openPendingLikers(),
                        onOpenStandouts: () => _openStandouts(),
                        onFixLocation: () => _openLocationCompletion(),
                        onRefresh: () =>
                            ref.read(browseControllerProvider).refresh(),
                      ),
                      loading: () => const AppAsyncState.loading(
                        message: 'Loading candidates…',
                      ),
                      error: (error, stackTrace) {
                        if (error is ApiError && error.statusCode == 409) {
                          return _BrowseConflictState(
                            message: error.message,
                            onRetry: () => ref.invalidate(browseProvider),
                          );
                        }

                        final message = error is ApiError
                            ? error.message
                            : 'Unable to load browse candidates right now.';
                        return AppAsyncState.error(
                          message: message,
                          onRetry: () => ref.invalidate(browseProvider),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleLike(BrowseCandidate candidate) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ref
          .read(browseControllerProvider)
          .likeCandidate(candidate.id);

      if (!mounted) {
        return;
      }

      final message = result.isMatch && result.matchedUserName != null
          ? 'It\'s a match with ${result.matchedUserName}!'
          : result.message;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          action: result.isMatch && result.matchId != null
              ? SnackBarAction(
                  label: 'Message now',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => ConversationThreadScreen(
                          currentUser: widget.currentUser,
                          conversation: ConversationSummary(
                            // Stage A backend contract: matchId is the live
                            // conversation id and can be used directly.
                            id: result.matchId!,
                            otherUserId: result.matchedUserId ?? candidate.id,
                            otherUserName:
                                result.matchedUserName ?? candidate.name,
                            messageCount: 0,
                            lastMessageAt: DateTime.now(),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : null,
        ),
      );
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handlePass(BrowseCandidate candidate) async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final message = await ref
          .read(browseControllerProvider)
          .passCandidate(candidate.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _handleUndo() async {
    if (_isSubmitting) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ref.read(browseControllerProvider).undoLastSwipe();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _openCandidateProfile(BrowseCandidate candidate) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProfileScreen.otherUser(
          userId: candidate.id,
          userName: candidate.name,
        ),
      ),
    );
  }

  Future<void> _openStandouts() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const StandoutsScreen()),
    );
  }

  Future<void> _openPendingLikers() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const PendingLikersScreen(),
      ),
    );
  }

  Future<void> _openLocationCompletion() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const LocationCompletionScreen(),
      ),
    );
  }
}

class _BrowseIntroCard extends StatelessWidget {
  const _BrowseIntroCard({
    required this.currentUserName,
    required this.candidateCount,
    required this.hasDailyPick,
    required this.locationMissing,
    required this.onUndo,
    required this.onRefresh,
    required this.actionsDisabled,
  });

  final String currentUserName;
  final int? candidateCount;
  final bool hasDailyPick;
  final bool locationMissing;
  final VoidCallback onUndo;
  final VoidCallback onRefresh;
  final bool actionsDisabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final description = switch (candidateCount) {
      null => 'Refreshing the next profiles for you.',
      0 => 'No one new is ready right now. Refresh for the latest candidates.',
      final count =>
        '$count ${count == 1 ? 'candidate is' : 'candidates are'} ready to browse.',
    };

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF252534), Color(0xFF1E313A), Color(0xFF343226)]
              : const [Color(0xFFFFF3E6), Color(0xFFEAF6FF), Color(0xFFF4F0FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
                    color: _browseRose.withValues(alpha: isDark ? 0.20 : 0.12),
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                  ),
                  child: SizedBox.square(
                    dimension: 40,
                    child: Icon(
                      Icons.favorite_outline_rounded,
                      color: isDark ? const Color(0xFFFFC4D0) : _browseRose,
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
                        'Discover',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(description, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Refresh browse',
                  onPressed: actionsDisabled ? null : onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BrowseStatusPill(
                  icon: Icons.favorite_outline_rounded,
                  label: 'Browsing as $currentUserName',
                  color: _browseRose,
                ),
                if (candidateCount != null)
                  _BrowseStatusPill(
                    icon: Icons.people_outline_rounded,
                    label: '$candidateCount ready now',
                    color: _browseSky,
                  ),
                if (hasDailyPick)
                  const _BrowseStatusPill(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Today\'s daily pick',
                    color: _browseAmber,
                  ),
                if (locationMissing)
                  const _BrowseStatusPill(
                    icon: Icons.location_off_outlined,
                    label: 'Location incomplete',
                    color: _browseMint,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: actionsDisabled ? null : onUndo,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: const Text('Undo last swipe'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseStatusPill extends StatelessWidget {
  const _BrowseStatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.18 : 0.10,
        ),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
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

class _DeveloperSessionPanel extends StatelessWidget {
  const _DeveloperSessionPanel({required this.user});

  final UserSummary user;

  @override
  Widget build(BuildContext context) {
    return DeveloperOnlyCalloutCard(
      title: 'Browse diagnostics',
      description:
          '${user.name} is active on this device. Expand this only when you need backend/system health while testing.',
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: 12),
          leading: const Icon(Icons.monitor_heart_outlined),
          title: const Text('Connection status'),
          children: [
            const BackendHealthBanner(),
            const SizedBox(height: 12),
            Text(
              'Check connection health without pulling attention away from the next profile.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseContent extends StatelessWidget {
  const _BrowseContent({
    required this.browse,
    required this.developerPanel,
    required this.isSubmitting,
    required this.onLike,
    required this.onPass,
    required this.onViewProfile,
    required this.onOpenPendingLikers,
    required this.onOpenStandouts,
    required this.onFixLocation,
    required this.onRefresh,
  });

  final BrowseResponse browse;
  final Widget developerPanel;
  final bool isSubmitting;
  final ValueChanged<BrowseCandidate> onLike;
  final ValueChanged<BrowseCandidate> onPass;
  final ValueChanged<BrowseCandidate> onViewProfile;
  final VoidCallback onOpenPendingLikers;
  final VoidCallback onOpenStandouts;
  final VoidCallback onFixLocation;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    if (browse.candidates.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: [
            if (browse.dailyPick case final dailyPick?) ...[
              _DailyPickCard(dailyPick: dailyPick),
              SizedBox(height: AppTheme.listSpacing()),
            ],
            const _BrowseEmptyCard(),
            SizedBox(height: AppTheme.listSpacing()),
            if (browse.locationMissing) ...[
              _LocationWarningCard(onPressed: onFixLocation),
              SizedBox(height: AppTheme.listSpacing()),
            ],
            _DiscoveryShortcutRow(
              onOpenPendingLikers: onOpenPendingLikers,
              onOpenStandouts: onOpenStandouts,
            ),
            SizedBox(height: AppTheme.listSpacing()),
            developerPanel,
          ],
        ),
      );
    }

    final currentCandidate = browse.candidates.first;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: ListView(
              children: [
                Dismissible(
                  key: ValueKey(currentCandidate.id),
                  direction: isSubmitting
                      ? DismissDirection.none
                      : DismissDirection.horizontal,
                  background: const _SwipeCue(
                    alignment: Alignment.centerLeft,
                    icon: Icons.favorite_rounded,
                    label: 'Like',
                  ),
                  secondaryBackground: const _SwipeCue(
                    alignment: Alignment.centerRight,
                    icon: Icons.close_rounded,
                    label: 'Pass',
                  ),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      onLike(currentCandidate);
                    } else {
                      onPass(currentCandidate);
                    }

                    return false;
                  },
                  child: _CandidateCard(
                    candidate: currentCandidate,
                    remainingCount: browse.candidates.length,
                    onViewProfile: () => onViewProfile(currentCandidate),
                  ),
                ),
                const SizedBox(height: AppTheme.navBarHeight),
                SizedBox(height: AppTheme.listSpacing()),
                if (browse.dailyPick case final dailyPick?) ...[
                  _DailyPickCard(dailyPick: dailyPick),
                  SizedBox(height: AppTheme.listSpacing()),
                ],
                _DiscoveryShortcutRow(
                  onOpenPendingLikers: onOpenPendingLikers,
                  onOpenStandouts: onOpenStandouts,
                ),
                if (browse.locationMissing) ...[
                  SizedBox(height: AppTheme.listSpacing()),
                  _LocationWarningCard(onPressed: onFixLocation),
                ],
                SizedBox(height: AppTheme.listSpacing()),
                developerPanel,
              ],
            ),
          ),
        ),
        SizedBox(height: AppTheme.listSpacing()),
        _BrowseActionBar(
          candidate: currentCandidate,
          isSubmitting: isSubmitting,
          onLike: onLike,
          onPass: onPass,
        ),
      ],
    );
  }
}

class _DiscoveryShortcutRow extends StatelessWidget {
  const _DiscoveryShortcutRow({
    required this.onOpenPendingLikers,
    required this.onOpenStandouts,
  });

  final VoidCallback onOpenPendingLikers;
  final VoidCallback onOpenStandouts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DiscoveryShortcutCard(
            icon: Icons.favorite_rounded,
            accentColor: _browseRose,
            title: 'Likes you',
            subtitle: 'See who is already interested',
            onTap: onOpenPendingLikers,
          ),
        ),
        SizedBox(width: AppTheme.listSpacing()),
        Expanded(
          child: _DiscoveryShortcutCard(
            icon: Icons.auto_awesome_rounded,
            accentColor: _browseAmber,
            title: 'Standouts',
            subtitle: 'Jump to the strongest signals',
            onTap: onOpenStandouts,
          ),
        ),
      ],
    );
  }
}

class _DiscoveryShortcutCard extends StatelessWidget {
  const _DiscoveryShortcutCard({
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      borderRadius: AppTheme.cardRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: AppTheme.cardRadius,
        onTap: onTap,
        child: Ink(
          decoration: AppTheme.surfaceDecoration(
            context,
            color: Color.alphaBlend(
              accentColor.withValues(alpha: isDark ? 0.14 : 0.07),
              colorScheme.surfaceContainerLow,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                  ),
                  child: SizedBox.square(
                    dimension: 38,
                    child: Icon(icon, color: accentColor, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowseEmptyCard extends StatelessWidget {
  const _BrowseEmptyCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: LinearGradient(
          colors: [colorScheme.surface, colorScheme.surfaceContainerLow],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const ShellHeroPill(
              icon: Icons.coffee_rounded,
              label: 'Quiet moment',
            ),
            const SizedBox(height: 14),
            Text(
              'Nothing new is ready just yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No candidates are available right now. Try refreshing in a bit.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseActionBar extends StatelessWidget {
  const _BrowseActionBar({
    required this.candidate,
    required this.isSubmitting,
    required this.onLike,
    required this.onPass,
  });

  final BrowseCandidate candidate;
  final bool isSubmitting;
  final ValueChanged<BrowseCandidate> onLike;
  final ValueChanged<BrowseCandidate> onPass;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: AppTheme.surfaceDecoration(
          context,
          color: Color.alphaBlend(
            _browseSky.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.08 : 0.03,
            ),
            Color.alphaBlend(
              _browseAmber.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.05 : 0.02,
              ),
              colorScheme.surface.withValues(alpha: 0.95),
            ),
          ),
          borderRadius: AppTheme.panelRadius,
          prominent: true,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSubmitting ? null : () => onPass(candidate),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: theme.brightness == Brightness.dark
                        ? const Color(0xFFD6E4EF)
                        : const Color(0xFF4E6478),
                    side: BorderSide(color: _browseSky.withValues(alpha: 0.22)),
                    backgroundColor: theme.brightness == Brightness.dark
                        ? _browseSky.withValues(alpha: 0.12)
                        : _browseSky.withValues(alpha: 0.05),
                  ),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Pass'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : () => onLike(candidate),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: _browseRose,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.favorite_rounded),
                  label: const Text('Like'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyPickCard extends StatelessWidget {
  const _DailyPickCard({required this.dailyPick});

  final DailyPick dailyPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final headline = dailyPick.alreadySeen
        ? 'Already seen today'
        : 'Featured for today';
    final supportingLine = [
      dailyPick.approximateLocation,
      dailyPick.summaryLine,
    ].whereType<String>().join(' · ');

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _browseRose.withValues(alpha: isDark ? 0.08 : 0.03),
          Color.alphaBlend(
            _browseAmber.withValues(alpha: isDark ? 0.18 : 0.09),
            colorScheme.surfaceContainerLow,
          ),
        ),
        prominent: true,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                const _BrowseStatusPill(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Today\'s daily pick',
                  color: _browseAmber,
                ),
                if (dailyPick.alreadySeen)
                  const _BrowseStatusPill(
                    icon: Icons.visibility_outlined,
                    label: 'Already seen',
                    color: _browseSlate,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PersonMediaThumbnail(
                  key: ValueKey('daily-pick-media-${dailyPick.userId}'),
                  name: dailyPick.userName,
                  photoUrl: _primaryPhotoUrl(
                    dailyPick.primaryPhotoUrl,
                    dailyPick.photoUrls,
                  ),
                  width: 72,
                  height: 88,
                  borderRadius: AppTheme.cardRadius,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${dailyPick.userName}, ${dailyPick.userAge}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        headline,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (supportingLine.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          supportingLine,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends ConsumerWidget {
  const _CandidateCard({
    required this.candidate,
    required this.remainingCount,
    required this.onViewProfile,
  });

  final BrowseCandidate candidate;
  final int remainingCount;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final presentationContextState = ref.watch(
      presentationContextProvider(candidate.id),
    );
    final photoUrl = _primaryPhotoUrl(
      candidate.primaryPhotoUrl,
      candidate.photoUrls,
    );
    final stateColor = candidate.state.toLowerCase() == 'active'
        ? _browseMint
        : _browseSlate;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _browseSky.withValues(alpha: isDark ? 0.10 : 0.035),
          Color.alphaBlend(
            _browseAmber.withValues(alpha: isDark ? 0.05 : 0.025),
            colorScheme.surfaceContainerLow,
          ),
        ),
        prominent: true,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                PersonMediaThumbnail(
                  key: ValueKey('browse-candidate-media-${candidate.id}'),
                  name: candidate.name,
                  photoUrl: photoUrl,
                  width: double.infinity,
                  height: 220,
                  borderRadius: const BorderRadius.all(Radius.circular(26)),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _BrowseQueuePill(
                        label: remainingCount > 1
                            ? '1 of $remainingCount ready'
                            : 'Ready now',
                        color: _browseSky,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: SafetyActionsButton(
                    targetUserId: candidate.id,
                    targetUserName: candidate.name,
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: photoUrl == null
                          ? const Color(
                              0xFF6A7E90,
                            ).withValues(alpha: isDark ? 0.52 : 0.36)
                          : Colors.black.withValues(alpha: 0.24),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: photoUrl == null ? 0.18 : 0.12,
                        ),
                      ),
                      borderRadius: const BorderRadius.all(Radius.circular(22)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidate.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              if (candidate.age > 0)
                                Text(
                                  'Age ${candidate.age}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                              if (candidate.approximateLocation != null)
                                Text(
                                  candidate.approximateLocation!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.92),
                                  ),
                                ),
                            ],
                          ),
                          if (candidate.summaryLine != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              candidate.summaryLine!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.listSpacing()),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BrowseStatusPill(
                  icon: Icons.person_outline_rounded,
                  label: formatDisplayLabel(candidate.state),
                  color: stateColor,
                ),
                if (candidate.approximateLocation != null)
                  _BrowseStatusPill(
                    icon: Icons.location_on_outlined,
                    label: candidate.approximateLocation!,
                    color: _browseSky,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onViewProfile,
                style: TextButton.styleFrom(foregroundColor: _browseTeal),
                icon: const Icon(Icons.person_outline_rounded),
                label: const Text('See full profile'),
              ),
            ),
            SizedBox(height: AppTheme.listSpacing(compact: true)),
            _BrowsePresentationContext(state: presentationContextState),
          ],
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

class _BrowsePresentationContext extends StatelessWidget {
  const _BrowsePresentationContext({required this.state});

  final AsyncValue<ProfilePresentationContext> state;

  @override
  Widget build(BuildContext context) {
    return state.when(
      data: (contextData) =>
          _BrowsePresentationContextContent(contextData: contextData),
      loading: () => const _BrowseWhyPlaceholder(
        message: 'Loading recommendation context...',
      ),
      error: (error, stackTrace) => const _BrowseWhyPlaceholder(
        message: 'Recommendation context is unavailable right now.',
      ),
    );
  }
}

class _BrowsePresentationContextContent extends StatelessWidget {
  const _BrowsePresentationContextContent({required this.contextData});

  final ProfilePresentationContext contextData;

  @override
  Widget build(BuildContext context) {
    final tags = contextData.reasonTags
        .map(formatDisplayLabel)
        .toList(growable: false);
    final visibleTags = tags.take(3).toList(growable: false);
    final remainingTagCount = tags.length - visibleTags.length;

    return _BrowseInlineReasonSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrowseReasonHeader(),
          const SizedBox(height: 6),
          Text(contextData.summary),
          if (visibleTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in visibleTags) _BrowseReasonTag(label: tag),
                if (remainingTagCount > 0)
                  _BrowseReasonTag(
                    label: '+$remainingTagCount more',
                    muted: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BrowseWhyPlaceholder extends StatelessWidget {
  const _BrowseWhyPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _BrowseInlineReasonSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrowseReasonHeader(),
          const SizedBox(height: 6),
          Text(message),
        ],
      ),
    );
  }
}

class _BrowseInlineReasonSection extends StatelessWidget {
  const _BrowseInlineReasonSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.only(left: 12, top: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _browseSky.withValues(alpha: 0.10)),
          left: BorderSide(
            color: _browseSky.withValues(alpha: isDark ? 0.34 : 0.22),
            width: 3,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _BrowseReasonHeader extends StatelessWidget {
  const _BrowseReasonHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.lightbulb_outline_rounded, size: 16, color: _browseSky),
        const SizedBox(width: 8),
        Text(
          'Why this profile is shown',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: _browseSky,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BrowseReasonTag extends StatelessWidget {
  const _BrowseReasonTag({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final color = muted ? _browseSlate : _browseSky;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BrowseQueuePill extends StatelessWidget {
  const _BrowseQueuePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
        ),
      ),
    );
  }
}

class _LocationWarningCard extends StatelessWidget {
  const _LocationWarningCard({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.64),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.location_off_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Add your location to unlock stronger recommendations and better nearby matches.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onPressed,
                icon: const Icon(Icons.edit_location_alt_outlined),
                label: const Text('Fix location'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeCue extends StatelessWidget {
  const _SwipeCue({
    required this.alignment,
    required this.icon,
    required this.label,
  });

  final Alignment alignment;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: alignment == Alignment.centerLeft
            ? _browseRose.withValues(alpha: 0.12)
            : _browseSlate.withValues(alpha: 0.12),
        borderRadius: AppTheme.cardRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: alignment == Alignment.centerLeft
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            if (alignment == Alignment.centerRight) ...[
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
            ],
            Icon(icon),
            if (alignment == Alignment.centerLeft) ...[
              const SizedBox(width: 8),
              Text(label, style: Theme.of(context).textTheme.titleMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrowseConflictState extends StatelessWidget {
  const _BrowseConflictState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: DecoratedBox(
          decoration: AppTheme.surfaceDecoration(
            context,
            gradient: AppTheme.heroGradient(context),
            prominent: true,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShellHeroPill(
                  icon: Icons.lock_outline_rounded,
                  label: 'Profile conflict',
                ),
                const SizedBox(height: 16),
                Text(
                  'Browse unavailable for this user',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(message),
                const SizedBox(height: 18),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
