import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/conversation_summary.dart';
import '../../models/message_dto.dart';
import '../../models/user_summary.dart';
import '../../shared/formatting/date_formatting.dart';
import '../../shared/widgets/app_async_state.dart';
import '../../shared/widgets/user_avatar.dart';
import '../profile/profile_screen.dart';
import '../safety/safety_action_sheet.dart';
import 'conversation_thread_provider.dart';

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
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

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

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            UserAvatar(name: widget.conversation.otherUserName, radius: 16),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.conversation.otherUserName)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'View profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => ProfileScreen.otherUser(
                    userId: widget.conversation.otherUserId,
                    userName: widget.conversation.otherUserName,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.person_outline_rounded),
          ),
          SafetyActionsButton(
            targetUserId: widget.conversation.otherUserId,
            targetUserName: widget.conversation.otherUserName,
            canUnmatch: true,
            onCompleted: (context, outcome) {
              if (outcome.removesRelationship) {
                Navigator.of(context).maybePop();
              }
            },
          ),
          IconButton(
            tooltip: 'Refresh messages',
            onPressed: () => ref
                .read(
                  conversationThreadControllerProvider(widget.conversation.id),
                )
                .refresh(),
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
                'Conversation with ${widget.conversation.otherUserName}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: threadState.when(
                  data: (messages) {
                    if (messages.isEmpty) {
                      return const AppAsyncState.empty(
                        message:
                            'No messages yet. Say hello to start the conversation.',
                      );
                    }

                    _scheduleAutoScrollToLatest(messages.length);

                    return _MessageList(
                      scrollController: _messagesScrollController,
                      messages: messages,
                      currentUserId: widget.currentUser.id,
                      otherUserName: widget.conversation.otherUserName,
                      onRefresh: () => ref
                          .read(
                            conversationThreadControllerProvider(
                              widget.conversation.id,
                            ),
                          )
                          .refresh(),
                    );
                  },
                  loading: () =>
                      const AppAsyncState.loading(message: 'Loading messages…'),
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
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onChanged: (_) => setState(() {}),
                          onSubmitted: (_) => _handleSend(),
                          decoration: const InputDecoration(
                            labelText: 'Message',
                            hintText: 'Send a message',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: trimmedMessage.isEmpty || _isSending
                            ? null
                            : _handleSend,
                        child: Text(_isSending ? 'Sending…' : 'Send'),
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

  void _scheduleAutoScrollToLatest(int messageCount) {
    if (_lastAutoScrolledMessageCount == messageCount) {
      return;
    }

    final isInitialAutoScroll = _lastAutoScrolledMessageCount == -1;
    _lastAutoScrolledMessageCount = messageCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_messagesScrollController.hasClients) {
        return;
      }

      final position = _messagesScrollController.position;
      final isNearLatest = position.maxScrollExtent - position.pixels < 80;
      if (!isInitialAutoScroll && !isNearLatest && messageCount > 1) {
        return;
      }

      _messagesScrollController.animateTo(
        position.maxScrollExtent,
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
    required this.otherUserName,
    required this.onRefresh,
  });

  final ScrollController scrollController;
  final List<MessageDto> messages;
  final String currentUserId;
  final String otherUserName;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        controller: scrollController,
        itemCount: messages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final message = messages[index];
          final isOutgoing = message.senderId == currentUserId;

          return Align(
            alignment: isOutgoing
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Card(
                color: isOutgoing
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOutgoing ? 'You' : otherUserName,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(message.content),
                      const SizedBox(height: 8),
                      Text(
                        formatDateTimeStamp(message.sentAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
