/// Backend report taxonomy for `POST /api/users/{id}/report/{targetId}`.
/// Backend requires `{reason, description?, blockUser}` and rejects empty
/// bodies with 400 (`SocialDtos.java:74`, `RestApiServer.java:1316-1336`).
enum ReportReason {
  spam('SPAM', 'Spam or scam'),
  inappropriateContent('INAPPROPRIATE_CONTENT', 'Inappropriate content'),
  harassment('HARASSMENT', 'Harassment or abuse'),
  fakeProfile('FAKE_PROFILE', 'Fake profile'),
  underage('UNDERAGE', 'Possibly underage'),
  other('OTHER', 'Something else');

  const ReportReason(this.value, this.label);

  final String value;
  final String label;
}

class ReportUserRequest {
  const ReportUserRequest({
    required this.reason,
    this.description,
    this.blockUser = false,
  });

  final ReportReason reason;
  final String? description;
  final bool blockUser;

  Map<String, dynamic> toJson() {
    return {
      'reason': reason.value,
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      'blockUser': blockUser,
    };
  }
}
