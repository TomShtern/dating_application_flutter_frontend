import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_dating_application_1/api/api_client.dart';
import 'package:flutter_dating_application_1/models/profile_update_response.dart';
import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/features/stats/stats_provider.dart';
import 'package:flutter_dating_application_1/models/achievement_summary.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/profile_update_request.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_stats.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

final _selectedUserStateProvider =
    NotifierProvider<_SelectedUserNotifier, UserSummary?>(
      _SelectedUserNotifier.new,
    );

void main() {
  test('user-scoped providers rebind when the selected user changes', () async {
    final apiClient = _ReactiveUserApiClient();

    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(apiClient),
        selectedUserProvider.overrideWith(
          (ref) async => ref.watch(_selectedUserStateProvider),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      (await container.read(browseProvider.future)).candidates.single.name,
      'Alex',
    );
    expect(
      (await container.read(
        matchesProvider.future,
      )).matches.single.otherUserName,
      'Blair',
    );
    expect(
      (await container.read(conversationsProvider.future)).single.otherUserName,
      'Casey',
    );
    expect((await container.read(profileProvider.future)).name, 'Dana');
    expect(
      (await container.read(statsProvider.future)).items.single.value,
      'A',
    );
    expect(
      (await container.read(achievementsProvider.future)).single.title,
      'Starter A',
    );

    container.read(_selectedUserStateProvider.notifier).state = _userB;
    await Future<void>.microtask(() {});

    expect(
      (await container.read(browseProvider.future)).candidates.single.name,
      'Jordan',
    );
    expect(
      (await container.read(
        matchesProvider.future,
      )).matches.single.otherUserName,
      'Riley',
    );
    expect(
      (await container.read(conversationsProvider.future)).single.otherUserName,
      'Skyler',
    );
    expect((await container.read(profileProvider.future)).name, 'Maya');
    expect(
      (await container.read(statsProvider.future)).items.single.value,
      'B',
    );
    expect(
      (await container.read(achievementsProvider.future)).single.title,
      'Starter B',
    );

    expect(apiClient.browseUserIds, ['user-a', 'user-b']);
    expect(apiClient.matchesUserIds, ['user-a', 'user-b']);
    expect(apiClient.conversationUserIds, ['user-a', 'user-b']);
    expect(apiClient.profileUserIds, ['user-a', 'user-b']);
    expect(apiClient.profileActingUserIds, ['user-a', 'user-b']);
    expect(apiClient.statsUserIds, ['user-a', 'user-b']);
    expect(apiClient.achievementUserIds, ['user-a', 'user-b']);
  });
}

const _userA = UserSummary(
  id: 'user-a',
  name: 'Dana',
  age: 27,
  state: 'ACTIVE',
);

const _userB = UserSummary(
  id: 'user-b',
  name: 'Maya',
  age: 29,
  state: 'ACTIVE',
);

class _ReactiveUserApiClient extends ApiClient {
  _ReactiveUserApiClient() : super(dio: Dio());

  final List<String> browseUserIds = <String>[];
  final List<String> matchesUserIds = <String>[];
  final List<String> conversationUserIds = <String>[];
  final List<String> profileUserIds = <String>[];
  final List<String?> profileActingUserIds = <String?>[];
  final List<String> statsUserIds = <String>[];
  final List<String> achievementUserIds = <String>[];

  @override
  Future<BrowseResponse> getBrowse({required String userId}) async {
    browseUserIds.add(userId);
    return switch (userId) {
      'user-a' => const BrowseResponse(
        candidates: [
          BrowseCandidate(
            id: 'candidate-a',
            name: 'Alex',
            age: 28,
            state: 'ACTIVE',
          ),
        ],
        dailyPick: null,
        dailyPickViewed: false,
        locationMissing: false,
      ),
      'user-b' => const BrowseResponse(
        candidates: [
          BrowseCandidate(
            id: 'candidate-b',
            name: 'Jordan',
            age: 31,
            state: 'ACTIVE',
          ),
        ],
        dailyPick: null,
        dailyPickViewed: false,
        locationMissing: false,
      ),
      _ => throw StateError('Unexpected browse user $userId'),
    };
  }

