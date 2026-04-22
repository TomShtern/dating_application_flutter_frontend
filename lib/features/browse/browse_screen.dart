import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/browse_candidate.dart';
import '../../models/browse_response.dart';
import '../../models/conversation_summary.dart';
import '../../models/daily_pick.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/display_text.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../shared/widgets/user_avatar.dart';
import '../chat/conversation_thread_screen.dart';
import '../home/backend_health_banner.dart';
import '../location/location_completion_screen.dart';
import '../profile/profile_screen.dart';
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

class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _DeveloperSessionPanel extends StatelessWidget {
  const _DeveloperSessionPanel({required this.user});

  final UserSummary user;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: colorScheme.surface.withValues(alpha: 0.8),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Icon(
            Icons.monitor_heart_outlined,
            color: colorScheme.primary,
          ),
          title: const Text('Connection status'),
          subtitle: Text('${user.name} is active on this device'),
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

class _DailyPickCard extends StatelessWidget {
  const _DailyPickCard({required this.dailyPick});

  final DailyPick dailyPick;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                UserAvatar(name: dailyPick.userName, radius: 22),
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
                        'Featured for you because ${dailyPick.reason}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
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

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate, required this.onViewProfile});

  final BrowseCandidate candidate;
  final VoidCallback onViewProfile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 208),
              padding: const EdgeInsets.all(18),
              decoration: AppTheme.surfaceDecoration(
                context,
                gradient: AppTheme.accentGradient(context),
                borderRadius: const BorderRadius.all(Radius.circular(26)),
                prominent: true,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: -20,
                    right: -8,
                    child: _AmbientGlow(
                      size: 74,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  Positioned(
                    bottom: -18,
                    left: -12,
                    child: _AmbientGlow(
                      size: 56,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: AppTheme.chipRadius,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Text(
                                'New for you',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: Colors.white),
                              ),
                            ),
                          ),
                          const Spacer(),
                          SafetyActionsButton(
                            targetUserId: candidate.id,
                            targetUserName: candidate.name,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      UserAvatar(name: candidate.name, radius: 30),
                      const SizedBox(height: 12),
                      Text(
                        candidate.name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Age ${candidate.age}',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                          Text(
                            '${formatDisplayLabel(candidate.state)} profile',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
