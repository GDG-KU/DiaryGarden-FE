import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:diary_garden/core/config/api_config.dart';
import 'package:diary_garden/data/models/remote_diary_entry.dart';

class DiaryApiException implements Exception {
  const DiaryApiException(this.message);
  final String message;

  @override
  String toString() => 'DiaryApiException: $message';
}

class DiaryApiClient {
  DiaryApiClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  Future<RemoteDiaryEntry> createDiary({
    required String authToken,
    required String treeId,
    required String content,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/diaries');
    final response = await _httpClient.post(
      uri,
      headers: _headers(token: authToken),
      body: jsonEncode({
        'treeId': treeId,
        'content': content,
      }),
    );
    return _parseDiary(response);
  }

  Future<RemoteDiaryEntry> fetchDiary({
    required String id,
    String? authToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/diaries/$id');
    final response = await _httpClient.get(
      uri,
      headers: _headers(token: authToken),
    );
    return _parseDiary(response);
  }

  Future<List<RemoteDiaryEntry>> fetchDiaries({
    required String authToken,
    int limit = 0,
    String? lastDocId,
  }) async {
    final query = <String, String>{};
    if (limit > 0) {
      query['limit'] = '$limit';
    }
    if (lastDocId != null && lastDocId.isNotEmpty) {
      query['lastDocId'] = lastDocId;
    }

    final uri = Uri.parse('$_baseUrl/api/diaries').replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final response = await _httpClient.get(
      uri,
      headers: _headers(token: authToken),
    );
    final decoded = _decodeResponse(response);
    final data = decoded['data'];
    if (data is List) {
      return data
          .map((e) {
            if (e is Map<String, dynamic>) {
              return RemoteDiaryEntry.fromJson(e);
            }
            if (e is Map) {
              return RemoteDiaryEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              );
            }
            throw const DiaryApiException('알 수 없는 일기 데이터 형식입니다.');
          })
          .toList();
    }
    throw const DiaryApiException('일기 목록을 불러올 수 없습니다.');
  }

  RemoteDiaryEntry _parseDiary(http.Response response) {
    final decoded = _decodeResponse(response);
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return RemoteDiaryEntry.fromJson(data);
    }
    if (data is Map) {
      return RemoteDiaryEntry.fromJson(Map<String, dynamic>.from(data));
    }
    throw const DiaryApiException('일기 정보를 해석할 수 없습니다.');
  }

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw DiaryApiException('빈 응답을 받았습니다. (${response.statusCode})');
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final success = decoded['success'];
    if (response.statusCode >= 400 || success == false) {
      final message = decoded['message']?.toString() ?? '요청이 실패했습니다.';
      throw DiaryApiException(message);
    }
    return decoded;
  }
}
