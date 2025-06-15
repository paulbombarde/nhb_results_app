import 'package:intl/intl.dart';
import '../models/handball_models.dart';
import '../match.dart';

/// Transformer class to convert HandballGame objects to Match objects
/// for use with the SVG image generator
class HandballTransformer {
  /// Map of team name replacements for better display in templates
  /// Original team name -> Display name
  static const Map<String, String> teamNameReplacements = {
    'Nyon Handball - La Côte': 'NHB La Côte',
    'Nyon Handball - La Cote': 'NHB La Côte',
    'Nyon HandBall - La Côte': 'NHB La Côte',
    'Nyon HandBall - La Cote': 'NHB La Côte',
    'Nyon HB - La Côte': 'NHB La Côte',
    'Nyon HB - La Cote': 'NHB La Côte',
    'Nyon HB': 'NHB La Côte',
    "Nyon HandBall La Côte": "NHB La Côte",
    "Lausanne-Ville/Cugy Handball": "LVC Handball",
    "Lausanne-Ville/Cugy Handball 2": "LVC Handball 2",
    "Lancy Plan-les-Ouates Hb": "Lancy PLO",
    "SG Genève Paquis - Lancy PLO": "Genève Paquis - Lancy",
    "SG Genève /TCGG/ Nyon": "SG Genève/TCGG/Nyon",
    "SG Wacker Thun 2 / Steffisburg": "Wacker Thun/Steffisburg",
    "SG Troinex / Chênois Genève": "SG Troinex/Chênois",
  };

  /// Convert a single HandballGame to a Match object
  /// Handles null values and formats data appropriately
  static Match fromHandballGame(HandballGame game) {
    // Format the date
    final date = _formatDate(game.gameDateTime);
    
    // Get venue/place
    final place = game.venueName ?? 'Lieu inconnu';
    
    // Get league/level
    final level = game.leagueShortName ?? game.groupShortName ?? 'Niveau inconnu';
    
    // Get team names with potential replacements
    final team1 = _replaceTeamName(game.homeTeamName ?? 'Équipe inconnue');
    final team2 = _replaceTeamName(game.awayTeamName ?? 'Équipe inconnue');
    
    // Get scores (or placeholder if not available)
    final score1 = game.homeTeamScore?.toString() ?? '-';
    final score2 = game.awayTeamScore?.toString() ?? '-';
    
    return Match(
      date: date,
      place: place,
      level: level,
      team1: team1,
      team2: team2,
      score1: score1,
      score2: score2,
    );
  }

  /// Convert a list of HandballGame objects to a list of Match objects
  static List<Match> fromHandballGames(List<HandballGame> games) {
    return games.map((game) => fromHandballGame(game)).toList();
  }
  
  /// Format the date string from API format to display format
  /// Handles null or invalid date strings
  static String _formatDate(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'Date inconnue';
    }
    
    try {
      // Parse the input date string (format: 2024-09-08T17:30:00)
      final dateTime = DateTime.parse(dateTimeString);
      
      // Format the date in French style
      final formatter = DateFormat('EEEE d MMMM', 'fr_FR');
      return _capitalizeFirstLetter(formatter.format(dateTime));
    } catch (e) {
      // Return the original string if parsing fails
      return dateTimeString;
    }
  }
  
  /// Replace team name if it exists in the replacement map
  static String _replaceTeamName(String originalName) {
    return teamNameReplacements[originalName] ?? originalName;
  }
  
  /// Capitalize the first letter of a string
  static String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}