import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/message_dto.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_overflow_menu_button.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/app_route_header.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'conversation_thread_provider.dart';

enum _ConversationMenuAction { viewProfile, safetyActions, refresh }

const _threadTeal = Color(0xFF009688);
const _threadSky = Color(0xFF188DC8);

class ConversationThreadScreen extends ConsumerStatefulWidget {
  const ConversationThreadScreen({
    super.key,
    required this.currentUser,
    required this.conversation,
    this.refreshInterval = const Duration(seconds: 20),
  });

  final UserSummary currentUser;
  final ConversationSummary conversation;
  final Duration refreshInterval;

  @override
  ConsumerState<ConversationThreadScreen> createState() =>
      _ConversationThreadScreenState();
}

class _ConversationThreadScreenState
    extends ConsumerState<ConversationThreadScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _messageController;
  late final ScrollController _messagesScrollController;
  Timer? _refreshTimer;
  bool _isSending = false;
  int _lastAutoScrolledMessageCount = -1;
  bool? _lastAutoScrollUsesBottomExtent;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  // TODO: Return backend-provided activity status once presence data exists.
  bool get _showActivityIndicator => false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController = TextEditingController();
    _messagesScrollController = ScrollController();
    _startRefreshTimer();
  }

  @override
  void didUpdateWidget(covariant ConversationThreadScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.conversation.id != widget.conversation.id) {
      _lastAutoScrolledMessageCount = -1;
      _lastAutoScrollUsesBottomExtent = null;
    }

    if (oldWidget.conversation.id != widget.conversation.id ||
        oldWidget.refreshInterval != widget.refreshInterval) {
      _startRefreshTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _messageController.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final threadState = ref.watch(
      conversationThreadProvider(widget.conversation.id),
    );
    final threadController = ref.read(
      conversationThreadControllerProvider(widget.conversation.id),
    );
    final trimmedMessage = _messageController.text.trim();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppRouteHeader(
                title: 'Conversation',
                subtitle: 'Back to chats',
                trailing: AppOverflowMenuButton<_ConversationMenuAction>(
                  tooltip: 'Conversation options',
                  items: const [
                    PopupMenuItem<_ConversationMenuAction>(
                      value: _ConversationMenuAction.viewProfile,
                      child: Text('View profile'),
                    ),
                    PopupMenuItem<_ConversationMenuAction>(
                      value: _ConversationMenuAction.safetyActions,
                      child: Text('Safety actions'),
                    ),
                    PopupMenuItem<_ConversationMenuAction>(
                      value: _ConversationMenuAction.refresh,
                      child: Text('Refresh messages'),
                    ),
                  ],
                  onSelected: _handleConversationMenuAction,
                ),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _handleConversationMenuAction(
                  _ConversationMenuAction.viewProfile,
                ),
                borderRadius: AppTheme.cardRadius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      UserAvatar(
                        name: widget.conversation.otherUserName,
                        radius: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.conversation.otherUserName,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (_showActivityIndicator)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: BoxDecoration(
                                      color: colorScheme.onSurfaceVariant,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      'Status unavailable',
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'Tap name to view profile',
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => threadState.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return _ConversationThreadEmptyState(
                          otherUserName: widget.conversation.otherUserName,
                          onRefresh: threadController.refresh,
                        );
                      }

                      final useSparseLayout = messages.length <= 4;
                      _scheduleAutoScrollToLatest(
                        messages.length,
                        alignToBottom: true,
                      );

                      return useSparseLayout
                          ? _SparseMessageList(
                              scrollController: _messagesScrollController,
                              messages: messages,
                              currentUserId: widget.currentUser.id,
                              viewportHeight: constraints.maxHeight,
                              onRefresh: threadController.refresh,
                            )
                          : _MessageList(
                              scrollController: _messagesScrollController,
                              messages: messages,
                              currentUserId: widget.currentUser.id,
                              onRefresh: threadController.refresh,
                            );
                    },
                    loading: () => const AppAsyncState.loading(
                      message: 'Loading messages…',
                    ),
                    error: (error, stackTrace) => AppAsyncState.error(
                      message: error is ApiError
                          ? error.message
                          : 'Unable to load messages right now.',
                      onRetry: threadController.refresh,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: Color.alphaBlend(
                  _threadTeal.withValues(alpha: isDark ? 0.08 : 0.035),
                  colorScheme.surfaceContainerLow,
                ),
                borderRadius: AppTheme.panelRadius,
                clipBehavior: Clip.antiAlias,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: AppTheme.panelRadius,
                    border: Border.all(
                      color: _threadTeal.withValues(
                        alpha: isDark ? 0.20 : 0.12,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            tooltip: 'Attachments (coming soon)',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Media attachments coming soon.'),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.add_rounded,
                              color: _threadTeal.withValues(alpha: 0.78),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              minLines: 1,
                              maxLines: 3,
                              textInputAction: TextInputAction.send,
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (_) => _handleSend(),
                              decoration: InputDecoration(
                                hintText:
                                    'Message ${widget.conversation.otherUserName}',
                                isDense: true,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            tooltip: _isSending
                                ? 'Sending message…'
                                : 'Send message',
                            onPressed: trimmedMessage.isEmpty || _isSending
                                ? null
                                : _handleSend,
                            style: IconButton.styleFrom(
                              backgroundColor: _threadTeal,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  colorScheme.surfaceContainerHighest,
                              disabledForegroundColor: colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.62),
                            ),
                            icon: _isSending
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.arrow_upward_rounded),
                          ),
                        ],
                      ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleConversationMenuAction(
    _ConversationMenuAction action,
  ) async {
    switch (action) {
      case _ConversationMenuAction.viewProfile:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => ProfileScreen.otherUser(
              userId: widget.conversation.otherUserId,
              userName: widget.conversation.otherUserName,
            ),
          ),
        );
      case _ConversationMenuAction.safetyActions:
        final outcome = await showModalBottomSheet<SafetyActionOutcome>(
          context: context,
          showDragHandle: true,
          builder: (sheetContext) => SafetyActionSheet(
            targetUserId: widget.conversation.otherUserId,
            targetUserName: widget.conversation.otherUserName,
            canUnmatch: true,
          ),
        );

        if (!mounted || outcome == null) {
          return;
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(outcome.message)));
        if (outcome.removesRelationship) {
          Navigator.of(context).maybePop();
        }
      case _ConversationMenuAction.refresh:
        await ref
            .read(conversationThreadControllerProvider(widget.conversation.id))
            .refresh();
    }
  }

  Future<void> _handleSend() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await ref
          .read(conversationThreadControllerProvider(widget.conversation.id))
          .sendMessage(message);

      if (!mounted) {
        return;
      }

      _messageController.clear();
      FocusScope.of(context).unfocus();
      setState(() {});
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send the message right now.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();

    if (widget.refreshInterval <= Duration.zero) {
      return;
    }

    _refreshTimer = Timer.periodic(widget.refreshInterval, (_) {
      _refreshIfVisible();
    });
  }

  void _refreshIfVisible() {
    if (!mounted || _isSending) {
      return;
    }

    if (_appLifecycleState != AppLifecycleState.resumed) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return;
    }

    ref
        .read(conversationThreadControllerProvider(widget.conversation.id))
        .refresh();
  }

  void _scheduleAutoScrollToLatest(
    int messageCount, {
    required bool alignToBottom,
  }) {
    if (_lastAutoScrolledMessageCount == messageCount &&
        _lastAutoScrollUsesBottomExtent == alignToBottom) {
      return;
    }

    final isInitialAutoScroll =
        _lastAutoScrolledMessageCount == -1 ||
        _lastAutoScrollUsesBottomExtent == null;
    _lastAutoScrolledMessageCount = messageCount;
    _lastAutoScrollUsesBottomExtent = alignToBottom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_messagesScrollController.hasClients) {
        return;
      }

      final position = _messagesScrollController.position;
      final isNearLatest = alignToBottom
          ? (position.maxScrollExtent - position.pixels).abs() < 80
          : (position.pixels - position.minScrollExtent).abs() < 80;
      if (!isInitialAutoScroll && !isNearLatest && messageCount > 1) {
        return;
      }

      final targetOffset = alignToBottom
          ? position.maxScrollExtent
          : position.minScrollExtent;

      if (isInitialAutoScroll) {
        _messagesScrollController.jumpTo(targetOffset);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_messagesScrollController.hasClients) {
            return;
          }
          _messagesScrollController.jumpTo(
            alignToBottom
                ? _messagesScrollController.position.maxScrollExtent
                : _messagesScrollController.position.minScrollExtent,
          );
        });
        return;
      }

      _messagesScrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.scrollController,
    required this.messages,
    required this.currentUserId,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final List<MessageDto> messages;
  final String currentUserId;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final entries = _buildChronologicalConversationEntries(
      messages,
      currentUserId,
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];

          return Padding(
            padding: EdgeInsets.only(top: entry.topSpacing),
            child: entry.isDayDivider
                ? _MessageDayDivider(label: entry.dayLabel!)
                : _MessageBubble(entry: entry),
          );
        },
      ),
    );
  }
}

