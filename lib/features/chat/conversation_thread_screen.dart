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
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'conversation_thread_provider.dart';

enum _ConversationMenuAction { viewProfile, safetyActions, refresh }

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
    final trimmedMessage = _messageController.text.trim();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _handleConversationMenuAction(
            _ConversationMenuAction.viewProfile,
          ),
          borderRadius: AppTheme.chipRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserAvatar(name: widget.conversation.otherUserName, radius: 18),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.conversation.otherUserName,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
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
                                style: theme.textTheme.bodySmall?.copyWith(
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
          ),
        ),
        actions: [
          AppOverflowMenuButton<_ConversationMenuAction>(
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
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => threadState.when(
                    data: (messages) {
                      if (messages.isEmpty) {
                        return AppAsyncState.empty(
                          message:
                              'No messages yet. Say hello to start the conversation.',
                          onRefresh: () => ref
                              .read(
                                conversationThreadControllerProvider(
                                  widget.conversation.id,
                                ),
                              )
                              .refresh(),
                        );
                      }

                      final useSparseLayout = messages.length <= 4;
                      _scheduleAutoScrollToLatest(
                        messages.length,
                        alignToBottom: useSparseLayout,
                      );

                      return useSparseLayout
                          ? _SparseMessageList(
                              scrollController: _messagesScrollController,
                              messages: messages,
                              currentUserId: widget.currentUser.id,
                              otherUserName: widget.conversation.otherUserName,
                              viewportHeight: constraints.maxHeight,
                              onRefresh: () => ref
                                  .read(
                                    conversationThreadControllerProvider(
                                      widget.conversation.id,
                                    ),
                                  )
                                  .refresh(),
                            )
                          : _MessageList(
                              scrollController: _messagesScrollController,
                              messages: messages,
                              currentUserId: widget.currentUser.id,
                              onRefresh: () => ref
                                  .read(
                                    conversationThreadControllerProvider(
                                      widget.conversation.id,
                                    ),
                                  )
                                  .refresh(),
                            );
                    },
                    loading: () => const AppAsyncState.loading(
                      message: 'Loading messages…',
                    ),
                    error: (error, stackTrace) => AppAsyncState.error(
                      message: error is ApiError
                          ? error.message
                          : 'Unable to load messages right now.',
                      onRetry: () => ref.invalidate(
                        conversationThreadProvider(widget.conversation.id),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: AppTheme.surfaceDecoration(
                  context,
                  color: colorScheme.surface.withValues(alpha: 0.97),
                  prominent: true,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 3,
                          textInputAction: TextInputAction.send,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _handleSend(),
                          decoration: const InputDecoration(
                            hintText: 'Say something kind, curious, or clear',
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        tooltip: 'Send message',
                        onPressed: trimmedMessage.isEmpty || _isSending
                            ? null
                            : _handleSend,
                        icon: _isSending
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.arrow_upward_rounded),
                      ),
                    ],
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

      _messagesScrollController.animateTo(
        alignToBottom ? position.maxScrollExtent : position.minScrollExtent,
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
    final entries = _buildConversationEntries(messages, currentUserId);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        reverse: true,
        controller: scrollController,
        padding: const EdgeInsets.symmetric(vertical: 4),
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
    required this.otherUserName,
    required this.viewportHeight,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final List<MessageDto> messages;
  final String currentUserId;
  final String otherUserName;
  final double viewportHeight;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final entries = _buildChronologicalConversationEntries(
      messages,
      currentUserId,
    );
    final topInset = _sparseThreadTopInset(viewportHeight);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(top: topInset, bottom: 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: viewportHeight - topInset - 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SparseThreadSummaryCard(
                otherUserName: otherUserName,
                messageCount: messages.length,
                startedAt: messages.first.sentAt,
              ),
              const SizedBox(height: 14),
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

double _sparseThreadTopInset(double viewportHeight) {
  return (viewportHeight * 0.18).clamp(72.0, 160.0).toDouble();
}

class _SparseThreadSummaryCard extends StatelessWidget {
  const _SparseThreadSummaryCard({
    required this.otherUserName,
    required this.messageCount,
    required this.startedAt,
  });

  final String otherUserName;
  final int messageCount;
  final DateTime startedAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final countLabel = messageCount == 1
        ? '1 message so far'
        : '$messageCount messages so far';
    final summaryGradient = LinearGradient(
      colors: theme.brightness == Brightness.dark
          ? [colorScheme.surfaceContainerLow, AppTheme.matchTintColor(context)]
          : [AppTheme.matchTint, colorScheme.surface],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        gradient: summaryGradient,
        prominent: true,
      ),
      child: Padding(
        padding: AppTheme.sectionPadding(compact: true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            UserAvatar(name: otherUserName, radius: 32),
            const SizedBox(height: 12),
            Text(
              otherUserName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              '$countLabel · Started ${formatShortDate(startedAt)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: AppTheme.glassDecoration(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Text(
                  'Be genuine, be curious',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: const BorderRadius.all(Radius.circular(999)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
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
    final incomingBubbleColor = theme.brightness == Brightness.dark
        ? colorScheme.surfaceContainerLow
        : AppTheme.matchTint;
    final bubbleDecoration = entry.isOutgoing
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primaryContainer,
                colorScheme.primaryContainer.withValues(alpha: 0.70),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: _messageBubbleRadius(entry),
          )
        : BoxDecoration(
            color: incomingBubbleColor,
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
                Text(message.content),
                if (entry.showTimestamp) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: entry.isOutgoing
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Text(
                      _formatMessageTime(message.sentAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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

List<_ConversationEntry> _buildConversationEntries(
  List<MessageDto> messages,
  String currentUserId,
) {
  final chronologicalEntries = _buildBaseConversationEntries(
    messages,
    currentUserId,
  );
  final displayEntries = chronologicalEntries.reversed.toList(growable: false);

  return List<_ConversationEntry>.generate(displayEntries.length, (index) {
    final current = displayEntries[index];
    final older = index + 1 < displayEntries.length
        ? displayEntries[index + 1]
        : null;

    return current.copyWith(topSpacing: _spacingAbove(current, older));
  }, growable: false);
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
