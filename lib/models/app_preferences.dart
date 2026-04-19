import 'package:flutter/material.dart';

enum AppThemeModePreference {
  system,
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
    AppThemeModePreference.system => ThemeMode.system,
    AppThemeModePreference.light => ThemeMode.light,
    AppThemeModePreference.dark => ThemeMode.dark,
  };

  static AppThemeModePreference fromStorageValue(String? value) {
    return switch (value) {
      'light' => AppThemeModePreference.light,
      'dark' => AppThemeModePreference.dark,
      _ => AppThemeModePreference.system,
    };
  }
}

class AppPreferences {
  const AppPreferences({this.themeMode = AppThemeModePreference.system});

  final AppThemeModePreference themeMode;

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    final themeModeValue = json['themeMode'];
    final themeMode = themeModeValue is String ? themeModeValue : null;

    return AppPreferences(
      themeMode: AppThemeModePreference.fromStorageValue(themeMode),
    );
  }

  Map<String, dynamic> toJson() {
    return {'themeMode': themeMode.name};
  }

  AppPreferences copyWith({AppThemeModePreference? themeMode}) {
    return AppPreferences(themeMode: themeMode ?? this.themeMode);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppPreferences && other.themeMode == themeMode;
  }

  @override
  int get hashCode => themeMode.hashCode;
}
