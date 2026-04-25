import 'package:flutter_dating_application_1/models/achievement_summary.dart';
import 'package:flutter_dating_application_1/models/blocked_user_summary.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/browse_response.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/daily_pick.dart';
import 'package:flutter_dating_application_1/models/location_metadata.dart';
import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/matches_response.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/notification_item.dart';
import 'package:flutter_dating_application_1/models/pending_liker.dart';
import 'package:flutter_dating_application_1/models/standout.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_stats.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

export 'package:flutter_dating_application_1/models/achievement_summary.dart';
export 'package:flutter_dating_application_1/models/blocked_user_summary.dart';
export 'package:flutter_dating_application_1/models/browse_candidate.dart';
export 'package:flutter_dating_application_1/models/browse_response.dart';
export 'package:flutter_dating_application_1/models/conversation_summary.dart';
export 'package:flutter_dating_application_1/models/daily_pick.dart';
export 'package:flutter_dating_application_1/models/location_metadata.dart';
export 'package:flutter_dating_application_1/models/match_summary.dart';
export 'package:flutter_dating_application_1/models/matches_response.dart';
export 'package:flutter_dating_application_1/models/message_dto.dart';
export 'package:flutter_dating_application_1/models/notification_item.dart';
export 'package:flutter_dating_application_1/models/pending_liker.dart';
export 'package:flutter_dating_application_1/models/standout.dart';
export 'package:flutter_dating_application_1/models/user_detail.dart';
export 'package:flutter_dating_application_1/models/user_stats.dart';
export 'package:flutter_dating_application_1/models/user_summary.dart';

const currentUser = UserSummary(
  id: '11111111-1111-1111-1111-111111111111',
  name: 'Dana',
  age: 27,
  state: 'ACTIVE',
);

const browseCandidates = <BrowseCandidate>[
  BrowseCandidate(
    id: '22222222-2222-2222-2222-222222222222',
    name: 'Noa',
    age: 29,
    state: 'ACTIVE',
  ),
  BrowseCandidate(
    id: '33333333-3333-3333-3333-333333333333',
    name: 'Maya',
    age: 30,
    state: 'ACTIVE',
  ),
  BrowseCandidate(
    id: '44444444-4444-4444-4444-444444444444',
    name: 'Rin',
    age: 28,
    state: 'ACTIVE',
  ),
  BrowseCandidate(
    id: '55555555-5555-5555-5555-555555555555',
    name: 'Leah',
    age: 31,
    state: 'ACTIVE',
  ),
  BrowseCandidate(
    id: '66666666-6666-6666-6666-666666666666',
    name: 'Ari',
    age: 26,
    state: 'ACTIVE',
  ),
];

const dailyPick = DailyPick(
  userId: '33333333-3333-3333-3333-333333333333',
  userName: 'Maya',
  userAge: 30,
  date: '2026-04-23',
  reason: 'Strong compatibility on pace and conversation style.',
  alreadySeen: false,
);

const browseResponse = BrowseResponse(
  candidates: browseCandidates,
  dailyPick: dailyPick,
  dailyPickViewed: false,
  locationMissing: false,
);

final matches = <MatchSummary>[
  MatchSummary(
    matchId:
        '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    otherUserId: '22222222-2222-2222-2222-222222222222',
    otherUserName: 'Noa',
    state: 'ACTIVE',
    createdAt: DateTime.parse('2026-04-18T14:00:00Z'),
  ),
  MatchSummary(
    matchId:
        '11111111-1111-1111-1111-111111111111_33333333-3333-3333-3333-333333333333',
    otherUserId: '33333333-3333-3333-3333-333333333333',
    otherUserName: 'Maya',
    state: 'ACTIVE',
    createdAt: DateTime.parse('2026-04-17T10:00:00Z'),
  ),
  MatchSummary(
    matchId:
        '11111111-1111-1111-1111-111111111111_55555555-5555-5555-5555-555555555555',
    otherUserId: '55555555-5555-5555-5555-555555555555',
    otherUserName: 'Leah',
    state: 'ACTIVE',
    createdAt: DateTime.parse('2026-04-15T09:30:00Z'),
  ),
  MatchSummary(
    matchId:
        '11111111-1111-1111-1111-111111111111_66666666-6666-6666-6666-666666666666',
    otherUserId: '66666666-6666-6666-6666-666666666666',
    otherUserName: 'Ari',
    state: 'ACTIVE',
    createdAt: DateTime.parse('2026-04-12T18:00:00Z'),
  ),
  MatchSummary(
    matchId:
        '11111111-1111-1111-1111-111111111111_77777777-7777-7777-7777-777777777777',
    otherUserId: '77777777-7777-7777-7777-777777777777',
    otherUserName: 'Yael',
    state: 'ACTIVE',
    createdAt: DateTime.parse('2026-04-10T08:15:00Z'),
  ),
];

