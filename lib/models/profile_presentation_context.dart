import 'person_summary_fields.dart';

class ProfilePresentationContext {
  const ProfilePresentationContext({
    required this.viewerUserId,
    required this.targetUserId,
    required this.summary,
    required this.reasonTags,
    required this.details,
    required this.generatedAt,
  });

  final String viewerUserId;
  final String targetUserId;
  final String summary;
  final List<String> reasonTags;
  final List<String> details;
  final String generatedAt;

  factory ProfilePresentationContext.fromJson(Map<String, dynamic> json) {
    return ProfilePresentationContext(
      viewerUserId: json['viewerUserId'] as String? ?? '',
      targetUserId: json['targetUserId'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      reasonTags: parseStringList(json['reasonTags']),
      details: parseStringList(json['details']),
      generatedAt: json['generatedAt'] as String? ?? '',
    );
  }
}
