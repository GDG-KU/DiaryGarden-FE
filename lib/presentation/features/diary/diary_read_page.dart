import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/config/api_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../../data/datasource/diary_api_client.dart';
import '../../../data/datasource/local_diary_entries.dart';
import '../../../data/models/diary_entry.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/emotion_helper.dart';

class DiaryReadPage extends StatefulWidget {
  DiaryReadPage({super.key, List<DiaryEntry>? entries, this.onDelete, this.onEntryUpdated})
    : entries = entries ?? localDiaryEntries;

  final List<DiaryEntry> entries;
  final ValueChanged<String>? onDelete;
  final ValueChanged<DiaryEntry>? onEntryUpdated;

  @override
  State<DiaryReadPage> createState() => _DiaryReadPageState();
}

class _DiaryReadPageState extends State<DiaryReadPage> {
  late List<DiaryEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List.from(widget.entries);
  }

  void _updateEntry(DiaryEntry updatedEntry) {
    setState(() {
      final index = _entries.indexWhere((e) => e.id == updatedEntry.id);
      if (index != -1) {
        _entries[index] = updatedEntry;
      }
    });
    widget.onEntryUpdated?.call(updatedEntry);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: '뒤로가기',
        ),
        title: const Text(
          '일기 읽기',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.trunk.withValues(alpha: 0.08),
      ),
      body: _entries.isEmpty ? _buildEmptyState() : _buildDiaryList(context),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 48,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 작성된 일기가 없습니다',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              '첫 일기를 작성해보세요!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryList(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final topEmotions = _getTopEmotions(entry);

        return Card(
          color: Colors.white,
          elevation: 1,
          shadowColor: AppColors.trunk.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showDiaryDialog(context, entry),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                entry.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _EmotionChip(emotion: entry.dominantEmotion),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.content.replaceAll('\n', ' '),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatDate(entry.date),
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: topEmotions
                        .map(
                          (emotionEntry) => Container(
                            width: 6,
                            height: 48,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: emotionColor(emotionEntry.key),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDiaryDialog(BuildContext context, DiaryEntry entry) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _DiaryDetailDialog(
        entry: entry,
        onDelete: widget.onDelete,
        onEntryUpdated: (updatedEntry) {
          _updateEntry(updatedEntry);
          // Dialog를 닫지 않고 업데이트만 함
        },
      ),
    );
  }

  List<MapEntry<String, double>> _getTopEmotions(DiaryEntry entry) {
    final sorted = entry.emotionScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.where((e) => e.value > 0.1).take(3).toList();
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(date);
  }
}

/// 일기 상세 다이얼로그 - StatefulWidget으로 재분석 상태 관리
class _DiaryDetailDialog extends StatefulWidget {
  const _DiaryDetailDialog({
    required this.entry,
    this.onDelete,
    this.onEntryUpdated,
  });

  final DiaryEntry entry;
  final ValueChanged<String>? onDelete;
  final ValueChanged<DiaryEntry>? onEntryUpdated;

  @override
  State<_DiaryDetailDialog> createState() => _DiaryDetailDialogState();
}

class _DiaryDetailDialogState extends State<_DiaryDetailDialog> {
  final DiaryApiClient _diaryApiClient = DiaryApiClient();
  
  late DiaryEntry _currentEntry;
  bool _isAnalyzing = false;
  String? _analyzeError;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    
    // 감정 분석이 비어있으면 자동으로 재분석 요청
    if (_needsReanalysis()) {
      _triggerReanalysis();
    }
  }

  /// 재분석이 필요한지 확인
  /// aiComment가 없으면 감정 분석이 안 된 것으로 판단
  bool _needsReanalysis() {
    return _currentEntry.aiComment?.isEmpty ?? true;
  }

  /// 비동기로 감정 분석 재요청
  /// 분석 완료 후 해당 일기만 다시 fetch하여 DB 정합성 확보
  Future<void> _triggerReanalysis() async {
    if (_isAnalyzing) return;
    
    setState(() {
      _isAnalyzing = true;
      _analyzeError = null;
    });

    try {
      final token = await TokenStorage.readToken() ?? ApiConfig.maybeAuthToken;
      if (token == null) {
        throw Exception('인증 토큰이 없습니다.');
      }

      debugPrint('🔍 감정 분석 재요청 중... (id: ${_currentEntry.id})');
      
      // 1. 감정 분석 요청 (서버에서 분석 후 DB 업데이트)
      await _diaryApiClient.analyzeDiary(
        id: _currentEntry.id,
        authToken: token,
      );

      debugPrint('✅ 감정 분석 완료, DB에서 다시 조회 중...');
      
      // 2. 분석 완료 후 해당 일기만 다시 fetch (DB 정합성 확보)
      final freshEntry = await _diaryApiClient.fetchDiary(
        id: _currentEntry.id,
        authToken: token,
      );

      debugPrint('📥 일기 다시 조회 완료: ${freshEntry.dominantEmotion}');
      debugPrint('   Scores: ${freshEntry.emotionScores}');
      debugPrint('   AI Comment: ${freshEntry.aiComment}');

      if (mounted) {
        final updatedEntry = DiaryEntry(
          id: freshEntry.id,
          title: freshEntry.title.isNotEmpty ? freshEntry.title : _currentEntry.title,
          content: freshEntry.content.isNotEmpty ? freshEntry.content : _currentEntry.content,
          date: freshEntry.writtenDate,
          emotionScores: freshEntry.emotionScores,
          dominantEmotion: freshEntry.dominantEmotion,
          aiComment: freshEntry.aiComment,
        );

        setState(() {
          _currentEntry = updatedEntry;
          _isAnalyzing = false;
        });

        widget.onEntryUpdated?.call(updatedEntry);
      }
    } catch (e) {
      debugPrint('❌ 감정 분석 실패: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _analyzeError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedScores = _currentEntry.emotionScores.entries
        .where((e) => e.value > 0.1 && e.key != 'default')
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        _currentEntry.title,
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textSecondary.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_currentEntry.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              _currentEntry.content,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const Divider(height: 32),
            
            // 감정 분석 섹션 헤더
            Row(
              children: [
                const Text(
                  '감정 분석',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                // 재분석 버튼 (분석이 필요하거나 에러가 있을 때만 표시)
                if (!_isAnalyzing && (_needsReanalysis() || _analyzeError != null))
                  IconButton(
                    onPressed: _triggerReanalysis,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: '감정 재분석',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: AppColors.textSecondary,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 분석 중 상태
            if (_isAnalyzing)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.leafGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.leafGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.leafGreen,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'AI가 감정을 분석하고 있어요...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            // 분석 실패 상태
            else if (_analyzeError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.leafCoral.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.leafCoral.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.error_outline, 
                            color: AppColors.leafCoral, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            '감정 분석에 실패했습니다',
                            style: TextStyle(
                              color: AppColors.leafCoral,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _triggerReanalysis,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('다시 시도'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.leafCoral,
                          side: BorderSide(color: AppColors.leafCoral.withValues(alpha: 0.5)),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            // 감정 분석 결과가 비어있는 경우
            else if (sortedScores.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.psychology_outlined, 
                        color: AppColors.textSecondary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '아직 분석된 감정이 없습니다',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            // 감정 분석 결과 표시
            else
              ...sortedScores.map((scoreEntry) {
                final emotion = scoreEntry.key;
                final value = scoreEntry.value;
                final color = emotionColor(emotion);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  emotionLabel(emotion),
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${(value * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.8,
                                    ),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: value,
                                backgroundColor: color.withValues(alpha: 0.2),
                                color: color,
                                minHeight: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              
            // AI 한줄 코멘트 섹션
            if (_currentEntry.aiComment != null && _currentEntry.aiComment!.isNotEmpty) ...[
              const Divider(height: 32),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.leafGreen.withValues(alpha: 0.8),
                          AppColors.leafYellow.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'AI 한줄 코멘트',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.leafGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.leafGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  _currentEntry.aiComment!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (widget.onDelete != null)
          TextButton(
            onPressed: () {
              widget.onDelete?.call(_currentEntry.id);
              Navigator.of(context).pop();
            },
            child: const Text(
              '삭제',
              style: TextStyle(color: AppColors.leafCoral),
            ),
          ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.trunk,
            foregroundColor: AppColors.textOnTrunk,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}

class _EmotionChip extends StatelessWidget {
  const _EmotionChip({required this.emotion});

  final String emotion;

  @override
  Widget build(BuildContext context) {
    final background = emotionColor(emotion);
    final label = emotionLabel(emotion);
    final textColor = getTextColorForEmotion(emotion);

    return Chip(
      label: Text(label),
      backgroundColor: background.withValues(alpha: 0.9),
      labelStyle: TextStyle(
        color: textColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
