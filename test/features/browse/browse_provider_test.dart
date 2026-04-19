import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/like_result.dart';
import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/undo_swipe_result.dart';
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

  test('likeCandidate invalidates matches and conversations on a new match', () async {
    final apiClient = _FakeApiClient(
      browseResponses: const [
        BrowseResponse(
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
      ],
      likeResult: const LikeResult(
        isMatch: true,
        message: 'It\'s a match!',
        matchedUserName: 'Noa',
        matchId:
            '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
      ),
      matchResponses: [
        MatchesResponse(
          matches: [
            MatchSummary(
              matchId:
                  '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
              otherUserId: '22222222-2222-2222-2222-222222222222',
              otherUserName: 'Noa',
              state: 'ACTIVE',
              createdAt: DateTime.parse('2026-04-19T09:00:00Z'),
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
              matchId:
                  '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
              otherUserId: '22222222-2222-2222-2222-222222222222',
              otherUserName: 'Noa',
              state: 'ACTIVE',
              createdAt: DateTime.parse('2026-04-19T09:00:00Z'),
            ),
          ],
          totalCount: 1,
          offset: 0,
          limit: 20,
          hasMore: false,
        ),
      ],
      conversationResponses: [
        [
          ConversationSummary(
            id: '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
            otherUserId: '22222222-2222-2222-2222-222222222222',
            otherUserName: 'Noa',
            messageCount: 0,
            lastMessageAt: DateTime.parse('2026-04-19T09:00:00Z'),
          ),
        ],
        [
          ConversationSummary(
            id: '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
            otherUserId: '22222222-2222-2222-2222-222222222222',
            otherUserName: 'Noa',
            messageCount: 0,
            lastMessageAt: DateTime.parse('2026-04-19T09:00:00Z'),
          ),
        ],
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

    await container.read(matchesProvider.future);
    await container.read(conversationsProvider.future);
    expect(apiClient.matchesCalls, 1);
    expect(apiClient.conversationsCalls, 1);

    final result = await container
        .read(browseControllerProvider)
        .likeCandidate('target-1');

    expect(result.isMatch, isTrue);

    await container.read(matchesProvider.future);
    await container.read(conversationsProvider.future);

    expect(apiClient.matchesCalls, 2);
    expect(apiClient.conversationsCalls, 2);
  });

  test(
    'undoLastSwipe refreshes browse and invalidates related lists when needed',
    () async {
      final apiClient = _FakeApiClient(
        browseResponses: const [
          BrowseResponse(
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
          BrowseResponse(
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
        undoResult: const UndoSwipeResult(
          success: true,
          message: 'Last swipe undone',
          matchDeleted: true,
        ),
        matchResponses: [
          MatchesResponse(
            matches: [
              MatchSummary(
                matchId: 'match-1',
                otherUserId: 'user-2',
                otherUserName: 'Noa',
                state: 'ACTIVE',
                createdAt: DateTime.parse('2026-04-19T09:00:00Z'),
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
                createdAt: DateTime.parse('2026-04-19T09:10:00Z'),
              ),
            ],
            totalCount: 1,
            offset: 0,
            limit: 20,
            hasMore: false,
          ),
        ],
        conversationResponses: [
          [
            ConversationSummary(
              id: 'match-1',
              otherUserId: 'user-2',
              otherUserName: 'Noa',
              messageCount: 1,
              lastMessageAt: DateTime.parse('2026-04-19T09:00:00Z'),
            ),
          ],
          [
            ConversationSummary(
              id: 'match-2',
              otherUserId: 'user-3',
              otherUserName: 'Maya',
              messageCount: 2,
              lastMessageAt: DateTime.parse('2026-04-19T09:10:00Z'),
            ),
          ],
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

      await container.read(browseProvider.future);
      await container.read(matchesProvider.future);
      await container.read(conversationsProvider.future);

      final result = await container
          .read(browseControllerProvider)
          .undoLastSwipe();

      expect(result.message, 'Last swipe undone');
      await container.read(browseProvider.future);
      await container.read(matchesProvider.future);
      await container.read(conversationsProvider.future);

      expect(apiClient.undoCalls, 1);
      expect(apiClient.browseCalls, 2);
      expect(apiClient.matchesCalls, 2);
      expect(apiClient.conversationsCalls, 2);
    },
  );
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient({
    required this.browseResponses,
    this.likeResult = const LikeResult(
      isMatch: false,
      message: 'Like recorded',
    ),
    this.undoResult = const UndoSwipeResult(
      success: true,
      message: 'Last swipe undone',
      matchDeleted: false,
    ),
    this.matchResponses = const [],
    this.conversationResponses = const [],
  }) : super(dio: Dio());

  final List<BrowseResponse> browseResponses;
  final LikeResult likeResult;
  final UndoSwipeResult undoResult;
  final List<MatchesResponse> matchResponses;
  final List<List<ConversationSummary>> conversationResponses;
  int browseCalls = 0;
  int likeCalls = 0;
  int passCalls = 0;
  int undoCalls = 0;
  int matchesCalls = 0;
  int conversationsCalls = 0;

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
    return likeResult;
  }

  @override
  Future<String> passUser({
    required String userId,
    required String targetId,
  }) async {
    passCalls++;
    return 'Passed';
  }

  @override
  Future<UndoSwipeResult> undoLastSwipe({required String userId}) async {
    undoCalls++;
    return undoResult;
  }

  @override
  Future<MatchesResponse> getMatches({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    final responseIndex = matchesCalls < matchResponses.length
        ? matchesCalls
        : matchResponses.length - 1;
    matchesCalls++;
    return matchResponses[responseIndex];
  }

  @override
  Future<List<ConversationSummary>> getConversations({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    final responseIndex = conversationsCalls < conversationResponses.length
        ? conversationsCalls
        : conversationResponses.length - 1;
    conversationsCalls++;
    return conversationResponses[responseIndex];
  }
}
