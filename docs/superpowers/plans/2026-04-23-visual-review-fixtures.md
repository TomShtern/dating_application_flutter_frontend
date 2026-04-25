# Visual Review Fixtures Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace minimal inline screenshot data with a reusable, richer fixture system that produces realistic-density screenshots.

**Architecture:** Three new fixture files under `test/visual_inspection/fixtures/` — a catalog of canonical rich test entities, lightweight builders for DTO construction, and named scenario bundles consumed by screenshot tests. The existing `screenshot_test.dart` is refactored to import scenarios instead of defining raw data inline.

**Tech Stack:** Flutter 3.41, Dart 3.11, Riverpod (provider overrides), flutter_test golden/screenshot infrastructure.

**Implementation status:** Completed on 2026-04-23, with fresh verification via `flutter analyze`, `flutter test`, and `flutter test test/visual_inspection/screenshot_test.dart`. The only intentionally incomplete item below is the optional git commit step.

---

## File structure

| Action | Path                                                           | Responsibility                                                                           |
|--------|----------------------------------------------------------------|------------------------------------------------------------------------------------------|
| Create | `test/visual_inspection/fixtures/visual_fixture_catalog.dart`  | Canonical rich test entities (users, candidates, matches, conversations, messages, etc.) |
| Create | `test/visual_inspection/fixtures/visual_fixture_builders.dart` | Lightweight builder functions for creating DTO variants with readable overrides          |
| Create | `test/visual_inspection/fixtures/visual_scenarios.dart`        | Named scenario bundles that group entities into screen-ready provider override values    |
| Modify | `test/visual_inspection/screenshot_test.dart`                  | Remove inline data constants, import scenarios, wire each test to a named scenario       |
| Update | `docs/visual-review-workflow.md`                               | Document the new fixture/scenario structure (brief section)                              |

---

## Sub-agent split

This plan is structured for **3 sequential sub-agents**:

1. **Sub-agent A (Architecture):** Create the three fixture files with all builders and the first pass of scenarios.
2. **Sub-agent B (Integration):** Refactor `screenshot_test.dart` to consume scenarios, run screenshot tests, verify 18/18 pass.
3. **Sub-agent C (Verification + Docs):** Run full test suite, run flutter analyze, inspect screenshots, update docs.

---

## Task 1: Create fixture catalog and builders

**Files:**
- Create: `test/visual_inspection/fixtures/visual_fixture_catalog.dart`
- Create: `test/visual_inspection/fixtures/visual_fixture_builders.dart`

### Task 1a: Create `visual_fixture_catalog.dart`

This file holds canonical rich test entities. All IDs, names, and timestamps are fixed and deterministic.

- [x] **Step 1: Create the file with the current user and a richer cast of characters**

