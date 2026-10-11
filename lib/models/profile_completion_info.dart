/// Profile completion as the backend reports it (`ProfileCompletionDto`).
///
/// Field keys are the backend's `User.REQUIRED_PROFILE_FIELDS`, in this order:
/// [fieldOrder].
class ProfileCompletionInfo {
  const ProfileCompletionInfo({
    this.missingProfileFields = const [],
    this.missingProfileFieldLabels = const [],
    this.requiredProfileFieldCount = 0,
    this.profileComplete = false,
    this.canActivate = false,
    this.canBrowse = false,
  });

  /// Backend completion keys, in the order the backend checks them.
  static const fieldOrder = <String>[
    'name',
    'bio',
    'birthDate',
    'gender',
    'interestedIn',
    'location',
    'photoUrls',
    'pacePreferences',
  ];

  final List<String> missingProfileFields;

  /// Display names parallel to [missingProfileFields] (same index).
  final List<String> missingProfileFieldLabels;
  final int requiredProfileFieldCount;
  final bool profileComplete;
  final bool canActivate;
  final bool canBrowse;

  factory ProfileCompletionInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProfileCompletionInfo();
    }
    List<String> strings(Object? value) =>
        value is List ? value.whereType<String>().toList() : const [];

    return ProfileCompletionInfo(
      missingProfileFields: strings(json['missingProfileFields']),
      missingProfileFieldLabels: strings(json['missingProfileFieldLabels']),
      requiredProfileFieldCount:
          (json['requiredProfileFieldCount'] as num?)?.toInt() ?? 0,
      profileComplete: json['profileComplete'] as bool? ?? false,
      canActivate: json['canActivate'] as bool? ?? false,
      canBrowse: json['canBrowse'] as bool? ?? false,
    );
  }

  static String defaultLabel(String key) {
    return switch (key) {
      'name' => 'Add your name',
      'birthDate' => 'Add your date of birth',
      'location' => 'Set your location',
      'photoUrls' => 'Add a profile photo',
      'pacePreferences' => 'Set your pace preferences',
      'gender' => 'Set your gender',
      'interestedIn' => "Set who you're interested in",
      'bio' => 'Add a bio',
      _ => 'Complete: $key',
    };
  }
}
