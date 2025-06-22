import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../models/handball_models.dart';
import '../match.dart';

/// Transformer class to convert HandballGame objects to Match objects
/// for use with the SVG image generator
class HandballTransformer {
  // Initialize French locale data
  static bool _localeInitialized = false;
  
  static void _initializeLocale() {
    if (!_localeInitialized) {
      initializeDateFormatting('fr_FR', null);
      _localeInitialized = true;
    }
  }
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
  static Match fromHandballGame(HandballGame game, [Map<String, String>? customReplacements]) {
    // Format the date
    final date = _formatDate(game.gameDateTime);
    
    // Get venue/place
    final place = game.venueName ?? 'Lieu inconnu';
    
    // Get league/level
    final level = game.leagueShortName ?? game.groupShortName ?? 'Niveau inconnu';
    
    // Get team names with potential replacements
    final team1 = _replaceTeamName(game.homeTeamName ?? 'Équipe inconnue', customReplacements);
    final team2 = _replaceTeamName(game.awayTeamName ?? 'Équipe inconnue', customReplacements);
    
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
  static List<Match> fromHandballGames(List<HandballGame> games, [Map<String, String>? customReplacements]) {
    return games.map((game) => fromHandballGame(game, customReplacements)).toList();
  }
  
  /// Format the date string from API format to display format
  /// Handles null or invalid date strings
  static String _formatDate(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) {
      return 'DATE INCONNUE';
    }
    
    try {
      // Ensure French locale is initialized
      _initializeLocale();
      
      // Parse the input date string (format: 2024-09-08T17:30:00)
      final dateTime = DateTime.parse(dateTimeString);
      
      // Format the date in French style: day_in_week day_in_month month
      final formatter = DateFormat('EEEE d MMMM', 'fr_FR');
      final formattedDate = formatter.format(dateTime);
      
      // Convert the entire date to uppercase
      return formattedDate.toUpperCase();
    } catch (e) {
      // Return the original string if parsing fails
      return dateTimeString;
    }
  }
  
  /// Replace team name if it exists in the replacement map
  /// Uses custom replacements if provided, otherwise falls back to default replacements
  static String _replaceTeamName(String originalName, [Map<String, String>? customReplacements]) {
    final replacements = customReplacements ?? teamNameReplacements;
    return replacements[originalName] ?? originalName;
  }
}