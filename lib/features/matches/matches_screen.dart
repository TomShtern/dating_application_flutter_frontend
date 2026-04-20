import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/match_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/user_avatar.dart';
import '../chat/conversation_thread_screen.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'matches_provider.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesState = ref.watch(matchesProvider);
    final matchCount = matchesState.maybeWhen(
      data: (response) => response.matches.length,
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your matches'),
        actions: [
          IconButton(
            tooltip: 'Refresh matches',
            onPressed: () => ref.read(matchesControllerProvider).refresh(),
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
              _MatchesHero(currentUser: currentUser, matchCount: matchCount),
              const SizedBox(height: 18),
              Expanded(
                child: matchesState.when(
                  data: (response) {
                    if (response.matches.isEmpty) {
                      return AppAsyncState.empty(
                        message:
                            'No matches yet. Keep exploring to find mutual likes.',
                        onRefresh: () =>
                            ref.read(matchesControllerProvider).refresh(),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(matchesControllerProvider).refresh(),
                      child: ListView.separated(
                        itemCount: response.matches.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          return _MatchCard(
                            currentUser: currentUser,
                            match: response.matches[index],
                          );
                        },
                      ),
                    );
                  },
                  loading: () =>
                      const AppAsyncState.loading(message: 'Loading matches…'),
                  error: (error, stackTrace) => AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load matches right now.',
                    onRetry: () => ref.invalidate(matchesProvider),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchesHero extends StatelessWidget {
  const _MatchesHero({required this.currentUser, this.matchCount});

  final UserSummary currentUser;
  final int? matchCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final countLabel = switch (matchCount) {
      null => 'Syncing matches',
      1 => '1 mutual connection',
      final count => '$count mutual connections',
    };

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: AppTheme.heroGradient(context),
        prominent: true,
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MatchBadge(
              icon: Icons.favorite_rounded,
              label: 'Mutual spark',
            ),
            const SizedBox(height: 16),
            Text(
              'Mutual matches for ${currentUser.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'These are the strongest signals in the app, so they deserve more visual love than a plain list.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MatchBadge(icon: Icons.bolt_rounded, label: countLabel),
                _MatchBadge(
                  icon: Icons.schedule_rounded,
                  label: 'Freshest mutual likes first',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  const _MatchBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: AppTheme.glassDecoration(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.currentUser, required this.match});

  final UserSummary currentUser;
  final MatchSummary match;

  void _openConversation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ConversationThreadScreen(
          currentUser: currentUser,
          conversation: ConversationSummary(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.cardRadius,
          onTap: () => _openConversation(context),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(name: match.otherUserName, radius: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.otherUserName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mutual interest is already locked in — all that is left is saying hello.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'View profile',
                      onPressed: () => _openProfile(context),
                      icon: const Icon(Icons.person_outline_rounded),
                    ),
                    SafetyActionsButton(
                      targetUserId: match.otherUserId,
                      targetUserName: match.otherUserName,
                      canUnmatch: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MatchBadge(
                      icon: Icons.favorite_border_rounded,
                      label: 'Matched on ${formatShortDate(match.createdAt)}',
                    ),
                    _MatchBadge(
                      icon: Icons.verified_user_outlined,
                      label: match.state,
                    ),
                    const _MatchBadge(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Ready to message',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => _openConversation(context),
                  icon: const Icon(Icons.forum_rounded),
                  label: const Text('Message now'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
