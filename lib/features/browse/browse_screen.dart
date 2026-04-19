import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/browse_candidate.dart';
import '../../models/browse_response.dart';
import '../../models/conversation_summary.dart';
import '../../models/daily_pick.dart';
import '../../models/user_summary.dart';
import '../../shared/widgets/app_async_state.dart';
import '../chat/conversation_thread_screen.dart';
import '../home/backend_health_banner.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'browse_provider.dart';

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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BackendHealthBanner(),
              const SizedBox(height: 16),
              _CurrentUserSummary(user: widget.currentUser),
              const SizedBox(height: 16),
              Expanded(
                child: browseState.when(
                  data: (browse) => _BrowseContent(
                    browse: browse,
                    isSubmitting: _isSubmitting,
                    onLike: (candidate) => _handleLike(candidate),
                    onPass: (candidate) => _handlePass(candidate),
                    onViewProfile: (candidate) =>
                        _openCandidateProfile(candidate),
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
}

class _CurrentUserSummary extends StatelessWidget {
  const _CurrentUserSummary({required this.user});

  final UserSummary user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Browsing as ${user.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Age ${user.age} • ${user.state}'),
          ],
        ),
      ),
    );
  }
}

class _BrowseContent extends StatelessWidget {
  const _BrowseContent({
    required this.browse,
    required this.isSubmitting,
    required this.onLike,
    required this.onPass,
    required this.onViewProfile,
  });

  final BrowseResponse browse;
  final bool isSubmitting;
  final ValueChanged<BrowseCandidate> onLike;
  final ValueChanged<BrowseCandidate> onPass;
  final ValueChanged<BrowseCandidate> onViewProfile;

  @override
  Widget build(BuildContext context) {
    if (browse.candidates.isEmpty) {
      return ListView(
        children: [
          if (browse.dailyPick case final dailyPick?) ...[
            _DailyPickCard(dailyPick: dailyPick),
            const SizedBox(height: 16),
          ],
          if (browse.locationMissing) ...[
            const _LocationWarningCard(),
            const SizedBox(height: 16),
          ],
          const _BrowseEmptyCard(),
        ],
      );
    }

    final currentCandidate = browse.candidates.first;

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              if (browse.dailyPick case final dailyPick?) ...[
                _DailyPickCard(dailyPick: dailyPick),
                const SizedBox(height: 16),
              ],
              _CandidateCard(
                candidate: currentCandidate,
                onViewProfile: () => onViewProfile(currentCandidate),
              ),
              const SizedBox(height: 12),
              Text(
                '${browse.candidates.length} candidate(s) ready',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (browse.locationMissing) ...[
                const SizedBox(height: 16),
                const _LocationWarningCard(),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
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

class _BrowseEmptyCard extends StatelessWidget {
  const _BrowseEmptyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'No candidates are available right now. Try refreshing in a bit.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
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
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSubmitting ? null : () => onPass(candidate),
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Pass'),
                ),
              ),
              const SizedBox(width: 16),
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
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today\'s daily pick',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('${dailyPick.userName}, ${dailyPick.userAge}'),
            const SizedBox(height: 4),
            Text(dailyPick.reason),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    candidate.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                SafetyActionsButton(
                  targetUserId: candidate.id,
                  targetUserName: candidate.name,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Age ${candidate.age} • ${candidate.state}'),
            const SizedBox(height: 16),
            Text(
              'The current browse payload is intentionally lean. More profile richness can come after the backend DTO grows.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onViewProfile,
              icon: const Icon(Icons.person_outline_rounded),
              label: const Text('View profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationWarningCard extends StatelessWidget {
  const _LocationWarningCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.location_off_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your selected user is missing location data, so discovery results may be limited.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
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
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Browse unavailable for this user',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(message),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
