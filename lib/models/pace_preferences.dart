/// Pace preferences as the backend models them: four enum answers that are
/// either all set or all null (`PacePreferencesDtos` / `MatchPreferences`).
///
/// Values are the backend enum names, sent and received verbatim.
class PacePreferences {
  const PacePreferences({
    this.messagingFrequency,
    this.timeToFirstDate,
    this.communicationStyle,
    this.depthPreference,
  });

  static const blank = PacePreferences();

  final String? messagingFrequency;
  final String? timeToFirstDate;
  final String? communicationStyle;
  final String? depthPreference;

  /// The backend rejects a partial object, so only a complete one is sendable.
  bool get isComplete =>
      messagingFrequency != null &&
      timeToFirstDate != null &&
      communicationStyle != null &&
      depthPreference != null;

  factory PacePreferences.fromJson(Object? json) {
    if (json is! Map) {
      return blank;
    }
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    return PacePreferences(
      messagingFrequency: read('messagingFrequency'),
      timeToFirstDate: read('timeToFirstDate'),
      communicationStyle: read('communicationStyle'),
      depthPreference: read('depthPreference'),
    );
  }

  Map<String, dynamic> toJson() => {
    'messagingFrequency': messagingFrequency,
    'timeToFirstDate': timeToFirstDate,
    'communicationStyle': communicationStyle,
    'depthPreference': depthPreference,
  };

  PacePreferences copyWith({
    String? messagingFrequency,
    String? timeToFirstDate,
    String? communicationStyle,
    String? depthPreference,
  }) {
    return PacePreferences(
      messagingFrequency: messagingFrequency ?? this.messagingFrequency,
      timeToFirstDate: timeToFirstDate ?? this.timeToFirstDate,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      depthPreference: depthPreference ?? this.depthPreference,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PacePreferences &&
        other.messagingFrequency == messagingFrequency &&
        other.timeToFirstDate == timeToFirstDate &&
        other.communicationStyle == communicationStyle &&
        other.depthPreference == depthPreference;
  }

  @override
  int get hashCode => Object.hash(
    messagingFrequency,
    timeToFirstDate,
    communicationStyle,
    depthPreference,
  );
}

/// One pace question and its backend enum answers, in display order.
class PaceQuestion {
  const PaceQuestion({
    required this.title,
    required this.options,
    required this.read,
    required this.write,
  });

  final String title;

  /// Backend enum name -> label.
  final Map<String, String> options;
  final String? Function(PacePreferences) read;
  final PacePreferences Function(PacePreferences, String) write;
}

/// Enum names and labels mirror `MatchPreferences.PacePreferences` in the
/// backend; keep them in sync with it.
final paceQuestions = <PaceQuestion>[
  PaceQuestion(
    title: 'How often do you like to message?',
    options: const {
      'RARELY': 'Rarely',
      'OFTEN': 'Often',
      'CONSTANTLY': 'Constantly',
      'WILDCARD': 'No preference',
    },
    read: (pace) => pace.messagingFrequency,
    write: (pace, value) => pace.copyWith(messagingFrequency: value),
  ),
  PaceQuestion(
    title: 'How soon to a first date?',
    options: const {
      'QUICKLY': 'Quickly (1-2 days)',
      'FEW_DAYS': 'A few days',
      'WEEKS': 'Weeks',
      'MONTHS': 'Months',
      'WILDCARD': 'No preference',
    },
    read: (pace) => pace.timeToFirstDate,
    write: (pace, value) => pace.copyWith(timeToFirstDate: value),
  ),
  PaceQuestion(
    title: 'How do you like to communicate?',
    options: const {
      'TEXT_ONLY': 'Text only',
      'VOICE_NOTES': 'Voice notes',
      'VIDEO_CALLS': 'Video calls',
      'IN_PERSON_ONLY': 'In person only',
      'MIX_OF_EVERYTHING': 'Mix of everything',
    },
    read: (pace) => pace.communicationStyle,
    write: (pace, value) => pace.copyWith(communicationStyle: value),
  ),
  PaceQuestion(
    title: 'How deep do you like to go?',
    options: const {
      'SMALL_TALK': 'Small talk',
      'DEEP_CHAT': 'Deep chat',
      'EXISTENTIAL': 'Existential exploration',
      'DEPENDS_ON_VIBE': 'Depends on the vibe',
    },
    read: (pace) => pace.depthPreference,
    write: (pace, value) => pace.copyWith(depthPreference: value),
  ),
];