class _SparseMessageList extends StatelessWidget {
  const _SparseMessageList({
    required this.scrollController,
    required this.messages,
    required this.currentUserId,
    required this.viewportHeight,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final List<MessageDto> messages;
  final String currentUserId;
  final double viewportHeight;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final entries = _buildChronologicalConversationEntries(
      messages,
      currentUserId,
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewportHeight - 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in entries)
                Padding(
                  padding: EdgeInsets.only(top: entry.topSpacing),
                  child: entry.isDayDivider
                      ? _MessageDayDivider(label: entry.dayLabel!)
                      : _MessageBubble(entry: entry),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationThreadEmptyState extends StatelessWidget {
  const _ConversationThreadEmptyState({
    required this.otherUserName,
    required this.onRefresh,
  });

  final String otherUserName;
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
          _threadSky.withValues(alpha: isDark ? 0.08 : 0.03),
          Color.alphaBlend(
            _threadTeal.withValues(alpha: isDark ? 0.14 : 0.05),
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
                color: _threadTeal.withValues(alpha: isDark ? 0.22 : 0.12),
                borderRadius: const BorderRadius.all(Radius.circular(14)),
              ),
              child: SizedBox.square(
                dimension: 44,
                child: Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: isDark ? const Color(0xFF91E2DC) : _threadTeal,
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
                    'No messages yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Start the conversation with $otherUserName when you\'re ready.',
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

class _MessageDayDivider extends StatelessWidget {
  const _MessageDayDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            _threadSky.withValues(alpha: isDark ? 0.10 : 0.04),
            colorScheme.surfaceContainerHigh,
          ),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.18),
          ),
          borderRadius: const BorderRadius.all(Radius.circular(999)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 12,
                color: isDark ? const Color(0xFF9FD2EF) : _threadSky,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.entry});

  final _ConversationEntry entry;

  @override
  Widget build(BuildContext context) {
    final message = entry.message!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final incomingBubbleColor = Color.alphaBlend(
      _threadSky.withValues(alpha: isDark ? 0.10 : 0.035),
      colorScheme.surfaceContainerLow,
    );
    final outgoingTextColor = isDark
        ? const Color(0xFFEAFBFA)
        : const Color(0xFF0F4D54);
    final bubbleDecoration = entry.isOutgoing
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF0A4A4F), Color(0xFF126A72)]
                  : const [Color(0xFFA8E0D8), Color(0xFF90D5CB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: _messageBubbleRadius(entry),
          )
        : BoxDecoration(
            color: incomingBubbleColor,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.16),
            ),
            borderRadius: _messageBubbleRadius(entry),
          );

