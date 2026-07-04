import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/standout.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

enum StandoutsViewMode { grid, list }

final standoutsProvider = FutureProvider<StandoutsSnapshot>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getStandouts(userId: currentUser.id);
});

final standoutsViewModeProvider =
    NotifierProvider<StandoutsViewModeNotifier, StandoutsViewMode?>(
      StandoutsViewModeNotifier.new,
    );

final standoutsControllerProvider = Provider<StandoutsController>((ref) {
  return StandoutsController(ref);
});

class StandoutsController {
  StandoutsController(this._ref);

  final Ref _ref;

  Future<void> refresh() {
    return _ref.refresh(standoutsProvider.future);
  }
}

class StandoutsViewModeNotifier extends Notifier<StandoutsViewMode?> {
  @override
  StandoutsViewMode? build() => null;

  void setViewMode(StandoutsViewMode? mode) {
    state = mode;
  }
}
