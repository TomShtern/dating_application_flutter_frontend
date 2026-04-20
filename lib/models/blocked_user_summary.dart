class BlockedUserSummary {
  const BlockedUserSummary({
    required this.userId,
    required this.name,
    required this.statusLabel,
  });

  final String userId;
  final String name;
  final String statusLabel;

  factory BlockedUserSummary.fromJson(Map<String, dynamic> json) {
    final userId = json['userId'] as String?;
    if (userId == null || userId.trim().isEmpty) {
      throw StateError('Missing userId in BlockedUserSummary.fromJson');
    }

    return BlockedUserSummary(
      userId: userId,
      name: json['name'] as String? ?? 'Unknown user',
      statusLabel: json['statusLabel'] as String? ?? 'Blocked profile',
    );
  }
}
