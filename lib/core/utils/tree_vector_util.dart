import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import 'emotion_helper.dart';

const Size _kTreeBaseSize = Size(238, 319);

class TreeVectorData {
  TreeVectorData({
    required this.svg,
    required this.logicalSize,
    required this.baseSize,
  }) : widthFactor = logicalSize.width / baseSize.width,
       heightFactor = logicalSize.height / baseSize.height;

  final String svg;
  final Size logicalSize;
  final Size baseSize;
  final double widthFactor;
  final double heightFactor;

  Size get intrinsicSize => logicalSize;

  SvgPicture toPicture({
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    bool useBaseSize = false,
  }) {
    final resolved = useBaseSize
        ? _resolveFromBase(width: width, height: height)
        : _resolveLogical(width: width, height: height);
    return SvgPicture.string(
      svg,
      width: resolved.width,
      height: resolved.height,
      fit: fit,
      allowDrawingOutsideViewBox: true,
    );
  }

  Size _resolveLogical({double? width, double? height}) {
    if (width == null && height == null) {
      return intrinsicSize;
    }
    if (width != null && height != null) {
      return Size(width, height);
    }
    if (width != null) {
      final ratio = intrinsicSize.height / intrinsicSize.width;
      return Size(width, width * ratio);
    }
    final resolvedHeight = height!;
    final ratio = intrinsicSize.width / intrinsicSize.height;
    return Size(resolvedHeight * ratio, resolvedHeight);
  }

  Size _resolveFromBase({double? width, double? height}) {
    if (width == null && height == null) {
      return intrinsicSize;
    }
    if (width != null && height != null) {
      return Size(width * widthFactor, height * heightFactor);
    }
    if (width != null) {
      final resolvedWidth = width * widthFactor;
      final aspect = intrinsicSize.height / intrinsicSize.width;
      return Size(resolvedWidth, resolvedWidth * aspect);
    }
    final resolvedBaseHeight = height! * heightFactor;
    final aspect = intrinsicSize.width / intrinsicSize.height;
    return Size(resolvedBaseHeight * aspect, resolvedBaseHeight);
  }
}

class TreeVectorUtil {
  const TreeVectorUtil._();

  static const Size baseSize = _kTreeBaseSize;

  static const Map<int, _TreeAsset> _treeAssets = {
    1: _TreeAsset('assets/svgs/tree_level_1.svg', Size(86, 79)),
    2: _TreeAsset('assets/svgs/tree_level_2.svg', Size(135, 173)),
    3: _TreeAsset('assets/svgs/tree_level_3.svg', Size(214, 227)),
    4: _TreeAsset('assets/svgs/tree_level_4.svg', Size(238, 319)),
  };

  // Number of colored leaves per level
  static const Map<int, int> _levelLeafCount = {
    1: 0,
    2: 2,
    3: 5,
    4: 10,
  };

  // Determine tree level based on diary count
  static int _levelForDiaryCount(int count) {
    if (count == 0) return 1;
    if (count <= 2) return 2;
    if (count <= 4) return 3;
    return 4; // 5-7 diaries
  }

  static final Map<int, Future<String>> _templateCache = {};
  static final Map<_TreeCacheKey, Future<TreeVectorData>> _renderCache = {};
  static const bool _kDebugMode = false; // Set to true to enable debug logging

  /// Generate tree SVG colored by diary emotions
  /// 
  /// Each item in [emotionData] represents one diary entry.
  /// The tree level is automatically determined by the number of entries.
  /// Each diary's dominant emotion determines one leaf's color.
  static Future<TreeVectorData> svgFor({
    required List<Map<String, dynamic>> emotionData,
    bool debug = false,
  }) {
    final diaryCount = emotionData.length;
    final level = _levelForDiaryCount(diaryCount);
    final signature = _canonicalizeEmotionData(emotionData, level);
    final cacheKey = _TreeCacheKey(level, signature.cacheKey);

    if (_kDebugMode || debug) {
      debugPrint('🌳 TreeVectorUtil.svgFor:');
      debugPrint('  Diary Count: $diaryCount');
      debugPrint('  Auto Level: $level');
      debugPrint('  Emotion Data: $emotionData');
      debugPrint('  Signature: ${signature.cacheKey}');
      debugPrint('  Entries: ${signature.entries.map((e) => '${e.emotion}=${e.score}').join(', ')}');
    }

    return _renderCache.putIfAbsent(cacheKey, () async {
      final template = await _loadTemplate(level);
      final palette = _paletteForDiaries(signature.entries, level);
      
      if (_kDebugMode || debug) {
        debugPrint('  Palette: ${palette.map((c) => _colorToHex(c)).join(', ')}');
      }
      
      final adjustedSvg = _applyPalette(template, palette);
      final asset = _treeAssets[level]!;
      return TreeVectorData(
        svg: adjustedSvg,
        logicalSize: asset.size,
        baseSize: baseSize,
      );
    });
  }

  static Future<String> _loadTemplate(int level) {
    final asset = _treeAssets[level]!;
    return _templateCache.putIfAbsent(
      level,
      () => rootBundle.loadString(asset.assetPath),
    );
  }

