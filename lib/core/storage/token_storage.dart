import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  const TokenStorage._();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> readToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static Future<void> saveUser({
    required String username,
    required String displayName,
  }) async {
    try {
      final encoded = jsonEncode({
        'username': username,
        'displayName': displayName,
      });
      await _storage.write(key: _userKey, value: encoded);
    } catch (e) {
      // Log error or rethrow if needed
      throw Exception('Failed to save user data: $e');
    }
  }

  static Future<Map<String, String>?> readUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null || userJson.isEmpty) return null;
    try {
      final decoded = jsonDecode(userJson) as Map<String, dynamic>;
      return {
        'username': decoded['username']?.toString() ?? '',
        'displayName': decoded['displayName']?.toString() ?? '',
      };
    } catch (e) {
      print('Failed to decode user data: $e');
      return null;
    }
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
