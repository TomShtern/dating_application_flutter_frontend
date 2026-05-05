import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../api/api_error.dart';
import '../auth/selected_user_provider.dart';
import '../../models/message_dto.dart';
import '../../models/user_summary.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;
import 'conversations_provider.dart';

final conversationThreadProvider =
    FutureProvider.family<List<MessageDto>, String>((
      ref,
      conversationId,
    ) async {
      final apiClient = ref.watch(apiClientProvider);
      final currentUser = await user_guard.watchSelectedUser(ref);
      return apiClient.getMessages(
        conversationId: conversationId,
        userId: currentUser.id,
      );
    });

final conversationLocalMessagesProvider =
    NotifierProvider<
      ConversationLocalMessagesNotifier,
      Map<String, List<MessageDto>>
    >(ConversationLocalMessagesNotifier.new);

final conversationThreadMessagesProvider =
    Provider.family<AsyncValue<List<MessageDto>>, String>((
      ref,
      conversationId,
    ) {
      final remoteMessages = ref.watch(
        conversationThreadProvider(conversationId),
      );
      final localMessages = ref.watch(
        conversationLocalMessagesProvider.select(
          (state) => state[conversationId] ?? const <MessageDto>[],
        ),
      );

      return remoteMessages.whenData(
        (messages) => _mergeConversationMessages(messages, localMessages),
      );
    });

final conversationThreadControllerProvider =
    Provider.family<ConversationThreadController, String>((
      ref,
      conversationId,
    ) {
      return ConversationThreadController(ref, conversationId);
    });

class ConversationThreadController {
  ConversationThreadController(this._ref, this._conversationId);

  final Ref _ref;
  final String _conversationId;

  Future<void> refresh() async {
    final messages = await _ref.refresh(
      conversationThreadProvider(_conversationId).future,
    );
    if (!_ref.mounted) {
      return;
    }

    _ref
        .read(conversationLocalMessagesProvider.notifier)
        .pruneSynced(_conversationId, messages);
  }

  Future<MessageDto> sendMessage(String content) async {
    final currentUser =
        _readCachedSelectedUser() ?? await _requireSelectedUser();
    final trimmedContent = content.trim();

    if (trimmedContent.isEmpty) {
      throw const ApiError(message: 'Please enter a message before sending.');
    }

    final localMessages = _ref.read(conversationLocalMessagesProvider.notifier);
    final localMessage = localMessages.queueSending(
      conversationId: _conversationId,
      senderId: currentUser.id,
      content: trimmedContent,
    );

    return _sendQueuedMessage(
      currentUser: currentUser,
      queuedMessage: localMessage,
    );
  }

  Future<MessageDto> retryMessage(MessageDto message) async {
    if (!message.isLocallyFailed || message.localId == null) {
      throw const ApiError(
        message: 'Only failed local messages can be retried.',
      );
    }

    final currentUser =
        _readCachedSelectedUser() ?? await _requireSelectedUser();
    final localMessages = _ref.read(conversationLocalMessagesProvider.notifier);
    final retryingMessage = message.copyWith(
      localState: MessageLocalState.sending,
    );

    localMessages.upsertMessage(
      conversationId: _conversationId,
      message: retryingMessage,
    );

    return _sendQueuedMessage(
      currentUser: currentUser,
      queuedMessage: retryingMessage,
    );
  }

  Future<MessageDto> _sendQueuedMessage({
    required UserSummary currentUser,
    required MessageDto queuedMessage,
  }) async {
    final apiClient = _ref.read(apiClientProvider);

    try {
      final message = await apiClient.sendMessage(
        conversationId: _conversationId,
        userId: currentUser.id,
        content: queuedMessage.content.trim(),
      );

      if (!_ref.mounted) {
        return message;
      }

      _ref
          .read(conversationLocalMessagesProvider.notifier)
          .replaceWithConfirmed(
            conversationId: _conversationId,
            queuedMessage: queuedMessage,
            confirmedMessage: message,
          );

      _ref.invalidate(conversationsProvider);
      unawaited(refresh());
      return message;
    } on ApiError {
      _ref
          .read(conversationLocalMessagesProvider.notifier)
          .markFailed(conversationId: _conversationId, message: queuedMessage);
      rethrow;
    } catch (_) {
      _ref
          .read(conversationLocalMessagesProvider.notifier)
          .markFailed(conversationId: _conversationId, message: queuedMessage);
      rethrow;
    }
  }

