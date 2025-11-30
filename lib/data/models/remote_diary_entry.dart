class RemoteDiaryEntry {
  const RemoteDiaryEntry({
    required this.id,
    required this.userId,
    required this.treeId,
    required this.content,
    required this.writtenDate,
    required this.createdAt,
    required this.updatedAt,
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

    final writtenDate = _parseDate(json['writtenDate']) ?? _parseDate(json['written_date']);
    final createdAt = _parseDate(json['createdAt']) ?? _parseDate(json['created_at']);
    final updatedAt = _parseDate(json['updatedAt']) ?? _parseDate(json['updated_at']);

    return RemoteDiaryEntry(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? json['user_id']?.toString() ?? '',
      treeId: json['treeId']?.toString() ?? json['tree_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      writtenDate: writtenDate ?? DateTime.now(),
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  final String id;
  final String userId;
  final String treeId;
  final String content;
  final DateTime writtenDate;
  final DateTime createdAt;
  final DateTime updatedAt;
}
