import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/match_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mutual matches for ${currentUser.name}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: matchesState.when(
                  data: (response) {
                    if (response.matches.isEmpty) {
                      return const AppAsyncState.empty(
                        message:
                            'No matches yet. Keep exploring to find mutual likes.',
                      );
                    }

                    return ListView.separated(
                      itemCount: response.matches.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _MatchCard(
                          currentUser: currentUser,
                          match: response.matches[index],
                        );
                      },
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

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.favorite_rounded)),
        title: Text(match.otherUserName),
        subtitle: Text(
          'Matched on ${formatShortDate(match.createdAt)} • ${match.state}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'View profile',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ProfileScreen.otherUser(
                      userId: match.otherUserId,
                      userName: match.otherUserName,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_outline_rounded),
            ),
            SafetyActionsButton(
              targetUserId: match.otherUserId,
              targetUserName: match.otherUserName,
              canUnmatch: true,
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () {
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
        },
      ),
    );
  }
}
