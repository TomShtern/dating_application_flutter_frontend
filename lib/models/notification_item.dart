class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.data,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime? createdAt;
  final bool isRead;
  final Map<String, String> data;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final data = rawData is Map ? rawData : const <dynamic, dynamic>{};

    return NotificationItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'UNKNOWN',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      isRead: json['isRead'] as bool? ?? false,
      data: data.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  }

  NotificationTypeRegistration? get typeRegistration {
    return notificationTypeRegistry[type.trim().toUpperCase()];
  }

  NotificationRoute? get safeRoute {
    return typeRegistration?.resolve(data);
  }

  bool get isKnownType => typeRegistration != null;

  bool get isKnownRoutableType => safeRoute != null;

  String? get matchId => isKnownRoutableType ? data['matchId'] : null;

  String? get conversationId =>
      isKnownRoutableType ? data['conversationId'] : null;

  String? get otherUserId {
    if (!isKnownRoutableType) {
      return null;
    }

    return data['otherUserId'] ?? data['senderId'] ?? data['accepterUserId'];
  }
}

enum NotificationDestination { chatThread, profile }

class NotificationRoute {
  const NotificationRoute({
    required this.destination,
    required this.actionLabel,
    required this.data,
  });

  final NotificationDestination destination;
  final String actionLabel;
  final Map<String, String> data;
}

class NotificationTypeRegistration {
  const NotificationTypeRegistration({
    required this.type,
    required this.requiredKeys,
    this.destination,
    this.actionLabel,
  });

  final String type;
  final Set<String> requiredKeys;
  final NotificationDestination? destination;
  final String? actionLabel;

  NotificationRoute? resolve(Map<String, String> data) {
    final hasRequiredData = requiredKeys.every(
      (key) => (data[key]?.trim().isNotEmpty ?? false),
    );
    if (!hasRequiredData || destination == null || actionLabel == null) {
      return null;
    }

    return NotificationRoute(
      destination: destination!,
      actionLabel: actionLabel!,
      data: data,
    );
  }
}

const notificationTypeRegistry = <String, NotificationTypeRegistration>{
  'MATCH_FOUND': NotificationTypeRegistration(
    type: 'MATCH_FOUND',
    requiredKeys: {'matchId', 'conversationId', 'otherUserId'},
    destination: NotificationDestination.chatThread,
    actionLabel: 'Open chat',
  ),
  'NEW_MESSAGE': NotificationTypeRegistration(
    type: 'NEW_MESSAGE',
    requiredKeys: {'conversationId', 'senderId', 'messageId'},
    destination: NotificationDestination.chatThread,
    actionLabel: 'Open thread',
  ),
  'FRIEND_REQUEST': NotificationTypeRegistration(
    type: 'FRIEND_REQUEST',
    requiredKeys: {'requestId', 'fromUserId', 'matchId'},
    destination: NotificationDestination.profile,
    actionLabel: 'View profile',
  ),
  'FRIEND_REQUEST_ACCEPTED': NotificationTypeRegistration(
    type: 'FRIEND_REQUEST_ACCEPTED',
    requiredKeys: {'requestId', 'accepterUserId', 'matchId', 'conversationId'},
    destination: NotificationDestination.chatThread,
    actionLabel: 'Open chat',
  ),
  'GRACEFUL_EXIT': NotificationTypeRegistration(
    type: 'GRACEFUL_EXIT',
    requiredKeys: {'initiatorId', 'matchId'},
  ),
};
