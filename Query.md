# Handball Results App

A simplified handball data retrieval system that fetches game data from the Swiss Handball Federation's GraphQL API.

## Overview

This Flutter application demonstrates a clean, one-shot data retrieval approach for handball games. It connects to the official handball.ch GraphQL endpoint to fetch comprehensive game information for a specific club and season.

## Features

- **GraphQL Data Retrieval**: Direct connection to https://www.handball.ch/Umbraco/Api/MatchCenter/Query
- **Comprehensive Game Data**: Fetches all game details including teams, scores, venues, leagues, and dates
- **Flexible Filtering**: View all games, live games, completed games, or upcoming games
- **Clean Architecture**: Separated models, services, and UI components
- **Error Handling**: Robust error handling with user-friendly messages
- **Configurable Parameters**: Easy to change club ID and season ID

## Architecture

### Core Components

1. **Models** (`lib/models/handball_models.dart`)
   - `HandballGame`: Main game data model matching GraphQL response
   - `HandballGamesResponse`: Response wrapper for API calls
   - `HandballConfig`: Configuration for club and season parameters

2. **Services**
   - `HandballGraphQLClient` (`lib/services/handball_client.dart`): GraphQL client for API communication
   - `HandballService` (`lib/services/handball_service.dart`): Business logic layer with filtering capabilities

4. **Utilities** (`lib/utils/date_utils.dart`)
   - Date parsing and formatting utilities
   - Relative time calculations

## GraphQL Query

The application uses this GraphQL query to fetch game data:

```graphql
query getGames($clubId: Int, $seasonId: Int) {
  games(clubId: $clubId, seasonId: $seasonId) {
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
```

## Configuration

Default configuration (can be modified in `HandballConfig.defaultConfig`):
- **Club ID**: 330442 (Nyon HandBall La Côte)
- **Season ID**: 2024

## Usage

### Running the Demo

```bash
# Command line demo
dart lib/run_handball_demo.dart
```

### Using the Service

```dart
import 'services/handball_service.dart';

final service = HandballService();

// Get all games
final games = await service.getAllGames();

// Get live games only
final liveGames = await service.getLiveGames();

// Get games by team
final teamGames = await service.getGamesByTeam('Nyon');

// Custom club/season
final customGames = await service.getGames(
  clubId: 330442,
  seasonId: 2024,
);
```

## API Response Example

The API returns comprehensive game data:

```json
{
  "data": {
    "games": [
      {
        "gameNumber": 1,
        "homeTeamName": "Team A",
        "awayTeamName": "Team B",
        "homeTeamScore": 25,
        "awayTeamScore": 23,
        "venueName": "Sports Hall",
        "leagueShortName": "M1",
        "gameDateTime": "2024-09-08T17:30:00",
        "isLive": false
      }
    ]
  }
}
```

## Error Handling

The system includes comprehensive error handling:
- Network connectivity issues
- GraphQL API errors
- Data parsing errors
- Invalid configurations

## Dependencies

- `flutter`: UI framework
- `http`: HTTP client for GraphQL requests
- Standard Dart libraries for JSON parsing

## Testing

The application includes:
- Command-line demo for testing API connectivity

## Development Notes

### Type Safety
The models use safe type casting to handle potential string/integer mismatches from the API:

```dart
static int? _parseIntSafely(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}
```

### Extensibility
The architecture is designed for easy extension:
- Add new filtering methods to `HandballService`
- Extend `HandballGame` model for additional fields
- Create specialized UI components for different game types
