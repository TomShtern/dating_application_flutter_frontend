import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';
import 'package:flutter_dating_application_1/shared/providers/selected_user_guard.dart';

final _requiredSelectedUserProvider = Provider<Future<UserSummary>>((ref) {
  return requireSelectedUser(ref);
});

final _requiredActionableTargetProvider =
    Provider.family<Future<UserSummary>, String>((ref, targetId) {
      return requireActionableTargetUser(ref, targetId);
    });

void main() {
  const currentUser = UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  );

  test('returns the selected user when one is available', () async {
    final container = ProviderContainer(
      overrides: [
        selectedUserProvider.overrideWith((ref) async => currentUser),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(_requiredSelectedUserProvider);

    expect(result, currentUser);
  });

  test('throws a friendly error when no selected user exists', () async {
    final container = ProviderContainer(
      overrides: [
        selectedUserProvider.overrideWithValue(
          const AsyncData<UserSummary?>(null),
        ),
      ],
    );
    addTearDown(container.dispose);

    final future = container.read(_requiredSelectedUserProvider);

    await expectLater(
      future,
      throwsA(
        isA<ApiError>().having(
          (error) => error.message,
          'message',
          'Please choose a dev user first.',
        ),
      ),
    );
  });

  test('rejects self-directed safety targets', () async {
    final container = ProviderContainer(
      overrides: [
        selectedUserProvider.overrideWith((ref) async => currentUser),
      ],
    );
    addTearDown(container.dispose);

    final future = container.read(
      _requiredActionableTargetProvider(currentUser.id),
    );

    await expectLater(
      future,
      throwsA(
        isA<ApiError>().having(
          (error) => error.message,
          'message',
          'You cannot perform safety actions on your own account.',
        ),
      ),
    );
  });
}