```dart
// test/visual_inspection/fixtures/visual_fixture_catalog.dart
//
// Canonical rich test entities for visual review screenshots.
// All values are deterministic — never random or time-dependent.
//
// Re-export model types used throughout so consumers need only one import.

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
export 'package:flutter_dating_application_1/models/health_status.dart';
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

// --- Current user (stable across all scenarios) ---

const currentUser = UserSummary(
  id: '11111111-1111-1111-1111-111111111111',
  name: 'Dana',
  age: 27,
  state: 'ACTIVE',
);

// --- Browse candidates (5 for discover density) ---

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
    id: '44444444-4044-4444-4444-444444444444',
    name: 'Rin',
    age: 28,
    state: 'ACTIVE',
  ),
  BrowseCandidate(
    id: '55555555-5055-5555-5555-555555555555',
    name: 'Leah',
    age: 31,
    state: 'ACTIVE',
  ),
  BrowseCandidate(
    id: '66666666-6066-6666-6666-666666666666',
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
  reason: 'Strong compatibility on pace and conversation style',
  alreadySeen: false,
);

const browseResponse = BrowseResponse(
  candidates: browseCandidates,
  dailyPick: dailyPick,
  dailyPickViewed: false,
  locationMissing: false,
);

// --- Matches (5 matches) ---

final matches = <MatchSummary>[
  MatchSummary(
    matchId: '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    otherUserId: '22222222-2222-2222-2222-222222222222',
    otherUserName: 'Noa',
    state: 'ACTIVE',
    createdAt: DateTime.parse('2026-04-18T14:00:00Z'),
  ),
  MatchSummary(
    matchId: '11111111-1111-1111-1111-111111111111_33333333-3333-3333-3333-333333333333',
    otherUserId: '33333333-3333-3333-3333-333333333333',
    otherUserName: 'Maya',
    state: 'ACTIVE',
    createdAt: DateTime.parse('2026-04-17T10:00:00Z'),
  ),
  MatchSummary(
    matchId: '11111111-1111-1111-1111-111111111111_55555555-5055-5555-5555-555555555555',
    otherUserId: '55555555-5055-5555-5555-555555555555',
    otherUserName: 'Leah',
    state: 'ACTIVE',
    createdAt: DateTime.parse('2026-04-15T09:30:00Z'),
  ),
  MatchSummary(
    matchId: '11111111-1111-1111-1111-111111111111_66666666-6066-6666-6666-666666666666',
    otherUserId: '66666666-6066-6666-6666-666666666666',
    otherUserName: 'Ari',
    state: 'ACTIVE',
    createdAt: DateTime.parse('2026-04-12T18:00:00Z'),
  ),
  MatchSummary(
    matchId: '11111111-1111-1111-1111-111111111111_77777777-7077-7777-7777-777777777777',
    otherUserId: '77777777-7077-7777-7777-777777777777',
    otherUserName: 'Yael',
    state: 'ACTIVE',
    createdAt: DateTime.parse('2026-04-10T08:15:00Z'),
  ),
];

final matchesResponse = MatchesResponse(
  matches: matches,
  totalCount: 5,
  offset: 0,
  limit: 20,
  hasMore: false,
);

// --- Conversations (5 conversations with varied recency) ---

final conversations = <ConversationSummary>[
  ConversationSummary(
    id: '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222',
    otherUserId: '22222222-2222-2222-2222-222222222222',
    otherUserName: 'Noa',
    messageCount: 8,
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
    id: '11111111-1111-1111-1111-111111111111_55555555-5055-5555-5555-555555555555',
    otherUserId: '55555555-5055-5555-5555-555555555555',
    otherUserName: 'Leah',
    messageCount: 14,
    lastMessageAt: DateTime.parse('2026-04-21T16:30:00Z'),
  ),
  ConversationSummary(
    id: '11111111-1111-1111-1111-111111111111_66666666-6066-6666-6666-666666666666',
    otherUserId: '66666666-6066-6666-6666-666666666666',
    otherUserName: 'Ari',
    messageCount: 1,
    lastMessageAt: DateTime.parse('2026-04-19T12:00:00Z'),
  ),
  ConversationSummary(
    id: '11111111-1111-1111-1111-111111111111_77777777-7077-7777-7777-777777777777',
    otherUserId: '77777777-7077-7777-7777-777777777777',
    otherUserName: 'Yael',
    messageCount: 22,
    lastMessageAt: DateTime.parse('2026-04-18T08:45:00Z'),
  ),
];

// --- Conversation thread messages (12 messages across 2 days) ---

const _conversationId = '11111111-1111-1111-1111-111111111111_22222222-2222-2222-2222-222222222222';

final conversationMessages = <MessageDto>[
  // Day 1 — April 22
  MessageDto(
    id: 'msg-1',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Hey Dana! I saw we both like beach walks',
    sentAt: DateTime.parse('2026-04-22T10:00:00Z'),
  ),
  MessageDto(
    id: 'msg-2',
    conversationId: _conversationId,
    senderId: '11111111-1111-1111-1111-111111111111',
    content: 'Hey Noa! Yeah the beach at sunrise is unbeatable',
    sentAt: DateTime.parse('2026-04-22T10:05:00Z'),
  ),
  MessageDto(
    id: 'msg-3',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Do you have a favorite spot? I usually go to Gordon Beach',
    sentAt: DateTime.parse('2026-04-22T10:12:00Z'),
  ),
  MessageDto(
    id: 'msg-4',
    conversationId: _conversationId,
    senderId: '11111111-1111-1111-1111-111111111111',
    content: 'Gordon is great! I tend toward Frishman though. Less crowded in the mornings',
    sentAt: DateTime.parse('2026-04-22T10:20:00Z'),
  ),
  MessageDto(
    id: 'msg-5',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Smart. Want to grab coffee at that place near Frishman this weekend?',
    sentAt: DateTime.parse('2026-04-22T10:30:00Z'),
  ),
  MessageDto(
    id: 'msg-6',
    conversationId: _conversationId,
    senderId: '11111111-1111-1111-1111-111111111111',
    content: 'Sounds perfect — Saturday morning?',
    sentAt: DateTime.parse('2026-04-22T10:35:00Z'),
  ),
  MessageDto(
    id: 'msg-7',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Saturday works! Say 10? I also know a great brunch spot nearby if you are up for it',
    sentAt: DateTime.parse('2026-04-22T10:40:00Z'),
  ),
  // Day 2 — April 23
  MessageDto(
    id: 'msg-8',
    conversationId: _conversationId,
    senderId: '11111111-1111-1111-1111-111111111111',
    content: '10 is great. And brunch after coffee sounds amazing. I love a good shakshuka',
    sentAt: DateTime.parse('2026-04-23T08:00:00Z'),
  ),
  MessageDto(
    id: 'msg-9',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'They have the best shakshuka in Tel Aviv. Their bread is also incredible',
    sentAt: DateTime.parse('2026-04-23T08:10:00Z'),
  ),
  MessageDto(
    id: 'msg-10',
    conversationId: _conversationId,
    senderId: '11111111-1111-1111-1111-111111111111',
    content: 'You had me at bread. See you Saturday!',
    sentAt: DateTime.parse('2026-04-23T08:15:00Z'),
  ),
  MessageDto(
    id: 'msg-11',
    conversationId: _conversationId,
    senderId: '22222222-2222-2222-2222-222222222222',
    content: 'Looking forward to it. Let me know if plans change',
    sentAt: DateTime.parse('2026-04-23T08:20:00Z'),
  ),
  MessageDto(
    id: 'msg-12',
    conversationId: _conversationId,
    senderId: '11111111-1111-1111-1111-111111111111',
    content: 'Will do. Have a great rest of the week! ☀️',
    sentAt: DateTime.parse('2026-04-23T09:15:00Z'),
  ),
];

// The first conversation in the list, used for the thread screenshot.
ConversationSummary get firstConversation => conversations.first;

// --- Standouts (5 standouts) ---

const standoutsSnapshot = StandoutsSnapshot(
  standouts: [
    Standout(
      id: 'standout-1',
      standoutUserId: '55555555-5055-5555-5555-555555555555',
      standoutUserName: 'Leah',
      standoutUserAge: 31,
      rank: 1,
      score: 98,
      reason: 'Shared pace, music taste, and a strong match on conversation style',
      createdAt: null,
      interactedAt: null,
    ),
    Standout(
      id: 'standout-2',
      standoutUserId: '66666666-6066-6666-6666-666666666666',
      standoutUserName: 'Ari',
      standoutUserAge: 26,
      rank: 2,
      score: 94,
      reason: 'Backend rank suggests high reply odds this week',
      createdAt: null,
      interactedAt: null,
    ),
    Standout(
      id: 'standout-3',
      standoutUserId: '88888888-8088-8888-8888-888888888888',
      standoutUserName: 'Shira',
      standoutUserAge: 28,
      rank: 3,
      score: 91,
      reason: 'Your recent activity aligns with their preferences',
      createdAt: null,
      interactedAt: null,
    ),
    Standout(
      id: 'standout-4',
      standoutUserId: '99999999-9099-9999-9999-999999999999',
      standoutUserName: 'Tomer',
      standoutUserAge: 32,
      rank: 4,
      score: 87,
      reason: 'Both active in overlapping time windows',
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
      reason: 'Similar location patterns suggest natural meeting potential',
      createdAt: null,
      interactedAt: null,
    ),
  ],
  totalCandidates: 5,
  fromCache: false,
  message: 'Fresh standout picks based on current activity',
);

// --- Pending likers (5 pending likers) ---

const pendingLikers = <PendingLiker>[
  PendingLiker(
    userId: '77777777-7077-7777-7777-777777777777',
    name: 'Nina',
    age: 26,
    likedAt: null,
  ),
  PendingLiker(
    userId: '88888888-8088-8888-8888-888888888888',
    name: 'Shira',
    age: 28,
    likedAt: null,
  ),
  PendingLiker(
    userId: '99999999-9099-9999-9999-999999999999',
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

// --- Blocked users (4 blocked users) ---

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

// --- Notifications (8 items, mixed types and read states) ---

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
    data: const {'conversationId': 'conv-noa'},
  ),
  NotificationItem(
    id: 'notif-3',
    type: 'LIKE',
    title: 'Someone liked you',
    message: 'You have a new admirer. Check who liked you.',
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
    message: 'Yael sent you a photo.',
    createdAt: DateTime.parse('2026-04-21T09:00:00Z'),
    isRead: true,
    data: const {'conversationId': 'conv-yael'},
  ),
  NotificationItem(
    id: 'notif-7',
    type: 'ACHIEVEMENT',
    title: 'Achievement unlocked',
    message: 'You earned the Conversation closer badge!',
    createdAt: DateTime.parse('2026-04-20T18:00:00Z'),
    isRead: true,
    data: const {'achievementId': 'ach-conversation-closer'},
  ),
  NotificationItem(
    id: 'notif-8',
    type: 'SYSTEM',
    title: 'Profile tip',
    message: 'Adding a second photo can increase your match rate by up to 30%.',
    createdAt: DateTime.parse('2026-04-19T12:00:00Z'),
    isRead: true,
    data: const {},
  ),
];

// --- Stats (8 stat items with varied values) ---

const userStats = UserStats(items: [
  UserStatItem(label: 'Likes sent', value: '42'),
  UserStatItem(label: 'Likes received', value: '38'),
  UserStatItem(label: 'Matches total', value: '12'),
  UserStatItem(label: 'Matches this week', value: '4'),
  UserStatItem(label: 'Conversations started', value: '9'),
  UserStatItem(label: 'Conversation reply rate', value: '87%'),
  UserStatItem(label: 'Average response time', value: '23 min'),
  UserStatItem(label: 'Profile views', value: '156'),
]);

// --- Achievements (5 — mix of unlocked and in-progress) ---

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

// --- Profile detail (current user) ---

final profileDetail = UserDetail(
  id: '11111111-1111-1111-1111-111111111111',
  name: 'Dana',
  age: 27,
  bio: 'Loves coffee, beach walks, and polished UI states. Always planning the next brunch.',
  gender: 'FEMALE',
  interestedIn: ['MALE'],
  approximateLocation: 'Tel Aviv',
  maxDistanceKm: 50,
  photoUrls: ['/photos/dana-1.jpg'],
  state: 'ACTIVE',
);

// --- Other user profile detail (for viewing someone's profile) ---

const otherUserProfileDetail = UserDetail(
  id: '44444444-4044-4444-4444-444444444444',
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

// --- Available users (for dev-user picker) ---

const availableUsers = <UserSummary>[
  UserSummary(
    id: '11111111-1111-1111-1111-111111111111',
    name: 'Dana',
    age: 27,
    state: 'ACTIVE',
  ),
  UserSummary(
    id: '22222222-2222-2222-2222-222222222222',
    name: 'Noa',
    age: 29,
    state: 'ACTIVE',
  ),
];

// --- Location fixtures ---

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
```

