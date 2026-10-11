/// Today's swipe allowance, as reported by `GET /api/users/{id}/daily-status`.
class DailyStatus {
  const DailyStatus({
    required this.likes,
    required this.superLikes,
    required this.passes,
    this.resetsAt,
  });

  final DailyAllowance likes;
  final DailyAllowance superLikes;
  final DailyAllowance passes;
  final DateTime? resetsAt;

  factory DailyStatus.fromJson(Map<String, dynamic> json) {
    return DailyStatus(
      likes: DailyAllowance.fromJson(json['likes']),
      superLikes: DailyAllowance.fromJson(json['superLikes']),
      passes: DailyAllowance.fromJson(json['passes']),
      resetsAt: DateTime.tryParse(json['resetsAt'] as String? ?? ''),
    );
  }
}

class DailyAllowance {
  const DailyAllowance({
    required this.used,
    required this.remaining,
    required this.unlimited,
  });

  final int used;

  /// Null when [unlimited], and when the backend did not send the kind at all.
  final int? remaining;
  final bool unlimited;

  factory DailyAllowance.fromJson(Object? json) {
    final map = json is Map ? json : const <String, dynamic>{};
    return DailyAllowance(
      used: (map['used'] as num?)?.toInt() ?? 0,
      remaining: (map['remaining'] as num?)?.toInt(),
      unlimited: map['unlimited'] as bool? ?? false,
    );
  }
}
