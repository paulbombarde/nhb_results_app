import 'dart:math';

class Match {
  final String date;
  final String place;
  final String level;
  final String team1;
  final String team2;
  final String score1;
  final String score2;

  Match({
    required this.date,
    required this.place,
    required this.level,
    required this.team1,
    required this.team2,
    required this.score1,
    required this.score2,
  });
}

// Dummy data for testing and development
final List<Match> dummyMatches = [
  Match(
    date: "Samedi 10 Septembre",
    place: "Stadium A",
    level: "Premier League",
    team1: "Team Alpha",
    team2: "Team Beta",
    score1: "10",
    score2: "20",
  ),
  Match(
    date: "Samedi 10 Septembre",
    place: "Arena Central",
    level: "Championship",
    team1: "Lions FC",
    team2: "Eagles United",
    score1: "25",
    score2: "18",
  ),
  Match(
    date: "Samedi 10 Septembre",
    place: "Sports Complex B",
    level: "Division 1",
    team1: "Thunder Bolts",
    team2: "Storm Riders",
    score1: "32",
    score2: "28",
  ),
  Match(
    date: "Dimanche 11 Septembre",
    place: "Metropolitan Stadium",
    level: "Premier League",
    team1: "Fire Dragons",
    team2: "Ice Wolves",
    score1: "15",
    score2: "22",
  ),
  Match(
    date: "Dimanche 11 Septembre",
    place: "Victory Arena",
    level: "Championship",
    team1: "Golden Hawks",
    team2: "Silver Sharks",
    score1: "41",
    score2: "35",
  ),
  Match(
    date: "Dimanche 11 Septembre",
    place: "Elite Sports Center",
    level: "Division 1",
    team1: "Crimson Tigers",
    team2: "Azure Panthers",
    score1: "29",
    score2: "31",
  ),
];

/// Selects a random subset of matches (up to 4 matches) from the available dummy matches
List<Match> getRandomMatches(int numMatches) {
  final random = Random();
  final availableMatches = List<Match>.from(dummyMatches);
  
  // Shuffle the list and take the first numMatches
  availableMatches.shuffle(random);
  return availableMatches.take(numMatches).toList();
}