- [x] **Step 2: Run dart analyze on the new file to verify no compile errors**

Run: `dart analyze test/visual_inspection/fixtures/visual_fixture_catalog.dart`
Expected: No issues found.

### Task 1b: Create `visual_fixture_builders.dart`

This file provides lightweight builder functions for creating DTO variants with readable overrides. These are needed because most models lack `copyWith()`. These builders should remain small and DTO-specific.

- [x] **Step 1: Create the builders file**

```dart
// test/visual_inspection/fixtures/visual_fixture_builders.dart
//
// Lightweight builder helpers for constructing DTO variants in tests.
// These exist because most models do not provide copyWith().
//
// Design rule: each builder is a plain function that creates one DTO
// with sensible defaults and named overrides. No abstract factories,
// no deeply nested DSL, no test-only inheritance.

import 'package:flutter_dating_application_1/models/achievement_summary.dart';
import 'package:flutter_dating_application_1/models/blocked_user_summary.dart';
import 'package:flutter_dating_application_1/models/browse_candidate.dart';
import 'package:flutter_dating_application_1/models/conversation_summary.dart';
import 'package:flutter_dating_application_1/models/match_summary.dart';
import 'package:flutter_dating_application_1/models/message_dto.dart';
import 'package:flutter_dating_application_1/models/notification_item.dart';
import 'package:flutter_dating_application_1/models/pending_liker.dart';
import 'package:flutter_dating_application_1/models/user_detail.dart';
import 'package:flutter_dating_application_1/models/user_stats.dart';
import 'package:flutter_dating_application_1/models/user_summary.dart';

/// Creates a [UserSummary] with sensible defaults and named overrides.
UserSummary buildUserSummary({
  String id = '00000000-0000-0000-0000-000000000000',
  String name = 'Test User',
  int age = 25,
  String state = 'ACTIVE',
}) {
  return UserSummary(id: id, name: name, age: age, state: state);
}

/// Creates a [BrowseCandidate] with sensible defaults.
BrowseCandidate buildBrowseCandidate({
  String id = '00000000-0000-0000-0000-000000000000',
  String name = 'Test Candidate',
  int age = 25,
  String state = 'ACTIVE',
}) {
  return BrowseCandidate(id: id, name: name, age: age, state: state);
}

/// Creates a [UserDetail] with sensible defaults.
UserDetail buildUserDetail({
  String id = '00000000-0000-0000-0000-000000000000',
  String name = 'Test User',
  int age = 25,
  String bio = 'A short bio for testing.',
  String gender = 'FEMALE',
  List<String> interestedIn = const ['MALE'],
  String approximateLocation = 'Tel Aviv',
  int maxDistanceKm = 50,
  List<String> photoUrls = const [],
  String state = 'ACTIVE',
}) {
  return UserDetail(
    id: id,
    name: name,
    age: age,
    bio: bio,
    gender: gender,
    interestedIn: interestedIn,
    approximateLocation: approximateLocation,
    maxDistanceKm: maxDistanceKm,
    photoUrls: photoUrls,
    state: state,
  );
}

/// Creates a [MatchSummary] with sensible defaults.
MatchSummary buildMatch({
  String matchId = 'match-default',
  String otherUserId = '00000000-0000-0000-0000-000000000000',
  String otherUserName = 'Test Match',
  String state = 'ACTIVE',
  DateTime? createdAt,
}) {
  return MatchSummary(
    matchId: matchId,
    otherUserId: otherUserId,
    otherUserName: otherUserName,
    state: state,
    createdAt: createdAt ?? DateTime.parse('2026-04-20T12:00:00Z'),
  );
}

/// Creates a [ConversationSummary] with sensible defaults.
ConversationSummary buildConversation({
  String id = 'conv-default',
  String otherUserId = '00000000-0000-0000-0000-000000000000',
  String otherUserName = 'Test Chat',
  int messageCount = 5,
  DateTime? lastMessageAt,
}) {
  return ConversationSummary(
    id: id,
    otherUserId: otherUserId,
    otherUserName: otherUserName,
    messageCount: messageCount,
    lastMessageAt: lastMessageAt ?? DateTime.parse('2026-04-20T12:00:00Z'),
  );
}

/// Creates a [MessageDto] with sensible defaults.
MessageDto buildMessage({
  String id = 'msg-default',
  String conversationId = 'conv-default',
  String senderId = '00000000-0000-0000-0000-000000000000',
  String content = 'Test message content',
  DateTime? sentAt,
}) {
  return MessageDto(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    content: content,
    sentAt: sentAt ?? DateTime.parse('2026-04-20T12:00:00Z'),
  );
}

/// Creates a [PendingLiker] with sensible defaults.
PendingLiker buildPendingLiker({
  String userId = '00000000-0000-0000-0000-000000000000',
  String name = 'Test Liker',
  int age = 25,
  DateTime? likedAt,
}) {
  return PendingLiker(
    userId: userId,
    name: name,
    age: age,
    likedAt: likedAt,
  );
}

/// Creates a [BlockedUserSummary] with sensible defaults.
BlockedUserSummary buildBlockedUser({
  String userId = '00000000-0000-0000-0000-000000000000',
  String name = 'Test Blocked',
  String statusLabel = 'Blocked profile',
}) {
  return BlockedUserSummary(
    userId: userId,
    name: name,
    statusLabel: statusLabel,
  );
}

/// Creates a [NotificationItem] with sensible defaults.
NotificationItem buildNotification({
  String id = 'notif-default',
  String type = 'SYSTEM',
  String title = 'Test Notification',
  String message = 'Test notification body.',
  DateTime? createdAt,
  bool isRead = false,
  Map<String, String> data = const {},
}) {
  return NotificationItem(
    id: id,
    type: type,
    title: title,
    message: message,
    createdAt: createdAt ?? DateTime.parse('2026-04-20T12:00:00Z'),
    isRead: isRead,
    data: data,
  );
}

/// Creates a [UserStatItem] with sensible defaults.
UserStatItem buildStatItem({
  String label = 'Test stat',
  String value = '0',
}) {
  return UserStatItem(label: label, value: value);
}

/// Creates an [AchievementSummary] with sensible defaults.
AchievementSummary buildAchievement({
  String title = 'Test Achievement',
  String? subtitle,
  String? progress,
  bool? isUnlocked,
}) {
  return AchievementSummary(
    title: title,
    subtitle: subtitle,
    progress: progress,
    isUnlocked: isUnlocked,
  );
}
```

