import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import 'package:second_brain/l10n/app_localizations.dart';

import '../../config/theme.dart';
import '../../models/project.dart';
import '../../providers/projects_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/project_card.dart';
import '../../utils/notification_service_v2.dart';
import '../../widgets/skeleton_card.dart';

enum _ProjectSortBy { updatedAt, title, deadline, progress }

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  ProjectStatus? _statusFilter;
  _ProjectSortBy _sortBy = _ProjectSortBy.updatedAt;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _activeFilterCount() {
    var count = 0;
    if (_statusFilter != null) count++;
    if (_searchQuery.isNotEmpty) count++;
    return count;
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _statusFilter = null;
      _sortBy = _ProjectSortBy.updatedAt;
      _showSearch = false;
    });
  }

  List<Widget> _buildFilterChips(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[];
    if (_statusFilter != null) {
      final label = switch (_statusFilter!) {
        ProjectStatus.active => l10n.active,
        ProjectStatus.paused => 'Pausados',
        ProjectStatus.completed => l10n.statusCompleted,
        ProjectStatus.abandoned => 'Abandonados',
      };
      chips.add(_buildActiveFilterChip(label, () {
        setState(() => _statusFilter = null);
      }));
    }
    if (_searchQuery.isNotEmpty) {
      chips.add(_buildActiveFilterChip('"$_searchQuery"', () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      }));
    }
    return chips;
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onRemove) {
    return InputChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: BrainTheme.cardDark,
      labelStyle: TextStyle(color: BrainTheme.textPrimary),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) return const SkeletonGrid();
        final allProjects = provider.projects;

        if (allProjects.isEmpty) {
          return EmptyState(
            emoji: '🚀',
            title: AppLocalizations.of(context).emptyState,
            subtitle: AppLocalizations.of(context).emptyStateDescription,
            actionLabel: AppLocalizations.of(context).createProject,
            onAction: () => Navigator.pushNamed(context, '/project'),
          );
        }

        var filtered = allProjects.where((p) {
          if (_statusFilter != null && p.status != _statusFilter) return false;
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return p.title.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q) ||
              p.objective.toLowerCase().contains(q);
        }).toList();

        filtered.sort((a, b) {
          switch (_sortBy) {
            case _ProjectSortBy.title:
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            case _ProjectSortBy.deadline:
              final aDate = a.deadline ?? DateTime(9999);
              final bDate = b.deadline ?? DateTime(9999);
              return aDate.compareTo(bDate);
            case _ProjectSortBy.progress:
              return _projectProgress(b, provider)
                  .compareTo(_projectProgress(a, provider));
            case _ProjectSortBy.updatedAt:
              return b.updatedAt.compareTo(a.updatedAt);
          }
        });

        final active =
            filtered.where((p) => p.status == ProjectStatus.active).toList();
        final paused =
            filtered.where((p) => p.status == ProjectStatus.paused).toList();
        final completed =
            filtered.where((p) => p.status == ProjectStatus.completed).toList();
        final abandoned =
            filtered.where((p) => p.status == ProjectStatus.abandoned).toList();

        return Column(
          children: [
            _StatsBar(provider: provider),
            _FilterBar(
              statusFilter: _statusFilter,
              searchQuery: _searchQuery,
              showSearch: _showSearch,
              sortBy: _sortBy,
              activeFilterCount: _activeFilterCount(),
              onStatusFilterChanged: (s) => setState(() => _statusFilter = s),
              onSortChanged: (s) => setState(() => _sortBy = s),
              onToggleSearch: () => setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              }),
              onClearFilters: _clearFilters,
            ),
            if (_showSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).searchInProjects,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: BrainTheme.borderDark),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .slideY(begin: -0.2, end: 0),
              ),
            if (_buildFilterChips(context).isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ..._buildFilterChips(context),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _clearFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: BrainTheme.accentRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color:
                                  BrainTheme.accentRed.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.clear_all,
                                  size: 12, color: BrainTheme.accentRed),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context).clearFilters,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: BrainTheme.accentRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _searchQuery.isNotEmpty ? '🔍' : '📭',
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty
                            ? '${AppLocalizations.of(context).noResults} "$_searchQuery"'
                            : _statusFilter != null
                                ? '${AppLocalizations.of(context).no} ${AppLocalizations.of(context).projects.toLowerCase()} ${_statusLabel(_statusFilter!).toLowerCase()}'
                                : '${AppLocalizations.of(context).no} ${AppLocalizations.of(context).projects}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: BrainTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.loadProjects(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    children: [
                      if (active.isNotEmpty)
                        _buildSection(
                          context,
                          'Activos',
                          active,
                          BrainTheme.accentGreen,
                          Icons.play_arrow_rounded,
                          provider,
                        ),
                      if (paused.isNotEmpty)
                        _buildSection(
                          context,
                          'Pausados',
                          paused,
                          BrainTheme.accentOrange,
                          Icons.pause_rounded,
                          provider,
                        ),
                      if (completed.isNotEmpty)
                        _buildSection(
                          context,
                          AppLocalizations.of(context).statusCompleted,
                          completed,
                          BrainTheme.accentBlue,
                          Icons.check_rounded,
                          provider,
                        ),
                      if (abandoned.isNotEmpty)
                        _buildSection(
                          context,
                          'Abandonados',
                          abandoned,
                          BrainTheme.textTertiary,
                          Icons.stop_rounded,
                          provider,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _projectProgress(Project project, ProjectsProvider provider) {
    return 0.0;
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Project> projects,
    Color color,
    IconData icon,
    ProjectsProvider provider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: BrainTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${projects.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(projects.length, (index) {
          return ProjectCard(
            project: projects[index],
            onTap: () => Navigator.pushNamed(
              context,
              '/project',
              arguments: projects[index].id,
            ),
            onDelete: () => _deleteProject(context, projects[index], provider),
          )
              .animate()
              .fadeIn(
                duration: 300.ms,
                delay: (index * 60).ms,
              )
              .slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
        }),
      ],
    );
  }

  Future<void> _deleteProject(
      BuildContext context, Project project, ProjectsProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Text(AppLocalizations.of(context).itemDeleted,
            style: TextStyle(color: BrainTheme.textPrimary)),
        content: Text(
          '${AppLocalizations.of(context).no} "${project.title}"?',
          style: TextStyle(color: BrainTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context).cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: BrainTheme.accentRed,
                foregroundColor: Colors.white),
            child: Text(AppLocalizations.of(context).delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final pid = project.id;
      await provider.deleteProject(pid);
      if (context.mounted) {
        showSuccessNotification(
          '${AppLocalizations.of(context).itemDeleted}',
          actionLabel: AppLocalizations.of(context).undo,
          onAction: () => provider.restoreProject(pid),
        );
      }
    }
  }

  String _statusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return AppLocalizations.of(context).active;
      case ProjectStatus.paused:
        return 'Pausados';
      case ProjectStatus.completed:
        return AppLocalizations.of(context).statusCompleted;
      case ProjectStatus.abandoned:
        return 'Abandonados';
    }
  }
}

