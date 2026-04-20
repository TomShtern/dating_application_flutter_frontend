import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/standout.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

final standoutsProvider = FutureProvider<StandoutsSnapshot>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final currentUser = await user_guard.watchSelectedUser(ref);
  return apiClient.getStandouts(userId: currentUser.id);
});

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
