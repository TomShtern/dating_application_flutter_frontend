class ConversationSummary {
  const ConversationSummary({
    required this.id,
    required this.otherUserId,
    required this.otherUserName,
    required this.messageCount,
    required this.lastMessageAt,
  });

  final String id;
  final String otherUserId;
  final String otherUserName;
  final int messageCount;
  final DateTime lastMessageAt;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) {
    return ConversationSummary(
      id: json['id'] as String? ?? '',
      otherUserId: json['otherUserId'] as String? ?? '',
      otherUserName: json['otherUserName'] as String? ?? 'Unknown user',
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      lastMessageAt:
          DateTime.tryParse(json['lastMessageAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
