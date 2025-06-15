import '../models/handball_models.dart';
import 'handball_client.dart';

/// Service for handball data operations
class HandballService {
  final HandballGraphQLClient _client;
  
  // Cache for games to avoid repeated API calls
  List<HandballGame>? _cachedGames;
  DateTime? _lastFetchTime;
  
  // Cache expiration time (5 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  HandballService({HandballGraphQLClient? client})
      : _client = client ?? HandballGraphQLClient();

  /// Fetch all games for the default club and season with caching
  Future<List<HandballGame>> getAllGames() async {
    try {
      // Check if we have a valid cache
      if (_cachedGames != null && _lastFetchTime != null) {
        final now = DateTime.now();
        if (now.difference(_lastFetchTime!) < _cacheExpiration) {
          return _cachedGames!;
        }
      }
      
      // Fetch fresh data
      final response = await _client.getGamesWithDefaults();
      
      // Update cache
      _cachedGames = response.games;
      _lastFetchTime = DateTime.now();
      
      return response.games;
    } catch (e) {
      throw HandballServiceException('Failed to fetch games: $e');
    }
  }

  /// Fetch games for a specific club and season
  Future<List<HandballGame>> getGames({
    required int clubId,
    required int seasonId,
  }) async {
    try {
      final response = await _client.getGames(
        clubId: clubId,
        seasonId: seasonId,
      );
      return response.games;
    } catch (e) {
      throw HandballServiceException('Failed to fetch games: $e');
    }
  }

  /// Get games filtered by team name (home or away)
  Future<List<HandballGame>> getGamesByTeam(String teamName) async {
    final allGames = await getAllGames();
    return allGames.where((game) {
      final homeTeam = game.homeTeamName?.toLowerCase() ?? '';
      final awayTeam = game.awayTeamName?.toLowerCase() ?? '';
      final searchTerm = teamName.toLowerCase();
      return homeTeam.contains(searchTerm) || awayTeam.contains(searchTerm);
    }).toList();
  }

  /// Get only live games
  Future<List<HandballGame>> getLiveGames() async {
    final allGames = await getAllGames();
    return allGames.where((game) => game.isLive == true).toList();
  }

  /// Get games by league
  Future<List<HandballGame>> getGamesByLeague(String leagueShortName) async {
    final allGames = await getAllGames();
    return allGames.where((game) => 
      game.leagueShortName?.toLowerCase() == leagueShortName.toLowerCase()
    ).toList();
  }

  /// Get games by venue
  Future<List<HandballGame>> getGamesByVenue(String venueName) async {
    final allGames = await getAllGames();
    return allGames.where((game) => 
      game.venueName?.toLowerCase().contains(venueName.toLowerCase()) == true
    ).toList();
  }

  /// Get upcoming games (games without scores)
  Future<List<HandballGame>> getUpcomingGames() async {
    final allGames = await getAllGames();
    return allGames.where((game) => 
      game.homeTeamScore == null && game.awayTeamScore == null
    ).toList();
  }

  /// Get completed games (games with scores)
  Future<List<HandballGame>> getCompletedGames() async {
    final allGames = await getAllGames();
    return allGames.where((game) =>
      game.homeTeamScore != null && game.awayTeamScore != null
    ).toList();
  }
  
  /// Get games for a specific date
  Future<List<HandballGame>> getGamesByDate(DateTime date) async {
    try {
      final allGames = await getAllGames();
      return allGames.where((game) {
        if (game.gameDateTime == null) return false;
        final gameDate = DateTime.parse(game.gameDateTime!);
        return gameDate.year == date.year &&
               gameDate.month == date.month &&
               gameDate.day == date.day;
      }).toList();
    } catch (e) {
      throw HandballServiceException('Failed to get games by date: $e');
    }
  }
  
  /// Get all dates with completed games
  Future<List<DateTime>> getDatesWithCompletedGames() async {
    try {
      final completedGames = await getCompletedGames();
      final Set<String> uniqueDates = {};
      final List<DateTime> result = [];
      
      for (final game in completedGames) {
        if (game.gameDateTime != null) {
          final dateTime = DateTime.parse(game.gameDateTime!);
          final dateString = '${dateTime.year}-${dateTime.month}-${dateTime.day}';
          if (!uniqueDates.contains(dateString)) {
            uniqueDates.add(dateString);
            result.add(DateTime(dateTime.year, dateTime.month, dateTime.day));
          }
        }
      }
      
      return result..sort((a, b) => b.compareTo(a)); // Sort descending (newest first)
    } catch (e) {
      throw HandballServiceException('Failed to get dates with completed games: $e');
    }
  }
  
  /// Group games by date
  Future<Map<DateTime, List<HandballGame>>> getGamesGroupedByDate() async {
    try {
      final allGames = await getAllGames();
      final Map<String, List<HandballGame>> tempGrouped = {};
      final Map<DateTime, List<HandballGame>> result = {};
      
      // First group by date string to handle null dates
      for (final game in allGames) {
        if (game.gameDateTime == null) continue;
        
        final dateTime = DateTime.parse(game.gameDateTime!);
        final dateString = '${dateTime.year}-${dateTime.month}-${dateTime.day}';
        
        if (!tempGrouped.containsKey(dateString)) {
          tempGrouped[dateString] = [];
        }
        
        tempGrouped[dateString]!.add(game);
      }
      
      // Convert string keys to DateTime objects
      for (final entry in tempGrouped.entries) {
        final parts = entry.key.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          final dateKey = DateTime(year, month, day);
          result[dateKey] = entry.value;
        }
      }
      
      return result;
    } catch (e) {
      throw HandballServiceException('Failed to group games by date: $e');
    }
  }
  
  /// Get completed games grouped by date
  Future<Map<DateTime, List<HandballGame>>> getCompletedGamesGroupedByDate() async {
    try {
      final completedGames = await getCompletedGames();
      final Map<String, List<HandballGame>> tempGrouped = {};
      final Map<DateTime, List<HandballGame>> result = {};
      
      // First group by date string to handle null dates
      for (final game in completedGames) {
        if (game.gameDateTime == null) continue;
        
        final dateTime = DateTime.parse(game.gameDateTime!);
        final dateString = '${dateTime.year}-${dateTime.month}-${dateTime.day}';
        
        if (!tempGrouped.containsKey(dateString)) {
          tempGrouped[dateString] = [];
        }
        
        tempGrouped[dateString]!.add(game);
      }
      
      // Convert string keys to DateTime objects
      for (final entry in tempGrouped.entries) {
        final parts = entry.key.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          final dateKey = DateTime(year, month, day);
          result[dateKey] = entry.value;
        }
      }
      
      return result;
    } catch (e) {
      throw HandballServiceException('Failed to group completed games by date: $e');
    }
  }

  /// Clear the cache to force fresh data on next request
  void clearCache() {
    _cachedGames = null;
    _lastFetchTime = null;
  }

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}

/// Exception thrown by the handball service
class HandballServiceException implements Exception {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  
  const HandballServiceException(
    this.message, {
    this.error,
    this.stackTrace,
  });
  
  @override
  String toString() => 'HandballServiceException: $message${error != null ? ' ($error)' : ''}';
}

/// Loading state for handball data operations
enum HandballLoadingState {
  initial,
  loading,
  loaded,
  error,
}