final matchesResponse = MatchesResponse(
  matches: matches,
  totalCount: matches.length,
  offset: 0,
  limit: 20,
  hasMore: false,
);

final conversations = <ConversationSummary>[
  ConversationSummary(
    id: '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    otherUserId: '22222222-2222-2222-2222-222222222222',
    otherUserName: 'Noa',
    messageCount: 12,
    lastMessageAt: DateTime.parse('2026-04-23T09:15:00Z'),
  ),
  ConversationSummary(
    id: '11111111-1111-1111-1111-111111111111_33333333-3333-3333-3333-333333333333',
    otherUserId: '33333333-3333-3333-3333-333333333333',
    otherUserName: 'Maya',
    messageCount: 3,
    lastMessageAt: DateTime.parse('2026-04-22T20:00:00Z'),
  ),
  ConversationSummary(
    id: '11111111-1111-1111-1111-111111111111_55555555-5555-5555-5555-555555555555',
    otherUserId: '55555555-5555-5555-5555-555555555555',
    otherUserName: 'Leah',
    messageCount: 14,
    lastMessageAt: DateTime.parse('2026-04-21T16:30:00Z'),
  ),
  ConversationSummary(
    id: '11111111-1111-1111-1111-111111111111_66666666-6666-6666-6666-666666666666',
    otherUserId: '66666666-6666-6666-6666-666666666666',
    otherUserName: 'Ari',
    messageCount: 1,
    lastMessageAt: DateTime.parse('2026-04-19T12:00:00Z'),
  ),
  ConversationSummary(
    id: '11111111-1111-1111-1111-111111111111_77777777-7777-7777-7777-777777777777',
    otherUserId: '77777777-7777-7777-7777-777777777777',
    otherUserName: 'Yael',
    messageCount: 22,
    lastMessageAt: DateTime.parse('2026-04-18T08:45:00Z'),
  ),
];

ConversationSummary get firstConversation => conversations.first;

const _conversationId =
    '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222';

final conversationMessages = <MessageDto>[
  MessageDto(
    id: 'msg-1',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Hey Dana! I saw we both like beach walks.',
    sentAt: DateTime.parse('2026-04-22T10:00:00Z'),
  ),
  MessageDto(
    id: 'msg-2',
    conversationId: _conversationId,
    senderId: currentUser.id,
    content: 'Hey Noa! Sunrise beach walks are pretty unbeatable.',
    sentAt: DateTime.parse('2026-04-22T10:05:00Z'),
  ),
  MessageDto(
    id: 'msg-3',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Do you have a favorite spot? I usually end up at Gordon.',
    sentAt: DateTime.parse('2026-04-22T10:12:00Z'),
  ),
  MessageDto(
    id: 'msg-4',
    conversationId: _conversationId,
    senderId: currentUser.id,
    content: 'Frishman for me. A little calmer, especially early.',
    sentAt: DateTime.parse('2026-04-22T10:20:00Z'),
  ),
  MessageDto(
    id: 'msg-5',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Smart choice. Want to grab coffee nearby this weekend?',
    sentAt: DateTime.parse('2026-04-22T10:30:00Z'),
  ),
  MessageDto(
    id: 'msg-6',
    conversationId: _conversationId,
    senderId: currentUser.id,
    content: 'That sounds perfect. Saturday morning?',
    sentAt: DateTime.parse('2026-04-22T10:35:00Z'),
  ),
  MessageDto(
    id: 'msg-7',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Saturday at 10 works. I know a brunch spot nearby too.',
    sentAt: DateTime.parse('2026-04-22T10:40:00Z'),
  ),
  MessageDto(
    id: 'msg-8',
    conversationId: _conversationId,
    senderId: currentUser.id,
    content: 'Coffee plus brunch is an easy yes from me.',
    sentAt: DateTime.parse('2026-04-23T08:00:00Z'),
  ),
  MessageDto(
    id: 'msg-9',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Excellent. Their shakshuka is worth rearranging a weekend for.',
    sentAt: DateTime.parse('2026-04-23T08:10:00Z'),
  ),
  MessageDto(
    id: 'msg-10',
    conversationId: _conversationId,
    senderId: currentUser.id,
    content: 'You had me at shakshuka.',
    sentAt: DateTime.parse('2026-04-23T08:15:00Z'),
  ),
  MessageDto(
    id: 'msg-11',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Amazing. I will book us a table after coffee.',
    sentAt: DateTime.parse('2026-04-23T08:20:00Z'),
  ),
  MessageDto(
    id: 'msg-12',
    conversationId: _conversationId,
    senderId: currentUser.id,
    content: 'Perfect. See you Saturday and have a great week until then ☀️',
    sentAt: DateTime.parse('2026-04-23T09:15:00Z'),
  ),
];

