import 'location_metadata.dart';
import 'person_summary_fields.dart';
import 'profile_completion_info.dart';
import 'profile_update_request.dart';

class ProfileEditSnapshot {
  const ProfileEditSnapshot({
    required this.userId,
    required this.editable,
    required this.readOnly,
    this.completionInfo = const ProfileCompletionInfo(),
  });

  final String userId;
  final ProfileEditEditable editable;
  final ProfileEditReadOnly readOnly;
  final ProfileCompletionInfo completionInfo;

  factory ProfileEditSnapshot.fromJson(Map<String, dynamic> json) {
    return ProfileEditSnapshot(
      userId: json['userId'] as String? ?? '',
      editable: ProfileEditEditable.fromJson(
        Map<String, dynamic>.from(json['editable'] as Map? ?? const {}),
      ),
      readOnly: ProfileEditReadOnly.fromJson(
        Map<String, dynamic>.from(json['readOnly'] as Map? ?? const {}),
      ),
      completionInfo: ProfileCompletionInfo.fromJson(json),
    );
  }

  ProfileUpdateRequest toUpdateRequest() {
    return ProfileUpdateRequest(
      name: editable.name,
      bio: editable.bio,
      gender: editable.gender,
      interestedIn: editable.interestedIn,
      maxDistanceKm: editable.maxDistanceKm,
      minAge: editable.minAge,
      maxAge: editable.maxAge,
      heightCm: editable.heightCm,
      location: editable.location?.toProfileLocationRequest(),
      pacePreferences: editable.pacePreferences,
    );
  }
}

class ProfileEditEditable {
  const ProfileEditEditable({
    this.name,
    this.bio,
    this.birthDate,
    this.gender,
    this.interestedIn = const <String>[],
    this.maxDistanceKm,
    this.minAge,
    this.maxAge,
    this.heightCm,
    this.smoking,
    this.drinking,
    this.wantsKids,
    this.lookingFor,
    this.education,
    this.interests = const <String>[],
    this.dealbreakers = const ProfileEditDealbreakers(
      acceptableSmoking: <String>[],
      acceptableDrinking: <String>[],
      acceptableKidsStance: <String>[],
      acceptableLookingFor: <String>[],
      acceptableEducation: <String>[],
    ),
    this.pacePreferences,
    this.location,
  });

  final String? name;
  final String? bio;
  final String? birthDate;
  final String? gender;
  final List<String> interestedIn;
  final int? maxDistanceKm;
  final int? minAge;
  final int? maxAge;
  final int? heightCm;
  final String? smoking;
  final String? drinking;
  final String? wantsKids;
  final String? lookingFor;
  final String? education;
  final List<String> interests;
  final ProfileEditDealbreakers dealbreakers;
  final String? pacePreferences;
  final ProfileEditLocation? location;

  factory ProfileEditEditable.fromJson(Map<String, dynamic> json) {
    return ProfileEditEditable(
      name: parseNullableString(json['name']),
      bio: parseNullableString(json['bio']),
      birthDate: parseNullableString(json['birthDate']),
      gender: parseNullableString(json['gender']),
      interestedIn: parseStringList(json['interestedIn']),
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toInt(),
      minAge: (json['minAge'] as num?)?.toInt(),
      maxAge: (json['maxAge'] as num?)?.toInt(),
      heightCm: (json['heightCm'] as num?)?.toInt(),
      smoking: parseNullableString(json['smoking']),
      drinking: parseNullableString(json['drinking']),
      wantsKids: parseNullableString(json['wantsKids']),
      lookingFor: parseNullableString(json['lookingFor']),
      education: parseNullableString(json['education']),
      interests: parseStringList(json['interests']),
      dealbreakers: ProfileEditDealbreakers.fromJson(
        Map<String, dynamic>.from(json['dealbreakers'] as Map? ?? const {}),
      ),
      pacePreferences: parseNullableString(json['pacePreferences']),
      location: json['location'] is Map
          ? ProfileEditLocation.fromJson(
              Map<String, dynamic>.from(json['location'] as Map),
            )
          : null,
    );
  }
}

