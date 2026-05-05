class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.messageCount,
    required this.lastMessageAt,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.lastSenderId,
    this.lastSenderName,
  });

  final String id;
  final String otherUserId;
  final String otherUserName;
  final int messageCount;
  final DateTime lastMessageAt;
  final String? lastMessagePreview;
  final int unreadCount;
  final String? lastSenderId;
  final String? lastSenderName;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    final lastMessage = _asMap(json['lastMessage']);
    final lastMessageSender = _asMap(lastMessage?['sender']);

    return ConversationSummary(
      id: json['id'] as String? ?? '',
      otherUserId: json['otherUserId'] as String? ?? '',
      otherUserName: json['otherUserName'] as String? ?? 'Unknown user',
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      lastMessageAt:
          _parseDateTime(json['lastMessageAt']) ??
          _parseDateTime(lastMessage?['sentAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      lastMessagePreview: _readFirstString([
        json['lastMessagePreview'],
        json['lastMessageText'],
        json['lastMessageSummary'],
        if (json['lastMessage'] is String) json['lastMessage'],
        lastMessage?['content'],
        lastMessage?['text'],
        lastMessage?['preview'],
        lastMessage?['summary'],
      ]),
      unreadCount: _parseInt(json['unreadCount']) ?? 0,
      lastSenderId: _readFirstString([
        json['lastSenderId'],
        json['lastMessageSenderId'],
        lastMessage?['senderId'],
        lastMessageSender?['id'],
      ]),
      lastSenderName: _readFirstString([
        json['lastSenderName'],
        json['lastMessageSenderName'],
        lastMessage?['senderName'],
        lastMessageSender?['name'],
      ]),
    );
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    if (value is! Map) {
      return null;
    }

    return Map<String, dynamic>.from(value);
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static int? _parseInt(Object? value) {
    return switch (value) {
      final int number => number,
      final num number => number.toInt(),
      final String text => int.tryParse(text.trim()),
      _ => null,
    };
  }

  static String? _readFirstString(Iterable<Object?> candidates) {
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return null;
  }
}
