import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const Map<String, Color> emotionColors = {
  'happy': AppColors.leafYellow,
  'sad': AppColors.leafBlue,
  'angry': AppColors.leafCoral,
  'calm': AppColors.leafGreen,
  'default': AppColors.trunk,
};

const Map<String, String> emotionLabels = {
  'happy': '기쁨',
  'sad': '슬픔',
  'angry': '화남',
  'calm': '차분',
  'default': '보통',
};

Color emotionColor(String emotion) {
  return emotionColors[emotion] ?? emotionColors['default']!;
}

String emotionLabel(String emotion) {
  return emotionLabels[emotion] ?? emotionLabels['default']!;
}

Color getTextColorForEmotion(String emotion) {
  return switch (emotion) {
    'happy' || 'calm' => AppColors.textOnLeaf,
    'sad' => AppColors.textOnLeaf,
    'angry' => AppColors.textOnTrunk,
    _ => AppColors.textOnTrunk,
  };
}
