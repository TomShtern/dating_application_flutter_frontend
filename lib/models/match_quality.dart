class MatchQuality {
  const MatchQuality({
    required this.matchId,
    required this.perspectiveUserId,
    required this.otherUserId,
    required this.compatibilityScore,
    required this.compatibilityLabel,
    required this.starDisplay,
    required this.paceSyncLevel,
    required this.distanceKm,
    required this.ageDifference,
    required this.highlights,
  });

  final String matchId;
  final String perspectiveUserId;
  final String otherUserId;
  final int compatibilityScore;
  final String compatibilityLabel;
  final String starDisplay;
  final String paceSyncLevel;
  final double distanceKm;
  final int ageDifference;
  final List<String> highlights;

  factory MatchQuality.fromJson(Map<String, dynamic> json) {
    return MatchQuality(
      matchId: json['matchId'] as String? ?? '',
      perspectiveUserId: json['perspectiveUserId'] as String? ?? '',
      otherUserId: json['otherUserId'] as String? ?? '',
      compatibilityScore: (json['compatibilityScore'] as num?)?.toInt() ?? 0,
      compatibilityLabel: json['compatibilityLabel'] as String? ?? '',
      starDisplay: json['starDisplay'] as String? ?? '',
      paceSyncLevel: json['paceSyncLevel'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      ageDifference: (json['ageDifference'] as num?)?.toInt() ?? 0,
      highlights: (json['highlights'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(growable: false),
    );
  }
}
