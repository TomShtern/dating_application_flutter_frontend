import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/shell_hero.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import 'conversation_thread_screen.dart';
import 'conversations_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsState = ref.watch(conversationsProvider);
    final controller = ref.read(conversationsControllerProvider);
    final heroDescription = switch (conversationsState) {
      AsyncData(:final value) when value.isEmpty =>
        'Start a conversation when you match.',
      AsyncData(:final value) =>
        '${value.length} ongoing ${value.length == 1 ? 'chat' : 'chats'}',
      _ => 'Your conversations',
    };

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShellHero(
            compact: true,
            eyebrowLabel: 'Messages',
            header: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Refresh conversations',
                  onPressed: controller.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            title: 'Chats',
            description: heroDescription,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: conversationsState.when(
                data: (conversations) {
                  if (conversations.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: AppTheme.screenPadding(),
                      children: [
                        AppAsyncState.empty(
                          message:
                              'No conversations yet — once you match and message someone, they\'ll show up here.',
                          onRefresh: controller.refresh,
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: AppTheme.screenPadding(),
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) =>
                        SizedBox(height: AppTheme.listSpacing()),
                    itemBuilder: (context, index) => _ConversationCard(
                      currentUser: currentUser,
                      summary: conversations[index],
                    ),
                  );
                },
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppTheme.screenPadding(),
                  children: const [
                    AppAsyncState.loading(message: 'Loading conversations…'),
                  ],
                ),
                error: (error, stackTrace) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: AppTheme.screenPadding(),
                  children: [
                    AppAsyncState.error(
                      message: error is ApiError
                          ? error.message
                          : 'Unable to load conversations right now.',
                      onRetry: () => ref.invalidate(conversationsProvider),
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

class _ConversationCard extends StatelessWidget {
  const _ConversationCard({required this.currentUser, required this.summary});

  final UserSummary currentUser;
  final ConversationSummary summary;

  void _openConversation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ConversationThreadScreen(
          currentUser: currentUser,
          conversation: summary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final preview = _conversationPreview(summary);
    final messageSummary = switch (summary.messageCount) {
      0 => 'New match, ready for the first message',
      1 => '1 message so far',
      final count => '$count messages so far',
    };

    return Material(
      color: Colors.transparent,
      borderRadius: AppTheme.panelRadius,
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: AppTheme.surfaceDecoration(context),
        child: InkWell(
          borderRadius: AppTheme.panelRadius,
          onTap: () => _openConversation(context),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.cardPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                UserAvatar(name: summary.otherUserName, radius: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              summary.otherUserName,
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatShortDate(summary.lastMessageAt),
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.mail_outline_rounded,
                            size: 18,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              messageSummary,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
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

String _conversationPreview(ConversationSummary summary) {
  return switch (summary.messageCount) {
    0 => 'No messages yet — say hi when you\'re ready.',
    1 => 'One message so far. Pick the chat back up.',
    2 || 3 || 4 => 'A few messages exchanged — keep it going.',
    _ => 'An ongoing conversation.',
  };
}
