import 'handball_models.dart';

/// Model representing a date in the calendar
class CalendarDateModel {
  final DateTime date;
  final bool hasGames;
  final int gameCount;
  
  const CalendarDateModel({
    required this.date,
    required this.hasGames,
    this.gameCount = 0,
  });
}

/// State for selected games
class SelectedGamesState {
  final List<HandballGame> availableGames;
  final List<HandballGame> selectedGames;
  final DateTime selectedDate;
  final bool isLoading;
  final String? errorMessage;
  
  const SelectedGamesState({
    required this.availableGames,
    required this.selectedGames,
    required this.selectedDate,
    this.isLoading = false,
    this.errorMessage,
  });
  
  SelectedGamesState copyWith({
    List<HandballGame>? availableGames,
    List<HandballGame>? selectedGames,
    DateTime? selectedDate,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SelectedGamesState(
      availableGames: availableGames ?? this.availableGames,
      selectedGames: selectedGames ?? this.selectedGames,
      selectedDate: selectedDate ?? this.selectedDate,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}