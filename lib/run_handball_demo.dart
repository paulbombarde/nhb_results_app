// ignore_for_file: avoid_print

import 'dart:io';
import 'services/handball_service.dart';
import 'models/handball_models.dart';

/// Demo application to test handball data retrieval
Future<void> main() async {
  print('🏐 Handball Data Retrieval Demo');
  print('================================');
  
  final service = HandballService();
  
  try {
    print('\n📡 Fetching handball games...');
    print('Club ID: ${HandballConfig.defaultConfig.clubId}');
    print('Season ID: ${HandballConfig.defaultConfig.seasonId}');
    print('Endpoint: https://www.handball.ch/Umbraco/Api/MatchCenter/Query');
    
    final games = await service.getAllGames();
    
    print('\n✅ Successfully fetched ${games.length} games!');
    print('=' * 50);
    
    if (games.isEmpty) {
      print('No games found for the specified club and season.');
      return;
    }
    
    // Display all games
    print('\n📋 ALL GAMES:');
    print('-' * 50);
    for (int i = 0; i < games.length; i++) {
      final game = games[i];
      print('${i + 1}. ${_formatGame(game)}');
    }
    
    // Display live games
    final liveGames = await service.getLiveGames();
    if (liveGames.isNotEmpty) {
      print('\n🔴 LIVE GAMES (${liveGames.length}):');
      print('-' * 50);
      for (final game in liveGames) {
        print('• ${_formatGame(game)}');
      }
    }
    
    // Display completed games
    final completedGames = await service.getCompletedGames();
    if (completedGames.isNotEmpty) {
      print('\n✅ COMPLETED GAMES (${completedGames.length}):');
      print('-' * 50);
      for (final game in completedGames) {
        print('• ${_formatGame(game)}');
      }
    }
    
    // Display upcoming games
    final upcomingGames = await service.getUpcomingGames();
    if (upcomingGames.isNotEmpty) {
      print('\n⏰ UPCOMING GAMES (${upcomingGames.length}):');
      print('-' * 50);
      for (final game in upcomingGames) {
        print('• ${_formatGame(game)}');
      }
    }
    
    // Display leagues
    final leagues = games
        .map((g) => g.leagueShortName)
        .where((l) => l != null && l.isNotEmpty)
        .toSet()
        .toList();
    
    if (leagues.isNotEmpty) {
      print('\n🏆 LEAGUES FOUND:');
      print('-' * 50);
      for (final league in leagues) {
        final leagueGames = games.where((g) => g.leagueShortName == league).length;
        print('• $league ($leagueGames games)');
      }
    }
    
    // Display venues
    final venues = games
        .map((g) => g.venueName)
        .where((v) => v != null && v.isNotEmpty)
        .toSet()
        .toList();
    
    if (venues.isNotEmpty) {
      print('\n🏟️ VENUES:');
      print('-' * 50);
      for (final venue in venues) {
        final venueGames = games.where((g) => g.venueName == venue).length;
        print('• $venue ($venueGames games)');
      }
    }
    
    print('\n🎉 Demo completed successfully!');
    
  } catch (e) {
    print('\n❌ Error occurred: $e');
    exit(1);
  } finally {
    service.dispose();
  }
}

/// Format a game for display
String _formatGame(HandballGame game) {
  final homeTeam = game.homeTeamName ?? 'Unknown';
  final awayTeam = game.awayTeamName ?? 'Unknown';
  final homeScore = game.homeTeamScore?.toString() ?? '-';
  final awayScore = game.awayTeamScore?.toString() ?? '-';
  final venue = game.venueName ?? 'Unknown venue';
  final league = game.leagueShortName ?? 'Unknown league';
  final date = game.gameDateTime ?? 'Unknown date';
  final isLive = game.isLive == true ? ' 🔴 LIVE' : '';
  
  return '$homeTeam vs $awayTeam ($homeScore:$awayScore) - $venue - $league - $date$isLive';
}

/// Interactive demo that allows user to test different configurations
Future<void> runInteractiveDemo() async {
  print('🏐 Interactive Handball Demo');
  print('============================');
  
  final service = HandballService();
  
  while (true) {
    print('\nChoose an option:');
    print('1. Fetch all games (default config)');
    print('2. Fetch games by custom club/season');
    print('3. Search games by team name');
    print('4. Show live games only');
    print('5. Show games by league');
    print('6. Exit');
    print('\nEnter your choice (1-6): ');
    
    final input = stdin.readLineSync();
    
    try {
      switch (input) {
        case '1':
          await _showAllGames(service);
          break;
        case '2':
          await _showCustomGames(service);
          break;
        case '3':
          await _searchByTeam(service);
          break;
        case '4':
          await _showLiveGames(service);
          break;
        case '5':
          await _showGamesByLeague(service);
          break;
        case '6':
          print('Goodbye! 👋');
          service.dispose();
          return;
        default:
          print('Invalid choice. Please enter 1-6.');
      }
    } catch (e) {
      print('❌ Error: $e');
    }
  }
}

Future<void> _showAllGames(HandballService service) async {
  print('\n📡 Fetching all games...');
  final games = await service.getAllGames();
  print('Found ${games.length} games:');
  for (final game in games) {
    print('• ${_formatGame(game)}');
  }
}

Future<void> _showCustomGames(HandballService service) async {
  print('Enter club ID: ');
  final clubIdStr = stdin.readLineSync();
  print('Enter season ID: ');
  final seasonIdStr = stdin.readLineSync();
  
  final clubId = int.tryParse(clubIdStr ?? '');
  final seasonId = int.tryParse(seasonIdStr ?? '');
  
  if (clubId == null || seasonId == null) {
    print('Invalid input. Please enter valid numbers.');
    return;
  }
  
  print('\n📡 Fetching games for club $clubId, season $seasonId...');
  final games = await service.getGames(clubId: clubId, seasonId: seasonId);
  print('Found ${games.length} games:');
  for (final game in games) {
    print('• ${_formatGame(game)}');
  }
}

Future<void> _searchByTeam(HandballService service) async {
  print('Enter team name to search: ');
  final teamName = stdin.readLineSync();
  
  if (teamName == null || teamName.isEmpty) {
    print('Please enter a valid team name.');
    return;
  }
  
  print('\n🔍 Searching for games with team: $teamName...');
  final games = await service.getGamesByTeam(teamName);
  print('Found ${games.length} games:');
  for (final game in games) {
    print('• ${_formatGame(game)}');
  }
}

Future<void> _showLiveGames(HandballService service) async {
  print('\n🔴 Fetching live games...');
  final games = await service.getLiveGames();
  print('Found ${games.length} live games:');
  for (final game in games) {
    print('• ${_formatGame(game)}');
  }
}

Future<void> _showGamesByLeague(HandballService service) async {
  print('Enter league name: ');
  final leagueName = stdin.readLineSync();
  
  if (leagueName == null || leagueName.isEmpty) {
    print('Please enter a valid league name.');
    return;
  }
  
  print('\n🏆 Fetching games for league: $leagueName...');
  final games = await service.getGamesByLeague(leagueName);
  print('Found ${games.length} games:');
  for (final game in games) {
    print('• ${_formatGame(game)}');
  }
}