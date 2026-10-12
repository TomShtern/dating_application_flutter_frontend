import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_error.dart';
import '../../models/profile_edit_snapshot.dart';
import '../../shared/widgets/app_async_state.dart';
import '../auth/auth_controller.dart';
import '../profile/profile_provider.dart';
import '../updates/update_banner.dart';
import 'onboarding_screen.dart';

/// Shows [child] only once the backend reports the profile complete; until
/// then the guided [OnboardingScreen] runs. The decision comes from the
/// backend's completion info (`profileComplete`), never from local rules.
class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<ProfileEditSnapshot>>(profileEditSnapshotProvider, (
      previous,
      next,
    ) {
      final wasIncomplete =
          previous?.value?.completionInfo.profileComplete == false;
      final nowComplete = next.value?.completionInfo.profileComplete == true;
      if (wasIncomplete && nowComplete) {
        unawaited(_refreshStoredUser(ref));
      }
    });

    final snapshot = ref.watch(profileEditSnapshotProvider);
    // Keep showing the previous value while a save refreshes it, so the
    // current step does not flash a spinner between saves.
    final value = snapshot.hasValue ? snapshot.value : null;

    if (value == null) {
      if (snapshot.hasError) {
        final error = snapshot.error;
        return Scaffold(
          body: AppAsyncState.error(
            message: error is ApiError
                ? error.message
                : 'Could not load your profile.',
            onRetry: () => ref.invalidate(profileEditSnapshotProvider),
          ),
        );
      }
      return const Scaffold(
        body: AppAsyncState.loading(message: 'Loading your profile…'),
      );
    }

    if (value.completionInfo.profileComplete) {
      return child;
    }
    return UpdateBannerHost(
      child: OnboardingScreen(info: value.completionInfo),
    );
  }

  /// The stored user summary (name, age, state) was saved while the profile
  /// was still incomplete; re-provisioning refreshes it.
  Future<void> _refreshStoredUser(WidgetRef ref) async {
    try {
      await ref.read(authControllerProvider.notifier).provision();
    } on ApiError {
      // Best effort: the summary refreshes on the next launch anyway.
    }
  }
}
