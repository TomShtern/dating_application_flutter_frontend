import 'person_summary_fields.dart';

class MatchSummary {
  const MatchSummary({
    required this.matchId,
    required this.otherUserId,
    required this.otherUserName,
    required this.state,
    required this.createdAt,
    this.primaryPhotoUrl,
    this.photoUrls = const <String>[],
    this.approximateLocation,
    this.summaryLine,
  });

  final String matchId;
  final String otherUserId;
  final String otherUserName;
  final String state;
  final DateTime createdAt;
  final String? primaryPhotoUrl;
  final List<String> photoUrls;
  final String? approximateLocation;
  final String? summaryLine;

  factory MatchSummary.fromJson(Map<String, dynamic> json) {
    return MatchSummary(
      matchId: json['matchId'] as String? ?? '',
      otherUserId: json['otherUserId'] as String? ?? '',
      otherUserName: json['otherUserName'] as String? ?? 'Unknown user',
      state: json['state'] as String? ?? 'UNKNOWN',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      primaryPhotoUrl: parseNullableString(json['primaryPhotoUrl']),
      photoUrls: parseStringList(json['photoUrls']),
      approximateLocation: parseNullableString(json['approximateLocation']),
      summaryLine: parseNullableString(json['summaryLine']),
    );
  }
}
