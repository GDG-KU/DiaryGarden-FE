import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 오프라인에서 작성된 일기를 로컬에 저장하고 관리하는 클래스.
/// 네트워크 복구 시 서버로 전송될 때까지 보관합니다.
class PendingDiaryStorage {
  static const _pendingDiariesKey = 'pending_diaries';

  const PendingDiaryStorage._();

  /// 대기 중인 일기 추가
  static Future<void> addPendingDiary(PendingDiary diary) async {
    final diaries = await getPendingDiaries();
    diaries.add(diary);
    await _savePendingDiaries(diaries);
    debugPrint(
      'PendingDiaryStorage: Added pending diary for ${diary.writtenDate}',
    );
  }

  /// 대기 중인 일기 목록 조회
  static Future<List<PendingDiary>> getPendingDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_pendingDiariesKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];

    try {
      final decoded = jsonDecode(jsonStr) as List;
      return decoded
          .map((e) => PendingDiary.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('PendingDiaryStorage: Failed to parse pending diaries: $e');
      return [];
    }
  }

  /// 대기 중인 일기가 있는지 확인
  static Future<bool> hasPendingDiaries() async {
    final diaries = await getPendingDiaries();
    return diaries.isNotEmpty;
  }

  /// 대기 중인 일기 개수 조회
  static Future<int> getPendingCount() async {
    final diaries = await getPendingDiaries();
    return diaries.length;
  }

  /// 특정 날짜에 대기 중인 일기가 있는지 확인
  static Future<bool> hasPendingForDate(DateTime date) async {
    final diaries = await getPendingDiaries();
    final dateStr = _formatDate(date);
    return diaries.any((d) => _formatDate(d.writtenDate) == dateStr);
  }

  /// 동기화 성공한 일기 제거
  static Future<void> removePendingDiary(String localId) async {
    final diaries = await getPendingDiaries();
    diaries.removeWhere((d) => d.localId == localId);
    await _savePendingDiaries(diaries);
    debugPrint('PendingDiaryStorage: Removed pending diary $localId');
  }

  /// 모든 대기 중인 일기 삭제 (로그아웃 시)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingDiariesKey);
    debugPrint('PendingDiaryStorage: Cleared all pending diaries');
  }

  static Future<void> _savePendingDiaries(List<PendingDiary> diaries) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(diaries.map((d) => d.toJson()).toList());
    await prefs.setString(_pendingDiariesKey, jsonStr);
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 대기 중인 일기 모델
class PendingDiary {
  PendingDiary({
    required this.localId,
    required this.title,
    required this.content,
    required this.writtenDate,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  factory PendingDiary.fromJson(Map<String, dynamic> json) {
    return PendingDiary(
      localId: json['localId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      writtenDate: DateTime.parse(json['writtenDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
    );
  }

  final String localId;
  final String title;
  final String content;
  final DateTime writtenDate;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  Map<String, dynamic> toJson() => {
    'localId': localId,
    'title': title,
    'content': content,
    'writtenDate': writtenDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
    'lastError': lastError,
  };

  PendingDiary copyWith({int? retryCount, String? lastError}) {
    return PendingDiary(
      localId: localId,
      title: title,
      content: content,
      writtenDate: writtenDate,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }
}
