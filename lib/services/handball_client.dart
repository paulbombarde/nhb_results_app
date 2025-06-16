import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/handball_models.dart';

/// GraphQL client for handball data retrieval
class HandballGraphQLClient {
  static const String _endpoint = 'https://www.handball.ch/Umbraco/Api/MatchCenter/Query';
  
  final http.Client _httpClient;

  HandballGraphQLClient({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();

  /// GraphQL query for retrieving games
  static const String _gamesQuery = '''
    query getGames(\$clubId: Int, \$seasonId: Int) {
      games(clubId: \$clubId, seasonId: \$seasonId) {
        gameNumber
        objectId
        objectType
        isLive
        seasonId
        gameDateTime
        homeTeamId
        homeTeamName
        homeTeamShortName
        homeTeamClubId
        homeTeamScore
        homeTeamScoreInterval
        awayTeamId
        awayTeamName
        awayTeamShortName
        awayTeamClubId
        awayTeamScore
        awayTeamScoreInterval
        venueName
        venueId
        type
        groupShortName
        leagueShortName
        gameStatusId
        gameTypeId
        gameGroupOrCupId
        __typename
      }
    }
  ''';

  /// Fetch games for a specific club and season
  Future<HandballGamesResponse> getGames({
    required int clubId,
    required int seasonId,
  }) async {
    try {
      final payload = {
        'operationName': 'getGames',
        'variables': {
          'clubId': clubId,
          'seasonId': seasonId,
        },
        'query': _gamesQuery,
      };

      final response = await _httpClient.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Check for GraphQL errors
        if (jsonData.containsKey('errors')) {
          final errors = jsonData['errors'] as List<dynamic>;
          throw HandballClientException(
            'GraphQL errors: ${errors.map((e) => e['message']).join(', ')}',
          );
        }

        return HandballGamesResponse.fromJson(jsonData);
      } else {
        throw HandballClientException(
          'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      if (e is HandballClientException) {
        rethrow;
      }
      throw HandballClientException('Failed to fetch games: $e');
    }
  }

  /// Fetch games using provided configuration or default if not provided
  Future<HandballGamesResponse> getGamesWithDefaults({HandballConfig? config}) async {
    final configToUse = config ?? HandballConfig.defaultConfig;
    return getGames(
      clubId: configToUse.clubId,
      seasonId: configToUse.seasonId,
    );
  }

  /// Close the HTTP client
  void dispose() {
    _httpClient.close();
  }
}

/// Exception thrown by the handball client
class HandballClientException implements Exception {
  final String message;
  
  const HandballClientException(this.message);
  
  @override
  String toString() => 'HandballClientException: $message';
}