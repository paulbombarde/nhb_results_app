import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/handball_models.dart';
import '../providers/handball_providers.dart';

class ConfigurationScreen extends ConsumerStatefulWidget {
  final int initialTab;
  final String? elemToEdit;
  
  const ConfigurationScreen({
    super.key,
    this.initialTab = 0,
    this.elemToEdit,
  });

  @override
  ConsumerState<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends ConsumerState<ConfigurationScreen> with SingleTickerProviderStateMixin {
  late TextEditingController _clubIdController;
  late TextEditingController _seasonIdController;
  late TextEditingController _originalNameController;
  late TextEditingController _replacementNameController;
  late TextEditingController _originalLevelController;
  late TextEditingController _replacementLevelController;
  bool _hasChanges = false;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    final config = ref.read(handballConfigProvider);
    _clubIdController = TextEditingController(text: config.clubId.toString());
    _seasonIdController = TextEditingController(text: config.seasonId.toString());
    _originalNameController = TextEditingController();
    _replacementNameController = TextEditingController();
    _originalLevelController = TextEditingController();
    _replacementLevelController = TextEditingController();
    
    // Initialize tab controller with the initial tab from widget
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    
    // Add listeners to detect changes
    _clubIdController.addListener(_checkForChanges);
    _seasonIdController.addListener(_checkForChanges);
    
    // If a team to edit was provided, open the edit dialog after the build is complete
    if (widget.elemToEdit != null) {
      if ( widget.initialTab == 1 ) { // team tab
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _editTeamReplacement(widget.elemToEdit!);
        });
      }
      else if (widget.initialTab == 2 ) { // level tab
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _editLevelReplacement(widget.elemToEdit!);
        });
      }
    }
  }
  
  @override
  void dispose() {
    _clubIdController.dispose();
    _seasonIdController.dispose();
    _originalNameController.dispose();
    _replacementNameController.dispose();
    _originalLevelController.dispose();
    _replacementLevelController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  void _checkForChanges() {
    final config = ref.read(handballConfigProvider);
    final newClubId = int.tryParse(_clubIdController.text);
    final newSeasonId = int.tryParse(_seasonIdController.text);
    
    final hasChanges = 
        newClubId != null && 
        newSeasonId != null && 
        (newClubId != config.clubId || newSeasonId != config.seasonId);
    
    if (_hasChanges != hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }
  
  Future<void> _applyChanges() async {
    final newClubId = int.tryParse(_clubIdController.text);
    final newSeasonId = int.tryParse(_seasonIdController.text);
    
    if (newClubId != null && newSeasonId != null) {
      // Show loading indicator
      setState(() {
        _hasChanges = false;
      });
      
      // Update the configuration
      await ref.read(handballConfigProvider.notifier).updateConfig(
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

  // Show dialog to add or edit a team replacement
  void _showTeamReplacementDialog({String? originalName, String? replacementName}) {
    _originalNameController.text = originalName ?? '';
    _replacementNameController.text = replacementName ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(originalName == null ? 'Add Team Replacement' : 'Edit Team Replacement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _originalNameController,
              decoration: const InputDecoration(
                labelText: 'Original Team Name',
                hintText: 'Enter the original team name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _replacementNameController,
              decoration: const InputDecoration(
                labelText: 'Replacement Name',
                hintText: 'Enter the replacement name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final original = _originalNameController.text.trim();
              final replacement = _replacementNameController.text.trim();
              
              if (original.isNotEmpty && replacement.isNotEmpty) {
                // Add or update the replacement
                await ref.read(teamReplacementsProvider.notifier).addOrUpdateReplacement(original, replacement);
                
                // Show success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(originalName == null
                        ? 'Team replacement added successfully'
                        : 'Team replacement updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  // Reset team replacements to defaults
  Future<void> _resetTeamReplacements() async {
    await ref.read(teamReplacementsProvider.notifier).resetToDefaults();
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Team replacements reset to defaults'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
  
  // Find and edit a team replacement by original name
  void _editTeamReplacement(String originalName) {
    final teamReplacements = ref.read(teamReplacementsProvider);
    
    // Check if the team exists in replacements
    final teamReplacement = teamReplacements[originalName] ?? originalName;

    // Open dialog
    _showTeamReplacementDialog(
      originalName: originalName,
      replacementName: teamReplacement,
    );
  }
  
  // Find and edit a team replacement by original name
  void _editLevelReplacement(String originalName) {
    final levelReplacements = ref.read(levelReplacementsProvider);
    
    // Check if the team exists in replacements
    final levelReplacement = levelReplacements[originalName] ?? originalName;

    // Open dialog
    _showLevelReplacementDialog(
      originalName: originalName,
      replacementName: levelReplacement,
    );
  }
  
  // Build the API configuration tab
  Widget _buildApiConfigTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
  
  // Build the team replacements tab
  Widget _buildTeamReplacementsTab() {
    final teamReplacements = ref.watch(teamReplacementsProvider);
    final entries = teamReplacements.entries.toList();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Team Name Replacements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () => _showTeamReplacementDialog(),
                tooltip: 'Add new team replacement',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Swipe left to delete a replacement',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Team replacements list
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No team replacements defined'))
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Dismissible(
                        key: Key(entry.key),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          await ref.read(teamReplacementsProvider.notifier).removeReplacement(entry.key);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Team replacement removed'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(entry.key),
                            subtitle: Text('→ ${entry.value}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showTeamReplacementDialog(
                                originalName: entry.key,
                                replacementName: entry.value,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Reset button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: OutlinedButton(
              onPressed: _resetTeamReplacements,
              child: const Text('Reset to Default Replacements'),
            ),
          ),
        ],
      ),
    );
  }
  
  // Show dialog to add or edit a level replacement
  void _showLevelReplacementDialog({String? originalName, String? replacementName}) {
    _originalLevelController.text = originalName ?? '';
    _replacementLevelController.text = replacementName ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(originalName == null ? 'Add Level Replacement' : 'Edit Level Replacement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _originalLevelController,
              decoration: const InputDecoration(
                labelText: 'Original Level Name',
                hintText: 'Enter the original level name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _replacementLevelController,
              decoration: const InputDecoration(
                labelText: 'Replacement Name',
                hintText: 'Enter the replacement name',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final original = _originalLevelController.text.trim();
              final replacement = _replacementLevelController.text.trim();
              
              if (original.isNotEmpty && replacement.isNotEmpty) {
                // Add or update the replacement
                await ref.read(levelReplacementsProvider.notifier).addOrUpdateReplacement(original, replacement);
                
                // Show success message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(originalName == null
                        ? 'Level replacement added successfully'
                        : 'Level replacement updated successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
  
  // Reset level replacements to defaults
  Future<void> _resetLevelReplacements() async {
    await ref.read(levelReplacementsProvider.notifier).resetToDefaults();
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Level replacements reset to defaults'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }
  
  // Build the level replacements tab
  Widget _buildLevelReplacementsTab() {
    final levelReplacements = ref.watch(levelReplacementsProvider);
    final entries = levelReplacements.entries.toList();
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Level Name Replacements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: () => _showLevelReplacementDialog(),
                tooltip: 'Add new level replacement',
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Swipe left to delete a replacement',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Level replacements list
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('No level replacements defined'))
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Dismissible(
                        key: Key(entry.key),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16.0),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          await ref.read(levelReplacementsProvider.notifier).removeReplacement(entry.key);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Level replacement removed'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(entry.key),
                            subtitle: Text('→ ${entry.value}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _showLevelReplacementDialog(
                                originalName: entry.key,
                                replacementName: entry.value,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          // Reset button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: OutlinedButton(
              onPressed: _resetLevelReplacements,
              child: const Text('Reset Level Replacements'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        leading: BackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'API Settings'),
            Tab(text: 'Team Names'),
            Tab(text: 'Levels'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApiConfigTab(),
          _buildTeamReplacementsTab(),
          _buildLevelReplacementsTab(),
        ],
      ),
    );
  }
}