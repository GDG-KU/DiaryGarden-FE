import 'package:flutter/material.dart';

import 'diary_read_page.dart';
import 'diary_write_page.dart';
import 'theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Diary Garden Palette')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '컬러 베이스',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '다람쥐 헌 쳇바퀴에 타고파.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: const [
                  _SwatchSample(
                    'Background',
                    AppColors.background,
                    AppColors.textPrimary,
                  ),
                  _SwatchSample(
                    'Trunk',
                    AppColors.trunk,
                    AppColors.textOnTrunk,
                  ),
                  _SwatchSample(
                    'Leaf · Green',
                    AppColors.leafGreen,
                    AppColors.textOnLeaf,
                  ),
                  _SwatchSample(
                    'Leaf · Blue',
                    AppColors.leafBlue,
                    AppColors.textOnLeaf,
                  ),
                  _SwatchSample(
                    'Leaf · Coral',
                    AppColors.leafCoral,
                    AppColors.textOnLeaf,
                  ),
                  _SwatchSample(
                    'Leaf · Yellow',
                    AppColors.leafYellow,
                    AppColors.textOnLeaf,
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                '텍스트 색상 가이드',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Primary Text',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '다람쥐 헌 쳇바퀴에 타고파.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Secondary Text',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '다람쥐 헌 쳇바퀴에 타고파.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('일기 쓰기'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.leafGreen,
                        foregroundColor: AppColors.textOnLeaf,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DiaryWritePage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.menu_book_rounded),
                      label: const Text('일기 읽기'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.trunk,
                        side: BorderSide(
                          color: AppColors.trunk.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DiaryReadPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwatchSample extends StatelessWidget {
  const _SwatchSample(this.label, this.color, this.labelColor);

  final String label;
  final Color color;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final hex = _hexWithoutAlpha(color);

    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: labelColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '#',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '#$hex',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: labelColor.withValues(alpha: 0.9),
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  String _hexWithoutAlpha(Color color) {
    int to8Bit(double channel) => ((channel * 255.0).round()) & 0xff;

    final red = to8Bit(color.r).toRadixString(16).padLeft(2, '0');
    final green = to8Bit(color.g).toRadixString(16).padLeft(2, '0');
    final blue = to8Bit(color.b).toRadixString(16).padLeft(2, '0');
    return '$red$green$blue'.toUpperCase();
  }
}
