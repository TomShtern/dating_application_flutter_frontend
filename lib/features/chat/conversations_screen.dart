import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../theme/app_theme.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/user_avatar.dart';
import 'conversation_thread_screen.dart';
import 'conversations_provider.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsState = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            tooltip: 'Refresh conversations',
            onPressed: () =>
                ref.read(conversationsControllerProvider).refresh(),
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
                child: conversationsState.when(
                  data: (conversations) {
                    if (conversations.isEmpty) {
                      return AppAsyncState.empty(
                        message:
                            'No conversations yet. Once you match and message, they will show up here.',
                        onRefresh: () =>
                            ref.read(conversationsControllerProvider).refresh(),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () =>
                          ref.read(conversationsControllerProvider).refresh(),
                      child: ListView.separated(
                        itemCount: conversations.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: AppTheme.listSpacing()),
                        itemBuilder: (context, index) {
                          return _ConversationCard(
                            currentUser: currentUser,
                            summary: conversations[index],
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const AppAsyncState.loading(
                    message: 'Loading conversations…',
                  ),
                  error: (error, stackTrace) => AppAsyncState.error(
                    message: error is ApiError
                        ? error.message
                        : 'Unable to load conversations right now.',
                    onRetry: () => ref.invalidate(conversationsProvider),
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
    final colorScheme = Theme.of(context).colorScheme;
    final preview = _conversationPreview(summary);
    final messageSummary = switch (summary.messageCount) {
      0 => 'New match, ready for the first message',
      1 => '1 message so far',
      final count => '$count messages so far',
    };

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            formatShortDate(summary.lastMessageAt),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        preview,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
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
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => _openConversation(context),
              icon: const Icon(Icons.chat_bubble_rounded),
              label: const Text('Open chat'),
            ),
          ],
        ),
      ),
    );
  }
}

String _conversationPreview(ConversationSummary summary) {
  return switch (summary.messageCount) {
    0 => 'New match — send the first message when you are ready.',
    1 => 'The chat has started and is easy to pick back up.',
    2 || 3 || 4 => 'A short back-and-forth is already underway.',
    _ => 'An active conversation is waiting for your next reply.',
  };
}
