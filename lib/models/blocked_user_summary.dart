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
    return BlockedUserSummary(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown user',
      statusLabel: json['statusLabel'] as String? ?? 'Blocked profile',
    );
  }
}