    return Align(
      alignment: entry.isOutgoing
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: bubbleDecoration,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: entry.isOutgoing
                        ? outgoingTextColor
                        : colorScheme.onSurface,
                    height: 1.34,
                  ),
                ),
                if (entry.showTimestamp) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: entry.isOutgoing
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Text(
                      _formatMessageTime(message.sentAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: entry.isOutgoing
                            ? outgoingTextColor.withValues(alpha: 0.78)
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<_ConversationEntry> _buildChronologicalConversationEntries(
  List<MessageDto> messages,
  String currentUserId,
) {
  final chronologicalEntries = _buildBaseConversationEntries(
    messages,
    currentUserId,
  );

  return List<_ConversationEntry>.generate(chronologicalEntries.length, (
    index,
  ) {
    final current = chronologicalEntries[index];
    final older = index > 0 ? chronologicalEntries[index - 1] : null;

    return current.copyWith(topSpacing: _spacingAbove(current, older));
  }, growable: false);
}

List<_ConversationEntry> _buildBaseConversationEntries(
  List<MessageDto> messages,
  String currentUserId,
) {
  final chronologicalEntries = <_ConversationEntry>[];

  for (var index = 0; index < messages.length; index++) {
    final message = messages[index];
    final previousMessage = index > 0 ? messages[index - 1] : null;
    final nextMessage = index + 1 < messages.length
        ? messages[index + 1]
        : null;

    if (previousMessage == null ||
        !_isSameDay(previousMessage.sentAt, message.sentAt)) {
      chronologicalEntries.add(
        _ConversationEntry.dayDivider(formatShortDate(message.sentAt)),
      );
    }

    final groupsWithOlder =
        previousMessage != null &&
        _isSameSenderOnSameDay(previousMessage, message);
    final groupsWithNewer =
        nextMessage != null && _isSameSenderOnSameDay(message, nextMessage);

    chronologicalEntries.add(
      _ConversationEntry.message(
        message: message,
        isOutgoing: message.senderId == currentUserId,
        groupsWithOlder: groupsWithOlder,
        groupsWithNewer: groupsWithNewer,
      ),
    );
  }

  return chronologicalEntries;
}

double _spacingAbove(_ConversationEntry current, _ConversationEntry? older) {
  if (older == null) {
    return 0;
  }

  if (current.isDayDivider || older.isDayDivider) {
    return 12;
  }

  return current.groupsWithOlder ? 4 : 10;
}

BorderRadius _messageBubbleRadius(_ConversationEntry entry) {
  const large = Radius.circular(20);
  const small = Radius.circular(8);

  if (entry.isOutgoing) {
    return BorderRadius.only(
      topLeft: large,
      topRight: entry.groupsWithOlder ? small : large,
      bottomLeft: large,
      bottomRight: entry.groupsWithNewer ? small : large,
    );
  }

  return BorderRadius.only(
    topLeft: entry.groupsWithOlder ? small : large,
    topRight: large,
    bottomLeft: entry.groupsWithNewer ? small : large,
    bottomRight: large,
  );
}

bool _isSameSenderOnSameDay(MessageDto older, MessageDto newer) {
  return older.senderId == newer.senderId &&
      _isSameDay(older.sentAt, newer.sentAt);
}

bool _isSameDay(DateTime left, DateTime right) {
  final leftLocal = left.toLocal();
  final rightLocal = right.toLocal();

  return leftLocal.year == rightLocal.year &&
      leftLocal.month == rightLocal.month &&
      leftLocal.day == rightLocal.day;
}

String _formatMessageTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour >= 12 ? 'PM' : 'AM';

  return '$hour:$minute $meridiem';
}

class _ConversationEntry {
  const _ConversationEntry.dayDivider(this.dayLabel)
    : isDayDivider = true,
      message = null,
      isOutgoing = false,
      groupsWithOlder = false,
      groupsWithNewer = false,
      topSpacing = 0;

  const _ConversationEntry.message({
    required this.message,
    required this.isOutgoing,
    required this.groupsWithOlder,
    required this.groupsWithNewer,
  }) : isDayDivider = false,
       dayLabel = null,
       topSpacing = 0;

  final bool isDayDivider;
  final String? dayLabel;
  final MessageDto? message;
  final bool isOutgoing;
  final bool groupsWithOlder;
  final bool groupsWithNewer;
  final double topSpacing;

  bool get showTimestamp => !isDayDivider && !groupsWithNewer;

  _ConversationEntry copyWith({double? topSpacing}) {
    if (isDayDivider) {
      return _ConversationEntry.dayDivider(
        dayLabel!,
      )._copyAssignedSpacing(topSpacing ?? this.topSpacing);
    }

    return _ConversationEntry.message(
      message: message!,
      isOutgoing: isOutgoing,
      groupsWithOlder: groupsWithOlder,
      groupsWithNewer: groupsWithNewer,
    )._copyAssignedSpacing(topSpacing ?? this.topSpacing);
  }

  _ConversationEntry _copyAssignedSpacing(double spacing) {
    return _ConversationEntry._internal(
      isDayDivider: isDayDivider,
      dayLabel: dayLabel,
      message: message,
      isOutgoing: isOutgoing,
      groupsWithOlder: groupsWithOlder,
      groupsWithNewer: groupsWithNewer,
      topSpacing: spacing,
    );
  }

  const _ConversationEntry._internal({
    required this.isDayDivider,
    required this.dayLabel,
    required this.message,
    required this.isOutgoing,
    required this.groupsWithOlder,
    required this.groupsWithNewer,
    required this.topSpacing,
  });
}