class _StatsBar extends StatelessWidget {
  final ProjectsProvider provider;

  _StatsBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.projects.length;
    final active = provider.activeProjects.length;
    final paused = provider.pausedProjects.length;
    final completed = provider.completedProjects.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrainTheme.accentOf(context).withValues(alpha: 0.12),
            BrainTheme.accentBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrainTheme.accentOf(context).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.folder_outlined,
            value: '$total',
            label: AppLocalizations.of(context).all,
            color: BrainTheme.accentOf(context),
          ),
          _StatItem(
            icon: Icons.play_arrow_rounded,
            value: '$active',
            label: AppLocalizations.of(context).active,
            color: BrainTheme.accentGreen,
          ),
          _StatItem(
            icon: Icons.pause_rounded,
            value: '$paused',
            label: 'Pausados',
            color: BrainTheme.accentOrange,
          ),
          _StatItem(
            icon: Icons.check_rounded,
            value: '$completed',
            label: AppLocalizations.of(context).completedTasks,
            color: BrainTheme.accentBlue,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.2, end: 0, curve: Curves.easeOut);
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: BrainTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: BrainTheme.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final ProjectStatus? statusFilter;
  final String searchQuery;
  final bool showSearch;
  final _ProjectSortBy sortBy;
  final int activeFilterCount;
  final ValueChanged<ProjectStatus?> onStatusFilterChanged;
  final ValueChanged<_ProjectSortBy> onSortChanged;
  final VoidCallback onToggleSearch;
  final VoidCallback onClearFilters;

  const _FilterBar({
    required this.statusFilter,
    required this.searchQuery,
    required this.showSearch,
    required this.sortBy,
    required this.activeFilterCount,
    required this.onStatusFilterChanged,
    required this.onSortChanged,
    required this.onToggleSearch,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _FilterChip(
                        label: AppLocalizations.of(context).all,
                        selected: statusFilter == null,
                        color: BrainTheme.accentOf(context),
                        onTap: () => onStatusFilterChanged(null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppLocalizations.of(context).active,
                        selected: statusFilter == ProjectStatus.active,
                        color: BrainTheme.accentGreen,
                        onTap: () => onStatusFilterChanged(
                          statusFilter == ProjectStatus.active
                              ? null
                              : ProjectStatus.active,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pausados',
                        selected: statusFilter == ProjectStatus.paused,
                        color: BrainTheme.accentOrange,
                        onTap: () => onStatusFilterChanged(
                          statusFilter == ProjectStatus.paused
                              ? null
                              : ProjectStatus.paused,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppLocalizations.of(context).statusCompleted,
                        selected: statusFilter == ProjectStatus.completed,
                        color: BrainTheme.accentBlue,
                        onTap: () => onStatusFilterChanged(
                          statusFilter == ProjectStatus.completed
                              ? null
                              : ProjectStatus.completed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Abandonados',
                        selected: statusFilter == ProjectStatus.abandoned,
                        color: BrainTheme.textTertiary,
                        onTap: () => onStatusFilterChanged(
                          statusFilter == ProjectStatus.abandoned
                              ? null
                              : ProjectStatus.abandoned,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _IconButton(
                icon: Icons.search,
                isActive: showSearch || searchQuery.isNotEmpty,
                activeColor: BrainTheme.accentOf(context),
                onTap: onToggleSearch,
              ),
              const SizedBox(width: 6),
              _SortDropdown(sortBy: sortBy, onChanged: onSortChanged),
              const SizedBox(width: 6),
              _FilterIconButton(
                icon: Icons.filter_list,
                isActive: activeFilterCount > 0,
                activeColor: BrainTheme.accentOf(context),
                badgeCount: activeFilterCount,
                onTap: onClearFilters,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected ? color.withValues(alpha: 0.4) : BrainTheme.borderDark,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? color : BrainTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.3)
                : BrainTheme.borderDark,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isActive ? activeColor : BrainTheme.textSecondary,
        ),
      ),
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final int badgeCount;
  final VoidCallback onTap;

  const _FilterIconButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.3)
                : BrainTheme.borderDark,
            width: 1,
          ),
        ),
        child: Badge(
          isLabelVisible: badgeCount > 0,
          label: Text('$badgeCount',
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? activeColor : BrainTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final _ProjectSortBy sortBy;
  final ValueChanged<_ProjectSortBy> onChanged;

  _SortDropdown({required this.sortBy, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrainTheme.borderDark, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_ProjectSortBy>(
          value: sortBy,
          isDense: true,
          dropdownColor: BrainTheme.cardDark,
          icon: Icon(Icons.sort, size: 18, color: BrainTheme.textSecondary),
          style: TextStyle(fontSize: 13, color: BrainTheme.textSecondary),
          items: _ProjectSortBy.values.map((sort) {
            String label;
            switch (sort) {
              case _ProjectSortBy.updatedAt:
                label = AppLocalizations.of(context).sortCreatedAt;
              case _ProjectSortBy.title:
                label = AppLocalizations.of(context).sortTitle;
              case _ProjectSortBy.deadline:
                label = AppLocalizations.of(context).sortDueDate;
              case _ProjectSortBy.progress:
                label = 'Progreso';
            }
            return DropdownMenuItem(
              value: sort,
              child: Text(label),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}
