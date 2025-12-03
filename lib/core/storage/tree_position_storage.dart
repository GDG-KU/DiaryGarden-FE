import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diary_garden/data/models/tree_position.dart';

/// Local storage for tree positions using SharedPreferences
/// Provides offline caching and quick loading of tree positions
class TreePositionStorage {
  const TreePositionStorage._();

  static const String _keyPrefix = 'tree_positions_';

  /// Get cache key for a specific garden level
  static String _cacheKey(String gardenLevel) => '$_keyPrefix$gardenLevel';

  /// Save tree positions for a specific garden level
  static Future<void> savePositions(
    String gardenLevel,
    List<TreePosition> positions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(gardenLevel);
      final jsonList = positions.map((p) => p.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await prefs.setString(key, jsonString);
      debugPrint('💾 Saved ${positions.length} tree positions for $gardenLevel');
    } catch (e) {
      debugPrint('⚠️ Failed to save tree positions: $e');
    }
  }

  /// Load tree positions for a specific garden level
  static Future<List<TreePosition>> loadPositions(String gardenLevel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(gardenLevel);
      final jsonString = prefs.getString(key);
      
      if (jsonString == null || jsonString.isEmpty) {
        debugPrint('📂 No cached positions for $gardenLevel');
        return [];
      }

      final jsonList = jsonDecode(jsonString) as List;
      final positions = jsonList
          .map((json) => TreePosition.fromJson(json as Map<String, dynamic>))
          .toList();
      
      debugPrint('📂 Loaded ${positions.length} tree positions for $gardenLevel');
      return positions;
    } catch (e) {
      debugPrint('⚠️ Failed to load tree positions: $e');
      return [];
    }
  }

  /// Update a single tree position in cache
  static Future<void> updatePosition(TreePosition position) async {
    try {
      final positions = await loadPositions(position.gardenLevel);
      final updatedPositions = positions.where((p) => p.treeId != position.treeId).toList()
        ..add(position);
      await savePositions(position.gardenLevel, updatedPositions);
      debugPrint('💾 Updated position for tree ${position.treeId} in ${position.gardenLevel}');
    } catch (e) {
      debugPrint('⚠️ Failed to update tree position: $e');
    }
  }

  /// Clear all cached tree positions
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
      for (final key in keys) {
        await prefs.remove(key);
      }
      debugPrint('🗑️ Cleared all tree position cache');
    } catch (e) {
      debugPrint('⚠️ Failed to clear tree positions: $e');
    }
  }

  /// Clear tree positions for a specific garden level
  static Future<void> clearGarden(String gardenLevel) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(gardenLevel);
      await prefs.remove(key);
      debugPrint('🗑️ Cleared tree positions for $gardenLevel');
    } catch (e) {
      debugPrint('⚠️ Failed to clear garden positions: $e');
    }
  }
}
