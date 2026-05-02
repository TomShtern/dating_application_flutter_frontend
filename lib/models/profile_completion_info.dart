class ProfileCompletionInfo {
  const ProfileCompletionInfo({
    this.missingProfileFields = const [],
    this.missingProfileFieldLabels = const {},
    this.requiredProfileFieldCount = 0,
    this.profileComplete = false,
    this.canActivate = false,
    this.canBrowse = false,
  });

  final List<String> missingProfileFields;
  final Map<String, String> missingProfileFieldLabels;
  final int requiredProfileFieldCount;
  final bool profileComplete;
  final bool canActivate;
  final bool canBrowse;

  factory ProfileCompletionInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ProfileCompletionInfo();
    }
    final missingFields = (json['missingProfileFields'] as List<dynamic>?)
            ?.whereType<String>()
            .toList() ??
        const [];
    final labels = <String, String>{};
    final rawLabels = json['missingProfileFieldLabels'];
    if (rawLabels is Map) {
      for (final entry in rawLabels.entries) {
        labels[entry.key.toString()] = entry.value.toString();
      }
    }
    return ProfileCompletionInfo(
      missingProfileFields: missingFields,
      missingProfileFieldLabels: labels,
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
      'dob' => 'Add your date of birth',
      'location' => 'Set your location',
      'photo' => 'Add a profile photo',
      'pace' => 'Set your pace preference',
      'gender' => 'Set your gender',
      'interestedIn' => "Set who you're interested in",
      'bio' => 'Add a bio',
      _ => 'Complete: $key',
    };
  }

  static bool isActionable(String key) {
    return switch (key) {
      'dob' => false,
      _ => true,
    };
  }
}