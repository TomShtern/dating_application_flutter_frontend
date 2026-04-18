import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

void main() {
  test('matches provider refreshes from the API client', () async {
    final apiClient = _FakeMatchesApiClient(
      responses: [
        MatchesResponse(
          matches: [
            MatchSummary(
              matchId: 'match-1',
              otherUserId: 'user-2',
              otherUserName: 'Noa',
              state: 'ACTIVE',
              createdAt: DateTime.parse('2026-04-18T12:34:56Z'),
            ),
          ],
          totalCount: 1,
          offset: 0,
          limit: 20,
          hasMore: false,
        ),
        MatchesResponse(
          matches: [
            MatchSummary(
              matchId: 'match-2',
              otherUserId: 'user-3',
              otherUserName: 'Maya',
              state: 'ACTIVE',
              createdAt: DateTime.parse('2026-04-18T13:00:00Z'),
            ),
          ],
          totalCount: 1,
          offset: 0,
          limit: 20,
          hasMore: false,
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

    final initial = await container.read(matchesProvider.future);
    expect(initial.matches.single.matchId, 'match-1');

    container.read(matchesControllerProvider).refresh();
    final refreshed = await container.read(matchesProvider.future);

    expect(refreshed.matches.single.matchId, 'match-2');
    expect(apiClient.calls, 2);
  });
}

class _FakeMatchesApiClient extends ApiClient {
  _FakeMatchesApiClient({required this.responses}) : super(dio: Dio());

  final List<MatchesResponse> responses;
  int calls = 0;

  @override
  Future<MatchesResponse> getMatches({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final index = calls < responses.length ? calls : responses.length - 1;
    calls++;
    return responses[index];
  }
}
