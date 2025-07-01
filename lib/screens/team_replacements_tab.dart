import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/handball_providers.dart';

class TeamReplacementsTab extends ConsumerStatefulWidget {
  final String? elemToEdit;
  
  const TeamReplacementsTab({
    super.key,
    this.elemToEdit,
  });

  @override
  ConsumerState<TeamReplacementsTab> createState() => _TeamReplacementsTabState();
}

class _TeamReplacementsTabState extends ConsumerState<TeamReplacementsTab> {
  late TextEditingController _originalNameController;
  late TextEditingController _replacementNameController;
  
  @override
  void initState() {
    super.initState();
    _originalNameController = TextEditingController();
    _replacementNameController = TextEditingController();
    
    // If a team to edit was provided, open the edit dialog after the build is complete
    if (widget.elemToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editTeamReplacement(widget.elemToEdit!);
      });
    }
  }
  
  @override
  void dispose() {
    _originalNameController.dispose();
    _replacementNameController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
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
}