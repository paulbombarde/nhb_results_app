import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/handball_models.dart';

/// Service for handling persistent storage of app configuration
class StorageService {
  // Keys for SharedPreferences
  static const String _settingsKey = 'settings';
  static const String _teamReplacementsKey = 'team_replacements';
  static const String _levelReplacementsKey = 'level_replacements';

  /// Singleton instance
  static final StorageService _instance = StorageService._internal();

  /// Factory constructor to return the singleton instance
  factory StorageService() => _instance;

  /// Private constructor for singleton pattern
  StorageService._internal();

  /// Save API configuration to persistent storage
  Future<bool> saveApiConfig(HandballConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configMap = {
        'seniorMaleLevel': config.seniorMaleLevel,
        'seniorFemaleLevel': config.seniorFemaleLevel,
        'clubId': config.clubId,
        'seasonId': config.seasonId,
      };
      
      return await prefs.setString(_settingsKey, jsonEncode(configMap));
    } catch (e) {
      debugPrint('Error saving API config: $e');
      return false;
    }
  }

  /// Load API configuration from persistent storage
  Future<HandballConfig?> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final configString = prefs.getString(_settingsKey);
      
      if (configString == null) {
        return null;
      }
      
      final configMap = jsonDecode(configString) as Map<String, dynamic>;
      return HandballConfig(
        seniorMaleLevel: configMap['seniorMaleLevel'] ?? "",
        seniorFemaleLevel: configMap['seniorFemaleLevel'] ?? "",
        clubId: configMap['clubId'] as int,
        seasonId: configMap['seasonId'] as int,
      );
    } catch (e) {
      debugPrint('Error loading API config: $e');
      return null;
    }
  }

  /// Save team replacements to persistent storage
  Future<bool> saveTeamReplacements(Map<String, String> replacements) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_teamReplacementsKey, jsonEncode(replacements));
    } catch (e) {
      debugPrint('Error saving team replacements: $e');
      return false;
    }
  }

  /// Load team replacements from persistent storage
  Future<Map<String, String>?> loadTeamReplacements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final replacementsString = prefs.getString(_teamReplacementsKey);
      
      if (replacementsString == null) {
        return null;
      }
      
      final Map<String, dynamic> decodedMap = jsonDecode(replacementsString);
      return Map<String, String>.from(decodedMap);
    } catch (e) {
      debugPrint('Error loading team replacements: $e');
      return null;
    }
  }

  /// Clear all stored configuration data
  Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_settingsKey);
      await prefs.remove(_teamReplacementsKey);
      await prefs.remove(_levelReplacementsKey);
      return true;
    } catch (e) {
      debugPrint('Error clearing storage data: $e');
      return false;
    }
  }

  /// Save level replacements to persistent storage
  Future<bool> saveLevelReplacements(Map<String, String> replacements) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_levelReplacementsKey, jsonEncode(replacements));
    } catch (e) {
      debugPrint('Error saving level replacements: $e');
      return false;
    }
  }

  /// Load level replacements from persistent storage
  Future<Map<String, String>?> loadLevelReplacements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final replacementsString = prefs.getString(_levelReplacementsKey);
      
      if (replacementsString == null) {
        return null;
      }
      
      final Map<String, dynamic> decodedMap = jsonDecode(replacementsString);
      return Map<String, String>.from(decodedMap);
    } catch (e) {
      debugPrint('Error loading level replacements: $e');
      return null;
    }
  }
}