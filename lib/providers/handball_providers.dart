import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/calendar_models.dart';
import '../models/handball_models.dart';
import '../services/handball_service.dart';
import '../svg_image_generator.dart';
import '../transformers/handball_transformer.dart';

/// Provider for the handball service
final handballServiceProvider = Provider<HandballService>((ref) {
  return HandballService();
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
    // Transform HandballGame objects to Match objects
    final matches = HandballTransformer.fromHandballGames(selectedGames);
    
    // Choose appropriate template based on number of games
    final templateCount = matches.length > 4 ? 4 : matches.length;
    final template = 'assets/www/results_$templateCount.svg';
    
    // Generate the image
    return await SvgImageGenerator.generateImageData(template, matches);
  } catch (e) {
    throw Exception('Failed to generate image: $e');
  }
});