class Standout {
  const Standout({
    required this.id,
    required this.standoutUserId,
    required this.standoutUserName,
    required this.standoutUserAge,
    required this.rank,
    required this.score,
    required this.reason,
    required this.createdAt,
    required this.interactedAt,
  });

  final String id;
  final String standoutUserId;
  final String standoutUserName;
  final int standoutUserAge;
  final int rank;
  final int score;
  final String reason;
  final DateTime? createdAt;
  final DateTime? interactedAt;

  factory Standout.fromJson(Map<String, dynamic> json) {
    return Standout(
      id: json['id'] as String? ?? '',
      standoutUserId: json['standoutUserId'] as String? ?? '',
      standoutUserName: json['standoutUserName'] as String? ?? 'Unknown user',
      standoutUserAge: (json['standoutUserAge'] as num?)?.toInt() ?? 0,
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      score: (json['score'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      interactedAt: DateTime.tryParse(json['interactedAt'] as String? ?? ''),
    );
  }
}

class StandoutsSnapshot {
  const StandoutsSnapshot({
    required this.standouts,
    required this.totalCandidates,
    required this.fromCache,
    required this.message,
  });

  final List<Standout> standouts;
  final int totalCandidates;
  final bool fromCache;
  final String message;

  factory StandoutsSnapshot.fromJson(Map<String, dynamic> json) {
    return StandoutsSnapshot(
      standouts: (json['standouts'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Standout.fromJson)
          .toList(growable: false),
      totalCandidates: (json['totalCandidates'] as num?)?.toInt() ?? 0,
      fromCache: json['fromCache'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }
}
