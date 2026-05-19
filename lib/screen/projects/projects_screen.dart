import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/project.dart';
import '../../providers/projects_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/project_card.dart';

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

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsProvider>(
      builder: (context, provider, _) {
        final allProjects = provider.projects;

        if (allProjects.isEmpty) {
          return EmptyState(
            emoji: '🚀',
            title: 'Sin proyectos aun',
            subtitle: 'Crea un proyecto para agrupar tareas, notas y objetivos.',
            actionLabel: 'Crear proyecto',
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
              return _projectProgress(b, provider).compareTo(_projectProgress(a, provider));
            case _ProjectSortBy.updatedAt:
              return b.updatedAt.compareTo(a.updatedAt);
          }
        });

        final active = filtered.where((p) => p.status == ProjectStatus.active).toList();
        final paused = filtered.where((p) => p.status == ProjectStatus.paused).toList();
        final completed = filtered.where((p) => p.status == ProjectStatus.completed).toList();
        final abandoned = filtered.where((p) => p.status == ProjectStatus.abandoned).toList();

        return Column(
          children: [
            _StatsBar(provider: provider),
            _FilterBar(
              statusFilter: _statusFilter,
              searchQuery: _searchQuery,
              showSearch: _showSearch,
              sortBy: _sortBy,
              onStatusFilterChanged: (s) => setState(() => _statusFilter = s),
              onSortChanged: (s) => setState(() => _sortBy = s),
              onToggleSearch: () => setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              }),
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
                    hintText: 'Buscar proyectos...',
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
                ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.2, end: 0),
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
                            ? 'Sin resultados para "$_searchQuery"'
                            : _statusFilter != null
                                ? 'No hay proyectos ${_statusLabel(_statusFilter!).toLowerCase()}'
                                : 'Sin proyectos',
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
                        'Finalizados',
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
          ).animate().fadeIn(
            duration: 300.ms,
            delay: (index * 60).ms,
          ).slideX(begin: 0.05, end: 0, curve: Curves.easeOut);
        }),
      ],
    );
  }

  Future<void> _deleteProject(BuildContext context, Project project, ProjectsProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Text('Mover a papelera',
            style: TextStyle(color: BrainTheme.textPrimary)),
        content: Text(
          '¿Deseas mover "${project.title}" a la papelera?',
          style: TextStyle(color: BrainTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: BrainTheme.accentRed,
                foregroundColor: Colors.white),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await provider.deleteProject(project.id);
    }
  }

  String _statusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active: return 'Activos';
      case ProjectStatus.paused: return 'Pausados';
      case ProjectStatus.completed: return 'Finalizados';
      case ProjectStatus.abandoned: return 'Abandonados';
    }
  }

}

class _StatsBar extends StatelessWidget {
  final ProjectsProvider provider;

  const _StatsBar({required this.provider});

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
            BrainTheme.accentPurple.withValues(alpha: 0.12),
            BrainTheme.accentBlue.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrainTheme.accentPurple.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.folder_outlined,
            value: '$total',
            label: 'Total',
            color: BrainTheme.accentPurple,
          ),
          _StatItem(
            icon: Icons.play_arrow_rounded,
            value: '$active',
            label: 'Activos',
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
            label: 'Complet.',
            color: BrainTheme.accentBlue,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0, curve: Curves.easeOut);
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
  final ValueChanged<ProjectStatus?> onStatusFilterChanged;
  final ValueChanged<_ProjectSortBy> onSortChanged;
  final VoidCallback onToggleSearch;

  const _FilterBar({
    required this.statusFilter,
    required this.searchQuery,
    required this.showSearch,
    required this.sortBy,
    required this.onStatusFilterChanged,
    required this.onSortChanged,
    required this.onToggleSearch,
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
                        label: 'Todos',
                        selected: statusFilter == null,
                        color: BrainTheme.accentPurple,
                        onTap: () => onStatusFilterChanged(null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Activos',
                        selected: statusFilter == ProjectStatus.active,
                        color: BrainTheme.accentGreen,
                        onTap: () => onStatusFilterChanged(
                          statusFilter == ProjectStatus.active ? null : ProjectStatus.active,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Pausados',
                        selected: statusFilter == ProjectStatus.paused,
                        color: BrainTheme.accentOrange,
                        onTap: () => onStatusFilterChanged(
                          statusFilter == ProjectStatus.paused ? null : ProjectStatus.paused,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Finalizados',
                        selected: statusFilter == ProjectStatus.completed,
                        color: BrainTheme.accentBlue,
                        onTap: () => onStatusFilterChanged(
                          statusFilter == ProjectStatus.completed ? null : ProjectStatus.completed,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Abandonados',
                        selected: statusFilter == ProjectStatus.abandoned,
                        color: BrainTheme.textTertiary,
                        onTap: () => onStatusFilterChanged(
                          statusFilter == ProjectStatus.abandoned ? null : ProjectStatus.abandoned,
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
                activeColor: BrainTheme.accentPurple,
                onTap: onToggleSearch,
              ),
              const SizedBox(width: 6),
              _SortDropdown(sortBy: sortBy, onChanged: onSortChanged),
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
            color: selected ? color.withValues(alpha: 0.4) : BrainTheme.borderDark,
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
          color: isActive ? activeColor.withValues(alpha: 0.12) : BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.3) : BrainTheme.borderDark,
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

class _SortDropdown extends StatelessWidget {
  final _ProjectSortBy sortBy;
  final ValueChanged<_ProjectSortBy> onChanged;

  const _SortDropdown({required this.sortBy, required this.onChanged});

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
              case _ProjectSortBy.updatedAt: label = 'Reciente';
              case _ProjectSortBy.title: label = 'Nombre';
              case _ProjectSortBy.deadline: label = 'Fecha limite';
              case _ProjectSortBy.progress: label = 'Progreso';
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
