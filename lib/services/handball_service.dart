import '../models/handball_models.dart';
import 'handball_client.dart';

/// Service for handball data operations
class HandballService {
  final HandballGraphQLClient _client;

  HandballService({HandballGraphQLClient? client}) 
      : _client = client ?? HandballGraphQLClient();

  /// Fetch all games for the default club and season
  Future<List<HandballGame>> getAllGames() async {
    try {
      final response = await _client.getGamesWithDefaults();
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

  /// Dispose resources
  void dispose() {
    _client.dispose();
  }
}

/// Exception thrown by the handball service
class HandballServiceException implements Exception {
  final String message;
  
  const HandballServiceException(this.message);
  
  @override
  String toString() => 'HandballServiceException: $message';
}