import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/handball_providers.dart';

class LevelReplacementsTab extends ConsumerStatefulWidget {
  final String? elemToEdit;
  
  const LevelReplacementsTab({
    super.key,
    this.elemToEdit,
  });

  @override
  ConsumerState<LevelReplacementsTab> createState() => _LevelReplacementsTabState();
}

class _LevelReplacementsTabState extends ConsumerState<LevelReplacementsTab> {
  late TextEditingController _originalLevelController;
  late TextEditingController _replacementLevelController;
  
  @override
  void initState() {
    super.initState();
    _originalLevelController = TextEditingController();
    _replacementLevelController = TextEditingController();
    
    // If a level to edit was provided, open the edit dialog after the build is complete
    if (widget.elemToEdit != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _editLevelReplacement(widget.elemToEdit!);
      });
    }
  }
  
  @override
  void dispose() {
    _originalLevelController.dispose();
    _replacementLevelController.dispose();
    super.dispose();
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
  
  // Find and edit a level replacement by original name
  void _editLevelReplacement(String originalName) {
    final levelReplacements = ref.read(levelReplacementsProvider);
    
    // Check if the level exists in replacements
    final levelReplacement = levelReplacements[originalName] ?? originalName;

    // Open dialog
    _showLevelReplacementDialog(
      originalName: originalName,
      replacementName: levelReplacement,
    );
  }

  @override
  Widget build(BuildContext context) {
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
}