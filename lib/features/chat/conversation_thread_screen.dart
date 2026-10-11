import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/message_dto.dart';
import '../../models/user_presence.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_overflow_menu_button.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/user_avatar.dart';
import '../../theme/app_theme.dart';
import '../presence/presence_provider.dart';
import '../presence/presence_widgets.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'conversation_thread_provider.dart';
import 'conversations_provider.dart';

enum _ConversationMenuAction {
  viewProfile,
  safetyActions,
  refresh,
  archive,
  unarchive,
  delete,
}

enum _MessageAction { copy, unsend }

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
  bool _syncedConversationsAfterLoad = false;
  bool _showJumpToLatest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController = TextEditingController();
    _messagesScrollController = ScrollController()
      ..addListener(_handleMessagesScroll);
    _startRefreshTimer();
    // Once the thread loads, refetch the conversation list so the backend's
    // updated unread count reaches the chats list and shell badge.
    ref.listenManual(conversationThreadProvider(widget.conversation.id), (
      previous,
      next,
    ) {
      if (_syncedConversationsAfterLoad || !next.hasValue) {
        return;
      }
      _syncedConversationsAfterLoad = true;
      ref.invalidate(conversationsProvider);
    });
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

  void _handleMessagesScroll() {
    if (!_messagesScrollController.hasClients) {
      return;
    }

    final position = _messagesScrollController.position;
    final distanceFromBottom = position.maxScrollExtent - position.pixels;
    final shouldShow = distanceFromBottom > 160;

    if (shouldShow != _showJumpToLatest) {
      setState(() => _showJumpToLatest = shouldShow);
    }
  }

  Future<void> _jumpToLatest() async {
    if (!_messagesScrollController.hasClients) {
      return;
    }

    HapticFeedback.selectionClick();
    await _messagesScrollController.animateTo(
      _messagesScrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _copyMessage(MessageDto message) async {
    final content = message.content.trim();
    if (content.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) {
      return;
    }

    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Long-press on a bubble. Own delivered messages can also be unsent;
  /// everything else is copied straight away.
  Future<void> _showMessageActions(MessageDto message) async {
    final canUnsend =
        message.senderId == widget.currentUser.id &&
        message.localState == MessageLocalState.none &&
        message.id.isNotEmpty;
    if (!canUnsend) {
      return _copyMessage(message);
    }

    final action = await showModalBottomSheet<_MessageAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy'),
                onTap: () => Navigator.of(sheetContext).pop(_MessageAction.copy),
              ),
              ListTile(
                leading: Icon(Icons.undo_rounded, color: colorScheme.error),
                title: Text(
                  'Unsend',
                  style: TextStyle(color: colorScheme.error),
                ),
                subtitle: Text(
                  'Removes it for you and ${widget.conversation.otherUserName}',
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_MessageAction.unsend),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case _MessageAction.copy:
        await _copyMessage(message);
      case _MessageAction.unsend:
        await _unsendMessage(message);
    }
  }

  Future<void> _unsendMessage(MessageDto message) async {
    try {
      await ref
          .read(conversationThreadControllerProvider(widget.conversation.id))
          .deleteMessage(message);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message unsent'),
          duration: Duration(seconds: 2),
        ),
      );
    } on ApiError catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
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
      conversationThreadMessagesProvider(widget.conversation.id),
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
              PresenceObserver(
                userId: widget.conversation.otherUserId,
                conversationId: widget.conversation.id,
                builder: (context, presence) => _ConversationHeaderCard(
                  otherUserName: widget.conversation.otherUserName,
                  archived: widget.conversation.archived,
                  presence: presence,
                  onBack: () => Navigator.of(context).maybePop(),
                  onOpenProfile: () => _handleConversationMenuAction(
                    _ConversationMenuAction.viewProfile,
                  ),
                  onMenuSelected: _handleConversationMenuAction,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Stack(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) => threadState.when(
                        data: (messages) {
                          if (messages.isEmpty) {
                            return _ConversationThreadEmptyState(
                              otherUserName: widget.conversation.otherUserName,
                              onRefresh: threadController.refresh,
                              onUseOpener: _handleUseOpener,
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
                                  onRetryFailedMessage: _handleRetryMessage,
                                  onMessageLongPress: _showMessageActions,
                                )
                              : _MessageList(
                                  scrollController: _messagesScrollController,
                                  messages: messages,
                                  currentUserId: widget.currentUser.id,
                                  onRefresh: threadController.refresh,
                                  onRetryFailedMessage: _handleRetryMessage,
                                  onMessageLongPress: _showMessageActions,
                                  historyTruncated: messages.length >= 100,
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
                    Positioned(
                      right: 4,
                      bottom: 10,
                      child: AnimatedOpacity(
                        opacity: _showJumpToLatest ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: IgnorePointer(
                          ignoring: !_showJumpToLatest,
                          child: _JumpToLatestButton(onPressed: _jumpToLatest),
                        ),
                      ),
                    ),
                  ],
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
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.send,
                            onChanged: _handleMessageChanged,
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
                              ? SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onSurfaceVariant.withValues(
                                        alpha: 0.62,
                                      ),
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
      case _ConversationMenuAction.archive:
        await _runListAction(
          (controller) => controller.archive(widget.conversation.id),
          doneMessage: 'Chat archived.',
        );
      case _ConversationMenuAction.unarchive:
        await _runListAction(
          (controller) => controller.unarchive(widget.conversation.id),
          doneMessage: 'Chat moved back to your chats.',
        );
      case _ConversationMenuAction.delete:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(
              'Delete chat with ${widget.conversation.otherUserName}?',
            ),
            content: Text(
              'This removes the chat from your list only. '
              '${widget.conversation.otherUserName} still sees it, and it '
              'comes back with its messages if either of you writes again.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete chat'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) {
          return;
        }
        await _runListAction(
          (controller) => controller.delete(widget.conversation.id),
          doneMessage: 'Chat deleted.',
        );
    }
  }

  /// Archive, unarchive and delete all change the chats list, so a finished
  /// one closes the thread.
  Future<void> _runListAction(
    Future<void> Function(ConversationsController controller) action, {
    required String doneMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(ref.read(conversationsControllerProvider));
    } on ApiError catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  void _handleMessageChanged(String value) {
    setState(() {});
    // Typing is only reported while there is text; the controller throttles.
    if (value.trim().isNotEmpty) {
      ref
          .read(presenceControllerProvider.notifier)
          .notifyTyping(widget.conversation.id);
    }
  }

  void _handleUseOpener(String opener) {
    _messageController.text = opener;
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
    setState(() {});
  }

  Future<void> _handleSend() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isSending) {
      return;
    }

    _messageController.clear();

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

  Future<void> _handleRetryMessage(MessageDto message) async {
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
    });

    try {
      await ref
          .read(conversationThreadControllerProvider(widget.conversation.id))
          .retryMessage(message);
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
        const SnackBar(content: Text('Unable to retry the message right now.')),
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

class _ConversationHeaderCard extends StatelessWidget {
  const _ConversationHeaderCard({
    required this.otherUserName,
    required this.archived,
    required this.presence,
    required this.onBack,
    required this.onOpenProfile,
    required this.onMenuSelected,
  });

  final String otherUserName;
  final bool archived;

  /// Null while unknown or when it could not be loaded.
  final UserPresence? presence;
  final VoidCallback onBack;
  final VoidCallback onOpenProfile;
  final ValueChanged<_ConversationMenuAction> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: AppTheme.surfaceDecoration(
        context,
        color: Color.alphaBlend(
          _threadSky.withValues(alpha: isDark ? 0.10 : 0.035),
          Color.alphaBlend(
            _threadTeal.withValues(alpha: isDark ? 0.10 : 0.03),
            colorScheme.surfaceContainerLow,
          ),
        ),
        prominent: true,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Back to chats',
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Conversation',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Back to chats',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                AppOverflowMenuButton<_ConversationMenuAction>(
                  tooltip: 'Conversation options',
                  items: [
                    const PopupMenuItem<_ConversationMenuAction>(
                      value: _ConversationMenuAction.viewProfile,
                      child: Text('View profile'),
                    ),
                    const PopupMenuItem<_ConversationMenuAction>(
                      value: _ConversationMenuAction.safetyActions,
                      child: Text('Safety actions'),
                    ),
                    const PopupMenuItem<_ConversationMenuAction>(
                      value: _ConversationMenuAction.refresh,
                      child: Text('Refresh messages'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<_ConversationMenuAction>(
                      value: archived
                          ? _ConversationMenuAction.unarchive
                          : _ConversationMenuAction.archive,
                      child: Text(archived ? 'Unarchive chat' : 'Archive chat'),
                    ),
                    const PopupMenuItem<_ConversationMenuAction>(
                      value: _ConversationMenuAction.delete,
                      child: Text('Delete chat'),
                    ),
                  ],
                  onSelected: onMenuSelected,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onOpenProfile,
                borderRadius: AppTheme.cardRadius,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                  child: Row(
                    children: [
                      UserAvatar(name: otherUserName, radius: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              otherUserName,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _ConversationPresenceLine(presence: presence),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: _threadTeal.withValues(
                            alpha: isDark ? 0.20 : 0.10,
                          ),
                          borderRadius: AppTheme.chipRadius,
                          border: Border.all(
                            color: _threadTeal.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_outline_rounded,
                                size: 16,
                                color: _threadTeal,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Open profile',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: _threadTeal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

/// The line under the name: "typing" with dots, a dot with Online/Away, or the
/// plain profile hint when the person is offline or presence is unknown.
class _ConversationPresenceLine extends StatelessWidget {
  const _ConversationPresenceLine({required this.presence});

  final UserPresence? presence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final presence = this.presence;
    final style = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    if (presence != null && presence.typing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('typing', style: style?.copyWith(color: _threadTeal)),
          const SizedBox(width: 4),
          const TypingDots(color: _threadTeal),
        ],
      );
    }

    final isOnline = presence?.status == PresenceStatus.online;
    if (!isOnline && presence?.status != PresenceStatus.away) {
      return Text(
        'Tap name to view profile',
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isOnline
                ? AppTheme.activeColor(context)
                : colorScheme.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            isOnline ? 'Online' : 'Away',
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.scrollController,
    required this.messages,
    required this.currentUserId,
    required this.onRefresh,
    required this.onRetryFailedMessage,
    required this.onMessageLongPress,
    required this.historyTruncated,
  });

  final ScrollController scrollController;
  final List<MessageDto> messages;
  final String currentUserId;
  final Future<void> Function() onRefresh;
  final ValueChanged<MessageDto> onRetryFailedMessage;
  final ValueChanged<MessageDto> onMessageLongPress;
  final bool historyTruncated;

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
        itemCount: entries.length + (historyTruncated ? 1 : 0),
        itemBuilder: (context, index) {
          if (historyTruncated && index == 0) {
            return const _MessageHistoryTruncationNotice();
          }

          final entry = entries[historyTruncated ? index - 1 : index];

          return Padding(
            padding: EdgeInsets.only(top: entry.topSpacing),
            child: entry.isDayDivider
                ? _MessageDayDivider(label: entry.dayLabel!)
                : _MessageBubble(
                    entry: entry,
                    onRetryFailedMessage: onRetryFailedMessage,
                    onMessageLongPress: onMessageLongPress,
                  ),
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
    required this.onRetryFailedMessage,
    required this.onMessageLongPress,
  });

  final ScrollController scrollController;
  final List<MessageDto> messages;
  final String currentUserId;
  final double viewportHeight;
  final Future<void> Function() onRefresh;
  final ValueChanged<MessageDto> onRetryFailedMessage;
  final ValueChanged<MessageDto> onMessageLongPress;

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
                      : _MessageBubble(
                          entry: entry,
                          onRetryFailedMessage: onRetryFailedMessage,
                          onMessageLongPress: onMessageLongPress,
                        ),
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
    required this.onUseOpener,
  });

  final String otherUserName;
  final Future<void> Function() onRefresh;
  final ValueChanged<String> onUseOpener;

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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final opener in [
                        'Hi $otherUserName! What has your week been like?',
                        'Your photos caught my eye — what do you enjoy doing on weekends?',
                        'Quick question: coffee or a walk for a first meet?',
                      ])
                        ActionChip(
                          label: Text(
                            opener,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onPressed: () => onUseOpener(opener),
                        ),
                    ],
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

class _MessageHistoryTruncationNotice extends StatelessWidget {
  const _MessageHistoryTruncationNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
          borderRadius: AppTheme.chipRadius,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 15,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Showing the most recent messages. Older history stays on '
                  'the server.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

class _JumpToLatestButton extends StatelessWidget {
  const _JumpToLatestButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      shape: const CircleBorder(),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        tooltip: 'Jump to latest messages',
        onPressed: onPressed,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        color: colorScheme.onSurface,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
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
  const _MessageBubble({
    required this.entry,
    required this.onRetryFailedMessage,
    required this.onMessageLongPress,
  });

  final _ConversationEntry entry;
  final ValueChanged<MessageDto> onRetryFailedMessage;
  final ValueChanged<MessageDto> onMessageLongPress;

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
                  ? const [Color(0xFF0B5156), Color(0xFF15757E)]
                  : const [Color(0xFF96DBD2), Color(0xFF74C8BE)],
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

    return GestureDetector(
      onLongPress: () => onMessageLongPress(message),
      child: Align(
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
                  if (message.localState != MessageLocalState.none) ...[
                    const SizedBox(height: 8),
                    _MessageLocalStateRow(
                      message: message,
                      foregroundColor: entry.isOutgoing
                          ? outgoingTextColor.withValues(alpha: 0.88)
                          : colorScheme.onSurfaceVariant,
                      onRetryFailedMessage: onRetryFailedMessage,
                    ),
                  ] else if (entry.showTimestamp) ...[
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
      ),
    );
  }
}

class _MessageLocalStateRow extends StatelessWidget {
  const _MessageLocalStateRow({
    required this.message,
    required this.foregroundColor,
    required this.onRetryFailedMessage,
  });

  final MessageDto message;
  final Color foregroundColor;
  final ValueChanged<MessageDto> onRetryFailedMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.localState == MessageLocalState.sending) ...[
          SizedBox.square(
            dimension: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Sending…',
            style: theme.textTheme.bodySmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ] else if (message.localState == MessageLocalState.failed) ...[
          Icon(Icons.error_outline_rounded, size: 14, color: foregroundColor),
          const SizedBox(width: 6),
          Text(
            'Not sent',
            style: theme.textTheme.bodySmall?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () => onRetryFailedMessage(message),
            style: TextButton.styleFrom(
              foregroundColor: foregroundColor,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Retry'),
          ),
        ],
      ],
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
