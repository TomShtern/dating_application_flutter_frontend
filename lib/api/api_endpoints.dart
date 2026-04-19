class ApiEndpoints {
  const ApiEndpoints._();

  static const String health = '/api/health';
  static const String users = '/api/users';

  static String userDetail(String userId) => '/api/users/$userId';

  static String updateProfile(String userId) => '/api/users/$userId/profile';

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

  static String conversations(String userId) =>
      '/api/users/$userId/conversations';

  static String stats(String userId) => '/api/users/$userId/stats';

  static String achievements(String userId) =>
      '/api/users/$userId/achievements';

  static String messages(String conversationId) =>
      '/api/conversations/$conversationId/messages';
}
