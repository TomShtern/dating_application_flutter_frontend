import 'person_summary_fields.dart';

class DailyPick {
  const DailyPick({
    required this.userId,
    required this.userName,
    required this.userAge,
    required this.date,
    required this.reason,
    required this.alreadySeen,
    this.primaryPhotoUrl,
    this.photoUrls = const <String>[],
    this.approximateLocation,
    this.summaryLine,
  });

  final String userId;
  final String userName;
  final int userAge;
  final String date;
  final String reason;
  final bool alreadySeen;
  final String? primaryPhotoUrl;
  final List<String> photoUrls;
  final String? approximateLocation;
  final String? summaryLine;

  factory DailyPick.fromJson(Map<String, dynamic> json) {
    return DailyPick(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? 'Unknown user',
      userAge: (json['userAge'] as num?)?.toInt() ?? 0,
      date: json['date'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      alreadySeen: json['alreadySeen'] as bool? ?? false,
      primaryPhotoUrl: parseNullableString(json['primaryPhotoUrl']),
      photoUrls: parseStringList(json['photoUrls']),
      approximateLocation: parseNullableString(json['approximateLocation']),
      summaryLine: parseNullableString(json['summaryLine']),
    );
  }
}
