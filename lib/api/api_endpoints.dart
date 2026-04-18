class ApiEndpoints {
  const ApiEndpoints._();

  static const String health = '/api/health';
  static const String users = '/api/users';

  static String userDetail(String userId) => '/api/users/$userId';

  static String browse(String userId) => '/api/users/$userId/browse';

  static String like(String userId, String targetId) =>
      '/api/users/$userId/like/$targetId';

  static String pass(String userId, String targetId) =>
      '/api/users/$userId/pass/$targetId';

  static String matches(String userId) => '/api/users/$userId/matches';

  static String conversations(String userId) =>
      '/api/users/$userId/conversations';

  static String messages(String conversationId) =>
      '/api/conversations/$conversationId/messages';
}
