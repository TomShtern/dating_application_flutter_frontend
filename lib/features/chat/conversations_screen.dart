import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_group_label.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import 'conversation_thread_screen.dart';
import 'conversations_provider.dart';

const _conversationTeal = Color(0xFF009688);
const _conversationSky = Color(0xFF188DC8);
const _conversationSlate = Color(0xFF596579);

class ConversationsScreen extends ConsumerStatefulWidget {
  const ConversationsScreen({super.key, required this.currentUser});

  final UserSummary currentUser;

  @override
  ConsumerState<ConversationsScreen> createState() =>
      _ConversationsScreenState();
}

class _ConversationsScreenState extends ConsumerState<ConversationsScreen> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationsState = ref.watch(conversationsProvider);
    final controller = ref.read(conversationsControllerProvider);
    final conversationCount = conversationsState.maybeWhen(
      data: (value) => value.length,
      orElse: () => null,
    );
    final readyToStartCount = conversationsState.maybeWhen(
      data: (value) =>
          value.where((summary) => summary.messageCount == 0).length,
      orElse: () => null,
    );

    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              AppTheme.pagePadding,
              AppTheme.pagePadding,
              0,
            ),
            child: _ChatsIntroCard(
              conversationCount: conversationCount,
              readyToStartCount: readyToStartCount,
              onRefresh: controller.refresh,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.pagePadding,
              12,
              AppTheme.pagePadding,
              0,
            ),
            child: _ConversationSearchField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
              onClear: _clearSearch,
            ),
          ),
          SizedBox(height: AppTheme.sectionSpacing(compact: true)),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: conversationsState.when(
                data: (conversations) {
                  final filteredConversations = conversations
                      .where(
                        (summary) => _matchesConversationSearch(
                          summary,
                          currentUserId: widget.currentUser.id,
                          query: _searchQuery,
                        ),
                      )
                      .toList(growable: false);

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.pagePadding,
                      0,
                      AppTheme.pagePadding,
                      AppTheme.navBarHeight + AppTheme.pagePadding,
                    ),
                    children: [
                      if (conversations.isEmpty)
                        _ConversationsEmptyState(onRefresh: controller.refresh)
                      else if (filteredConversations.isEmpty)
                        _ConversationSearchEmptyState(
                          query: _searchQuery,
                          onClear: _clearSearch,
                        )
                      else ...[
                        AppGroupLabel(
                          title: _searchQuery.isEmpty
                              ? 'Open conversations'
                              : 'Matching conversations',
                          accentColor: _conversationTeal,
                          countText: '${filteredConversations.length}',
                        ),
                        SizedBox(height: AppTheme.listSpacing()),
                        for (
                          var index = 0;
                          index < filteredConversations.length;
                          index++
                        ) ...[
                          _ConversationCard(
                            currentUser: widget.currentUser,
                            summary: filteredConversations[index],
                          ),
                          if (index != filteredConversations.length - 1)
                            SizedBox(height: AppTheme.listSpacing()),
                        ],
                      ],
                    ],
                  );
                },
                loading: () => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    0,
                    AppTheme.pagePadding,
                    AppTheme.navBarHeight + AppTheme.pagePadding,
                  ),
                  children: const [
                    AppAsyncState.loading(message: 'Loading conversations…'),
                  ],
                ),
                error: (error, stackTrace) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pagePadding,
                    0,
                    AppTheme.pagePadding,
                    AppTheme.navBarHeight + AppTheme.pagePadding,
                  ),
                  children: [
                    AppAsyncState.error(
                      message: error is ApiError
                          ? error.message
                          : 'Unable to load conversations right now.',
                      onRetry: controller.refresh,
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

class _ConversationSearchField extends StatelessWidget {
  const _ConversationSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Color.alphaBlend(
        _conversationTeal.withValues(alpha: isDark ? 0.10 : 0.04),
        colorScheme.surfaceContainerLow,
      ),
      borderRadius: AppTheme.panelRadius,
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppTheme.panelRadius,
          border: Border.all(
            color: _conversationTeal.withValues(alpha: isDark ? 0.18 : 0.10),
          ),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search loaded chats',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: controller.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear chat search',
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatsIntroCard extends StatelessWidget {
  const _ChatsIntroCard({
    required this.conversationCount,
    required this.readyToStartCount,
    required this.onRefresh,
  });

  final int? conversationCount;
  final int? readyToStartCount;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final totalCount = conversationCount;
    final pendingFirstMessageCount = readyToStartCount ?? 0;
    final titleColor = isDark
        ? const Color(0xFFE7F8F6)
        : const Color(0xFF155C63);
    final subtitleColor = isDark
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.84)
        : const Color(0xFF5F7176);
    final description = switch (totalCount) {
      null => 'Checking the latest conversations.',
      0 => 'New matches and messages will show up here.',
      _ when pendingFirstMessageCount > 0 =>
        '$pendingFirstMessageCount waiting for a first message.',
      final count =>
        '$count ${count == 1 ? 'conversation' : 'conversations'} ready to pick back up.',
    };

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _conversationSky.withValues(alpha: isDark ? 0.10 : 0.045),
          Color.alphaBlend(
            _conversationTeal.withValues(alpha: isDark ? 0.14 : 0.055),
            colorScheme.surfaceContainerLow,
          ),
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _conversationTeal.withValues(
                      alpha: isDark ? 0.22 : 0.12,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(14)),
                  ),
                  child: SizedBox.square(
                    dimension: 40,
                    child: Icon(
                      Icons.mark_chat_unread_rounded,
                      color: isDark
                          ? const Color(0xFF91E2DC)
                          : _conversationTeal,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chats',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: titleColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  tooltip: 'Refresh conversations',
                  onPressed: () async {
                    await onRefresh();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ConversationInfoPill(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: totalCount == null
                      ? 'Syncing chats'
                      : '$totalCount ${totalCount == 1 ? 'ongoing chat' : 'ongoing chats'}',
                  backgroundColor: _conversationTeal.withValues(
                    alpha: isDark ? 0.18 : 0.11,
                  ),
                  foregroundColor: isDark
                      ? const Color(0xFF91E2DC)
                      : _conversationTeal,
                ),
                if (totalCount != null)
                  _ConversationInfoPill(
                    icon: Icons.mark_email_unread_outlined,
                    label: pendingFirstMessageCount == 0
                        ? 'All started'
                        : pendingFirstMessageCount == 1
                        ? '1 waiting to start'
                        : '$pendingFirstMessageCount waiting to start',
                    backgroundColor: _conversationSky.withValues(
                      alpha: isDark ? 0.18 : 0.10,
                    ),
                    foregroundColor: isDark
                        ? const Color(0xFF9FD2EF)
                        : _conversationSky,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationsEmptyState extends StatelessWidget {
  const _ConversationsEmptyState({required this.onRefresh});

  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _conversationSky.withValues(alpha: isDark ? 0.10 : 0.04),
          Color.alphaBlend(
            _conversationTeal.withValues(alpha: isDark ? 0.14 : 0.05),
            colorScheme.surfaceContainerLow,
          ),
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _conversationTeal.withValues(
                  alpha: isDark ? 0.22 : 0.12,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              child: SizedBox.square(
                dimension: 44,
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: isDark ? const Color(0xFF91E2DC) : _conversationTeal,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No conversations yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Once you match and start messaging, your conversations will show up here.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      await onRefresh();
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationSearchEmptyState extends StatelessWidget {
  const _ConversationSearchEmptyState({
    required this.query,
    required this.onClear,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _conversationSky.withValues(alpha: isDark ? 0.08 : 0.03),
          Color.alphaBlend(
            _conversationTeal.withValues(alpha: isDark ? 0.12 : 0.05),
            colorScheme.surfaceContainerLow,
          ),
        ),
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: _conversationSky.withValues(alpha: isDark ? 0.20 : 0.10),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              child: SizedBox.square(
                dimension: 44,
                child: Icon(
                  Icons.search_off_rounded,
                  color: isDark ? const Color(0xFF9FD2EF) : _conversationSky,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No chats match “$query”',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Search looks through the conversations already loaded on this device.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Clear search'),
                  ),
                ],
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
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final spec = _ConversationVisualSpec.forSummary(summary);
    final preview = _conversationPreview(summary, currentUser.id);
    final messageSummary = _conversationMessageSummary(summary);
    final timestamp = formatShortDate(summary.lastMessageAt);

    return Material(
      color: Colors.transparent,
      borderRadius: AppTheme.panelRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: AppTheme.panelRadius,
        onTap: () => _openConversation(context),
        child: Ink(
          decoration: AppTheme.surfaceDecoration(
            context,
            color: _conversationSurfaceColor(context, spec),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: spec.color.withValues(alpha: 0.78),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ConversationAvatarStack(summary: summary, spec: spec),
                  const SizedBox(width: 10),
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
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (summary.unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              _ConversationUnreadBadge(
                                count: summary.unreadCount,
                              ),
                            ],
                            if (_hasConversationTimestamp(summary)) ...[
                              const SizedBox(width: 8),
                              Text(
                                timestamp,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          preview,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: summary.unreadCount > 0
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant,
                            fontWeight: summary.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.w400,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _ConversationInfoPill(
                              icon: spec.icon,
                              label: messageSummary,
                              backgroundColor: spec.color.withValues(
                                alpha: theme.brightness == Brightness.dark
                                    ? 0.18
                                    : 0.10,
                              ),
                              foregroundColor: spec.foregroundColor,
                            ),
                            const Spacer(),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Open',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 20,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
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
      ),
    );
  }
}

class _ConversationAvatarStack extends StatelessWidget {
  const _ConversationAvatarStack({required this.summary, required this.spec});

  final ConversationSummary summary;
  final _ConversationVisualSpec spec;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: UserAvatar(name: summary.otherUserName, radius: 22),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: spec.color.withValues(alpha: 0.32)),
              ),
              child: SizedBox.square(
                dimension: 18,
                child: Icon(spec.icon, color: spec.foregroundColor, size: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationInfoPill extends StatelessWidget {
  const _ConversationInfoPill({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppTheme.chipRadius,
        border: Border.all(color: foregroundColor.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationUnreadBadge extends StatelessWidget {
  const _ConversationUnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _conversationTeal,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        boxShadow: [
          BoxShadow(
            color: _conversationTeal.withValues(alpha: isDark ? 0.20 : 0.14),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          count == 1 ? '1 unread' : '$count unread',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}

class _ConversationVisualSpec {
  const _ConversationVisualSpec({
    required this.color,
    required this.foregroundColor,
    required this.icon,
  });

  final Color color;
  final Color foregroundColor;
  final IconData icon;

  static _ConversationVisualSpec forSummary(ConversationSummary summary) {
    if (summary.unreadCount > 0) {
      return const _ConversationVisualSpec(
        color: _conversationTeal,
        foregroundColor: _conversationTeal,
        icon: Icons.mark_chat_unread_rounded,
      );
    }

    if (summary.messageCount == 0) {
      return const _ConversationVisualSpec(
        color: _conversationSky,
        foregroundColor: _conversationSky,
        icon: Icons.mark_email_unread_outlined,
      );
    }

    return const _ConversationVisualSpec(
      color: _conversationTeal,
      foregroundColor: _conversationTeal,
      icon: Icons.chat_bubble_outline_rounded,
    );
  }
}

String _conversationPreview(ConversationSummary summary, String currentUserId) {
  final preview = summary.lastMessagePreview?.trim();
  if (preview != null && preview.isNotEmpty) {
    final senderCue = _conversationSenderCue(summary, currentUserId);
    return senderCue == null ? preview : '$senderCue: $preview';
  }

  return switch (summary.messageCount) {
    0 => 'Send the first message when you are ready.',
    1 => 'Conversation started.',
    _ => 'Tap to continue the conversation.',
  };
}

String _conversationMessageSummary(ConversationSummary summary) {
  if (summary.unreadCount > 0) {
    return summary.unreadCount == 1
        ? '1 unread'
        : '${summary.unreadCount} unread';
  }

  return switch (summary.messageCount) {
    0 => 'Waiting to start',
    1 => '1 message',
    final count => '$count messages',
  };
}

String? _conversationSenderCue(
  ConversationSummary summary,
  String currentUserId,
) {
  if (summary.lastSenderId == currentUserId) {
    return 'You';
  }

  if (summary.lastSenderId == summary.otherUserId) {
    return summary.otherUserName;
  }

  final lastSenderName = summary.lastSenderName?.trim();
  if (lastSenderName != null && lastSenderName.isNotEmpty) {
    return lastSenderName;
  }

  return null;
}

bool _matchesConversationSearch(
  ConversationSummary summary, {
  required String currentUserId,
  required String query,
}) {
  final trimmedQuery = query.trim().toLowerCase();
  if (trimmedQuery.isEmpty) {
    return true;
  }

  final haystacks = <String>[
    summary.otherUserName,
    summary.lastMessagePreview ?? '',
    _conversationSenderCue(summary, currentUserId) ?? '',
  ];

  return haystacks.any((value) => value.toLowerCase().contains(trimmedQuery));
}

bool _hasConversationTimestamp(ConversationSummary summary) {
  return summary.lastMessageAt.millisecondsSinceEpoch > 0;
}

Color _conversationSurfaceColor(
  BuildContext context,
  _ConversationVisualSpec spec,
) {
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  return Color.alphaBlend(
    _conversationSlate.withValues(alpha: isDark ? 0.03 : 0.015),
    Color.alphaBlend(
      spec.color.withValues(alpha: isDark ? 0.10 : 0.05),
      colorScheme.surfaceContainerLow,
    ),
  );
}
