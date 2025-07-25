import 'package:flutter_test/flutter_test.dart';
import 'package:nhb_results_app/models/handball_models.dart';
import 'package:nhb_results_app/transformers/handball_transformer.dart';

void main() {
  group('HandballTransformer', () {
    test('should format date in French with day of week, day of month, and month name', () {
      // Arrange
      final game = HandballGame(
        gameDateTime: '2024-01-15T18:30:00', // Monday, January 15, 2024
        homeTeamName: 'Home Team',
        awayTeamName: 'Away Team',
        venueName: 'Test Venue',
        leagueShortName: 'Test League',
      );

      // Act
      final match = HandballTransformer.fromHandballGame(game);

      // Assert
      // Should be "LUNDI 15 JANVIER" (Monday 15 January in French, all uppercase)
      expect(match.date, equals('LUNDI 15 JANVIER'));
    });

    test('should format date for different days and months in French', () {
      // Test different dates to ensure all French day and month names work correctly
      final testCases = [
        {
          'input': '2024-01-01T12:00:00', // Monday, January 1, 2024
          'expected': 'LUNDI 1 JANVIER'
        },
        {
          'input': '2024-02-14T12:00:00', // Wednesday, February 14, 2024
          'expected': 'MERCREDI 14 FÉVRIER'
        },
        {
          'input': '2024-03-15T12:00:00', // Friday, March 15, 2024
          'expected': 'VENDREDI 15 MARS'
        },
        {
          'input': '2024-04-20T12:00:00', // Saturday, April 20, 2024
          'expected': 'SAMEDI 20 AVRIL'
        },
        {
          'input': '2024-05-12T12:00:00', // Sunday, May 12, 2024
          'expected': 'DIMANCHE 12 MAI'
        },
        {
          'input': '2024-06-18T12:00:00', // Tuesday, June 18, 2024
          'expected': 'MARDI 18 JUIN'
        },
        {
          'input': '2024-07-25T12:00:00', // Thursday, July 25, 2024
          'expected': 'JEUDI 25 JUILLET'
        },
        {
          'input': '2024-08-10T12:00:00', // Saturday, August 10, 2024
          'expected': 'SAMEDI 10 AOÛT'
        },
        {
          'input': '2024-09-05T12:00:00', // Thursday, September 5, 2024
          'expected': 'JEUDI 5 SEPTEMBRE'
        },
        {
          'input': '2024-10-22T12:00:00', // Tuesday, October 22, 2024
          'expected': 'MARDI 22 OCTOBRE'
        },
        {
          'input': '2024-11-30T12:00:00', // Saturday, November 30, 2024
          'expected': 'SAMEDI 30 NOVEMBRE'
        },
        {
          'input': '2024-12-25T12:00:00', // Wednesday, December 25, 2024
          'expected': 'MERCREDI 25 DÉCEMBRE'
        },
      ];

      for (final testCase in testCases) {
        // Arrange
        final game = HandballGame(
          gameDateTime: testCase['input'],
          homeTeamName: 'Home Team',
          awayTeamName: 'Away Team',
          venueName: 'Test Venue',
          leagueShortName: 'Test League',
        );

        // Act
        final match = HandballTransformer.fromHandballGame(game);

        // Assert
        expect(match.date, equals(testCase['expected']),
            reason: 'Failed for date: ${testCase['input']}');
      }
    });

    test('should handle null or empty date string gracefully', () {
      // Arrange
      final gameWithNullDate = HandballGame(
        gameDateTime: null,
        homeTeamName: 'Home Team',
        awayTeamName: 'Away Team',
      );

      final gameWithEmptyDate = HandballGame(
        gameDateTime: '',
        homeTeamName: 'Home Team',
        awayTeamName: 'Away Team',
      );

      // Act
      final matchWithNullDate = HandballTransformer.fromHandballGame(gameWithNullDate);
      final matchWithEmptyDate = HandballTransformer.fromHandballGame(gameWithEmptyDate);

      // Assert
      expect(matchWithNullDate.date, equals('DATE INCONNUE'));
      expect(matchWithEmptyDate.date, equals('DATE INCONNUE'));
    });

    test('should handle invalid date string gracefully', () {
      // Arrange
      final gameWithInvalidDate = HandballGame(
        gameDateTime: 'not-a-date',
        homeTeamName: 'Home Team',
        awayTeamName: 'Away Team',
      );

      // Act
      final match = HandballTransformer.fromHandballGame(gameWithInvalidDate);

      // Assert
      expect(match.date, equals('not-a-date'));
    });
    
    test('should apply team name replacements correctly', () {
      // Arrange
      final game = HandballGame(
        gameDateTime: '2024-01-15T18:30:00',
        homeTeamName: 'Original Team 1',
        awayTeamName: 'Original Team 2',
        venueName: 'Test Venue',
        leagueShortName: 'Test League',
      );
      
      final customReplacements = {
        'Original Team 1': 'Replaced Team 1',
        'Original Team 2': 'Replaced Team 2',
      };
      
      // Act
      final match = HandballTransformer.fromHandballGame(game, customReplacements);
      
      // Assert
      expect(match.team1, equals('Replaced Team 1'));
      expect(match.team2, equals('Replaced Team 2'));
    });
    
    test('should apply level name replacements correctly', () {
      // Arrange
      final game = HandballGame(
        gameDateTime: '2024-01-15T18:30:00',
        homeTeamName: 'Home Team',
        awayTeamName: 'Away Team',
        venueName: 'Test Venue',
        leagueShortName: 'Original Level',
      );
      
      final teamReplacements = <String, String>{};
      final levelReplacements = {
        'Original Level': 'Replaced Level',
      };
      
      // Act
      final match = HandballTransformer.fromHandballGame(game, teamReplacements, levelReplacements);
      
      // Assert
      expect(match.level, equals('Replaced Level'));
    });
    
    test('should apply both team and level replacements correctly', () {
      // Arrange
      final game = HandballGame(
        gameDateTime: '2024-01-15T18:30:00',
        homeTeamName: 'Original Team 1',
        awayTeamName: 'Original Team 2',
        venueName: 'Test Venue',
        leagueShortName: 'Original Level',
      );
      
      final teamReplacements = {
        'Original Team 1': 'Replaced Team 1',
        'Original Team 2': 'Replaced Team 2',
      };
      
      final levelReplacements = {
        'Original Level': 'Replaced Level',
      };
      
      // Act
      final match = HandballTransformer.fromHandballGame(game, teamReplacements, levelReplacements);
      
      // Assert
      expect(match.team1, equals('Replaced Team 1'));
      expect(match.team2, equals('Replaced Team 2'));
      expect(match.level, equals('Replaced Level'));
    });
    
    test('should handle empty level replacements map correctly', () {
      // Arrange
      final game = HandballGame(
        gameDateTime: '2024-01-15T18:30:00',
        homeTeamName: 'Home Team',
        awayTeamName: 'Away Team',
        venueName: 'Test Venue',
        leagueShortName: 'Original Level',
      );
      
      final teamReplacements = <String, String>{};
      final levelReplacements = <String, String>{};
      
      // Act
      final match = HandballTransformer.fromHandballGame(game, teamReplacements, levelReplacements);
      
      // Assert
      expect(match.level, equals('Original Level'));
    });

    test('should set template to null when seniorTeamLevelsToTemplates is not provided', () {
      // Arrange
      final game = HandballGame(
        gameDateTime: '2024-01-15T18:30:00',
        homeTeamName: 'Home Team',
        awayTeamName: 'Away Team',
        venueName: 'Test Venue',
        leagueShortName: 'Test League',
      );
      
      // Act
      final match = HandballTransformer.fromHandballGame(game);
      
      // Assert
      expect(match.template, isNull);
    });

    test('should set template correctly when seniorTeamLevelsToTemplates is provided', () {
      // Arrange
      final game = HandballGame(
        gameDateTime: '2024-01-15T18:30:00',
        homeTeamName: 'Home Team',
        awayTeamName: 'Away Team',
        venueName: 'Test Venue',
        leagueShortName: 'Test League',
      );
      
      final teamReplacements = <String, String>{};
      final levelReplacements = <String, String>{};
      final seniorTeamLevelsToTemplates = {
        'Test League': 'template_1',
        'Another League': 'template_2',
      };
      
      // Act
      final match = HandballTransformer.fromHandballGame(
        game,
        teamReplacements,
        levelReplacements,
        seniorTeamLevelsToTemplates
      );
      
      // Assert
      expect(match.template, equals('template_1'));
    });

    test('should set template to null when level is not in seniorTeamLevelsToTemplates', () {
      // Arrange
      final game = HandballGame(
        gameDateTime: '2024-01-15T18:30:00',
        homeTeamName: 'Home Team',
        awayTeamName: 'Away Team',
        venueName: 'Test Venue',
        leagueShortName: 'Test League',
      );
      
      final teamReplacements = <String, String>{};
      final levelReplacements = <String, String>{};
      final seniorTeamLevelsToTemplates = {
        'Another League': 'template_2',
      };
      
      // Act
      final match = HandballTransformer.fromHandballGame(
        game,
        teamReplacements,
        levelReplacements,
        seniorTeamLevelsToTemplates
      );
      
      // Assert
      expect(match.template, isNull);
    });

    test('should apply level replacements before looking up template', () {
      // Arrange
      final game = HandballGame(
        gameDateTime: '2024-01-15T18:30:00',
        homeTeamName: 'Home Team',
        awayTeamName: 'Away Team',
        venueName: 'Test Venue',
        leagueShortName: 'Original Level',
      );
      
      final teamReplacements = <String, String>{};
      final levelReplacements = {
        'Original Level': 'Replaced Level',
      };
      final seniorTeamLevelsToTemplates = {
        'Replaced Level': 'template_for_replaced_level',
      };
      
      // Act
      final match = HandballTransformer.fromHandballGame(
        game,
        teamReplacements,
        levelReplacements,
        seniorTeamLevelsToTemplates
      );
      
      // Assert
      expect(match.level, equals('Replaced Level'));
      expect(match.template, equals('template_for_replaced_level'));
    });
  });
}