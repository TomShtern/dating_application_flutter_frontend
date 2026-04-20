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
    return NotificationItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'UNKNOWN',
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      isRead: json['isRead'] as bool? ?? false,
      data:
          (json['data'] as Map<dynamic, dynamic>? ?? const <dynamic, dynamic>{})
              .map((key, value) => MapEntry(key.toString(), value.toString())),
    );
  }
}
