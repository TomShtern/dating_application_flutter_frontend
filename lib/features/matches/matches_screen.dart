import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/match_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/shell_hero.dart';
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
          padding: AppTheme.screenPadding(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                            SizedBox(height: AppTheme.listSpacing()),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(name: match.otherUserName, radius: 28),
                    const SizedBox(width: 12),
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
                            'Mutual interest is already there — now it is time for a real hello.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    SafetyActionsButton(
                      targetUserId: match.otherUserId,
                      targetUserName: match.otherUserName,
                      canUnmatch: true,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ShellHeroPill(
                      icon: Icons.favorite_border_rounded,
                      label: 'Matched ${formatShortDate(match.createdAt)}',
                    ),
                    ShellHeroPill(
                      icon: Icons.verified_user_outlined,
                      label: formatDisplayLabel(match.state),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _openConversation(context),
                      icon: const Icon(Icons.forum_rounded),
                      label: const Text('Message now'),
                    ),
                    TextButton.icon(
                      onPressed: () => _openProfile(context),
                      icon: const Icon(Icons.person_outline_rounded),
                      label: const Text('View profile'),
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
