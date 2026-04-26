import 'person_summary_fields.dart';

class BrowseCandidate {
  const BrowseCandidate({
    required this.id,
    required this.name,
    required this.age,
    required this.state,
    this.primaryPhotoUrl,
    this.photoUrls = const <String>[],
    this.approximateLocation,
    this.summaryLine,
  });

  final String id;
  final String name;
  final int age;
  final String state;
  final String? primaryPhotoUrl;
  final List<String> photoUrls;
  final String? approximateLocation;
  final String? summaryLine;

  factory BrowseCandidate.fromJson(Map<String, dynamic> json) {
    return BrowseCandidate(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown user',
      age: (json['age'] as num?)?.toInt() ?? 0,
      state: json['state'] as String? ?? 'UNKNOWN',
      primaryPhotoUrl: parseNullableString(json['primaryPhotoUrl']),
      photoUrls: parseStringList(json['photoUrls']),
      approximateLocation: parseNullableString(json['approximateLocation']),
      summaryLine: parseNullableString(json['summaryLine']),
    );
  }
}
