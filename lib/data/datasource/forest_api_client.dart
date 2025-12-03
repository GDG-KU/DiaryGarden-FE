import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:diary_garden/core/config/api_config.dart';
import 'package:diary_garden/data/models/tree_position.dart';

class ForestApiException implements Exception {
  const ForestApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ForestApiException: $message (status: $statusCode)';
}

class ForestApiClient {
  ForestApiClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      _baseUrl = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _httpClient;
  final String _baseUrl;

  /// Fetch all tree positions for a specific garden view
  /// 
  /// [gardenLevel] examples: "2025-12" (monthly), "2025" (yearly)
  Future<List<TreePosition>> fetchTreePositions({
    required String authToken,
    required String gardenLevel,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/gardens/$gardenLevel/trees/positions');

    final response = await _httpClient.get(
      uri,
      headers: _headers(token: authToken),
    );
    final decoded = _decodeResponse(response);
    final data = decoded['data'];
    if (data is List) {
      return data.map((e) {
        if (e is Map<String, dynamic>) {
          return TreePosition.fromJson(e);
        }
        if (e is Map) {
          return TreePosition.fromJson(Map<String, dynamic>.from(e as Map));
        }
        throw const ForestApiException('알 수 없는 Tree Position 데이터 형식입니다.');
      }).toList();
    }
    throw const ForestApiException('Tree Position 목록을 불러올 수 없습니다.');
  }

  /// Update position for a specific tree in a garden
  /// 
  /// [gardenLevel] examples: "2025-12" (monthly), "2025" (yearly)
  /// [positionX] and [positionY] are normalized coordinates (0.0 to 1.0)
  Future<TreePosition> updateTreePosition({
    required String authToken,
    required String gardenLevel,
    required String treeId,
    required double positionX,
    required double positionY,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/api/gardens/$gardenLevel/trees/positions/$treeId',
    );

    final response = await _httpClient.put(
      uri,
      headers: _headers(token: authToken),
      body: jsonEncode({
        'positionX': positionX,
        'positionY': positionY,
      }),
    );
    return _parseTreePosition(response);
  }

  TreePosition _parseTreePosition(http.Response response) {
    final decoded = _decodeResponse(response);
    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return TreePosition.fromJson(data);
    }
    if (data is Map) {
      return TreePosition.fromJson(Map<String, dynamic>.from(data));
    }
    throw const ForestApiException('Tree Position 정보를 해석할 수 없습니다.');
  }

  Map<String, String> _headers({String? token}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      throw ForestApiException(
        '빈 응답을 받았습니다. (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final success = decoded['success'];
    if (response.statusCode >= 400 || success == false) {
      final message = decoded['message']?.toString() ?? '요청이 실패했습니다.';
      throw ForestApiException(message, statusCode: response.statusCode);
    }
    return decoded;
  }
}