- [x] **Step 2: Run dart analyze to verify builders compile cleanly**

Run: `dart analyze test/visual_inspection/fixtures/visual_fixture_builders.dart`
Expected: No issues found.

### Task 1c: Create `visual_scenarios.dart`

This file groups catalog entities into named scenarios consumed by individual screenshot tests. Each scenario exposes only what the screen needs.

- [x] **Step 1: Create the scenarios file**

```dart
// test/visual_inspection/fixtures/visual_scenarios.dart
//
// Named scenario bundles for screenshot tests.
// Each scenario groups the provider override values, selected user,
// and screen-specific parameters needed for one screenshot capture.
//
// Scenarios import from the catalog. They DO NOT define raw data inline.

import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/browse_provider.dart';
import 'package:flutter_dating_application_1/features/browse/pending_likers_provider.dart';
import 'package:flutter_dating_application_1/features/browse/standouts_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_provider.dart';
import 'package:flutter_dating_application_1/features/chat/conversations_provider.dart';
import 'package:flutter_dating_application_1/features/home/backend_health_provider.dart';
import 'package:flutter_dating_application_1/features/location/location_provider.dart';
import 'package:flutter_dating_application_1/features/matches/matches_provider.dart';
import 'package:flutter_dating_application_1/features/notifications/notifications_provider.dart';
import 'package:flutter_dating_application_1/features/profile/profile_provider.dart';
import 'package:flutter_dating_application_1/features/safety/blocked_users_provider.dart';
import 'package:flutter_dating_application_1/features/stats/stats_provider.dart';
import 'package:flutter_dating_application_1/models/health_status.dart';
import 'package:flutter_dating_application_1/models/location_metadata.dart';
import 'package:flutter_dating_application_1/shared/persistence/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'visual_fixture_catalog.dart';

// ---------------------------------------------------------------------------
// Health status (shared across most scenarios)
// ---------------------------------------------------------------------------

final _healthOverride = backendHealthProvider.overrideWith(
  (ref) async => HealthStatus(
    status: 'ok',
    timestamp: DateTime.parse('2026-04-23T12:00:00Z'),
  ),
);

// ---------------------------------------------------------------------------
// Dev-user picker scenario
// ---------------------------------------------------------------------------

/// Provider overrides for the app startup / dev-user picker screenshot.
List<dynamic> get devUserPickerOverrides => [
  backendHealthProvider.overrideWith(
    (ref) async => HealthStatus(
      status: 'ok',
      timestamp: DateTime.parse('2026-04-23T12:00:00Z'),
    ),
  ),
  selectedUserProvider.overrideWith((ref) async => null),
  availableUsersProvider.overrideWith((ref) async => availableUsers),
];

// ---------------------------------------------------------------------------
// Signed-in shell scenario (used by all 5 tab screenshots)
// ---------------------------------------------------------------------------

/// Provider overrides for the signed-in shell + all 5 tabs.
List<dynamic> signedInShellOverrides(SharedPreferences preferences) => [
  sharedPreferencesProvider.overrideWithValue(preferences),
  _healthOverride,
  browseProvider.overrideWith((ref) async => browseResponse),
  matchesProvider.overrideWith((ref) async => matchesResponse),
  conversationsProvider.overrideWith((ref) async => conversations),
  profileProvider.overrideWith((ref) async => profileDetail),
  selectedUserProvider.overrideWith((ref) async => currentUser),
];

// ---------------------------------------------------------------------------
// Conversation thread scenario
// ---------------------------------------------------------------------------

/// Provider overrides for the populated conversation thread screenshot.
List<dynamic> get conversationThreadOverrides => [
  selectedUserProvider.overrideWith((ref) async => currentUser),
  conversationThreadProvider(firstConversation.id).overrideWith(
    (ref) async => conversationMessages,
  ),
];

// ---------------------------------------------------------------------------
// Standouts scenario
// ---------------------------------------------------------------------------

/// Provider overrides for the standouts screen screenshot.
List<dynamic> get standoutsOverrides => [
  selectedUserProvider.overrideWith((ref) async => currentUser),
  standoutsProvider.overrideWith((ref) async => standoutsSnapshot),
];

// ---------------------------------------------------------------------------
// Pending likers scenario
// ---------------------------------------------------------------------------

/// Provider overrides for the pending likers screen screenshot.
List<dynamic> get pendingLikersOverrides => [
  selectedUserProvider.overrideWith((ref) async => currentUser),
  pendingLikersProvider.overrideWith((ref) async => pendingLikers),
];

// ---------------------------------------------------------------------------
// Other-user profile scenario
// ---------------------------------------------------------------------------

/// Provider overrides for the other-user profile screenshot.
List<dynamic> get otherUserProfileOverrides => [
  selectedUserProvider.overrideWith((ref) async => currentUser),
  otherUserProfileProvider(otherUserProfileDetail.id).overrideWith(
    (ref) async => otherUserProfileDetail,
  ),
];

// ---------------------------------------------------------------------------
// Stats scenario
// ---------------------------------------------------------------------------

/// Provider overrides for the stats screen screenshot.
List<dynamic> get statsOverrides => [
  selectedUserProvider.overrideWith((ref) async => currentUser),
  statsProvider.overrideWith((ref) async => userStats),
];

// ---------------------------------------------------------------------------
// Achievements scenario
// ---------------------------------------------------------------------------

/// Provider overrides for the achievements screen screenshot.
List<dynamic> get achievementsOverrides => [
  selectedUserProvider.overrideWith((ref) async => currentUser),
  achievementsProvider.overrideWith((ref) async => achievements),
];

// ---------------------------------------------------------------------------
// Blocked users scenario
// ---------------------------------------------------------------------------

/// Provider overrides for the blocked users screen screenshot.
List<dynamic> get blockedUsersOverrides => [
  selectedUserProvider.overrideWith((ref) async => currentUser),
  blockedUsersProvider.overrideWith((ref) async => blockedUsers),
];

// ---------------------------------------------------------------------------
// Notifications scenario
// ---------------------------------------------------------------------------

/// Provider overrides for the notifications screen screenshot.
List<dynamic> get notificationsOverrides => [
  selectedUserProvider.overrideWith((ref) async => currentUser),
  notificationsProvider.overrideWith((ref) async => notifications),
];

// ---------------------------------------------------------------------------
// Location completion scenario
// ---------------------------------------------------------------------------

/// Provider overrides for the location completion screenshot.
List<dynamic> get locationCompletionOverrides => [
  selectedUserProvider.overrideWith((ref) async => currentUser),
  locationCountriesProvider.overrideWith((ref) async => locationCountries),
  locationCitySuggestionsProvider(
    const LocationCitySearchQuery(countryCode: 'IL', query: 'Tel'),
  ).overrideWith((ref) async => locationSuggestions),
];

// ---------------------------------------------------------------------------
// Base signed-in visual screen overrides
// ---------------------------------------------------------------------------

/// Minimal overrides for signed-in visual screens that only need the
/// current user (e.g. profile edit, verification).
List<dynamic> baseSignedInOverrides(SharedPreferences preferences) => [
  sharedPreferencesProvider.overrideWithValue(preferences),
  selectedUserProvider.overrideWith((ref) async => currentUser),
];
```

