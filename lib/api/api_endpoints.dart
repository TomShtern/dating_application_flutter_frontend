class ApiEndpoints {
  const ApiEndpoints._();

  static const String health = '/api/health';
  static const String users = '/api/users';
  static const String locationCountries = '/api/location/countries';
  static const String locationCities = '/api/location/cities';
  static const String resolveLocation = '/api/location/resolve';

  static String userDetail(String userId) => '/api/users/$userId';

  static String updateProfile(String userId) => '/api/users/$userId/profile';

  static String profileEditSnapshot(String userId) =>
      '/api/users/$userId/profile-edit-snapshot';

  static String profilePresentationContext(String viewerId, String targetId) =>
      '/api/users/$viewerId/presentation-context/$targetId';

  static String blockUser(String userId, String targetId) =>
      '/api/users/$userId/block/$targetId';

  static String unblockUser(String userId, String targetId) =>
      '/api/users/$userId/block/$targetId';

  static String reportUser(String userId, String targetId) =>
      '/api/users/$userId/report/$targetId';

  static String unmatchUser(String userId, String targetId) =>
      '/api/users/$userId/relationships/$targetId/unmatch';

  static String browse(String userId) => '/api/users/$userId/browse';

  static String like(String userId, String targetId) =>
      '/api/users/$userId/like/$targetId';

  static String pass(String userId, String targetId) =>
      '/api/users/$userId/pass/$targetId';

  static String undo(String userId) => '/api/users/$userId/undo';

  static String matches(String userId) => '/api/users/$userId/matches';

  static String matchQuality(String userId, String matchId) =>
      '/api/users/$userId/match-quality/$matchId';

  static String conversations(String userId) =>
      '/api/users/$userId/conversations';

  static String stats(String userId) => '/api/users/$userId/stats';

  static String achievements(String userId) =>
      '/api/users/$userId/achievements';

  static String pendingLikers(String userId) =>
      '/api/users/$userId/pending-likers';

  static String standouts(String userId) => '/api/users/$userId/standouts';

  static String notifications(String userId) =>
      '/api/users/$userId/notifications';

  static String markAllNotificationsRead(String userId) =>
      '/api/users/$userId/notifications/read-all';

  static String markNotificationRead(String userId, String notificationId) =>
      '/api/users/$userId/notifications/$notificationId/read';

  static String blockedUsers(String userId) =>
      '/api/users/$userId/blocked-users';

  static String startVerification(String userId) =>
      '/api/users/$userId/verification/start';

  static String confirmVerification(String userId) =>
      '/api/users/$userId/verification/confirm';

  static String messages(String conversationId) =>
      '/api/conversations/$conversationId/messages';
}