  Future<UserSummary> _requireSelectedUser() async {
    return user_guard.requireSelectedUser(_ref);
  }

  UserSummary? _readCachedSelectedUser() {
    return _ref.read(selectedUserProvider).whenOrNull(data: (user) => user);
  }
}

class ConversationLocalMessagesNotifier
    extends Notifier<Map<String, List<MessageDto>>> {
  @override
  Map<String, List<MessageDto>> build() => const <String, List<MessageDto>>{};

  MessageDto queueSending({
    required String conversationId,
    required String senderId,
    required String content,
  }) {
    final message = MessageDto.localSending(
      conversationId: conversationId,
      senderId: senderId,
      content: content,
    );

    _storeMessages(conversationId, [
      ..._messagesForConversation(conversationId),
      message,
    ]);
    return message;
  }

  void upsertMessage({
    required String conversationId,
    required MessageDto message,
  }) {
    final messages = [..._messagesForConversation(conversationId)];
    final index = messages.indexWhere(
      (item) => _matchesLocalMessage(item, message),
    );

    if (index == -1) {
      messages.add(message);
    } else {
      messages[index] = message;
    }

    _storeMessages(conversationId, messages);
  }

  void markFailed({
    required String conversationId,
    required MessageDto message,
  }) {
    upsertMessage(
      conversationId: conversationId,
      message: message.copyWith(localState: MessageLocalState.failed),
    );
  }

  void replaceWithConfirmed({
    required String conversationId,
    required MessageDto queuedMessage,
    required MessageDto confirmedMessage,
  }) {
    upsertMessage(
      conversationId: conversationId,
      message: confirmedMessage.copyWith(localId: queuedMessage.localId),
    );
  }

  void pruneSynced(String conversationId, List<MessageDto> remoteMessages) {
    final remoteIds = remoteMessages
        .map((message) => message.id)
        .where((id) => id.isNotEmpty)
        .toSet();

    final retainedMessages = _messagesForConversation(conversationId)
        .where(
          (message) =>
              message.localState != MessageLocalState.none ||
              !remoteIds.contains(message.id),
        )
        .toList(growable: false);

    _storeMessages(conversationId, retainedMessages);
  }

  List<MessageDto> _messagesForConversation(String conversationId) {
    return state[conversationId] ?? const <MessageDto>[];
  }

  void _storeMessages(String conversationId, List<MessageDto> messages) {
    final nextState = Map<String, List<MessageDto>>.from(state);

    if (messages.isEmpty) {
      nextState.remove(conversationId);
    } else {
      nextState[conversationId] = List<MessageDto>.unmodifiable(messages);
    }

    state = Map<String, List<MessageDto>>.unmodifiable(nextState);
  }

  bool _matchesLocalMessage(MessageDto left, MessageDto right) {
    return (left.localId != null &&
            right.localId != null &&
            left.localId == right.localId) ||
        left.id.isNotEmpty && left.id == right.id;
  }
}

List<MessageDto> _mergeConversationMessages(
  List<MessageDto> remoteMessages,
  List<MessageDto> localMessages,
) {
  final remoteIds = remoteMessages
      .map((message) => message.id)
      .where((id) => id.isNotEmpty)
      .toSet();
  final mergedMessages = <MessageDto>[
    ...remoteMessages,
    ...localMessages.where(
      (message) =>
          message.localState != MessageLocalState.none ||
          !remoteIds.contains(message.id),
    ),
  ];

  mergedMessages.sort((left, right) {
    final sentAtComparison = left.sentAt.compareTo(right.sentAt);
    if (sentAtComparison != 0) {
      return sentAtComparison;
    }

    if (left.localState == MessageLocalState.none &&
        right.localState != MessageLocalState.none) {
      return -1;
    }

    if (left.localState != MessageLocalState.none &&
        right.localState == MessageLocalState.none) {
      return 1;
    }

    return left.id.compareTo(right.id);
  });

  return List<MessageDto>.unmodifiable(mergedMessages);
}
