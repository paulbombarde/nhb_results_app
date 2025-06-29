import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/handball_models.dart';
import '../providers/handball_providers.dart';
import 'image_generation_screen.dart';
import 'configuration_screen.dart';

class ResultsScreen extends ConsumerWidget {
  final DateTime selectedDate;
  
  const ResultsScreen({
    super.key,
    required this.selectedDate,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We don't want to clear selections automatically anymore
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   ref.read(selectedGamesProvider.notifier).clearSelection();
    // });
    
    // Get games for the selected date
    final gamesAsync = ref.watch(gamesForSelectedDateProvider);
    
    // Watch the selected games to ensure the UI updates when selection changes
    final selectedGames = ref.watch(selectedGamesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Game Results'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ConfigurationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Date header
          DateHeader(date: selectedDate),
          
          // Games list
          Expanded(
            child: gamesAsync.when(
              data: (games) {
                if (games.isEmpty) {
                  return const Center(
                    child: Text('No games found for this date'),
                  );
                }
                
                return GameResultsList(
                  games: games,
                  selectedGames: selectedGames,
                  onGameToggled: (game) {
                    // Use read instead of watch for actions
                    ref.read(selectedGamesProvider.notifier).toggleGameSelection(game);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text('Error loading games: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(gamesForSelectedDateProvider);
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer(
        builder: (context, ref, _) {
          final selectedGames = ref.watch(selectedGamesProvider);
          
          return AnimatedOpacity(
            opacity: selectedGames.isNotEmpty ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 300),
            child: FloatingActionButton.extended(
              onPressed: selectedGames.isNotEmpty
                ? () {
                    // Navigate to image generation screen with selected games
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageGenerationScreen(
                          selectedGames: selectedGames,
                        ),
                      ),
                    );
                  }
                : null,
              label: const Text('Generate'),
              icon: const Icon(Icons.image),
              backgroundColor: selectedGames.isNotEmpty ? Colors.blue : Colors.grey,
            ),
          );
        },
      ),
    );
  }
}

class DateHeader extends StatelessWidget {
  final DateTime date;
  
  const DateHeader({
    super.key,
    required this.date,
  });
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            dateFormat.format(date),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class GameResultsList extends ConsumerWidget {
  final List<HandballGame> games;
  final List<HandballGame> selectedGames;
  final Function(HandballGame) onGameToggled;
  
  const GameResultsList({
    super.key,
    required this.games,
    required this.selectedGames,
    required this.onGameToggled,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the selected games to ensure the list rebuilds when selection changes
    return ListView.builder(
      itemCount: games.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final game = games[index];
        final isSelected = selectedGames.any((g) => g.objectId == game.objectId);
        
        return GameResultCard(
          game: game,
          isSelected: isSelected,
          onToggle: () => onGameToggled(game),
        );
      },
    );
  }
}

class GameResultCard extends StatelessWidget {
  final HandballGame game;
  final bool isSelected;
  final VoidCallback onToggle;
  
  const GameResultCard({
    super.key,
    required this.game,
    required this.isSelected,
    required this.onToggle,
  });
  
  void _showTeamOptionsMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy + size.height,
        position.dx + size.width,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          value: 'home',
          child: Text('Edit "${game.homeTeamName}" replacement'),
        ),
        PopupMenuItem(
          value: 'away',
          child: Text('Edit "${game.awayTeamName}" replacement'),
        ),
      ],
    ).then((value) {
      if (value == null) return;
      
      String teamName = value == 'home' ? game.homeTeamName! : game.awayTeamName!;
      
      // Navigate to configuration screen and open team replacement dialog
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ConfigurationScreen(
            initialTab: 1, // Team Names tab
            teamToEdit: teamName,
          ),
        ),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? Colors.blue.shade50 : null,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            onToggle();
          },
          onLongPress: () {
            _showTeamOptionsMenu(context);
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Checkbox for selection
                Checkbox(
                  value: isSelected,
                  onChanged: (_) {
                    onToggle();
                  },
                ),
              const SizedBox(width: 8),
              // Game details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // League and venue info
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            game.leagueShortName ?? 'Unknown',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            game.venueName ?? 'Unknown venue',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Teams
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            game.homeTeamName ?? 'Home Team',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${game.homeTeamScore ?? "-"} - ${game.awayTeamScore ?? "-"}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            game.awayTeamName ?? 'Away Team',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (game.homeTeamScoreInterval != null || game.awayTeamScoreInterval != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Halftime: ${game.homeTeamScoreInterval ?? "-"} - ${game.awayTeamScoreInterval ?? "-"}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}