- [x] **Step 2: Run dart analyze to verify scenarios compile cleanly**

Run: `dart analyze test/visual_inspection/fixtures/visual_scenarios.dart`
Expected: No issues found.

---

## Task 2: Refactor screenshot_test.dart to consume scenarios

**Files:**
- Modify: `test/visual_inspection/screenshot_test.dart`

This is the biggest change. The test file currently has ~850 lines of inline data, helper functions, and test cases. We need to:

1. Remove all inline data constants (everything from `const _currentUser` through `final _notifications`).
2. Import the scenarios file.
3. Refactor `_pumpSignedInShell` to import from scenarios.
4. Refactor each test to use scenario imports.
5. Ensure helper functions `_pumpVisualHarness`, `_pumpSignedInVisualScreen`, `_captureAndSave` remain intact but simplified.

### Step-by-step refactoring

- [x] **Step 1: Add the scenario import at the top of the file, remove all inline data constants**

Add this import near the top of the file:
```dart
import 'fixtures/visual_scenarios.dart';
```

Remove ALL inline data constants — everything from:
```dart
const _currentUser = UserSummary(
```
through to the end of:
```dart
final _notifications = [
```
and its closing `];`.

Also remove any model imports that are now re-exported by the catalog (they are re-exported through the scenarios import which re-exports the catalog).

