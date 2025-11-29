class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'DIARY_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String authToken = String.fromEnvironment('DIARY_API_TOKEN');

  static String? get maybeAuthToken => authToken.isEmpty ? null : authToken;
}
