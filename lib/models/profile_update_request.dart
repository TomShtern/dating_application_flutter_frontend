/// A partial profile update payload built from the fields currently surfaced
/// by the mobile read model.
///
/// Until the backend exposes a richer read DTO for profile editing, the mobile
/// client relies on omitted write-side fields being preserved server-side.
class ProfileUpdateRequest {
  const ProfileUpdateRequest({
    this.name,
    this.bio,
    this.gender,
    this.interestedIn,
    this.maxDistanceKm,
    this.minAge,
    this.maxAge,
    this.heightCm,
    this.location,
    this.pacePreferences,
  });

  final String? name;
  final String? bio;
  final String? gender;
  final List<String>? interestedIn;
  final int? maxDistanceKm;
  final int? minAge;
  final int? maxAge;
  final int? heightCm;
  final ProfileLocationRequest? location;
  final String? pacePreferences;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{};

    if (name != null) {
      payload['name'] = name;
    }
    if (bio != null) {
      payload['bio'] = bio;
    }
    if (gender != null && gender!.isNotEmpty) {
      payload['gender'] = gender;
    }
    if (interestedIn != null) {
      payload['interestedIn'] = List<String>.of(interestedIn!, growable: false);
    }
    if (maxDistanceKm != null) {
      payload['maxDistanceKm'] = maxDistanceKm;
    }
    if (minAge != null) {
      payload['minAge'] = minAge;
    }
    if (maxAge != null) {
      payload['maxAge'] = maxAge;
    }
    if (heightCm != null) {
      payload['heightCm'] = heightCm;
    }
    if (location != null) {
      payload['location'] = location!.toJson();
    }
    if (pacePreferences != null) {
      payload['pacePreferences'] = pacePreferences;
    }

    return payload;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ProfileUpdateRequest &&
        other.name == name &&
        other.bio == bio &&
        other.gender == gender &&
        _listEquals(other.interestedIn, interestedIn) &&
        other.maxDistanceKm == maxDistanceKm &&
        other.minAge == minAge &&
        other.maxAge == maxAge &&
        other.heightCm == heightCm &&
        other.location == location &&
        other.pacePreferences == pacePreferences;
  }

  @override
  int get hashCode => Object.hash(
    name,
    bio,
    gender,
    interestedIn == null ? null : Object.hashAll(interestedIn!),
    maxDistanceKm,
    minAge,
    maxAge,
    heightCm,
    location,
    pacePreferences,
  );
}

class ProfileLocationRequest {
  const ProfileLocationRequest({
    required this.countryCode,
    required this.cityName,
    this.zipCode,
    this.allowApproximate = false,
  });

  final String countryCode;
  final String cityName;
  final String? zipCode;
  final bool allowApproximate;

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'cityName': cityName,
      if (zipCode != null && zipCode!.isNotEmpty) 'zipCode': zipCode,
      'allowApproximate': allowApproximate,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ProfileLocationRequest &&
        other.countryCode == countryCode &&
        other.cityName == cityName &&
        other.zipCode == zipCode &&
        other.allowApproximate == allowApproximate;
  }

  @override
  int get hashCode =>
      Object.hash(countryCode, cityName, zipCode, allowApproximate);
}

bool _listEquals(List<String>? left, List<String>? right) {
  if (identical(left, right)) {
    return true;
  }

  if (left == null || right == null) {
    return left == right;
  }

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
