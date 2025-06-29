import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'settings_tab.dart';
import 'team_replacements_tab.dart';
import 'level_replacements_tab.dart';

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
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize tab controller with the initial tab from widget
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            Tab(text: 'Settings'),
            Tab(text: 'Teams'),
            Tab(text: 'Levels'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const ApiConfigTab(),
          TeamReplacementsTab(elemToEdit: widget.initialTab == 1 ? widget.elemToEdit : null),
          LevelReplacementsTab(elemToEdit: widget.initialTab == 2 ? widget.elemToEdit : null),
        ],
      ),
    );
  }
}