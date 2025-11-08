import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'data/local_diary_entries.dart';
import 'models/diary_entry.dart';
import 'theme/app_colors.dart';
import 'utils/emotion_helper.dart';

class DiaryReadPage extends StatelessWidget {
  DiaryReadPage({super.key, List<DiaryEntry>? entries, this.onDelete})
    : entries = entries ?? localDiaryEntries;

  final List<DiaryEntry> entries;
  final ValueChanged<String>? onDelete;

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
      body: entries.isEmpty ? _buildEmptyState() : _buildDiaryList(context),
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
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final entry = entries[index];
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
      builder: (dialogContext) {
        final sortedScores =
            entry.emotionScores.entries.where((e) => e.value > 0.05).toList()
              ..sort((a, b) => b.value.compareTo(a.value));

        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            entry.title,
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
                      _formatDate(entry.date),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Text(
                  entry.content,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  '감정 분석',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
              ],
            ),
          ),
          actions: [
            if (onDelete != null)
              TextButton(
                onPressed: () {
                  onDelete?.call(entry.id);
                  Navigator.of(dialogContext).pop();
                },
                child: const Text(
                  '삭제',
                  style: TextStyle(color: AppColors.leafCoral),
                ),
              ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
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
      },
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
