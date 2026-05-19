import 'package:flutter/material.dart';
import 'package:second_brain/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/search_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final search = context.read<SearchProvider>();
    final tasks = context.read<TasksProvider>().tasks;
    final projects = context.read<ProjectsProvider>().projects;
    final notes = context.read<NotesProvider>().notes;
    final goals = context.read<GoalsProvider>().goals;

    search.search(
      query: query,
      tasks: tasks,
      projects: projects,
      notes: notes,
      goals: goals,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: _onSearch,
          style: const TextStyle(fontSize: 17),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).searchTasks,
            border: InputBorder.none,
            filled: false,
          ),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                context.read<SearchProvider>().clear();
              },
            ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, search, _) {
          if (search.query.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('🔍', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).search,
                    style: TextStyle(
                      color: BrainTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).searchInTasks,
                    style: TextStyle(
                      color: BrainTheme.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          if (search.results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😕', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    '${AppLocalizations.of(context).noResults} para "${search.query}"',
                    style: TextStyle(
                      color: BrainTheme.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: search.results.length,
            itemBuilder: (context, index) {
              final result = search.results[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _typeColor(result.type).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(result.emoji,
                          style: const TextStyle(fontSize: 18)),
                    ),
                  ),
                  title: Text(
                    result.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: BrainTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    result.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: BrainTheme.textTertiary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: BrainTheme.textTertiary,
                  ),
                  onTap: () {
                    switch (result.type) {
                      case 'task':
                        Navigator.pushNamed(context, '/task',
                            arguments: result.id);
                        break;
                      case 'project':
                        Navigator.pushNamed(context, '/project',
                            arguments: result.id);
                        break;
                      case 'note':
                        Navigator.pushNamed(context, '/note',
                            arguments: result.id);
                        break;
                      case 'goal':
                        Navigator.pushNamed(context, '/goal',
                            arguments: result.id);
                        break;
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'task':
        return BrainTheme.accentBlue;
      case 'project':
        return BrainTheme.accentOrange;
      case 'note':
        return BrainTheme.accentGreen;
      case 'goal':
        return BrainTheme.accentPurple;
      default:
        return BrainTheme.accentPurple;
    }
  }
}
