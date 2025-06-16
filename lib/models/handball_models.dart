/// Handball game model that matches the GraphQL response structure
class HandballGame {
  final int? gameNumber;
  final String? objectId;
  final String? objectType;
  final bool? isLive;
  final int? seasonId;
  final String? gameDateTime;
  final int? homeTeamId;
  final String? homeTeamName;
  final String? homeTeamShortName;
  final int? homeTeamClubId;
  final int? homeTeamScore;
  final String? homeTeamScoreInterval;
  final int? awayTeamId;
  final String? awayTeamName;
  final String? awayTeamShortName;
  final int? awayTeamClubId;
  final int? awayTeamScore;
  final String? awayTeamScoreInterval;
  final String? venueName;
  final int? venueId;
  final String? type;
  final String? groupShortName;
  final String? leagueShortName;
  final int? gameStatusId;
  final int? gameTypeId;
  final int? gameGroupOrCupId;
  final String? typename;

  HandballGame({
    this.gameNumber,
    this.objectId,
    this.objectType,
    this.isLive,
    this.seasonId,
    this.gameDateTime,
    this.homeTeamId,
    this.homeTeamName,
    this.homeTeamShortName,
    this.homeTeamClubId,
    this.homeTeamScore,
    this.homeTeamScoreInterval,
    this.awayTeamId,
    this.awayTeamName,
    this.awayTeamShortName,
    this.awayTeamClubId,
    this.awayTeamScore,
    this.awayTeamScoreInterval,
    this.venueName,
    this.venueId,
    this.type,
    this.groupShortName,
    this.leagueShortName,
    this.gameStatusId,
    this.gameTypeId,
    this.gameGroupOrCupId,
    this.typename,
  });

  /// Create HandballGame from JSON response
  factory HandballGame.fromJson(Map<String, dynamic> json) {
    return HandballGame(
      gameNumber: _parseIntSafely(json['gameNumber']),
      objectId: json['objectId']?.toString(),
      objectType: json['objectType']?.toString(),
      isLive: json['isLive'] as bool?,
      seasonId: _parseIntSafely(json['seasonId']),
      gameDateTime: json['gameDateTime']?.toString(),
      homeTeamId: _parseIntSafely(json['homeTeamId']),
      homeTeamName: json['homeTeamName']?.toString(),
      homeTeamShortName: json['homeTeamShortName']?.toString(),
      homeTeamClubId: _parseIntSafely(json['homeTeamClubId']),
      homeTeamScore: _parseIntSafely(json['homeTeamScore']),
      homeTeamScoreInterval: json['homeTeamScoreInterval']?.toString(),
      awayTeamId: _parseIntSafely(json['awayTeamId']),
      awayTeamName: json['awayTeamName']?.toString(),
      awayTeamShortName: json['awayTeamShortName']?.toString(),
      awayTeamClubId: _parseIntSafely(json['awayTeamClubId']),
      awayTeamScore: _parseIntSafely(json['awayTeamScore']),
      awayTeamScoreInterval: json['awayTeamScoreInterval']?.toString(),
      venueName: json['venueName']?.toString(),
      venueId: _parseIntSafely(json['venueId']),
      type: json['type']?.toString(),
      groupShortName: json['groupShortName']?.toString(),
      leagueShortName: json['leagueShortName']?.toString(),
      gameStatusId: _parseIntSafely(json['gameStatusId']),
      gameTypeId: _parseIntSafely(json['gameTypeId']),
      gameGroupOrCupId: _parseIntSafely(json['gameGroupOrCupId']),
      typename: json['__typename']?.toString(),
    );
  }

  /// Safely parse integer values that might come as strings
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// Convert HandballGame to JSON
  Map<String, dynamic> toJson() {
    return {
      'gameNumber': gameNumber,
      'objectId': objectId,
      'objectType': objectType,
      'isLive': isLive,
      'seasonId': seasonId,
      'gameDateTime': gameDateTime,
      'homeTeamId': homeTeamId,
      'homeTeamName': homeTeamName,
      'homeTeamShortName': homeTeamShortName,
      'homeTeamClubId': homeTeamClubId,
      'homeTeamScore': homeTeamScore,
      'homeTeamScoreInterval': homeTeamScoreInterval,
      'awayTeamId': awayTeamId,
      'awayTeamName': awayTeamName,
      'awayTeamShortName': awayTeamShortName,
      'awayTeamClubId': awayTeamClubId,
      'awayTeamScore': awayTeamScore,
      'awayTeamScoreInterval': awayTeamScoreInterval,
      'venueName': venueName,
      'venueId': venueId,
      'type': type,
      'groupShortName': groupShortName,
      'leagueShortName': leagueShortName,
      'gameStatusId': gameStatusId,
      'gameTypeId': gameTypeId,
      'gameGroupOrCupId': gameGroupOrCupId,
      '__typename': typename,
    };
  }

  @override
  String toString() {
    return 'HandballGame(gameNumber: $gameNumber, homeTeam: $homeTeamName, awayTeam: $awayTeamName, score: $homeTeamScore-$awayTeamScore, date: $gameDateTime, venue: $venueName)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HandballGame) return false;
    if (objectId == null || other.objectId == null) {
      // If either objectId is null, compare all relevant fields
      return other.gameNumber == gameNumber &&
             other.homeTeamName == homeTeamName &&
             other.awayTeamName == awayTeamName &&
             other.gameDateTime == gameDateTime;
    }
    return other.objectId == objectId;
  }
  
  @override
  int get hashCode => objectId?.hashCode ??
    Object.hash(gameNumber, homeTeamName, awayTeamName, gameDateTime);
}

/// Response wrapper for GraphQL games query
class HandballGamesResponse {
  final List<HandballGame> games;

  HandballGamesResponse({required this.games});

  factory HandballGamesResponse.fromJson(Map<String, dynamic> json) {
    final gamesData = json['data']?['games'] as List<dynamic>? ?? [];
    final games = gamesData
        .map((gameJson) => HandballGame.fromJson(gameJson as Map<String, dynamic>))
        .toList();
    
    return HandballGamesResponse(games: games);
  }
}

/// Configuration for handball data retrieval
class HandballConfig {
  final int clubId;
  final int seasonId;

  const HandballConfig({
    required this.clubId,
    required this.seasonId,
  });

  /// Default configuration for NHB (Nyon Handball - La Cote)
  static const HandballConfig defaultConfig = HandballConfig(
    clubId: 330442,
    seasonId: 2024,
  );
  
  /// Create a copy of this config with optional new values
  HandballConfig copyWith({
    int? clubId,
    int? seasonId,
  }) {
    return HandballConfig(
      clubId: clubId ?? this.clubId,
      seasonId: seasonId ?? this.seasonId,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HandballConfig &&
        other.clubId == clubId &&
        other.seasonId == seasonId;
  }

  @override
  int get hashCode => Object.hash(clubId, seasonId);
}