  @override
  Future<MatchesResponse> getMatches({
    required String userId,
    int limit = 20,
    int offset = 0,
  }) async {
    matchesUserIds.add(userId);
    return switch (userId) {
      'user-a' => MatchesResponse(
        matches: [
          MatchSummary(
            matchId: 'match-a',
            otherUserId: 'other-a',
            otherUserName: 'Blair',
            state: 'ACTIVE',
            createdAt: DateTime.parse('2026-04-19T12:00:00Z'),
          ),
        ],
        totalCount: 1,
        offset: offset,
        limit: limit,
        hasMore: false,
      ),
      'user-b' => MatchesResponse(
        matches: [
          MatchSummary(
            matchId: 'match-b',
            otherUserId: 'other-b',
            otherUserName: 'Riley',
            state: 'ACTIVE',
            createdAt: DateTime.parse('2026-04-19T13:00:00Z'),
          ),
        ],
        totalCount: 1,
        offset: offset,
        limit: limit,
        hasMore: false,
      ),
      _ => throw StateError('Unexpected matches user $userId'),
    };
  }

  @override
  Future<List<ConversationSummary>> getConversations({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    conversationUserIds.add(userId);
    return switch (userId) {
      'user-a' => [
        ConversationSummary(
          id: 'conversation-a',
          otherUserId: 'chat-a',
          otherUserName: 'Casey',
          messageCount: 2,
          lastMessageAt: DateTime.parse('2026-04-19T14:00:00Z'),
        ),
      ],
      'user-b' => [
        ConversationSummary(
          id: 'conversation-b',
          otherUserId: 'chat-b',
          otherUserName: 'Skyler',
          messageCount: 4,
          lastMessageAt: DateTime.parse('2026-04-19T15:00:00Z'),
        ),
      ],
      _ => throw StateError('Unexpected conversations user $userId'),
    };
  }

  @override
  Future<UserDetail> getUserDetail({
    required String userId,
    String? actingUserId,
  }) async {
    profileUserIds.add(userId);
    profileActingUserIds.add(actingUserId);
    return switch (userId) {
      'user-a' => const UserDetail(
        id: 'user-a',
        name: 'Dana',
        age: 27,
        bio: 'Profile A',
        gender: 'FEMALE',
        interestedIn: ['MALE'],
        approximateLocation: 'Tel Aviv',
        maxDistanceKm: 25,
        photoUrls: [],
        state: 'ACTIVE',
      ),
      'user-b' => const UserDetail(
        id: 'user-b',
        name: 'Maya',
        age: 29,
        bio: 'Profile B',
        gender: 'FEMALE',
        interestedIn: ['FEMALE'],
        approximateLocation: 'Haifa',
        maxDistanceKm: 40,
        photoUrls: [],
        state: 'ACTIVE',
      ),
      _ => throw StateError('Unexpected profile user $userId'),
    };
  }

  @override
  Future<UserStats> getStats({required String userId}) async {
    statsUserIds.add(userId);
    return switch (userId) {
      'user-a' => const UserStats(
        items: [UserStatItem(label: 'Segment', value: 'A')],
      ),
      'user-b' => const UserStats(
        items: [UserStatItem(label: 'Segment', value: 'B')],
      ),
      _ => throw StateError('Unexpected stats user $userId'),
    };
  }

  @override
  Future<List<AchievementSummary>> getAchievements({
    required String userId,
  }) async {
    achievementUserIds.add(userId);
    return switch (userId) {
      'user-a' => const [AchievementSummary(title: 'Starter A')],
      'user-b' => const [AchievementSummary(title: 'Starter B')],
      _ => throw StateError('Unexpected achievement user $userId'),
    };
  }

  @override
  Future<ProfileUpdateResponse> updateProfile({
    required String userId,
    required ProfileUpdateRequest request,
  }) async {
    return const ProfileUpdateResponse();
  }
}

class _SelectedUserNotifier extends Notifier<UserSummary?> {
  @override
  UserSummary? build() => _userA;
}
