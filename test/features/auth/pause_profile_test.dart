import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_store.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const dana = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  Future<ProviderContainer> signedIn(_FakePauseApiClient apiClient) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await SelectedUserStore(preferences).saveSelectedUser(dana);
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        apiClientProvider.overrideWithValue(apiClient),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('pause and resume store the state the backend returns', () async {
    final container = await signedIn(_FakePauseApiClient());
    final controller = container.read(selectUserControllerProvider);

    await controller.pauseProfile();
    expect((await container.read(selectedUserProvider.future))?.isPaused, true);

    await controller.resumeProfile();
    expect((await container.read(selectedUserProvider.future))?.state, 'ACTIVE');
  });

  test('a refused pause re-reads the real state and rethrows', () async {
    final apiClient = _FakePauseApiClient()
      ..pauseError = const ApiError(
        message: 'Profile is not active.',
        code: 'PROFILE_NOT_ACTIVE',
        statusCode: 409,
      )
      ..serverState = 'PAUSED';
    final container = await signedIn(apiClient);

    await expectLater(
      container.read(selectUserControllerProvider).pauseProfile(),
      throwsA(isA<ApiError>()),
    );

    expect((await container.read(selectedUserProvider.future))?.isPaused, true);
  });
}

class _FakePauseApiClient extends ApiClient {
  _FakePauseApiClient() : super(dio: Dio());

  ApiError? pauseError;
  String serverState = 'ACTIVE';

  UserDetail _detail(String userId) => UserDetail.fromJson({
    'id': userId,
    'name': 'Dana',
    'age': 27,
    'state': serverState,
  });

  @override
  Future<UserDetail> pauseProfile({required String userId}) async {
    if (pauseError case final error?) {
      throw error;
    }
    serverState = 'PAUSED';
    return _detail(userId);
  }

  @override
  Future<UserDetail> resumeProfile({required String userId}) async {
    serverState = 'ACTIVE';
    return _detail(userId);
  }

  @override
  Future<UserDetail> getUserDetail({required String userId}) async {
    return _detail(userId);
  }
}
