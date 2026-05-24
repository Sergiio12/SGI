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
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
          focusNode: _searchFocusNode,
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

          final isEmpty = search.results.isEmpty;

          return Column(
            children: [
              _buildFilterChips(search),
              Expanded(
                child: isEmpty ? _buildEmptyState(search) : _buildResults(search),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(SearchProvider search) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: BrainTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: BrainTheme.borderDark),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: l10n.searchAllTypes,
              selected: search.filter == SearchFilter.all,
              onSelected: () => search.setFilter(SearchFilter.all),
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: l10n.searchTypeTask,
              selected: search.filter == SearchFilter.tasks,
              onSelected: () => search.setFilter(SearchFilter.tasks),
              color: BrainTheme.accentBlue,
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: l10n.searchTypeProject,
              selected: search.filter == SearchFilter.projects,
              onSelected: () => search.setFilter(SearchFilter.projects),
              color: BrainTheme.accentOrange,
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: l10n.searchTypeNote,
              selected: search.filter == SearchFilter.notes,
              onSelected: () => search.setFilter(SearchFilter.notes),
              color: BrainTheme.accentGreen,
            ),
            const SizedBox(width: 6),
            _FilterChip(
              label: l10n.searchTypeGoal,
              selected: search.filter == SearchFilter.goals,
              onSelected: () => search.setFilter(SearchFilter.goals),
              color: BrainTheme.accentPurple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(SearchProvider search) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            '${AppLocalizations.of(context).noResults} "${search.query}"',
            style: TextStyle(
              color: BrainTheme.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(SearchProvider search) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (search.hasTasks)
          _buildCategorySection(
            l10n.searchTypeTask,
            BrainTheme.accentBlue,
            Icons.checklist_rounded,
            search.tasksResults,
          ),
        if (search.hasProjects)
          _buildCategorySection(
            l10n.searchTypeProject,
            BrainTheme.accentOrange,
            Icons.folder_open_outlined,
            search.projectsResults,
          ),
        if (search.hasNotes)
          _buildCategorySection(
            l10n.searchTypeNote,
            BrainTheme.accentGreen,
            Icons.sticky_note_2_outlined,
            search.notesResults,
          ),
        if (search.hasGoals)
          _buildCategorySection(
            l10n.searchTypeGoal,
            BrainTheme.accentPurple,
            Icons.track_changes_outlined,
            search.goalsResults,
          ),
      ],
    );
  }

  Widget _buildCategorySection(
    String title,
    Color color,
    IconData icon,
    List<SearchResult> results,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: BrainTheme.textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${results.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...results.map((result) => _buildResultTile(result)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildResultTile(SearchResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
        dense: true,
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? BrainTheme.accentPurple;
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? chipColor.withValues(alpha: 0.15)
              : BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? chipColor.withValues(alpha: 0.5)
                : BrainTheme.borderDark,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? chipColor : BrainTheme.textTertiary,
          ),
        ),
      ),
    );
  }
}
