import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:diary_garden/core/config/api_config.dart';
import 'package:diary_garden/data/models/auth_session.dart';

class AuthApiException implements Exception {
  const AuthApiException(this.message);
  final String message;

  @override
  String toString() => 'AuthApiException: $message';
}

class AuthApiClient {
  AuthApiClient({http.Client? httpClient, String? baseUrl})
      : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _httpClient;
  final String _baseUrl;
  static const _defaultTimeout = Duration(seconds: 15);

  Future<AuthSession> register({
    required String username,
    required String password,
    required String displayName,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/register');
    final response = await _httpClient
        .post(
          uri,
          headers: _jsonHeaders(),
          body: jsonEncode({
            'username': username,
            'password': password,
            'displayName': displayName,
          }),
        )
        .timeout(_defaultTimeout);
    final decoded = _decodeResponse(response);
    final data = _expectMap(decoded['data']);
    return AuthSession.fromJson(data);
  }

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/auth/login');
    final response = await _httpClient
        .post(
          uri,
          headers: _jsonHeaders(),
          body: jsonEncode({
            'username': username,
            'password': password,
          }),
        )
        .timeout(_defaultTimeout);
    final decoded = _decodeResponse(response);
    final data = _expectMap(decoded['data']);
    return AuthSession.fromJson(data);
  }

  Future<AuthSession> verifyToken(String token) async {
    final uri = Uri.parse('$_baseUrl/api/auth/verify');
    final response = await _httpClient
        .post(
          uri,
          headers: _authHeaders(token),
        )
        .timeout(_defaultTimeout);
    final decoded = _decodeResponse(response);
    final data = _expectMap(decoded['data']);
    return AuthSession.fromJson(data, fallbackToken: token);
  }

  Future<AuthSession> fetchCurrentUser(String token) async {
    final uri = Uri.parse('$_baseUrl/api/auth/user');
    final response = await _httpClient
        .get(
          uri,
          headers: _authHeaders(token),
        )
        .timeout(_defaultTimeout);
    final decoded = _decodeResponse(response);
    final data = _expectMap(decoded['data']);
    return AuthSession.fromJson(data, fallbackToken: token);
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw AuthApiException('빈 응답을 받았습니다. (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final success = decoded['success'];
    if (response.statusCode >= 400 || success == false) {
      final message = decoded['message']?.toString() ?? '요청이 실패했습니다.';
      throw AuthApiException(message);
    }
    return decoded;
  }

  Map<String, String> _jsonHeaders() => {'Content-Type': 'application/json'};

  Map<String, String> _authHeaders(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _expectMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const AuthApiException('응답 형식이 올바르지 않습니다.');
  }
}
