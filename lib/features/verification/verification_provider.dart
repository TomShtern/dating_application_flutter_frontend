import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_client.dart';
import '../../models/verification_result.dart';
import '../../shared/providers/selected_user_guard.dart' as user_guard;

final verificationControllerProvider = Provider<VerificationController>((ref) {
  return VerificationController(ref);
});

class VerificationController {
  VerificationController(this._ref);

  final Ref _ref;

  Future<VerificationStartResult> start({
    required String method,
    required String contact,
  }) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final apiClient = _ref.read(apiClientProvider);
    return apiClient.startVerification(
      userId: currentUser.id,
      method: method,
      contact: contact,
    );
  }

  Future<VerificationConfirmationResult> confirm({
    required String verificationCode,
  }) async {
    final currentUser = await user_guard.requireSelectedUser(_ref);
    final apiClient = _ref.read(apiClientProvider);
    return apiClient.confirmVerification(
      userId: currentUser.id,
      verificationCode: verificationCode,
    );
  }
}
