import 'profile_completion_info.dart';

class ProfileUpdateResponse {
  const ProfileUpdateResponse({
    this.completionInfo = const ProfileCompletionInfo(),
  });

  final ProfileCompletionInfo completionInfo;

  factory ProfileUpdateResponse.fromJson(Map<String, dynamic> json) {
    return ProfileUpdateResponse(
      completionInfo: ProfileCompletionInfo.fromJson(
        json['completionInfo'] is Map
            ? Map<String, dynamic>.from(json['completionInfo'] as Map)
            : json,
      ),
    );
  }
}