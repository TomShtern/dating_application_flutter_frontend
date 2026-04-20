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
    final conversationCount = conversationsState.maybeWhen(
      data: (conversations) => conversations.length,
      orElse: () => null,
    );

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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ConversationsHero(
                currentUser: currentUser,
                conversationCount: conversationCount,
              ),
              const SizedBox(height: 18),
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
                            const SizedBox(height: 12),
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

class _ConversationsHero extends StatelessWidget {
  const _ConversationsHero({required this.currentUser, this.conversationCount});

  final UserSummary currentUser;
  final int? conversationCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final countLabel = switch (conversationCount) {
      null => 'Updating your inbox',
      1 => '1 conversation ready',
      final count => '$count conversations ready',
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
            const _ConversationBadge(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Conversations',
            ),
            const SizedBox(height: 16),
            Text(
              'Chats available to ${currentUser.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The list is cleaner now, but the same backend-driven threads are still doing the talking underneath.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ConversationBadge(
                  icon: Icons.mark_chat_unread_outlined,
                  label: countLabel,
                ),
                const _ConversationBadge(
                  icon: Icons.bolt_rounded,
                  label: 'Sorted by recent activity',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationBadge extends StatelessWidget {
  const _ConversationBadge({required this.icon, required this.label});

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
    final supportingCopy = summary.messageCount == 0
        ? 'Fresh match, clean slate — lead with something memorable.'
        : 'Keep the momentum going while the conversation is still warm.';

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
                  children: [
                    UserAvatar(name: summary.otherUserName, radius: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.otherUserName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            supportingCopy,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ConversationBadge(
                      icon: Icons.mail_outline_rounded,
                      label: '${summary.messageCount} message(s)',
                    ),
                    _ConversationBadge(
                      icon: Icons.schedule_rounded,
                      label: formatDateTimeStamp(summary.lastMessageAt),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: () => _openConversation(context),
                  icon: const Icon(Icons.chat_bubble_rounded),
                  label: const Text('Open chat'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