The following imports can be REMOVED since they are re-exported by `visual_fixture_catalog.dart` (via `visual_scenarios.dart`):
- `achievement_summary.dart`
- `blocked_user_summary.dart`
- `browse_candidate.dart`
- `browse_response.dart`
- `conversation_summary.dart`
- `daily_pick.dart`
- `health_status.dart`
- `location_metadata.dart`
- `match_summary.dart`
- `matches_response.dart`
- `message_dto.dart`
- `notification_item.dart`
- `pending_liker.dart`
- `standout.dart`
- `user_detail.dart`
- `user_stats.dart`
- `user_summary.dart`

The following imports must be KEPT (not re-exported):
- `dart:convert` — needed for `_preferencesWithTheme`
- `dart:io` — needed for `Platform.pathSeparator`
- `package:flutter/material.dart`
- `package:flutter_riverpod/flutter_riverpod.dart`
- `package:flutter_test/flutter_test.dart`
- `package:shared_preferences/shared_preferences.dart`
- `package:flutter_dating_application_1/features/auth/selected_user_provider.dart` — for `availableUsersProvider`
- `package:flutter_dating_application_1/features/browse/pending_likers_screen.dart`
- `package:flutter_dating_application_1/features/browse/standouts_screen.dart`
- `package:flutter_dating_application_1/features/chat/conversation_thread_screen.dart`
- `package:flutter_dating_application_1/features/home/app_home_screen.dart`
- `package:flutter_dating_application_1/features/home/signed_in_shell.dart`
- `package:flutter_dating_application_1/features/location/location_completion_screen.dart`
- `package:flutter_dating_application_1/features/notifications/notifications_screen.dart`
- `package:flutter_dating_application_1/features/profile/profile_edit_screen.dart`
- `package:flutter_dating_application_1/features/profile/profile_screen.dart`
- `package:flutter_dating_application_1/features/safety/blocked_users_screen.dart`
- `package:flutter_dating_application_1/features/settings/app_preferences_store.dart`
- `package:flutter_dating_application_1/features/stats/stats_screen.dart`
- `package:flutter_dating_application_1/features/stats/achievements_screen.dart`
- `package:flutter_dating_application_1/features/verification/verification_screen.dart`
- `package:flutter_dating_application_1/models/app_preferences.dart`
- `package:flutter_dating_application_1/theme/app_theme.dart`
- `support/screenshot_capture.dart`

Also recommended to remove these feature-level provider imports (now referenced through scenarios):
- `browse_provider.dart`
- `pending_likers_provider.dart`
- `standouts_provider.dart`
- `conversation_thread_provider.dart`
- `conversations_provider.dart`
- `backend_health_provider.dart`
- `location_provider.dart`
- `matches_provider.dart`
- `notifications_provider.dart`
- `profile_provider.dart`
- `blocked_users_provider.dart`
- `stats_provider.dart`
- `shared_preferences_provider.dart`

