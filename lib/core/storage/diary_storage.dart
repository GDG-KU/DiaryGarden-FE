import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:diary_garden/data/models/remote_diary_entry.dart';

/// 로컬 캐시를 활용한 일기 저장소.
/// - 작성된 날짜 목록을 SharedPreferences에 저장
/// - 마지막 동기화 시간을 저장하여 증분 동기화 지원
/// - 오프라인에서도 하루 1개 제한 체크 가능
class DiaryStorage {
  static const _writtenDatesKey = 'diary_written_dates';
  static const _lastSyncKey = 'diary_last_sync';
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  const DiaryStorage._();

  /// 특정 날짜에 이미 일기가 작성되었는지 확인
  static Future<bool> hasDiaryForDate(DateTime date) async {
    final dates = await _getWrittenDates();
    final dateStr = _dateFormat.format(date);
    return dates.contains(dateStr);
  }

  /// 작성된 날짜 추가 (일기 작성 성공 시 호출)
  static Future<void> addWrittenDate(DateTime date) async {
    final dates = await _getWrittenDates();
    final dateStr = _dateFormat.format(date);
    if (!dates.contains(dateStr)) {
      dates.add(dateStr);
      await _saveWrittenDates(dates);
    }
  }

  /// 마지막 동기화 시간 조회
  static Future<DateTime?> getLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_lastSyncKey);
    if (timestamp == null || timestamp.isEmpty) return null;
    return DateTime.tryParse(timestamp);
  }

  /// 서버에서 받은 일기 목록으로 로컬 캐시 업데이트
  /// [entries]: 서버에서 받은 일기 목록
  /// [fullSync]: true면 전체 동기화 (기존 캐시 대체), false면 증분 동기화 (추가만)
  static Future<void> updateFromEntries(
    List<RemoteDiaryEntry> entries, {
    bool fullSync = false,
  }) async {
    Set<String> dates;
    if (fullSync) {
      dates = {};
    } else {
      dates = (await _getWrittenDates()).toSet();
    }

    for (final entry in entries) {
      final dateStr = _dateFormat.format(entry.writtenDate);
      dates.add(dateStr);
    }

    await _saveWrittenDates(dates.toList());
    await _updateLastSyncTimestamp();
  }

  /// 로컬 캐시 초기화 (로그아웃 시 호출)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_writtenDatesKey);
    await prefs.remove(_lastSyncKey);
  }

  /// 작성된 날짜 목록 조회
  static Future<List<String>> _getWrittenDates() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_writtenDatesKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // JSON 파싱 실패 시 빈 목록 반환
    }
    return [];
  }

  /// 작성된 날짜 목록 저장
  static Future<void> _saveWrittenDates(List<String> dates) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_writtenDatesKey, jsonEncode(dates));
  }

  /// 마지막 동기화 시간 업데이트
  static Future<void> _updateLastSyncTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastSyncKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
