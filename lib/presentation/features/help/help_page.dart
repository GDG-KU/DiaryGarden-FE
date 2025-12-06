import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/emotion_helper.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('도움말'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // App guide section
          _HelpSection(
            title: '앱 사용법',
            icon: Icons.auto_stories_rounded,
            children: [
              _HelpItem(
                title: '일기 작성하기',
                content: '메인 화면 하단의 연필 버튼을 눌러 오늘의 일기를 작성하세요. '
                    '하루에 하나의 일기만 작성할 수 있어요.',
              ),
              _HelpItem(
                title: '주간 일기 보기',
                content: '"N월 M주차" 라벨을 탭하면 해당 주에 작성한 모든 일기를 '
                    '한눈에 볼 수 있어요.',
              ),
              _HelpItem(
                title: '나의 숲 꾸미기',
                content: '달력 아이콘을 눌러 나의 숲으로 이동하세요. '
                    '나무를 드래그하여 원하는 위치에 배치할 수 있어요.',
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Emotion guide section
          _HelpSection(
            title: '감정 색상 가이드',
            icon: Icons.palette_rounded,
            children: [
              _EmotionGuide(emotion: 'happy', description: '기쁨, 즐거움, 행복'),
              _EmotionGuide(emotion: 'sad', description: '슬픔, 우울, 아쉬움'),
              _EmotionGuide(emotion: 'angry', description: '화남, 분노, 짜증'),
              _EmotionGuide(emotion: 'calm', description: '차분함, 평온, 안정'),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // FAQ section
          _HelpSection(
            title: 'FAQ',
            icon: Icons.question_answer_rounded,
            children: [
              _HelpItem(
                title: '일기를 수정할 수 있나요?',
                content: '현재는 작성된 일기를 수정하는 기능은 제공하지 않아요. '
                    '신중하게 작성해주세요!',
              ),
              _HelpItem(
                title: '감정 분석은 어떻게 되나요?',
                content: 'AI가 일기 내용을 분석하여 자동으로 감정을 파악해요. '
                    '분석 결과는 일기 상세 화면에서 확인할 수 있어요.',
              ),
              _HelpItem(
                title: '나무는 언제 생기나요?',
                content: '일기를 작성하면 해당 주차에 나무가 하나 생겨요. '
                    '감정에 따라 나무의 색상이 달라져요.',
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Footer
          Center(
            child: Text(
              '💚 DiaryGarden',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.trunk, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  const _HelpItem({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionGuide extends StatelessWidget {
  const _EmotionGuide({
    required this.emotion,
    required this.description,
  });

  final String emotion;
  final String description;

  @override
  Widget build(BuildContext context) {
    final color = emotionColor(emotion);
    final label = emotionLabel(emotion);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