class ProfileEditDealbreakers {
  const ProfileEditDealbreakers({
    required this.acceptableSmoking,
    required this.acceptableDrinking,
    required this.acceptableKidsStance,
    required this.acceptableLookingFor,
    required this.acceptableEducation,
    this.minHeightCm,
    this.maxHeightCm,
    this.maxAgeDifference,
  });

  final List<String> acceptableSmoking;
  final List<String> acceptableDrinking;
  final List<String> acceptableKidsStance;
  final List<String> acceptableLookingFor;
  final List<String> acceptableEducation;
  final int? minHeightCm;
  final int? maxHeightCm;
  final int? maxAgeDifference;

  factory ProfileEditDealbreakers.fromJson(Map<String, dynamic> json) {
    return ProfileEditDealbreakers(
      acceptableSmoking: parseStringList(json['acceptableSmoking']),
      acceptableDrinking: parseStringList(json['acceptableDrinking']),
      acceptableKidsStance: parseStringList(json['acceptableKidsStance']),
      acceptableLookingFor: parseStringList(json['acceptableLookingFor']),
      acceptableEducation: parseStringList(json['acceptableEducation']),
      minHeightCm: (json['minHeightCm'] as num?)?.toInt(),
      maxHeightCm: (json['maxHeightCm'] as num?)?.toInt(),
      maxAgeDifference: (json['maxAgeDifference'] as num?)?.toInt(),
    );
  }
}

class ProfileEditLocation {
  const ProfileEditLocation({
    required this.label,
    this.latitude = 0,
    this.longitude = 0,
    this.precision = '',
    this.countryCode = '',
    this.cityName,
    this.zipCode,
    this.approximate = false,
  });

  final String label;
  final double latitude;
  final double longitude;
  final String precision;
  final String countryCode;
  final String? cityName;
  final String? zipCode;
  final bool approximate;

  factory ProfileEditLocation.fromJson(Map<String, dynamic> json) {
    return ProfileEditLocation(
      label: json['label'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      precision: json['precision'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      cityName: parseNullableString(json['cityName']),
      zipCode: parseNullableString(json['zipCode']),
      approximate: json['approximate'] as bool? ?? false,
    );
  }

  ResolvedLocation toResolvedLocation() {
    return ResolvedLocation(
      label: label,
      latitude: latitude,
      longitude: longitude,
      precision: precision,
      approximate: approximate,
      message: '',
      countryCode: countryCode,
      cityName: cityName,
      zipCode: zipCode,
      allowApproximate: approximate,
    );
  }

  ProfileLocationRequest toProfileLocationRequest() {
    return ProfileLocationRequest(
      countryCode: countryCode,
      cityName: cityName ?? '',
      zipCode: zipCode,
      allowApproximate: approximate,
    );
  }
}

typedef EditableProfileSnapshot = ProfileEditEditable;
typedef ProfileEditLocationSnapshot = ProfileEditLocation;
typedef ReadOnlyProfileSnapshot = ProfileEditReadOnly;

class ProfileEditReadOnly {
  const ProfileEditReadOnly({
    required this.name,
    required this.state,
    required this.photoUrls,
    this.verified = false,
    this.verificationMethod,
    this.verifiedAt,
  });

  final String name;
  final String state;
  final List<String> photoUrls;
  final bool verified;
  final String? verificationMethod;
  final DateTime? verifiedAt;

  factory ProfileEditReadOnly.fromJson(Map<String, dynamic> json) {
    return ProfileEditReadOnly(
      name: (json['name'] as String?) ?? '',
      state: json['state'] as String? ?? 'UNKNOWN',
      photoUrls: parseStringList(json['photoUrls']),
      verified: json['verified'] as bool? ?? false,
      verificationMethod: parseNullableString(json['verificationMethod']),
      verifiedAt: DateTime.tryParse(json['verifiedAt'] as String? ?? ''),
    );
  }
}
