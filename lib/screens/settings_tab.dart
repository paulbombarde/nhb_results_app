import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/handball_models.dart';
import '../../providers/handball_providers.dart';

class ApiConfigTab extends ConsumerStatefulWidget {
  const ApiConfigTab({super.key});

  @override
  ConsumerState<ApiConfigTab> createState() => _ApiConfigTabState();
}

class _ApiConfigTabState extends ConsumerState<ApiConfigTab> {
  late TextEditingController _seniorMaleLevelController;
  late TextEditingController _seniorFemaleLevelController;
  late TextEditingController _clubIdController;
  late TextEditingController _seasonIdController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(handballConfigProvider);
    _seniorMaleLevelController = TextEditingController(text: config.seniorMaleLevel);
    _seniorFemaleLevelController = TextEditingController(text: config.seniorFemaleLevel);
    _clubIdController = TextEditingController(text: config.clubId.toString());
    _seasonIdController = TextEditingController(text: config.seasonId.toString());
    
    // Add listeners to detect changes
    _seniorMaleLevelController.addListener(_checkForChanges);
    _seniorFemaleLevelController.addListener(_checkForChanges);
    _clubIdController.addListener(_checkForChanges);
    _seasonIdController.addListener(_checkForChanges);
  }
  
  @override
  void dispose() {
    _seniorMaleLevelController.dispose();
    _seniorFemaleLevelController.dispose();
    _clubIdController.dispose();
    _seasonIdController.dispose();
    super.dispose();
  }
  
  void _checkForChanges() {
    final config = ref.read(handballConfigProvider);
    final newClubId = int.tryParse(_clubIdController.text);
    final newSeasonId = int.tryParse(_seasonIdController.text);
    final newSeniorMaleLevel = _seniorMaleLevelController.text;
    final newSeniorFemaleLevel = _seniorFemaleLevelController.text;
    
    final hasChanges =
        newClubId != null &&
        newSeasonId != null &&
        (newClubId != config.clubId ||
         newSeasonId != config.seasonId ||
         newSeniorMaleLevel != config.seniorMaleLevel ||
         newSeniorFemaleLevel != config.seniorFemaleLevel);
    
    if (_hasChanges != hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }
  
  Future<void> _applyChanges() async {
    final newClubId = int.tryParse(_clubIdController.text);
    final newSeasonId = int.tryParse(_seasonIdController.text);
    final newSeniorMaleLevel = _seniorMaleLevelController.text;
    final newSeniorFemaleLevel = _seniorFemaleLevelController.text;
    
    if (newClubId != null || newSeasonId != null) {
      // Show loading indicator
      setState(() {
        _hasChanges = false;
      });
      
      // Update the configuration
      await ref.read(handballConfigProvider.notifier).updateConfig(
        seniorMaleLevel: newSeniorMaleLevel,
        seniorFemaleLevel: newSeniorFemaleLevel,
        clubId: newClubId,
        seasonId: newSeasonId,
      );
      
      // Invalidate providers to refresh data
      ref.invalidate(datesWithGamesProvider);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
  
  Future<void> _resetToDefaults() async {
    // Show loading indicator
    setState(() {
      _hasChanges = false;
    });
    
    // Reset to default configuration
    await ref.read(handballConfigProvider.notifier).resetToDefaults();
    
    // Update text controllers
    final defaultConfig = HandballConfig.defaultConfig;
    _seniorMaleLevelController.text = defaultConfig.seniorMaleLevel;
    _seniorFemaleLevelController.text = defaultConfig.seniorFemaleLevel;
    _clubIdController.text = defaultConfig.clubId.toString();
    _seasonIdController.text = defaultConfig.seasonId.toString();
    
    // Invalidate providers to refresh data
    ref.invalidate(datesWithGamesProvider);
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset to default configuration'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Senior Teams',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Senior Male League field
          TextField(
            controller: _seniorMaleLevelController,
            decoration: const InputDecoration(
              labelText: 'Senior Male League',
              hintText: 'Enter the league',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
          
          // Senior Female League field
          TextField(
            controller: _seniorFemaleLevelController,
            decoration: const InputDecoration(
              labelText: 'Senior Female League',
              hintText: 'Enter the league',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),

          const Text(
            'API Configuration',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Club ID field
          TextField(
            controller: _clubIdController,
            decoration: const InputDecoration(
              labelText: 'Club ID',
              hintText: 'Enter the club ID',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          
          // Season ID field
          TextField(
            controller: _seasonIdController,
            decoration: const InputDecoration(
              labelText: 'Season ID',
              hintText: 'Enter the season ID',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          
          // Help text
          const Text(
            'Default: Club ID 330442 (Nyon HandBall La Côte), Season ID 2024',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          
          // Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Reset button
              OutlinedButton(
                onPressed: _resetToDefaults,
                child: const Text('Reset to Defaults'),
              ),
              
              // Apply button
              ElevatedButton(
                onPressed: _hasChanges ? _applyChanges : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasChanges ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Apply Changes'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}