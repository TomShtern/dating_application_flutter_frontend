import 'package:flutter/material.dart';

import '../../models/profile_completion_info.dart';

class MissingField {
  const MissingField({
    required this.key,
    required this.label,
    required this.icon,
    this.isActionable = true,
  });

  final String key;
  final String label;
  final IconData icon;
  final bool isActionable;

  static IconData iconForKey(String key) {
    return switch (key) {
      'name' => Icons.badge_outlined,
      'dob' => Icons.cake_outlined,
      'location' => Icons.location_on_outlined,
      'photo' => Icons.photo_camera_outlined,
      'pace' => Icons.speed_outlined,
      'gender' => Icons.wc_rounded,
      'interestedIn' => Icons.favorite_border_rounded,
      'bio' => Icons.edit_note_rounded,
      _ => Icons.edit_note_rounded,
    };
  }
}

List<MissingField> missingFieldsFromInfo(ProfileCompletionInfo info) {
  if (info.profileComplete || info.missingProfileFields.isEmpty) {
    return const [];
  }

  return info.missingProfileFields.map((key) {
    final label =
        info.missingProfileFieldLabels[key] ?? ProfileCompletionInfo.defaultLabel(key);
    return MissingField(
      key: key,
      label: label,
      icon: MissingField.iconForKey(key),
      isActionable: ProfileCompletionInfo.isActionable(key),
    );
  }).toList();
}