import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/api/api_error.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/features/safety/safety_provider.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

const _currentUser = UserSummary(
  id: '11111111-1111-1111-1111-111111111111',
  name: 'Dana',
  age: 27,
  state: 'ACTIVE',
);

const _otherUserId = '22222222-2222-2222-2222-222222222222';

void main() {
  const otherUserDetail = UserDetail(
    id: _otherUserId,
    name: 'Noa',
    age: 29,
    bio: 'Always up for a museum date.',
    gender: 'FEMALE',
    interestedIn: ['MALE'],
    approximateLocation: 'Haifa',
    maxDistanceKm: 25,
    photoUrls: ['/photos/noa-1.jpg'],
    state: 'ACTIVE',
  );

  test(
    'blockUser calls the API and invalidates browse, matches, conversations, and the other profile',
    () async {
      final apiClient = _FakeSafetyApiClient(detail: otherUserDetail);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => _currentUser),
        ],
      );
      addTearDown(container.dispose);

      await container.read(browseProvider.future);
      await container.read(matchesProvider.future);
      await container.read(conversationsProvider.future);
      await container.read(otherUserProfileProvider(_otherUserId).future);

      await container.read(safetyControllerProvider).blockUser(_otherUserId);

      await container.read(browseProvider.future);
      await container.read(matchesProvider.future);
      await container.read(conversationsProvider.future);
      await container.read(otherUserProfileProvider(_otherUserId).future);

      expect(apiClient.blockCalls, [(_otherUserId, _currentUser.id)]);
      expect(apiClient.getBrowseCalls, 2);
      expect(apiClient.getMatchesCalls, 2);
      expect(apiClient.getConversationsCalls, 2);
      expect(apiClient.getUserDetailCalls, 2);
    },
  );

  test(
    'reportUser calls the API without invalidating cached relationship data',
    () async {
      final apiClient = _FakeSafetyApiClient(detail: otherUserDetail);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => _currentUser),
        ],
      );
      addTearDown(container.dispose);

      await container.read(browseProvider.future);
      await container.read(matchesProvider.future);
      await container.read(conversationsProvider.future);
      await container.read(otherUserProfileProvider(_otherUserId).future);

      await container.read(safetyControllerProvider).reportUser(_otherUserId);

      await container.read(browseProvider.future);
      await container.read(matchesProvider.future);
      await container.read(conversationsProvider.future);
      await container.read(otherUserProfileProvider(_otherUserId).future);

      expect(apiClient.reportCalls, [(_otherUserId, _currentUser.id)]);
      expect(apiClient.getBrowseCalls, 1);
      expect(apiClient.getMatchesCalls, 1);
      expect(apiClient.getConversationsCalls, 1);
      expect(apiClient.getUserDetailCalls, 1);
    },
  );

  test(
    'unmatchUser calls the API and invalidates browse, matches, conversations, and the other profile',
    () async {
      final apiClient = _FakeSafetyApiClient(detail: otherUserDetail);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => _currentUser),
        ],
      );
      addTearDown(container.dispose);

      await container.read(browseProvider.future);
      await container.read(matchesProvider.future);
      await container.read(conversationsProvider.future);
      await container.read(otherUserProfileProvider(_otherUserId).future);

      await container.read(safetyControllerProvider).unmatchUser(_otherUserId);

      await container.read(browseProvider.future);
      await container.read(matchesProvider.future);
      await container.read(conversationsProvider.future);
      await container.read(otherUserProfileProvider(_otherUserId).future);

      expect(apiClient.unmatchCalls, [(_otherUserId, _currentUser.id)]);
      expect(apiClient.getBrowseCalls, 2);
      expect(apiClient.getMatchesCalls, 2);
      expect(apiClient.getConversationsCalls, 2);
      expect(apiClient.getUserDetailCalls, 2);
    },
  );

  test(
    'unblockUser calls the API and invalidates browse, matches, conversations, and the other profile',
    () async {
      final apiClient = _FakeSafetyApiClient(detail: otherUserDetail);
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
          selectedUserProvider.overrideWith((ref) async => _currentUser),
        ],
      );
      addTearDown(container.dispose);

      await container.read(browseProvider.future);
      await container.read(matchesProvider.future);
      await container.read(conversationsProvider.future);
      await container.read(otherUserProfileProvider(_otherUserId).future);

      await container.read(safetyControllerProvider).unblockUser(_otherUserId);

      await container.read(browseProvider.future);
      await container.read(matchesProvider.future);
      await container.read(conversationsProvider.future);
      await container.read(otherUserProfileProvider(_otherUserId).future);

      expect(apiClient.unblockCalls, [(_otherUserId, _currentUser.id)]);
      expect(apiClient.getBrowseCalls, 2);
      expect(apiClient.getMatchesCalls, 2);
      expect(apiClient.getConversationsCalls, 2);
      expect(apiClient.getUserDetailCalls, 2);
    },
  );

  test('safety actions reject self-directed targets', () async {
    final apiClient = _FakeSafetyApiClient(detail: otherUserDetail);
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        selectedUserProvider.overrideWith((ref) async => _currentUser),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(safetyControllerProvider);

    await expectLater(
      controller.blockUser(_currentUser.id),
      throwsA(
        isA<ApiError>().having(
          (error) => error.message,
          'message',
          'You cannot perform safety actions on your own account.',
        ),
      ),
    );
    await expectLater(
      controller.reportUser(_currentUser.id),
      throwsA(isA<ApiError>()),
    );
    await expectLater(
      controller.unmatchUser(_currentUser.id),
      throwsA(isA<ApiError>()),
    );
    await expectLater(
      controller.unblockUser(_currentUser.id),
      throwsA(isA<ApiError>()),
    );
    expect(apiClient.blockCalls, isEmpty);
    expect(apiClient.reportCalls, isEmpty);
    expect(apiClient.unmatchCalls, isEmpty);
    expect(apiClient.unblockCalls, isEmpty);
  });
}

