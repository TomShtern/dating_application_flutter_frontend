enum NotificationPreferenceCategory {
  messages,
  matchesActivity,
  safetyAccount,
  marketingProduct,
}

class NotificationPreferences {
  const NotificationPreferences({
    this.messages = true,
    this.matchesActivity = true,
    this.safetyAccount = true,
    this.marketingProduct = true,
  });

  final bool messages;
  final bool matchesActivity;
  final bool safetyAccount;
  final bool marketingProduct;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      messages: _readBoolean(json['messages'], fallback: true),
      matchesActivity: _readBoolean(json['matchesActivity'], fallback: true),
      safetyAccount: _readBoolean(json['safetyAccount'], fallback: true),
      marketingProduct: _readBoolean(json['marketingProduct'], fallback: true),
    );
  }

  bool isEnabled(NotificationPreferenceCategory category) {
    return switch (category) {
      NotificationPreferenceCategory.messages => messages,
      NotificationPreferenceCategory.matchesActivity => matchesActivity,
      NotificationPreferenceCategory.safetyAccount => safetyAccount,
      NotificationPreferenceCategory.marketingProduct => marketingProduct,
    };
  }

  NotificationPreferences setCategoryEnabled(
    NotificationPreferenceCategory category,
    bool enabled,
  ) {
    return switch (category) {
      NotificationPreferenceCategory.messages => copyWith(messages: enabled),
      NotificationPreferenceCategory.matchesActivity => copyWith(
        matchesActivity: enabled,
      ),
      NotificationPreferenceCategory.safetyAccount => copyWith(
        safetyAccount: enabled,
      ),
      NotificationPreferenceCategory.marketingProduct => copyWith(
        marketingProduct: enabled,
      ),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'messages': messages,
      'matchesActivity': matchesActivity,
      'safetyAccount': safetyAccount,
      'marketingProduct': marketingProduct,
    };
  }

  NotificationPreferences copyWith({
    bool? messages,
    bool? matchesActivity,
    bool? safetyAccount,
    bool? marketingProduct,
  }) {
    return NotificationPreferences(
      messages: messages ?? this.messages,
      matchesActivity: matchesActivity ?? this.matchesActivity,
      safetyAccount: safetyAccount ?? this.safetyAccount,
      marketingProduct: marketingProduct ?? this.marketingProduct,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is NotificationPreferences &&
        other.messages == messages &&
        other.matchesActivity == matchesActivity &&
        other.safetyAccount == safetyAccount &&
        other.marketingProduct == marketingProduct;
  }

  @override
  int get hashCode =>
      Object.hash(messages, matchesActivity, safetyAccount, marketingProduct);
}

bool _readBoolean(dynamic value, {required bool fallback}) {
  if (value is bool) {
    return value;
  }

  return fallback;
}