Keep `selected_user_provider.dart` because it defines `availableUsersProvider` used in the dev-user picker test.

- [x] **Step 2: Update each test to use catalog references**

Replace all references to old private constants with catalog references:

| Old reference             | New reference            |
|---------------------------|--------------------------|
| `_currentUser`            | `currentUser`            |
| `_candidateUser`          | `browseCandidates.first` |
| `_dailyPick`              | `dailyPick`              |
| `_match`                  | `matches.first`          |
| `_conversation`           | `firstConversation`      |
| `_conversationMessages`   | `conversationMessages`   |
| `_profileDetail`          | `profileDetail`          |
| `_otherUserProfileDetail` | `otherUserProfileDetail` |
| `_standoutsSnapshot`      | `standoutsSnapshot`      |
| `_pendingLikers`          | `pendingLikers`          |
| `_locationCountries`      | `locationCountries`      |
| `_locationSuggestions`    | `locationSuggestions`    |
| `_userStats`              | `userStats`              |
| `_achievements`           | `achievements`           |
| `_blockedUsers`           | `blockedUsers`           |
| `_notifications`          | `notifications`          |

Here is the **complete refactored `screenshot_test.dart`**:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_dating_application_1/features/auth/selected_user_provider.dart';
import 'package:flutter_dating_application_1/features/browse/pending_likers_screen.dart';
import 'package:flutter_dating_application_1/features/browse/standouts_screen.dart';
import 'package:flutter_dating_application_1/features/chat/conversation_thread_screen.dart';
import 'package:flutter_dating_application_1/features/home/app_home_screen.dart';
import 'package:flutter_dating_application_1/features/home/signed_in_shell.dart';
import 'package:flutter_dating_application_1/features/location/location_completion_screen.dart';
import 'package:flutter_dating_application_1/features/notifications/notifications_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_edit_screen.dart';
import 'package:flutter_dating_application_1/features/profile/profile_screen.dart';
import 'package:flutter_dating_application_1/features/safety/blocked_users_screen.dart';
import 'package:flutter_dating_application_1/features/settings/app_preferences_store.dart';
import 'package:flutter_dating_application_1/features/stats/stats_screen.dart';
import 'package:flutter_dating_application_1/features/stats/achievements_screen.dart';
import 'package:flutter_dating_application_1/features/verification/verification_screen.dart';
import 'package:flutter_dating_application_1/models/app_preferences.dart';
import 'package:flutter_dating_application_1/theme/app_theme.dart';

import 'fixtures/visual_scenarios.dart';
import 'support/screenshot_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final GoldenFileComparator previousComparator = goldenFileComparator;
  final ScreenshotWriter screenshotWriter = ScreenshotWriter(
    Uri.file(
      [
        Directory.current.path,
        'test',
        'visual_inspection',
        'screenshot_test.dart',
      ].join(Platform.pathSeparator),
    ),
  );
  goldenFileComparator = screenshotWriter;
  tearDownAll(() {
    goldenFileComparator = previousComparator;
  });

  testWidgets('captures the app startup dev-user picker state', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpVisualHarness(
      tester,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          ...devUserPickerOverrides,
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: AppHomeScreen(),
        ),
      ),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'app startup dev-user picker',
      fileName: 'app_home_startup.png',
    );
  });

  testWidgets('captures the signed-in shell discover tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInShell(tester, preferences: preferences);

    await _captureAndSave(
      tester,
      scenarioName: 'signed-in shell discover tab',
      fileName: 'shell_discover.png',
    );
  });

  testWidgets('captures the signed-in shell matches tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInShell(tester, preferences: preferences);

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'signed-in shell matches tab',
      fileName: 'shell_matches.png',
    );
  });

  testWidgets('captures the signed-in shell chats tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInShell(tester, preferences: preferences);

    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'signed-in shell chats tab',
      fileName: 'shell_chats.png',
    );
  });

  testWidgets('captures the signed-in shell profile tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInShell(tester, preferences: preferences);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'signed-in shell profile tab',
      fileName: 'shell_profile.png',
    );
  });

  testWidgets('captures the signed-in shell settings tab', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInShell(tester, preferences: preferences);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'signed-in shell settings tab',
      fileName: 'shell_settings.png',
    );
  });

  testWidgets('captures a populated conversation thread', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpVisualHarness(
      tester,
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          ...conversationThreadOverrides,
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: ThemeMode.light,
          home: ConversationThreadScreen(
            currentUser: currentUser,
            conversation: firstConversation,
            refreshInterval: Duration.zero,
          ),
        ),
      ),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'populated conversation thread',
      fileName: 'conversation_thread.png',
    );
  });

  testWidgets('captures the standouts screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: standoutsOverrides,
      child: const StandoutsScreen(),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'standouts screen',
      fileName: 'standouts.png',
    );
  });

  testWidgets('captures the pending likers screen', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: pendingLikersOverrides,
      child: const PendingLikersScreen(),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'pending likers screen',
      fileName: 'pending_likers.png',
    );
  });

  testWidgets('captures the other-user profile screen', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: otherUserProfileOverrides,
      child: ProfileScreen.otherUser(
        userId: otherUserProfileDetail.id,
        userName: otherUserProfileDetail.name,
      ),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'other-user profile screen',
      fileName: 'profile_other_user.png',
    );
  });

  testWidgets('captures the profile edit screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      child: ProfileEditScreen(initialDetail: profileDetail),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'profile edit screen',
      fileName: 'profile_edit.png',
    );
  });

  testWidgets('captures the location completion screen', (
    WidgetTester tester,
  ) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: locationCompletionOverrides,
      child: const LocationCompletionScreen(),
    );

    await tester.enterText(find.byType(TextField).first, 'Tel');
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'location completion screen',
      fileName: 'location_completion.png',
    );
  });

  testWidgets('captures the stats screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: statsOverrides,
      child: const StatsScreen(currentUser: currentUser),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'stats screen',
      fileName: 'stats.png',
    );
  });

  testWidgets('captures the achievements screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: achievementsOverrides,
      child: const AchievementsScreen(currentUser: currentUser),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'achievements screen',
      fileName: 'achievements.png',
    );
  });

  testWidgets('captures the verification screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      child: const VerificationScreen(),
    );

    await tester.enterText(find.byType(TextField).first, 'dana@example.com');
    await tester.pumpAndSettle();

    await _captureAndSave(
      tester,
      scenarioName: 'verification screen',
      fileName: 'verification.png',
    );
  });

  testWidgets('captures the blocked users screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: blockedUsersOverrides,
      child: const BlockedUsersScreen(),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'blocked users screen',
      fileName: 'blocked_users.png',
    );
  });

  testWidgets('captures the notifications screen', (WidgetTester tester) async {
    final preferences = await _preferencesWithTheme(
      AppThemeModePreference.light,
    );

    await _pumpSignedInVisualScreen(
      tester,
      preferences: preferences,
      overrides: notificationsOverrides,
      child: const NotificationsScreen(),
    );

    await _captureAndSave(
      tester,
      scenarioName: 'notifications screen',
      fileName: 'notifications.png',
    );
  });
}

