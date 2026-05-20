import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';

import '../../config/theme.dart';
import '../../models/goal.dart';
import '../../providers/goals_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tags_provider.dart';
import '../../utils/undo_helper.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/goal_card.dart';
import '../../widgets/skeleton_card.dart';

enum _GoalSortBy { updatedAt, title, progress, target }

enum _ProgressFilter { all, notStarted, inProgress, completed }

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  GoalHorizon? _horizonFilter;
  _GoalSortBy _sortBy = _GoalSortBy.updatedAt;
  bool _showSearch = false;
  Set<String> _selectedTagIds = {};
  _ProgressFilter _progressFilter = _ProgressFilter.all;
  String? _selectedProjectId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GoalsProvider, ProjectsProvider>(
      builder: (context, goalsProvider, projectsProvider, _) {
        if (!goalsProvider.isLoaded) return const SkeletonList();
        final allGoals = goalsProvider.goals;

        if (allGoals.isEmpty) {
          final l10n = AppLocalizations.of(context);
          return EmptyState(
            emoji: '🎯',
            title: l10n.emptyState,
            subtitle: l10n.emptyStateDescription,
            actionLabel: l10n.createGoal,
            onAction: () => Navigator.pushNamed(context, '/goal'),
          );
        }

        var filtered = allGoals.where((g) {
          if (_horizonFilter != null && g.horizon != _horizonFilter) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            if (!g.title.toLowerCase().contains(q) &&
                !g.description.toLowerCase().contains(q) &&
                !g.metricLabel.toLowerCase().contains(q)) return false;
          }
          if (_selectedTagIds.isNotEmpty) {
            if (!g.tags.any((t) => _selectedTagIds.contains(t))) return false;
          }
          switch (_progressFilter) {
            case _ProgressFilter.notStarted:
              if (g.progress > 0) return false;
            case _ProgressFilter.inProgress:
              if (g.progress <= 0 || g.progress >= 1) return false;
            case _ProgressFilter.completed:
              if (g.progress < 1) return false;
            case _ProgressFilter.all:
              break;
          }
          if (_selectedProjectId != null &&
              !g.projectIds.contains(_selectedProjectId)) return false;
          return true;
        }).toList();

        filtered.sort((a, b) {
          switch (_sortBy) {
            case _GoalSortBy.title:
              return a.title.toLowerCase().compareTo(b.title.toLowerCase());
            case _GoalSortBy.progress:
              return a.progress.compareTo(b.progress);
            case _GoalSortBy.target:
              return a.targetValue.compareTo(b.targetValue);
            case _GoalSortBy.updatedAt:
              return b.updatedAt.compareTo(a.updatedAt);
          }
        });

        final monthly =
            filtered.where((g) => g.horizon == GoalHorizon.monthly).toList();
        final quarterly =
            filtered.where((g) => g.horizon == GoalHorizon.quarterly).toList();
        final yearly =
            filtered.where((g) => g.horizon == GoalHorizon.yearly).toList();

        return Column(
          children: [
            _StatsBar(provider: goalsProvider),
            _FilterBar(
              horizonFilter: _horizonFilter,
              searchQuery: _searchQuery,
              showSearch: _showSearch,
              sortBy: _sortBy,
              onHorizonFilterChanged: (h) => setState(() => _horizonFilter = h),
              onSortChanged: (s) => setState(() => _sortBy = s),
              onToggleSearch: () => setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              }),
              onAdvancedFilters: _showAdvancedFilters,
              activeFilterCount: _activeFilterCount(),
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
                    hintText: AppLocalizations.of(context).searchInGoals,
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
                            ? '${AppLocalizations.of(context).noResults}: "$_searchQuery"'
                            : AppLocalizations.of(context).noResults,
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
                  onRefresh: () => context.read<GoalsProvider>().loadGoals(),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    children: [
                      if (monthly.isNotEmpty)
                        _buildSection(
                          context,
                          AppLocalizations.of(context).goalMonthly,
                          monthly,
                          BrainTheme.accentGreen,
                          Icons.calendar_view_month,
                          projectsProvider,
                        ),
                      if (quarterly.isNotEmpty)
                        _buildSection(
                          context,
                          AppLocalizations.of(context).goalQuarterly,
                          quarterly,
                          BrainTheme.accentPurple,
                          Icons.view_week_outlined,
                          projectsProvider,
                        ),
                      if (yearly.isNotEmpty)
                        _buildSection(
                          context,
                          AppLocalizations.of(context).goalYearly,
                          yearly,
                          BrainTheme.accentBlue,
                          Icons.event_available_outlined,
                          projectsProvider,
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

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Goal> goals,
    Color color,
    IconData icon,
    ProjectsProvider projectsProvider,
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
                  '${goals.length}',
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
        ...List.generate(goals.length, (index) {
          return GoalCard(
            goal: goals[index],
            projectCount:
                projectsProvider.getProjectsByGoal(goals[index].id).length,
            onTap: () => Navigator.pushNamed(
              context,
              '/goal',
              arguments: goals[index].id,
            ),
            onDelete: () => _deleteGoal(context, goals[index]),
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

  Future<void> _deleteGoal(BuildContext context, Goal goal) async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Text(l10n.moveToTrashTitle,
            style: TextStyle(color: BrainTheme.textPrimary)),
        content: Text(
          '${l10n.moveToTrashContent} "${goal.title}"?',
          style: TextStyle(color: BrainTheme.textSecondary),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: BrainTheme.accentRed,
                foregroundColor: Colors.white),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final gid = goal.id;
      await context.read<GoalsProvider>().deleteGoal(gid);
      if (context.mounted) {
        showUndoSnackBar(
          context,
          message: '${l10n.itemDeleted}',
          onUndo: () => context.read<GoalsProvider>().restoreGoal(gid),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _horizonFilter = null;
      _selectedTagIds = {};
      _progressFilter = _ProgressFilter.all;
      _selectedProjectId = null;
      _sortBy = _GoalSortBy.updatedAt;
    });
  }

  int _activeFilterCount() {
    var count = 0;
    if (_horizonFilter != null) count++;
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedTagIds.isNotEmpty) count++;
    if (_progressFilter != _ProgressFilter.all) count++;
    if (_selectedProjectId != null) count++;
    if (_sortBy != _GoalSortBy.updatedAt) count++;
    return count;
  }

  Future<void> _showAdvancedFilters() async {
    final l10n = AppLocalizations.of(context);
    var selectedTagIds = _selectedTagIds.toSet();
    var progressFilter = _progressFilter;
    var selectedProjectId = _selectedProjectId;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                  left: 20,
                  right: 20,
                  top: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.filter,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: BrainTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: BrainTheme.textSecondary),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.tags,
                        style: TextStyle(color: BrainTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Consumer<TagsProvider>(
                      builder: (context, tagsProvider, _) {
                        final allTags = tagsProvider.tags;
                        if (allTags.isEmpty) {
                          return Text(
                            l10n.goalNoTagsAvailable,
                            style: TextStyle(
                                color: BrainTheme.textTertiary, fontSize: 13),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: allTags.map((tag) {
                            final selected = selectedTagIds.contains(tag.id);
                            return FilterChip(
                              label: Text(tag.name),
                              selected: selected,
                              selectedColor: tag.color.withValues(alpha: 0.2),
                              backgroundColor: BrainTheme.cardDark,
                              avatar: CircleAvatar(
                                backgroundColor: tag.color,
                                radius: 6,
                              ),
                              labelStyle: TextStyle(
                                color: selected
                                    ? tag.color
                                    : BrainTheme.textSecondary,
                              ),
                              onSelected: (isSelected) {
                                setModalState(() {
                                  if (isSelected) {
                                    selectedTagIds.add(tag.id);
                                  } else {
                                    selectedTagIds.remove(tag.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.goalsProgress,
                        style: TextStyle(color: BrainTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _ProgressFilter.values.map((filter) {
                        final selected = progressFilter == filter;
                        return ChoiceChip(
                          label: Text(_progressFilterLabel(filter, l10n)),
                          selected: selected,
                          selectedColor:
                              BrainTheme.accentPurple.withValues(alpha: 0.18),
                          backgroundColor: BrainTheme.cardDark,
                          labelStyle: TextStyle(
                            color: selected
                                ? BrainTheme.accentPurple
                                : BrainTheme.textSecondary,
                          ),
                          onSelected: (_) {
                            setModalState(() => progressFilter = filter);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(l10n.project,
                        style: TextStyle(color: BrainTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Consumer<ProjectsProvider>(
                      builder: (context, projectsProvider, _) {
                        final projects = projectsProvider.projects;
                        if (projects.isEmpty) {
                          return Text(
                            l10n.emptyState,
                            style: TextStyle(
                                color: BrainTheme.textTertiary, fontSize: 13),
                          );
                        }
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: Text(l10n.all),
                              selected: selectedProjectId == null,
                              selectedColor: BrainTheme.accentPurple
                                  .withValues(alpha: 0.18),
                              backgroundColor: BrainTheme.cardDark,
                              labelStyle: TextStyle(
                                color: selectedProjectId == null
                                    ? BrainTheme.accentPurple
                                    : BrainTheme.textSecondary,
                              ),
                              onSelected: (_) {
                                setModalState(() => selectedProjectId = null);
                              },
                            ),
                            ...projects.map((project) {
                              final selected = selectedProjectId == project.id;
                              final pColor = Color(project.colorValue);
                              return ChoiceChip(
                                label:
                                    Text('${project.emoji} ${project.title}'),
                                selected: selected,
                                selectedColor: pColor.withValues(alpha: 0.2),
                                backgroundColor: BrainTheme.cardDark,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? pColor
                                      : BrainTheme.textSecondary,
                                ),
                                onSelected: (_) {
                                  setModalState(() => selectedProjectId =
                                      selected ? null : project.id);
                                },
                              );
                            }),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _clearFilters();
                              Navigator.pop(context);
                            },
                            child: Text(l10n.clearFilters),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedTagIds = selectedTagIds;
                                _progressFilter = progressFilter;
                                _selectedProjectId = selectedProjectId;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: BrainTheme.accentPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(l10n.save),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _progressFilterLabel(_ProgressFilter filter, AppLocalizations l10n) {
    switch (filter) {
      case _ProgressFilter.all:
        return l10n.all;
      case _ProgressFilter.notStarted:
        return l10n.goalNotStarted;
      case _ProgressFilter.inProgress:
        return l10n.goalInProgress;
      case _ProgressFilter.completed:
        return l10n.statusCompleted;
    }
  }

  List<Widget> _buildFilterChips(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[];
    if (_horizonFilter != null) {
      final label = switch (_horizonFilter!) {
        GoalHorizon.monthly => l10n.goalMonthly,
        GoalHorizon.quarterly => l10n.goalQuarterly,
        GoalHorizon.yearly => l10n.goalYearly,
      };
      chips.add(_buildFilterChip(label, () {
        setState(() => _horizonFilter = null);
      }));
    }
    if (_searchQuery.isNotEmpty) {
      chips.add(_buildFilterChip('"$_searchQuery"', () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      }));
    }
    if (_selectedTagIds.isNotEmpty) {
      chips.add(_buildFilterChip('${l10n.tags}: ${_selectedTagIds.length}', () {
        setState(() => _selectedTagIds = {});
      }));
    }
    if (_progressFilter != _ProgressFilter.all) {
      chips.add(
          _buildFilterChip(_progressFilterLabel(_progressFilter, l10n), () {
        setState(() => _progressFilter = _ProgressFilter.all);
      }));
    }
    if (_selectedProjectId != null) {
      chips.add(_buildFilterChip(l10n.project, () {
        setState(() => _selectedProjectId = null);
      }));
    }
    return chips;
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return InputChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: BrainTheme.cardDark,
      labelStyle: TextStyle(color: BrainTheme.textPrimary),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StatsBar extends StatelessWidget {
  final GoalsProvider provider;

  const _StatsBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.goals.length;
    final monthly = provider.monthlyGoals.length;
    final quarterly = provider.quarterlyGoals.length;
    final yearly = provider.yearlyGoals.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrainTheme.accentPurple.withValues(alpha: 0.12),
            BrainTheme.accentGreen.withValues(alpha: 0.05),
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
            icon: Icons.track_changes_rounded,
            value: '$total',
            label: AppLocalizations.of(context).totalTasks,
            color: BrainTheme.accentPurple,
          ),
          _StatItem(
            icon: Icons.calendar_view_month,
            value: '$monthly',
            label: AppLocalizations.of(context).goalMonthly,
            color: BrainTheme.accentGreen,
          ),
          _StatItem(
            icon: Icons.view_week_outlined,
            value: '$quarterly',
            label: AppLocalizations.of(context).goalQuarterly,
            color: BrainTheme.accentOrange,
          ),
          _StatItem(
            icon: Icons.event_available_outlined,
            value: '$yearly',
            label: AppLocalizations.of(context).goalYearly,
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
  final GoalHorizon? horizonFilter;
  final String searchQuery;
  final bool showSearch;
  final _GoalSortBy sortBy;
  final ValueChanged<GoalHorizon?> onHorizonFilterChanged;
  final ValueChanged<_GoalSortBy> onSortChanged;
  final VoidCallback onToggleSearch;
  final VoidCallback onAdvancedFilters;
  final int activeFilterCount;

  const _FilterBar({
    required this.horizonFilter,
    required this.searchQuery,
    required this.showSearch,
    required this.sortBy,
    required this.onHorizonFilterChanged,
    required this.onSortChanged,
    required this.onToggleSearch,
    required this.onAdvancedFilters,
    required this.activeFilterCount,
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
                        selected: horizonFilter == null,
                        color: BrainTheme.accentPurple,
                        onTap: () => onHorizonFilterChanged(null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppLocalizations.of(context).goalMonthly,
                        selected: horizonFilter == GoalHorizon.monthly,
                        color: BrainTheme.accentGreen,
                        onTap: () => onHorizonFilterChanged(
                          horizonFilter == GoalHorizon.monthly
                              ? null
                              : GoalHorizon.monthly,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppLocalizations.of(context).goalQuarterly,
                        selected: horizonFilter == GoalHorizon.quarterly,
                        color: BrainTheme.accentOrange,
                        onTap: () => onHorizonFilterChanged(
                          horizonFilter == GoalHorizon.quarterly
                              ? null
                              : GoalHorizon.quarterly,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppLocalizations.of(context).goalYearly,
                        selected: horizonFilter == GoalHorizon.yearly,
                        color: BrainTheme.accentBlue,
                        onTap: () => onHorizonFilterChanged(
                          horizonFilter == GoalHorizon.yearly
                              ? null
                              : GoalHorizon.yearly,
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
              const SizedBox(width: 6),
              _FilterIconButton(
                icon: Icons.filter_list,
                isActive: activeFilterCount > 0,
                activeColor: BrainTheme.accentPurple,
                badgeCount: activeFilterCount,
                onTap: onAdvancedFilters,
              ),
            ],
          ),
        ],
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

class _SortDropdown extends StatelessWidget {
  final _GoalSortBy sortBy;
  final ValueChanged<_GoalSortBy> onChanged;

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
        child: DropdownButton<_GoalSortBy>(
          value: sortBy,
          isDense: true,
          dropdownColor: BrainTheme.cardDark,
          icon: Icon(Icons.sort, size: 18, color: BrainTheme.textSecondary),
          style: TextStyle(fontSize: 13, color: BrainTheme.textSecondary),
          items: _GoalSortBy.values.map((sort) {
            final l10n = AppLocalizations.of(context);
            String label;
            switch (sort) {
              case _GoalSortBy.updatedAt:
                label = l10n.sortRecent;
              case _GoalSortBy.title:
                label = l10n.sortTitle;
              case _GoalSortBy.progress:
                label = l10n.goalsProgress;
              case _GoalSortBy.target:
                label = l10n.objective;
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
