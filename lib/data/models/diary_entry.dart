class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final Map<String, double> emotionScores;
  final String dominantEmotion;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    required this.emotionScores,
    required this.dominantEmotion,
  });
}