const _goldenRootKey = ValueKey<String>('visual-review-root');

Future<SharedPreferences> _preferencesWithTheme(
  AppThemeModePreference themeMode,
) async {
  SharedPreferences.setMockInitialValues({
    AppPreferencesStore.storageKey: jsonEncode(
      AppPreferences(themeMode: themeMode).toJson(),
    ),
  });

  return SharedPreferences.getInstance();
}

Future<void> _captureAndSave(
  WidgetTester tester, {
  required String scenarioName,
  required String fileName,
}) async {
  final GoldenFileComparator comparator = goldenFileComparator;
  if (comparator is ScreenshotWriter) {
    comparator.registerScenario(fileName: fileName, scenarioName: scenarioName);
  }

  await expectLater(
    find.byKey(_goldenRootKey),
    matchesGoldenFile('screenshots/$fileName'),
  );
}

Future<void> _pumpVisualHarness(
  WidgetTester tester, {
  required Widget child,
}) async {
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.binding.setSurfaceSize(const Size(412, 915));

  await tester.pumpWidget(RepaintBoundary(key: _goldenRootKey, child: child));

  await tester.pumpAndSettle();
}

Future<void> _pumpSignedInShell(
  WidgetTester tester, {
  required SharedPreferences preferences,
}) async {
  await _pumpVisualHarness(
    tester,
    child: ProviderScope(
      overrides: signedInShellOverrides(preferences),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        home: SignedInShell(currentUser: currentUser),
      ),
    ),
  );
}

Future<void> _pumpSignedInVisualScreen(
  WidgetTester tester, {
  required SharedPreferences preferences,
  required Widget child,
  List overrides = const <dynamic>[],
}) async {
  await _pumpVisualHarness(
    tester,
    child: ProviderScope(
      overrides: [
        ...baseSignedInOverrides(preferences),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.light,
        home: child,
      ),
    ),
  );
}
```

- [x] **Step 3: Run the full screenshot test to verify 17/17 pass**

Run: `flutter test test/visual_inspection/screenshot_test.dart`
Expected: 17 tests, 17 passing, 0 failing.

- [x] **Step 4: Inspect the new screenshots in `build/visual_review/latest/`**

The screenshots should now show:
- **Discover**: 5 browse candidates
- **Matches**: 5 match cards
- **Chats**: 5 conversations
- **Conversation thread**: 12 messages across 2 days
- **Standouts**: 5 cards
- **Pending likers**: 5 rows
- **Blocked users**: 4 rows
- **Notifications**: 8 items
- **Stats**: 8 stat items
- **Achievements**: 5 achievements

---

## Task 3: Full verification and docs update

**Files:**
- Modify: `docs/visual-review-workflow.md` (add fixture section)

- [x] **Step 1: Run the full test suite**

Run: `flutter test`
Expected: All tests pass (163 tests in the current workspace).

- [x] **Step 2: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues found.

- [x] **Step 3: Add fixture documentation to `docs/visual-review-workflow.md`**

Add a brief section after the existing content describing the new fixture structure:

```markdown
## Visual fixture layer

Screenshot data is defined in `test/visual_inspection/fixtures/`:

- `visual_fixture_catalog.dart` — canonical rich test entities (users, candidates, matches, conversations, messages, etc.)
- `visual_fixture_builders.dart` — lightweight builder functions for creating DTO variants
- `visual_scenarios.dart` — named scenario bundles consumed by screenshot tests via provider overrides

When adding a new screenshot scenario, add the data to the catalog and create a scenario getter in the scenarios file. The screenshot test should consume the scenario, not define raw data inline.

See `docs/superpowers/plans/2026-04-23-visual-review-fixtures.md` for the full design.```

- [ ] **Step 4: Commit all changes**

```bash
git add test/visual_inspection/fixtures/ test/visual_inspection/screenshot_test.dart docs/visual-review-workflow.md
git commit -m "feat: add visual fixture layer with rich data for screenshot density"
```
