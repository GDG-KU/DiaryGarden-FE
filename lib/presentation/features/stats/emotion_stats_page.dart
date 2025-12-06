import 'package:flutter/material.dart';
import '../../../core/config/api_config.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/emotion_helper.dart';
import '../../../data/datasource/diary_api_client.dart';
import 'dart:math' as math;

class EmotionStatsPage extends StatefulWidget {
  const EmotionStatsPage({super.key});

  @override
  State<EmotionStatsPage> createState() => _EmotionStatsPageState();
}

class _EmotionStatsPageState extends State<EmotionStatsPage> {
  final DiaryApiClient _diaryApiClient = DiaryApiClient();
  
  bool _loading = true;
  String? _error;
  DateTime _selectedMonth = DateTime.now();
  Map<String, double> _emotionTotals = {};
  int _diaryCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    
    final token = await TokenStorage.readToken() ?? ApiConfig.maybeAuthToken;
    if (token == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '로그인이 필요해요';
      });
      return;
    }

    try {
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
      
      final diaries = await _diaryApiClient.fetchDiaries(
        authToken: token,
        writtenAfter: startDate,
        writtenBefore: endDate,
      );

      // Aggregate emotion scores
      final totals = <String, double>{};
      for (final diary in diaries) {
        for (final entry in diary.emotionScores.entries) {
          if (entry.key != 'default' && entry.value > 0) {
            totals[entry.key] = (totals[entry.key] ?? 0) + entry.value;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _emotionTotals = totals;
        _diaryCount = diaries.length;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ Failed to load emotion stats: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '데이터를 불러오지 못했어요';
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta, 1);
    });
    _loadStats();
  }

  List<MapEntry<String, double>> get _sortedEmotions {
    final sorted = _emotionTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted;
  }

  double get _totalScore {
    return _emotionTotals.values.fold(0.0, (sum, v) => sum + v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('감정 통계'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    // Month navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () => _changeMonth(-1),
                          ),
                          Expanded(
                            child: Text(
                              '${_selectedMonth.year}년 ${_selectedMonth.month}월',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: _diaryCount == 0
                          ? _buildEmptyState()
                          : _buildStatsContent(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.leafCoral.withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? '오류가 발생했어요',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.trunk,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 64,
            color: AppColors.textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            '이 달에 작성된 일기가 없어요',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '일기를 작성하면 감정 통계를 볼 수 있어요',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent() {
    final sortedEmotions = _sortedEmotions;
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary card
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.edit_note, color: AppColors.trunk, size: 28),
                const SizedBox(width: 12),
                Text(
                  '이번 달 일기',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_diaryCount개',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Emotion pie chart
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '감정 비율',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: _EmotionPieChart(
                    emotions: sortedEmotions,
                    total: _totalScore,
                  ),
                ),
                const SizedBox(height: 16),
                // Legend
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: sortedEmotions.map((e) {
                    final percent = (_totalScore > 0) 
                        ? (e.value / _totalScore * 100) 
                        : 0.0;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: emotionColor(e.key),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${emotionLabel(e.key)} ${percent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Top 3 emotions
        if (sortedEmotions.isNotEmpty) ...[
          const Text(
            '이번 달 감정 Top 3',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...sortedEmotions.take(3).toList().asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final emotion = entry.value;
            final percent = (_totalScore > 0) 
                ? (emotion.value / _totalScore * 100) 
                : 0.0;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _EmotionRankCard(
                rank: rank,
                emotion: emotion.key,
                percent: percent,
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _EmotionPieChart extends StatelessWidget {
  const _EmotionPieChart({
    required this.emotions,
    required this.total,
  });

  final List<MapEntry<String, double>> emotions;
  final double total;

  @override
  Widget build(BuildContext context) {
    if (emotions.isEmpty || total == 0) {
      return const Center(
        child: Text('데이터 없음'),
      );
    }

    return CustomPaint(
      size: const Size(200, 200),
      painter: _PieChartPainter(
        emotions: emotions,
        total: total,
      ),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  _PieChartPainter({
    required this.emotions,
    required this.total,
  });

  final List<MapEntry<String, double>> emotions;
  final double total;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;
    
    double startAngle = -math.pi / 2; // Start from top
    
    for (final emotion in emotions) {
      final sweepAngle = (emotion.value / total) * 2 * math.pi;
      final paint = Paint()
        ..color = emotionColor(emotion.key)
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      
      startAngle += sweepAngle;
    }

    // Draw white circle in center for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _EmotionRankCard extends StatelessWidget {
  const _EmotionRankCard({
    required this.rank,
    required this.emotion,
    required this.percent,
  });

  final int rank;
  final String emotion;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final color = emotionColor(emotion);
    final label = emotionLabel(emotion);
    
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$rank',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