  /// Assign colors to leaves based on diary entries
  /// 
  /// Returns a list of colors in the order they appear in the SVG file.
  /// The order is based on the placeholder colors in the SVG.
  static List<Color> _paletteForDiaries(List<_EmotionEntry> diaries, int level) {
    final leafCount = _levelLeafCount[level] ?? 0;
    
    if (leafCount == 0 || diaries.isEmpty) {
      return []; // No leaves to color
    }

    // Count occurrences of each emotion to find dominant
    final emotionCounts = <String, int>{};
    for (final diary in diaries) {
      emotionCounts[diary.emotion] = (emotionCounts[diary.emotion] ?? 0) + 1;
    }
    
    // Find dominant emotion (most frequent)
    String dominantEmotion = 'happy'; // default
    int maxCount = 0;
    for (final entry in emotionCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        dominantEmotion = entry.key;
      }
    }

    // Assign each diary to a leaf color
    final colors = <Color>[];
    
    for (int i = 0; i < leafCount; i++) {
      if (i < diaries.length) {
        // Assign diary's emotion color
        colors.add(emotionColor(diaries[i].emotion));
      } else {
        // Fill remaining leaves with dominant emotion or transparent
        colors.add(emotionColor(dominantEmotion).withOpacity(0.5));
      }
    }

    return colors;
  }

  static Color _resolveEmotionColor(String emotion) {
    if (emotion.isEmpty) {
      return AppColors.leafGreen;
    }
    final color = emotionColor(emotion);
    if (color == AppColors.trunk) {
      return AppColors.leafGreen;
    }
    return color;
  }

  static _EmotionSignature _canonicalizeEmotionData(
    List<Map<String, dynamic>> raw,
    int level,
  ) {
    final entries = _parseEmotionEntries(raw);
    
    if (entries.isEmpty) {
      return _EmotionSignature(
        level: level,
        entries: const [],
        cacheKey: 'L$level',
      );
    }

    // Keep all entries in their original order (diary order)
    final keyBuffer = StringBuffer('L$level');
    for (final e in entries) {
      keyBuffer
        ..write('|')
        ..write(e.emotion)
        ..write('=')
        ..write((e.score ?? 0).toStringAsFixed(4));
    }

    return _EmotionSignature(
      level: level,
      cacheKey: keyBuffer.toString(),
      entries: List.unmodifiable(entries),
    );
  }

  static List<_EmotionEntry> _parseEmotionEntries(
    List<Map<String, dynamic>> raw,
  ) {
    final result = <_EmotionEntry>[];
    for (var i = 0; i < raw.length; i++) {
      final emotionValue = raw[i]['emotion'];
      if (emotionValue is! String) {
        continue;
      }
      final emotion = _canonicalEmotionKey(emotionValue);
      final score = _tryParseScore(raw[i]['score']);
      result.add(_EmotionEntry(emotion: emotion, order: i, score: score));
    }
    return result;
  }

  static double? _tryParseScore(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return double.tryParse(trimmed);
    }
    return null;
  }

  static String _canonicalEmotionKey(String raw) {
    final key = raw.trim().toLowerCase();
    if (key.isEmpty) {
      return 'default';
    }
    if (emotionColors.containsKey(key)) {
      return key;
    }
    return 'default';
  }

  static String _applyPalette(String svg, List<Color> palette) {
    if (palette.isEmpty) {
      return svg; // No colors to apply
    }

    var result = svg;
    var colorIndex = 0;
    
    // List of placeholder colors in the order they should be replaced
    // This matches the emotion colors that appear in SVG files
    final placeholders = [
      '#EB875F', // angry/coral
      '#93E6AA', // calm/green  
      '#9FC0F5', // sad/blue
      '#FAE469', // happy/yellow
    ];
    
    // Replace each placeholder with colors from palette in order
    for (final placeholder in placeholders) {
      // Find all occurrences of this placeholder in the SVG
      var occurrenceCount = 0;
      var tempSvg = svg;
      while (tempSvg.contains(placeholder)) {
        occurrenceCount++;
        final index = tempSvg.indexOf(placeholder);
        tempSvg = tempSvg.substring(index + placeholder.length);
      }
      
      // Replace each occurrence with sequential colors from palette
      for (int i = 0; i < occurrenceCount && colorIndex < palette.length; i++) {
        final replacement = _colorToHex(palette[colorIndex]);
        // Replace first occurrence
        result = result.replaceFirst(placeholder, replacement);
        result = result.replaceFirst(placeholder.toLowerCase(), replacement);
        colorIndex++;
      }
    }
    
    return result;
  }

  static String _colorToHex(Color color) {
    final r = color.red.toRadixString(16).padLeft(2, '0').toUpperCase();
    final g = color.green.toRadixString(16).padLeft(2, '0').toUpperCase();
    final b = color.blue.toRadixString(16).padLeft(2, '0').toUpperCase();
    return '#$r$g$b';
  }

  static void clearCache() {
    _renderCache.clear();
  }
}

class _TreeAsset {
  const _TreeAsset(this.assetPath, this.size);

  final String assetPath;
  final Size size;
}

class _TreeCacheKey {
  const _TreeCacheKey(this.level, this.emotion);

  final int level;
  final String emotion;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _TreeCacheKey &&
        other.level == level &&
        other.emotion == emotion;
  }

  @override
  int get hashCode => Object.hash(level, emotion);
}

class _EmotionEntry {
  const _EmotionEntry({required this.emotion, required this.order, this.score});

  final String emotion;
  final int order;
  final double? score;
}

class _EmotionSignature {
  _EmotionSignature({
    required this.level,
    required this.cacheKey,
    required List<_EmotionEntry> entries,
  }) : entries = List.unmodifiable(entries);

  final int level;
  final String cacheKey;
  final List<_EmotionEntry> entries;
}