const standoutsSnapshot = StandoutsSnapshot(
  standouts: [
    Standout(
      id: 'standout-1',
      standoutUserId: '55555555-5555-5555-5555-555555555555',
      standoutUserName: 'Leah',
      standoutUserAge: 31,
      rank: 1,
      score: 98,
      reason: 'Shared pace, music taste, and strong conversation chemistry.',
      createdAt: null,
      interactedAt: null,
    ),
    Standout(
      id: 'standout-2',
      standoutUserId: '66666666-6666-6666-6666-666666666666',
      standoutUserName: 'Ari',
      standoutUserAge: 26,
      rank: 2,
      score: 94,
      reason: 'Backend rank suggests high reply odds this week.',
      createdAt: null,
      interactedAt: null,
    ),
    Standout(
      id: 'standout-3',
      standoutUserId: '88888888-8888-8888-8888-888888888888',
      standoutUserName: 'Shira',
      standoutUserAge: 28,
      rank: 3,
      score: 91,
      reason: 'Recent activity patterns line up unusually well.',
      createdAt: null,
      interactedAt: null,
    ),
    Standout(
      id: 'standout-4',
      standoutUserId: '99999999-9999-9999-9999-999999999999',
      standoutUserName: 'Tomer',
      standoutUserAge: 32,
      rank: 4,
      score: 87,
      reason: 'Both of you are most active at nearly the same times.',
      createdAt: null,
      interactedAt: null,
    ),
    Standout(
      id: 'standout-5',
      standoutUserId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      standoutUserName: 'Neta',
      standoutUserAge: 25,
      rank: 5,
      score: 84,
      reason: 'Close location patterns suggest easy real-world overlap.',
      createdAt: null,
      interactedAt: null,
    ),
  ],
  totalCandidates: 5,
  fromCache: false,
  message: 'Fresh standout picks based on current activity.',
);

const pendingLikers = <PendingLiker>[
  PendingLiker(
    userId: '12121212-1212-1212-1212-121212121212',
    name: 'Nina',
    age: 26,
    likedAt: null,
  ),
  PendingLiker(
    userId: '88888888-8888-8888-8888-888888888888',
    name: 'Shira',
    age: 28,
    likedAt: null,
  ),
  PendingLiker(
    userId: '99999999-9999-9999-9999-999999999999',
    name: 'Tomer',
    age: 32,
    likedAt: null,
  ),
  PendingLiker(
    userId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    name: 'Neta',
    age: 25,
    likedAt: null,
  ),
  PendingLiker(
    userId: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    name: 'Omer',
    age: 30,
    likedAt: null,
  ),
];

const blockedUsers = <BlockedUserSummary>[
  BlockedUserSummary(
    userId: 'cccccccc-cccc-cccc-cccc-cccccccccccc',
    name: 'Kai',
    statusLabel: 'Blocked after repeated spam',
  ),
  BlockedUserSummary(
    userId: 'dddddddd-dddd-dddd-dddd-dddddddddddd',
    name: 'Ron',
    statusLabel: 'Inappropriate messages',
  ),
  BlockedUserSummary(
    userId: 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    name: 'Tali',
    statusLabel: 'Offensive profile content',
  ),
  BlockedUserSummary(
    userId: 'ffffffff-ffff-ffff-ffff-ffffffffffff',
    name: 'Adi',
    statusLabel: 'Blocked after harassment',
  ),
];

