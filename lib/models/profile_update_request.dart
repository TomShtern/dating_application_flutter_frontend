/// A partial profile update payload built from the fields currently surfaced
/// by the mobile read model.
///
/// Until the backend exposes a richer read DTO for profile editing, the mobile
/// client relies on omitted write-side fields being preserved server-side.
class ProfileUpdateRequest {
  const ProfileUpdateRequest({
    required this.bio,
    required this.gender,
    required this.interestedIn,
    required this.maxDistanceKm,
  });

  final String bio;
  final String gender;
  final List<String> interestedIn;
  final int maxDistanceKm;

  Map<String, dynamic> toJson() {
    return {
      'bio': bio,
      'gender': gender,
      'interestedIn': List<String>.of(interestedIn, growable: false),
      'maxDistanceKm': maxDistanceKm,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ProfileUpdateRequest &&
        other.bio == bio &&
        other.gender == gender &&
        _listEquals(other.interestedIn, interestedIn) &&
        other.maxDistanceKm == maxDistanceKm;
  }

  @override
  int get hashCode =>
      Object.hash(bio, gender, Object.hashAll(interestedIn), maxDistanceKm);
}

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }

  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) {
      return false;
    }
  }

  return true;
}
