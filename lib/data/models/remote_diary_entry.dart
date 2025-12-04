class RemoteDiaryEntry {
  const RemoteDiaryEntry({
    required this.id,
    required this.userId,
    required this.treeId,
    required this.title,
    required this.content,
    required this.writtenDate,
    required this.createdAt,
    required this.updatedAt,
    required this.emotionScores,
    required this.dominantEmotion,
    this.aiComment,
  });

  factory RemoteDiaryEntry.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    Map<String, double> _parseEmotionScores(dynamic value) {
      if (value == null) return const {'default': 1.0};
      if (value is Map) {
        return value.map((key, val) {
          final score = val is num ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0;
          return MapEntry(key.toString(), score);
        });
      }
      return const {'default': 1.0};
    }

    final writtenDate = _parseDate(json['writtenDate']) ?? _parseDate(json['written_date']);
    final createdAt = _parseDate(json['createdAt']) ?? _parseDate(json['created_at']);
    final updatedAt = _parseDate(json['updatedAt']) ?? _parseDate(json['updated_at']);
    final emotionScores = _parseEmotionScores(json['emotionScores'] ?? json['emotion_scores']);
    final dominantEmotion = json['dominantEmotion']?.toString() ?? 
                            json['dominant_emotion']?.toString() ?? 
                            'default';

    return RemoteDiaryEntry(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      treeId: json['treeId']?.toString() ?? json['tree_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      writtenDate: writtenDate ?? DateTime.now(),
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      emotionScores: emotionScores,
      dominantEmotion: dominantEmotion,
      aiComment: json['aiComment']?.toString() ?? json['ai_comment']?.toString(),
    );
  }

  final String id;
  final String userId;
  final String treeId;
  final String title;
  final String content;
  final DateTime writtenDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, double> emotionScores;
  final String dominantEmotion;
  final String? aiComment;
}