final notifications = <NotificationItem>[
  NotificationItem(
    id: 'notif-1',
    type: 'MATCH',
    title: 'New match',
    message: 'You and Maya matched a few minutes ago.',
    createdAt: DateTime.parse('2026-04-23T11:00:00Z'),
    isRead: false,
    data: const {'matchId': 'match-maya'},
  ),
  NotificationItem(
    id: 'notif-2',
    type: 'MESSAGE',
    title: 'New message from Noa',
    message: 'Noa replied about the coffee date this weekend.',
    createdAt: DateTime.parse('2026-04-23T10:30:00Z'),
    isRead: false,
    data: const {'conversationId': _conversationId},
  ),
  NotificationItem(
    id: 'notif-3',
    type: 'LIKE',
    title: 'Someone liked you',
    message: 'You have a new admirer waiting in likes.',
    createdAt: DateTime.parse('2026-04-22T20:00:00Z'),
    isRead: true,
    data: const {},
  ),
  NotificationItem(
    id: 'notif-4',
    type: 'STANDOUT',
    title: 'New standout',
    message: 'Leah was highlighted as a standout pick for you.',
    createdAt: DateTime.parse('2026-04-22T15:00:00Z'),
    isRead: true,
    data: const {'standoutId': 'standout-1'},
  ),
  NotificationItem(
    id: 'notif-5',
    type: 'MATCH',
    title: 'New match',
    message: 'You and Leah matched yesterday.',
    createdAt: DateTime.parse('2026-04-21T14:00:00Z'),
    isRead: true,
    data: const {'matchId': 'match-leah'},
  ),
  NotificationItem(
    id: 'notif-6',
    type: 'MESSAGE',
    title: 'New message from Yael',
    message: 'Yael sent a cheerful follow-up about dinner.',
    createdAt: DateTime.parse('2026-04-21T09:00:00Z'),
    isRead: true,
    data: const {'conversationId': 'conversation-yael'},
  ),
  NotificationItem(
    id: 'notif-7',
    type: 'ACHIEVEMENT',
    title: 'Achievement unlocked',
    message: 'You earned the Conversation starter badge!',
    createdAt: DateTime.parse('2026-04-20T18:00:00Z'),
    isRead: true,
    data: const {'achievementId': 'achievement-starter'},
  ),
  NotificationItem(
    id: 'notif-8',
    type: 'SYSTEM',
    title: 'Profile tip',
    message: 'Adding a second photo can improve profile response rates.',
    createdAt: DateTime.parse('2026-04-19T12:00:00Z'),
    isRead: true,
    data: const {},
  ),
];

const userStats = UserStats(
  items: [
    UserStatItem(label: 'Likes sent', value: '42'),
    UserStatItem(label: 'Likes received', value: '38'),
    UserStatItem(label: 'Matches total', value: '12'),
    UserStatItem(label: 'Matches this week', value: '4'),
    UserStatItem(label: 'Conversations started', value: '9'),
    UserStatItem(label: 'Conversation reply rate', value: '87%'),
    UserStatItem(label: 'Average response time', value: '23 min'),
    UserStatItem(label: 'Profile views', value: '156'),
  ],
);

const achievements = <AchievementSummary>[
  AchievementSummary(
    title: 'First match streak',
    subtitle: 'Matched with someone three days in a row',
    progress: '3 / 3',
    isUnlocked: true,
  ),
  AchievementSummary(
    title: 'Conversation starter',
    subtitle: 'Send the first message in 5 different matches',
    progress: '5 / 5',
    isUnlocked: true,
  ),
  AchievementSummary(
    title: 'Conversation closer',
    subtitle: 'Keep reply rates above 80% for a week',
    progress: '87%',
    isUnlocked: false,
  ),
  AchievementSummary(
    title: 'Popular week',
    subtitle: 'Receive 10 or more likes in one week',
    progress: '7 / 10',
    isUnlocked: false,
  ),
  AchievementSummary(
    title: 'Profile complete',
    subtitle: 'Fill out all profile sections including photos',
    progress: '80%',
    isUnlocked: false,
  ),
];

final profileDetail = UserDetail(
  id: currentUser.id,
  name: currentUser.name,
  age: currentUser.age,
  bio:
      'Loves coffee, beach walks, and polished UI states. Always planning the next brunch.',
  gender: 'FEMALE',
  interestedIn: const ['MALE'],
  approximateLocation: 'Tel Aviv',
  maxDistanceKm: 50,
  photoUrls: const ['/photos/dana-1.jpg'],
  state: currentUser.state,
);

const otherUserProfileDetail = UserDetail(
  id: '44444444-4444-4444-4444-444444444444',
  name: 'Rin',
  age: 28,
  bio: 'Weekend climber, playlist curator, and unapologetic brunch optimist.',
  gender: 'FEMALE',
  interestedIn: ['FEMALE', 'MALE'],
  approximateLocation: 'Haifa',
  maxDistanceKm: 30,
  photoUrls: [],
  state: 'ACTIVE',
);

const availableUsers = <UserSummary>[
  currentUser,
  UserSummary(
    id: '22222222-2222-2222-2222-222222222222',
    name: 'Noa',
    age: 29,
    state: 'ACTIVE',
  ),
];

const locationCountries = <LocationCountry>[
  LocationCountry(
    code: 'IL',
    name: 'Israel',
    flagEmoji: '🇮🇱',
    available: true,
    defaultSelection: true,
  ),
  LocationCountry(
    code: 'US',
    name: 'United States',
    flagEmoji: '🇺🇸',
    available: true,
    defaultSelection: false,
  ),
];

const locationSuggestions = <LocationCity>[
  LocationCity(
    name: 'Tel Aviv',
    district: 'Tel Aviv District',
    countryCode: 'IL',
    priority: 1,
  ),
  LocationCity(
    name: 'Tel Mond',
    district: 'Central District',
    countryCode: 'IL',
    priority: 2,
  ),
];
