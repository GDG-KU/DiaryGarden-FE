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

  static const Map<int, int> _levelEmotionCapacity = {1: 0, 2: 2, 3: 5, 4: 11};

  static const List<_LeafShade> _leafShades = [
    _LeafShade(
      placeholderHex: '#93E6AA',
      lightnessDelta: 0.18,
      saturationDelta: -0.04,
    ),
    _LeafShade(placeholderHex: '#9FC0F5', lightnessDelta: 0.02),
    _LeafShade(
      placeholderHex: '#EB875F',
      lightnessDelta: -0.12,
      saturationDelta: 0.04,
    ),
    _LeafShade(
      placeholderHex: '#FAE469',
      lightnessDelta: 0.26,
      saturationDelta: -0.12,
    ),
  ];

  static final Map<int, Future<String>> _templateCache = {};
  static final Map<_TreeCacheKey, Future<TreeVectorData>> _renderCache = {};
  static const bool _kDebugMode = false; // Set to true to enable debug logging

  static Future<TreeVectorData> svgFor({
    required int level,
    required List<Map<String, dynamic>> emotionData,
    bool debug = false,
  }) {
    final normalizedLevel = level.clamp(1, _treeAssets.length);
    final signature = _canonicalizeEmotionData(emotionData, normalizedLevel);
    final cacheKey = _TreeCacheKey(normalizedLevel, signature.cacheKey);

    if (_kDebugMode || debug) {
      debugPrint('  TreeVectorUtil.svgFor:');
      debugPrint('  Level: $normalizedLevel');
      debugPrint('  Emotion Data: $emotionData');
      debugPrint('  Signature: ${signature.cacheKey}');
      debugPrint('  Entries: ${signature.entries.map((e) => '${e.emotion}=${e.score}').join(', ')}');
    }

    return _renderCache.putIfAbsent(cacheKey, () async {
      final template = await _loadTemplate(normalizedLevel);
      final palette = _paletteForSignature(signature);
      
      if (_kDebugMode || debug) {
        debugPrint('  Palette: ${palette.map((c) => _colorToHex(c)).join(', ')}');
      }
      
      final adjustedSvg = _applyPalette(template, palette);
      final asset = _treeAssets[normalizedLevel]!;
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

  static List<Color> _paletteForSignature(_EmotionSignature signature) {
    final groups = _distributeEntries(signature.entries);
    return List<Color>.generate(
      _leafShades.length,
      (index) => _mixGroupColor(groups[index], _leafShades[index]),
      growable: false,
    );
  }

  static List<List<_EmotionEntry>> _distributeEntries(
    List<_EmotionEntry> entries,
  ) {
    final groupCount = _leafShades.length;
    final groups = List.generate(groupCount, (_) => <_EmotionEntry>[]);
    if (entries.isEmpty) {
      return groups;
    }
    for (var i = 0; i < entries.length; i++) {
      groups[i % groupCount].add(entries[i]);
    }
    return groups;
  }

  static Color _mixGroupColor(List<_EmotionEntry> group, _LeafShade shade) {
    if (group.isEmpty) {
      return _shadeColorForEmotion('default', shade);
    }

    final colors = <Color>[];
    final weights = <double>[];
    for (final entry in group) {
      colors.add(_shadeColorForEmotion(entry.emotion, shade));
      // Use 1.0 as default weight if score is null or 0
      final weight = entry.score ?? 1.0;
      weights.add(weight.abs() > 0.001 ? weight.abs() : 1.0);
    }

    final totalWeight = weights.fold<double>(0, (sum, value) => sum + value);
    
    // If all weights are effectively zero (shouldn't happen now), use equal weights
    if (totalWeight < 0.001) {
      double r = 0, g = 0, b = 0;
      for (final color in colors) {
        r += color.red;
        g += color.green;
        b += color.blue;
      }
      final inv = 1 / colors.length;
      return Color.fromARGB(
        255,
        _channel(r * inv),
        _channel(g * inv),
        _channel(b * inv),
      );
    }

    // Weighted average of colors
    double r = 0, g = 0, b = 0;
    for (var i = 0; i < colors.length; i++) {
      final weight = weights[i];
      r += colors[i].red * weight;
      g += colors[i].green * weight;
      b += colors[i].blue * weight;
    }
    final inv = 1 / totalWeight;
    return Color.fromARGB(
      255,
      _channel(r * inv),
      _channel(g * inv),
      _channel(b * inv),
    );
  }

  static Color _shadeColorForEmotion(String emotion, _LeafShade shade) {
    final base = _resolveEmotionColor(emotion);
    return _shift(
      base,
      lightnessDelta: shade.lightnessDelta,
      saturationDelta: shade.saturationDelta,
    );
  }

  static int _channel(double value) => value.clamp(0, 255).round();

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

  static Color _shift(
    Color color, {
    double lightnessDelta = 0,
    double saturationDelta = 0,
  }) {
    var hsl = HSLColor.fromColor(color);
    final newSaturation = (hsl.saturation + saturationDelta).clamp(0.0, 1.0);
    final newLightness = (hsl.lightness + lightnessDelta).clamp(0.0, 1.0);
    hsl = hsl.withSaturation(newSaturation);
    hsl = hsl.withLightness(newLightness);
    return hsl.toColor();
  }

  static _EmotionSignature _canonicalizeEmotionData(
    List<Map<String, dynamic>> raw,
    int level,
  ) {
    final entries = _parseEmotionEntries(raw);
    final capacity = _levelEmotionCapacity[level] ?? 0;
    if (capacity <= 0 || entries.isEmpty) {
      return _EmotionSignature(
        level: level,
        entries: const [],
        cacheKey: 'L$level',
      );
    }

    final sorted = List<_EmotionEntry>.from(entries)
      ..sort((a, b) {
        final aScore = a.score;
        final bScore = b.score;
        if (aScore != null && bScore != null) {
          final diff = bScore.compareTo(aScore);
          if (diff != 0) return diff;
        } else if (aScore != null) {
          return -1;
        } else if (bScore != null) {
          return 1;
        }
        return a.order.compareTo(b.order);
      });

    final limited = sorted.take(capacity).toList(growable: false);
    final keyBuffer = StringBuffer('L$level');
    for (final e in limited) {
      keyBuffer
        ..write('|')
        ..write(e.emotion)
        ..write('=')
        ..write((e.score ?? 0).toStringAsFixed(4));
    }

    return _EmotionSignature(
      level: level,
      cacheKey: keyBuffer.toString(),
      entries: limited,
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
    var result = svg;
    for (var i = 0; i < _leafShades.length; i++) {
      final placeholder = _leafShades[i].placeholderHex;
      final replacement = _colorToHex(palette[i]);
      final placeholderUpper = placeholder.toUpperCase();
      final placeholderLower = placeholder.toLowerCase();
      
      result = result
          .replaceAll(placeholderUpper, replacement)
          .replaceAll(placeholderLower, replacement);
          
      if (placeholder.startsWith('#')) {
        final withoutHash = placeholder.substring(1);
        result = result
            .replaceAll(withoutHash.toUpperCase(), replacement.substring(1))
            .replaceAll(withoutHash.toLowerCase(), replacement.substring(1));
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

class _LeafShade {
  const _LeafShade({
    required this.placeholderHex,
    this.lightnessDelta = 0,
    this.saturationDelta = 0,
  });

  final String placeholderHex;
  final double lightnessDelta;
  final double saturationDelta;
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
