enum MessageLocalState { none, sending, failed }

class MessageDto {
  const MessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.localId,
    this.localState = MessageLocalState.none,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final String? localId;
  final MessageLocalState localState;

  bool get isLocallySending => localState == MessageLocalState.sending;
  bool get isLocallyFailed => localState == MessageLocalState.failed;

  factory MessageDto.localSending({
    required String conversationId,
    required String senderId,
    required String content,
    DateTime? sentAt,
    String? localId,
  }) {
    final resolvedLocalId =
        localId ??
        'local-${DateTime.now().microsecondsSinceEpoch}-${content.hashCode}';

    return MessageDto(
      id: resolvedLocalId,
      conversationId: conversationId,
      senderId: senderId,
      content: content,
      sentAt: sentAt ?? DateTime.now().toUtc(),
      localId: resolvedLocalId,
      localState: MessageLocalState.sending,
    );
  }

  factory MessageDto.fromJson(Map<String, dynamic> json) {
    return MessageDto(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      content: json['content'] as String? ?? '',
      sentAt:
          DateTime.tryParse(json['sentAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  MessageDto copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    DateTime? sentAt,
    String? localId,
    MessageLocalState? localState,
  }) {
    return MessageDto(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      localId: localId ?? this.localId,
      localState: localState ?? this.localState,
    );
  }
}
