import 'package:flutter_dating_application_1/models/profile_completion_info.dart';
import 'package:flutter_dating_application_1/models/profile_edit_snapshot.dart';

/// A profile the backend reports as complete, so `OnboardingGate` lets the
/// signed-in shell through. Override `profileEditSnapshotProvider` with it in
/// tests that pump `AppHomeScreen` or `DatingApp` with an authenticated user.
const completeProfileSnapshot = ProfileEditSnapshot(
  userId: '11111111-1111-1111-1111-111111111111',
  editable: EditableProfileSnapshot(),
  readOnly: ReadOnlyProfileSnapshot(
    name: 'Dana',
    photoUrls: [],
    state: 'ACTIVE',
  ),
  completionInfo: ProfileCompletionInfo(
    requiredProfileFieldCount: 8,
    profileComplete: true,
    canActivate: true,
    canBrowse: true,
  ),
);
