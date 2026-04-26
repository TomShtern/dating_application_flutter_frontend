import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/match_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/formatting/display_text.dart';
import '../../shared/widgets/person_media_thumbnail.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/app_async_state.dart';
import '../chat/conversation_thread_screen.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'match_factors_sheet.dart';
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

  Future<void> _openMatchFactors(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => MatchFactorsSheet(match: match),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final photoUrl = _primaryPhotoUrl(match.primaryPhotoUrl, match.photoUrls);

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
                    PersonMediaThumbnail(
                      key: ValueKey('match-media-${match.matchId}'),
                      name: match.otherUserName,
                      photoUrl: photoUrl,
                      width: 92,
                      height: 120,
                      borderRadius: const BorderRadius.all(Radius.circular(24)),
                    ),
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
                            match.summaryLine ??
                                match.approximateLocation ??
                                'Matched ${formatShortDate(match.createdAt)}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ShellHeroPill(
                                icon: Icons.favorite_border_rounded,
                                label:
                                    'Matched ${formatShortDate(match.createdAt)}',
                              ),
                              if (match.approximateLocation != null)
                                ShellHeroPill(
                                  icon: Icons.location_on_outlined,
                                  label: match.approximateLocation!,
                                ),
                              ShellHeroPill(
                                icon: Icons.verified_user_outlined,
                                label: formatDisplayLabel(match.state),
                              ),
                            ],
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
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _openConversation(context),
                      icon: const Icon(Icons.forum_rounded),
                      label: const Text('Message now'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openMatchFactors(context),
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: const Text('Why we match'),
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

String? _primaryPhotoUrl(String? primaryPhotoUrl, List<String> photoUrls) {
  if (primaryPhotoUrl != null && primaryPhotoUrl.trim().isNotEmpty) {
    return primaryPhotoUrl;
  }

  return photoUrls.isEmpty ? null : photoUrls.first;
}
