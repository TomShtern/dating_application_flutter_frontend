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

UserSummary buildUserSummary({
  String id = '00000000-0000-0000-0000-000000000000',
  String name = 'Test User',
  int age = 25,
  String state = 'ACTIVE',
}) {
  return UserSummary(id: id, name: name, age: age, state: state);
}

BrowseCandidate buildBrowseCandidate({
  String id = '00000000-0000-0000-0000-000000000000',
  String name = 'Test Candidate',
  int age = 25,
  String state = 'ACTIVE',
}) {
  return BrowseCandidate(id: id, name: name, age: age, state: state);
}

UserDetail buildUserDetail({
  String id = '00000000-0000-0000-0000-000000000000',
  String name = 'Test User',
  int age = 25,
  String bio = 'A short bio for testing.',
  String gender = 'FEMALE',
  List<String> interestedIn = const ['MALE'],
  String approximateLocation = 'Tel Aviv',
  int maxDistanceKm = 50,
  List<String> photoUrls = const <String>[],
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
    likedAt: likedAt ?? DateTime.parse('2026-04-20T12:00:00Z'),
  );
}

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

NotificationItem buildNotification({
  String id = 'notif-default',
  String type = 'SYSTEM',
  String title = 'Test notification',
  String message = 'Test notification body.',
  DateTime? createdAt,
  bool isRead = false,
  Map<String, String> data = const <String, String>{},
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

UserStatItem buildStatItem({String label = 'Test stat', String value = '0'}) {
  return UserStatItem(label: label, value: value);
}

AchievementSummary buildAchievement({
  String title = 'Test achievement',
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
