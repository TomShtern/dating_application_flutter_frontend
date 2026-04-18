import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/like_result.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  test('likeCandidate refreshes browse data from the server', () async {
    final apiClient = _FakeApiClient(
      browseResponses: [
        const BrowseResponse(
          candidates: [
            BrowseCandidate(
              id: 'target-1',
              name: 'Noa',
              age: 29,
              state: 'ACTIVE',
            ),
          ],
          dailyPick: null,
          dailyPickViewed: false,
          locationMissing: false,
        ),
        const BrowseResponse(
          candidates: [
            BrowseCandidate(
              id: 'target-2',
              name: 'Maya',
              age: 30,
              state: 'ACTIVE',
            ),
          ],
          dailyPick: null,
          dailyPickViewed: false,
          locationMissing: false,
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        selectedUserProvider.overrideWith(
          (ref) async => const UserSummary(
            id: '11111111-1111-1111-1111-111111111111',
            name: 'Dana',
            age: 27,
            state: 'ACTIVE',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final initialBrowse = await container.read(browseProvider.future);
    expect(initialBrowse.candidates.single.id, 'target-1');

    final result = await container
        .read(browseControllerProvider)
        .likeCandidate('target-1');

    expect(result.isMatch, isFalse);
    final refreshedBrowse = await container.read(browseProvider.future);
    expect(refreshedBrowse.candidates.single.id, 'target-2');
    expect(apiClient.browseCalls, 2);
    expect(apiClient.likeCalls, 1);
  });

  test('passCandidate refreshes browse data from the server', () async {
    final apiClient = _FakeApiClient(
      browseResponses: [
        const BrowseResponse(
          candidates: [
            BrowseCandidate(
              id: 'target-1',
              name: 'Noa',
              age: 29,
              state: 'ACTIVE',
            ),
          ],
          dailyPick: null,
          dailyPickViewed: false,
          locationMissing: false,
        ),
        const BrowseResponse(
          candidates: [
            BrowseCandidate(
              id: 'target-3',
              name: 'Lia',
              age: 31,
              state: 'ACTIVE',
            ),
          ],
          dailyPick: null,
          dailyPickViewed: false,
          locationMissing: false,
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        selectedUserProvider.overrideWith(
          (ref) async => const UserSummary(
            id: '11111111-1111-1111-1111-111111111111',
            name: 'Dana',
            age: 27,
            state: 'ACTIVE',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final initialBrowse = await container.read(browseProvider.future);
    expect(initialBrowse.candidates.single.id, 'target-1');

    final message = await container
        .read(browseControllerProvider)
        .passCandidate('target-1');

    expect(message, 'Passed');
    final refreshedBrowse = await container.read(browseProvider.future);
    expect(refreshedBrowse.candidates.single.id, 'target-3');
    expect(apiClient.browseCalls, 2);
    expect(apiClient.passCalls, 1);
  });
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({required this.browseResponses}) : super(dio: Dio());

  final List<BrowseResponse> browseResponses;
  int browseCalls = 0;
  int likeCalls = 0;
  int passCalls = 0;

  @override
  Future<BrowseResponse> getBrowse({required String userId}) async {
    final responseIndex = browseCalls < browseResponses.length
        ? browseCalls
        : browseResponses.length - 1;
    browseCalls++;
    return browseResponses[responseIndex];
  }

  @override
  Future<LikeResult> likeUser({
    required String userId,
    required String targetId,
  }) async {
    likeCalls++;
    return const LikeResult(isMatch: false, message: 'Like recorded');
  }

  @override
  Future<String> passUser({
    required String userId,
    required String targetId,
  }) async {
    passCalls++;
    return 'Passed';
  }
}
