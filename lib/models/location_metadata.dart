class LocationCountry {
  const LocationCountry({
    required this.code,
    required this.name,
    required this.flagEmoji,
    required this.available,
    required this.defaultSelection,
  });

  final String code;
  final String name;
  final String flagEmoji;
  final bool available;
  final bool defaultSelection;

  factory LocationCountry.fromJson(Map<String, dynamic> json) {
    return LocationCountry(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      flagEmoji: json['flagEmoji'] as String? ?? '',
      available: json['available'] as bool? ?? false,
      defaultSelection: json['defaultSelection'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is LocationCountry &&
        other.code == code &&
        other.name == name &&
        other.flagEmoji == flagEmoji &&
        other.available == available &&
        other.defaultSelection == defaultSelection;
  }

  @override
  int get hashCode =>
      Object.hash(code, name, flagEmoji, available, defaultSelection);
}

class LocationCity {
  const LocationCity({
    required this.name,
    required this.district,
    required this.countryCode,
    required this.priority,
  });

  final String name;
  final String district;
  final String countryCode;
  final int priority;

  factory LocationCity.fromJson(Map<String, dynamic> json) {
    return LocationCity(
      name: json['name'] as String? ?? '',
      district: json['district'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      priority: (json['priority'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is LocationCity &&
        other.name == name &&
        other.district == district &&
        other.countryCode == countryCode &&
        other.priority == priority;
  }

  @override
  int get hashCode => Object.hash(name, district, countryCode, priority);
}

class ResolvedLocation {
  const ResolvedLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.precision,
    required this.approximate,
    required this.message,
    this.countryCode,
    this.cityName,
    this.zipCode,
    this.allowApproximate,
  });

  final String label;
  final double latitude;
  final double longitude;
  final String precision;
  final bool approximate;
  final String message;
  final String? countryCode;
  final String? cityName;
  final String? zipCode;
  final bool? allowApproximate;

  factory ResolvedLocation.fromJson(Map<String, dynamic> json) {
    return ResolvedLocation(
      label: json['label'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      precision: json['precision'] as String? ?? '',
      approximate: json['approximate'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      countryCode: json['countryCode'] as String?,
      cityName: json['cityName'] as String?,
      zipCode: json['zipCode'] as String?,
      allowApproximate: json['allowApproximate'] as bool?,
    );
  }

  ResolvedLocation withProfileLocationInput({
    required String countryCode,
    required String cityName,
    String? zipCode,
    required bool allowApproximate,
  }) {
    return ResolvedLocation(
      label: label,
      latitude: latitude,
      longitude: longitude,
      precision: precision,
      approximate: approximate,
      message: message,
      countryCode: countryCode,
      cityName: cityName,
      zipCode: zipCode,
      allowApproximate: allowApproximate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is ResolvedLocation &&
        other.label == label &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.precision == precision &&
        other.approximate == approximate &&
        other.message == message &&
        other.countryCode == countryCode &&
        other.cityName == cityName &&
        other.zipCode == zipCode &&
        other.allowApproximate == allowApproximate;
  }

  @override
  int get hashCode => Object.hash(
    label,
    latitude,
    longitude,
    precision,
    approximate,
    message,
    countryCode,
    cityName,
    zipCode,
    allowApproximate,
  );
}
