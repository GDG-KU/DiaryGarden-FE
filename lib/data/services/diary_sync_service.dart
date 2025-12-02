import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:diary_garden/core/storage/diary_storage.dart';
import 'package:diary_garden/core/storage/pending_diary_storage.dart';
import 'package:diary_garden/data/datasource/diary_api_client.dart';

/// 오프라인에서 작성된 일기를 서버와 동기화하는 서비스.
class DiarySyncService {
  DiarySyncService({required DiaryApiClient apiClient})
    : _apiClient = apiClient;

  final DiaryApiClient _apiClient;
  Completer<SyncResult>? _syncCompleter;

  /// 동기화 상태 변경 콜백
  ValueChanged<SyncStatus>? onSyncStatusChanged;

  /// 대기 중인 모든 일기를 서버로 동기화
  /// [authToken]: 인증 토큰
  /// 반환값: 동기화 결과 (성공 개수, 실패 개수)
  Future<SyncResult> syncPendingDiaries(String authToken) async {
    if (_syncCompleter != null && !_syncCompleter!.isCompleted) {
      debugPrint('DiarySyncService: Already syncing, waiting for completion...');
      return _syncCompleter!.future;
    }

    _syncCompleter = Completer<SyncResult>();

    try {
      final pendingDiaries = await PendingDiaryStorage.getPendingDiaries();
      if (pendingDiaries.isEmpty) {
        debugPrint('DiarySyncService: No pending diaries to sync');
        final result = SyncResult(successCount: 0, failCount: 0);
        _syncCompleter!.complete(result);
        return result;
      }

      onSyncStatusChanged?.call(SyncStatus.syncing);
      debugPrint(
        'DiarySyncService: Starting sync of ${pendingDiaries.length} diaries',
      );

      int successCount = 0;
      int failCount = 0;

      for (final diary in pendingDiaries) {
        try {
          debugPrint('DiarySyncService: Syncing diary ${diary.localId}...');

          await _apiClient.createDiary(
            authToken: authToken,
            title: diary.title,
            content: diary.content,
            writtenDate: diary.writtenDate,
          );

          // 성공 시 pending에서 제거하고 DiaryStorage 업데이트
          await PendingDiaryStorage.removePendingDiary(diary.localId);
          await DiaryStorage.addWrittenDate(diary.writtenDate);

          successCount++;
          debugPrint(
            'DiarySyncService: Successfully synced diary ${diary.localId}',
          );
        } catch (e) {
          failCount++;
          debugPrint(
            'DiarySyncService: Failed to sync diary ${diary.localId}: $e',
          );

          // 실패 횟수 업데이트 (나중에 재시도 로직에서 사용 가능)
          // 현재는 단순히 남겨둠
        }
      }

      final status = failCount == 0
          ? SyncStatus.success
          : (successCount > 0 ? SyncStatus.partialSuccess : SyncStatus.failed);
      onSyncStatusChanged?.call(status);

      debugPrint(
        'DiarySyncService: Sync complete - success: $successCount, fail: $failCount',
      );
      
      final result = SyncResult(successCount: successCount, failCount: failCount);
      _syncCompleter!.complete(result);
      return result;
    } catch (e) {
      // Complete failure - exception occurred before the sync loop
      debugPrint('DiarySyncService: Sync failed with exception: $e');
      onSyncStatusChanged?.call(SyncStatus.failed);
      
      final result = SyncResult(successCount: 0, failCount: 0, error: e.toString());
      _syncCompleter!.complete(result);
      return result;
    }
  }

  /// 단일 일기 동기화 시도
  Future<bool> trySyncSingleDiary(String authToken, PendingDiary diary) async {
    try {
      await _apiClient.createDiary(
        authToken: authToken,
        title: diary.title,
        content: diary.content,
        writtenDate: diary.writtenDate,
      );

      await PendingDiaryStorage.removePendingDiary(diary.localId);
      await DiaryStorage.addWrittenDate(diary.writtenDate);

      return true;
    } catch (e) {
      debugPrint('DiarySyncService: Failed to sync single diary: $e');
      return false;
    }
  }
}

/// 동기화 결과
class SyncResult {
  const SyncResult({
    required this.successCount,
    required this.failCount,
    bool? skipped,
    this.error,
  }) : skipped = skipped ?? false;

  final int successCount;
  final int failCount;
  final bool skipped;
  final String? error;

  bool get hasFailures => failCount > 0;
  bool get allSuccess => skipped == false && failCount == 0 && successCount > 0;
  int get totalCount => successCount + failCount;
}

/// 동기화 상태
enum SyncStatus { idle, syncing, success, partialSuccess, failed }
