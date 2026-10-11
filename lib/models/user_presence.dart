enum PresenceStatus {
  online,
  away,
  offline;

  /// Anything the app does not recognise counts as offline, so a new backend
  /// status can never show a wrong indicator.
  static PresenceStatus parse(String? value) {
    return switch (value?.trim().toUpperCase()) {
      'ONLINE' => PresenceStatus.online,
      'AWAY' => PresenceStatus.away,
      _ => PresenceStatus.offline,
    };
  }
}

class UserPresence {
  const UserPresence({
    required this.status,
    required this.typing,
    this.checkedAt,
  });

  final PresenceStatus status;

  /// Only meaningful when the request named a conversation.
  final bool typing;
  final DateTime? checkedAt;

  /// Never throws: a field of the wrong type reads as offline / not typing.
  factory UserPresence.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    final checkedAt = json['checkedAt'];
    return UserPresence(
      status: PresenceStatus.parse(status is String ? status : null),
      typing: json['typing'] == true,
      checkedAt: checkedAt is String ? DateTime.tryParse(checkedAt) : null,
    );
  }
}
