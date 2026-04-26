import 'person_summary_fields.dart';

class PendingLiker {
  const PendingLiker({
    required this.userId,
    required this.name,
    required this.age,
    required this.likedAt,
    this.primaryPhotoUrl,
    this.photoUrls = const <String>[],
    this.approximateLocation,
    this.summaryLine,
  });

  final String userId;
  final String name;
  final int age;
  final DateTime? likedAt;
  final String? primaryPhotoUrl;
  final List<String> photoUrls;
  final String? approximateLocation;
  final String? summaryLine;

  factory PendingLiker.fromJson(Map<String, dynamic> json) {
    return PendingLiker(
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown user',
      age: (json['age'] as num?)?.toInt() ?? 0,
      likedAt: DateTime.tryParse(json['likedAt'] as String? ?? ''),
      primaryPhotoUrl: parseNullableString(json['primaryPhotoUrl']),
      photoUrls: parseStringList(json['photoUrls']),
      approximateLocation: parseNullableString(json['approximateLocation']),
      summaryLine: parseNullableString(json['summaryLine']),
    );
  }
}
