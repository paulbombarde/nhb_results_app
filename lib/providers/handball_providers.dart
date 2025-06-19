import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/calendar_models.dart';
import '../models/handball_models.dart';
import '../services/handball_service.dart';
import '../services/storage_service.dart';
import '../svg_image_generator.dart';
import '../transformers/handball_transformer.dart';

/// Provider for the storage service
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// Provider for the handball configuration
final handballConfigProvider = StateNotifierProvider<HandballConfigNotifier, HandballConfig>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return HandballConfigNotifier(storageService);
});

/// Notifier for handball configuration
class HandballConfigNotifier extends StateNotifier<HandballConfig> {
  final StorageService _storageService;
  
  HandballConfigNotifier(this._storageService) : super(HandballConfig.defaultConfig) {
    _loadFromStorage();
  }
  
  /// Load configuration from persistent storage
  Future<void> _loadFromStorage() async {
    try {
      final savedConfig = await _storageService.loadApiConfig();
      if (savedConfig != null) {
        state = savedConfig;
      }
    } catch (e) {
      debugPrint('Error loading config from storage: $e');
      // Keep default config if loading fails
    }
  }
  
  /// Update configuration and save to storage
  Future<void> updateConfig({int? clubId, int? seasonId}) async {
    final newState = state.copyWith(
      clubId: clubId,
      seasonId: seasonId,
    );
    
    state = newState;
    
    try {
      await _storageService.saveApiConfig(newState);
    } catch (e) {
      debugPrint('Error saving config to storage: $e');
    }
  }
  
  /// Reset to defaults and save to storage
  Future<void> resetToDefaults() async {
    state = HandballConfig.defaultConfig;
    
    try {
      await _storageService.saveApiConfig(HandballConfig.defaultConfig);
    } catch (e) {
      debugPrint('Error saving default config to storage: $e');
    }
  }
}

/// Provider for the handball service
final handballServiceProvider = Provider<HandballService>((ref) {
  // Watch the config provider to rebuild when config changes
  final config = ref.watch(handballConfigProvider);
  return HandballService(config: config);
});

/// Provider for loading state
final loadingProvider = StateProvider<HandballLoadingState>((ref) {
  return HandballLoadingState.initial;
});

/// Provider for error messages
final errorProvider = StateProvider<String?>((ref) {
  return null;
});

/// Provider for dates with completed games
final datesWithGamesProvider = FutureProvider<List<DateTime>>((ref) async {
  final handballService = ref.watch(handballServiceProvider);
  
  try {
    final dates = await handballService.getDatesWithCompletedGames();
    return dates;
  } catch (e) {
    ref.read(errorProvider.notifier).state = e.toString();
    rethrow;
  }
});

/// Provider for the currently selected date
final selectedDateProvider = StateProvider<DateTime?>((ref) {
  return null;
});

/// Provider for games on the selected date
final gamesForSelectedDateProvider = FutureProvider<List<HandballGame>>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final handballService = ref.watch(handballServiceProvider);
  
  if (selectedDate == null) {
    return [];
  }
  
  try {
    return await handballService.getGamesByDate(selectedDate);
  } catch (e) {
    ref.read(errorProvider.notifier).state = e.toString();
    return [];
  }
});

/// Provider for calendar dates with game information
final calendarDatesProvider = FutureProvider<List<CalendarDateModel>>((ref) async {
  final handballService = ref.watch(handballServiceProvider);
  final dates = await ref.watch(datesWithGamesProvider.future);
  final calendarDates = <CalendarDateModel>[];
  
  for (final date in dates) {
    final games = await handballService.getGamesByDate(date);
    calendarDates.add(CalendarDateModel(
      date: date,
      hasGames: games.isNotEmpty,
      gameCount: games.length,
    ));
  }
  
  return calendarDates;
});

/// Provider for selected games
final selectedGamesProvider = StateNotifierProvider<SelectedGamesNotifier, List<HandballGame>>((ref) {
  return SelectedGamesNotifier();
});

class SelectedGamesNotifier extends StateNotifier<List<HandballGame>> {
  SelectedGamesNotifier() : super([]);

  void toggleGameSelection(HandballGame game) {
    // Create a new list from the current state
    final currentlySelected = List<HandballGame>.from(state);
    
    // Check if the game is already in the list using the equality operator
    final isAlreadySelected = currentlySelected.contains(game);
    
    if (isAlreadySelected) {
      // Find the index of the game in the list
      final index = currentlySelected.indexWhere((g) => g == game);
      if (index >= 0) {
        currentlySelected.removeAt(index);
      }
    } else {
      currentlySelected.add(game);
    }
    
    // Update the state with the new list
    state = currentlySelected;
  }

  void clearSelection() {
    state = [];
  }
}

/// Provider for image generation
final imageGenerationProvider = FutureProvider.autoDispose.family<Uint8List?, List<HandballGame>>((ref, selectedGames) async {
  if (selectedGames.isEmpty) {
    return null;
  }

  try {
    // Get current team replacements
    final teamReplacements = ref.watch(teamReplacementsProvider);
    
    // Transform HandballGame objects to Match objects with custom replacements
    final matches = HandballTransformer.fromHandballGames(selectedGames, teamReplacements);
    
    // Choose appropriate template based on number of games
    final templateCount = matches.length > 4 ? 4 : matches.length;
    final template = 'assets/www/results_$templateCount.svg';
    
    // Generate the image
    return await SvgImageGenerator.generateImageData(template, matches);
  } catch (e) {
    throw Exception('Failed to generate image: $e');
  }
});

/// Provider for team name replacements
final teamReplacementsProvider = StateNotifierProvider<TeamReplacementsNotifier, Map<String, String>>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return TeamReplacementsNotifier(storageService);
});

/// Notifier for team name replacements
class TeamReplacementsNotifier extends StateNotifier<Map<String, String>> {
  final StorageService _storageService;
  
  TeamReplacementsNotifier(this._storageService) : super(Map<String, String>.from(HandballTransformer.teamNameReplacements)) {
    _loadFromStorage();
  }
  
  /// Load team replacements from persistent storage
  Future<void> _loadFromStorage() async {
    try {
      final savedReplacements = await _storageService.loadTeamReplacements();
      if (savedReplacements != null && savedReplacements.isNotEmpty) {
        state = savedReplacements;
      }
    } catch (e) {
      debugPrint('Error loading team replacements from storage: $e');
      // Keep default replacements if loading fails
    }
  }
  
  /// Add a new team replacement or update an existing one
  Future<void> addOrUpdateReplacement(String originalName, String replacementName) async {
    final updatedMap = Map<String, String>.from(state);
    updatedMap[originalName] = replacementName;
    state = updatedMap;
    
    try {
      await _storageService.saveTeamReplacements(updatedMap);
    } catch (e) {
      debugPrint('Error saving team replacements to storage: $e');
    }
  }
  
  /// Remove a team replacement
  Future<void> removeReplacement(String originalName) async {
    final updatedMap = Map<String, String>.from(state);
    updatedMap.remove(originalName);
    state = updatedMap;
    
    try {
      await _storageService.saveTeamReplacements(updatedMap);
    } catch (e) {
      debugPrint('Error saving team replacements to storage: $e');
    }
  }
  
  /// Reset to default replacements
  Future<void> resetToDefaults() async {
    final defaultReplacements = Map<String, String>.from(HandballTransformer.teamNameReplacements);
    state = defaultReplacements;
    
    try {
      await _storageService.saveTeamReplacements(defaultReplacements);
    } catch (e) {
      debugPrint('Error saving default team replacements to storage: $e');
    }
  }
}