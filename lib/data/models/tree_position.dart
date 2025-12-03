class TreePosition {
  const TreePosition({
    required this.gardenLevel,
    required this.treeId,
    required this.positionX,
    required this.positionY,
    required this.updatedAt,
  });

  factory TreePosition.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    return TreePosition(
      gardenLevel: json['gardenLevel']?.toString() ?? 
                   json['garden_level']?.toString() ?? '',
      treeId: json['treeId']?.toString() ?? json['tree_id']?.toString() ?? '',
      positionX: (json['positionX'] ?? json['position_x'] ?? 0.5).toDouble().clamp(0.0, 1.0),
      positionY: (json['positionY'] ?? json['position_y'] ?? 0.5).toDouble().clamp(0.0, 1.0),
      updatedAt: _parseDate(json['updatedAt']) ?? 
                 _parseDate(json['updated_at']) ?? 
                 DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gardenLevel': gardenLevel,
      'treeId': treeId,
      'positionX': positionX,
      'positionY': positionY,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Garden view scope (e.g., "2025-12" for monthly, "2025" for yearly)
  final String gardenLevel;

  /// Tree identifier matching diary's treeId
  final String treeId;

  /// Normalized horizontal position (0.0 to 1.0)
  final double positionX;

  /// Normalized vertical position (0.0 to 1.0)
  final double positionY;

  /// Last update timestamp
  final DateTime updatedAt;

  TreePosition copyWith({
    String? gardenLevel,
    String? treeId,
    double? positionX,
    double? positionY,
    DateTime? updatedAt,
  }) {
    return TreePosition(
      gardenLevel: gardenLevel ?? this.gardenLevel,
      treeId: treeId ?? this.treeId,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TreePosition(gardenLevel: $gardenLevel, treeId: $treeId, '
        'position: ($positionX, $positionY), updatedAt: $updatedAt)';
  }
}
