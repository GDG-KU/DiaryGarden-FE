import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  const ApiConfig._();

  static String get baseUrl => dotenv.env['DIARY_API_BASE_URL'] ?? '';

  static String get authToken => dotenv.env['DIARY_API_TOKEN'] ?? '';

  static String? get maybeAuthToken => authToken.isEmpty ? null : authToken;
}
