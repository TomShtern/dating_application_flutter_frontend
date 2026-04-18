class MatchSummary {
  const MatchSummary({
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    required this.state,
    required this.createdAt,
  });

  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String state;
  final DateTime createdAt;

  factory MatchSummary.fromJson(Map<String, dynamic> json) {
    return MatchSummary(
      matchId: json['matchId'] as String? ?? '',
      otherUserId: json['otherUserId'] as String? ?? '',
      otherUserName: json['otherUserName'] as String? ?? 'Unknown user',
      state: json['state'] as String? ?? 'UNKNOWN',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