class _FakeSafetyApiClient extends ApiClient {
  _FakeSafetyApiClient({required this.detail}) : super(dio: Dio());

  final UserDetail detail;
  int getBrowseCalls = 0;
  int getMatchesCalls = 0;
  int getConversationsCalls = 0;
  int getUserDetailCalls = 0;
  final List<(String, String)> blockCalls = <(String, String)>[];
  final List<(String, String)> unblockCalls = <(String, String)>[];
  final List<(String, String)> reportCalls = <(String, String)>[];
  final List<(String, String)> unmatchCalls = <(String, String)>[];

  @override
  Future<BrowseResponse> getBrowse({required String userId}) async {
    getBrowseCalls++;
    return const BrowseResponse(
      candidates: [
        BrowseCandidate(
          id: _otherUserId,
          name: 'Noa',
          age: 29,
          state: 'ACTIVE',
        ),
      ],
      dailyPick: null,
      dailyPickViewed: false,
      locationMissing: false,
    );
  }

  @override
  Future<MatchesResponse> getMatches({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    getMatchesCalls++;
    return MatchesResponse(
      matches: [
        MatchSummary(
          matchId: '${_currentUser.id}_$_otherUserId',
          otherUserId: _otherUserId,
          otherUserName: 'Noa',
          state: 'ACTIVE',
          createdAt: DateTime.parse('2026-04-18T12:34:56Z'),
        ),
      ],
      totalCount: 1,
      offset: 0,
      limit: 20,
      hasMore: false,
    );
  }

  @override
  Future<List<ConversationSummary>> getConversations({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    getConversationsCalls++;
    return [
      ConversationSummary(
        id: '${_currentUser.id}_$_otherUserId',
        otherUserId: _otherUserId,
        otherUserName: 'Noa',
        messageCount: 1,
        lastMessageAt: DateTime.parse('2026-04-18T12:34:56Z'),
      ),
    ];
  }

  @override
  Future<UserDetail> getUserDetail({
    required String userId,
    String? actingUserId,
  }) async {
    getUserDetailCalls++;
    return detail;
  }

  @override
  Future<String> blockUser({
    required String userId,
    required String targetId,
  }) async {
    blockCalls.add((targetId, userId));
    return 'User blocked.';
  }

  @override
  Future<String> unblockUser({
    required String userId,
    required String targetId,
  }) async {
    unblockCalls.add((targetId, userId));
    return 'User unblocked.';
  }

  @override
  Future<String> reportUser({
    required String userId,
    required String targetId,
  }) async {
    reportCalls.add((targetId, userId));
    return 'User reported.';
  }

  @override
  Future<String> unmatchUser({
    required String userId,
    required String targetId,
  }) async {
    unmatchCalls.add((targetId, userId));
    return 'Match removed.';
  }
}
