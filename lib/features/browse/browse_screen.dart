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
import '../../shared/widgets/highlight_tag_row.dart';
import '../../shared/widgets/developer_only_callout_card.dart';
import '../../shared/widgets/person_media_thumbnail.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../shared/widgets/user_avatar.dart';
import '../chat/conversation_thread_screen.dart';
import '../home/backend_health_banner.dart';
import '../location/location_completion_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/profile_provider.dart';
import '../safety/safety_action_sheet.dart';
import 'pending_likers_screen.dart';
import 'browse_provider.dart';
import 'standouts_screen.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          IconButton(
            tooltip: 'Undo last swipe',
            onPressed: _isSubmitting ? null : _handleUndo,
            icon: const Icon(Icons.undo_rounded),
          ),
          IconButton(
            tooltip: 'Refresh browse',
            onPressed: () => ref.read(browseControllerProvider).refresh(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
                  ShellHero(
                    compact: true,
                    title: '',
                    description:
                        'Swipe on a profile or open it for more detail.',
                    badges: [
                      ShellHeroPill(
                        icon: Icons.favorite_outline_rounded,
                        label: 'Browsing as ${widget.currentUser.name}',
                      ),
                    ],
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
                if (browse.dailyPick case final dailyPick?) ...[
                  _DailyPickCard(dailyPick: dailyPick),
                  SizedBox(height: AppTheme.listSpacing()),
                ],
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
                    onViewProfile: () => onViewProfile(currentCandidate),
                  ),
                ),
                SizedBox(height: AppTheme.listSpacing()),
                _DiscoveryShortcutRow(
                  onOpenPendingLikers: onOpenPendingLikers,
                  onOpenStandouts: onOpenStandouts,
                ),
                const SizedBox(height: 6),
                Text(
                  '${browse.candidates.length} candidate(s) ready',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
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
            icon: Icons.favorite_border_rounded,
            title: 'Likes you',
            subtitle: 'See who is already interested',
            onTap: onOpenPendingLikers,
          ),
        ),
        SizedBox(width: AppTheme.listSpacing()),
        Expanded(
          child: _DiscoveryShortcutCard(
            icon: Icons.auto_awesome_rounded,
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
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(context),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.cardRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(height: 10),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
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
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: AppTheme.surfaceDecoration(
          context,
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
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
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Pass'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSubmitting ? null : () => onLike(candidate),
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

class _DailyPickCard extends ConsumerWidget {
  const _DailyPickCard({required this.dailyPick});

  final DailyPick dailyPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final presentationContextState = ref.watch(
      presentationContextProvider(dailyPick.userId),
    );

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: AppTheme.heroGradient(context),
        prominent: true,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShellHeroPill(
              icon: Icons.auto_awesome_rounded,
              label: 'Today\'s daily pick',
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                  name: dailyPick.userName,
                  photoUrl: _primaryPhotoUrl(
                    dailyPick.primaryPhotoUrl,
                    dailyPick.photoUrls,
                  ),
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${dailyPick.userName}, ${dailyPick.userAge}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dailyPick.alreadySeen
                            ? 'Already seen today'
                            : 'Featured for today',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (dailyPick.approximateLocation != null ||
                          dailyPick.summaryLine != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          [
                            dailyPick.approximateLocation,
                            dailyPick.summaryLine,
                          ].whereType<String>().join(' · '),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BrowsePresentationContext(state: presentationContextState),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends ConsumerWidget {
  const _CandidateCard({required this.candidate, required this.onViewProfile});

  final BrowseCandidate candidate;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presentationContextState = ref.watch(
      presentationContextProvider(candidate.id),
    );
    final photoUrl = _primaryPhotoUrl(
      candidate.primaryPhotoUrl,
      candidate.photoUrls,
    );

    return Card(
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
                  height: 248,
                  borderRadius: const BorderRadius.all(Radius.circular(26)),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: AppTheme.chipRadius,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text('New for you'),
                    ),
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
                      color: Colors.black.withValues(alpha: 0.26),
                      borderRadius: const BorderRadius.all(Radius.circular(22)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            candidate.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 10,
                            runSpacing: 4,
                            children: [
                              if (candidate.age > 0)
                                Text(
                                  'Age ${candidate.age}',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                      ),
                                ),
                              if (candidate.approximateLocation != null)
                                Text(
                                  candidate.approximateLocation!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.92,
                                        ),
                                      ),
                                ),
                            ],
                          ),
                          if (candidate.summaryLine != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              candidate.summaryLine!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
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
            _BrowsePresentationContext(state: presentationContextState),
            SizedBox(height: AppTheme.listSpacing()),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewProfile,
                    icon: const Icon(Icons.person_outline_rounded),
                    label: const Text('See full profile'),
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
    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why this profile is shown',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(contextData.summary),
            if (contextData.reasonTags.isNotEmpty) ...[
              const SizedBox(height: 10),
              HighlightTagRow(
                tags: contextData.reasonTags
                    .map(formatDisplayLabel)
                    .toList(growable: false),
                icon: Icons.sell_outlined,
              ),
            ],
            if (contextData.details.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...contextData.details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(detail),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrowseWhyPlaceholder extends StatelessWidget {
  const _BrowseWhyPlaceholder({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Why this profile is shown',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Text(message),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final gradient = alignment == Alignment.centerLeft
        ? LinearGradient(
            colors: [
              colorScheme.primaryContainer,
              colorScheme.tertiaryContainer,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [
              colorScheme.secondaryContainer,
              colorScheme.surfaceContainerHighest,
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          );

    return Container(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: gradient,
        borderRadius: AppTheme.cardRadius,
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
