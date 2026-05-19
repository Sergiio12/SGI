import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';

import '../../config/theme.dart';
import '../../models/goal.dart';
import '../../providers/goals_provider.dart';
import '../../providers/projects_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/goal_card.dart';
import '../../widgets/skeleton_card.dart';

enum _GoalSortBy { updatedAt, title, progress, target }

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
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return g.title.toLowerCase().contains(q) ||
              g.description.toLowerCase().contains(q) ||
              g.metricLabel.toLowerCase().contains(q);
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
              onHorizonFilterChanged: (h) =>
                  setState(() => _horizonFilter = h),
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
                    hintText: AppLocalizations.of(context)!.searchInGoals,
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
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide:
                          BorderSide(color: BrainTheme.borderDark),
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms).slideY(
                    begin: -0.2, end: 0),
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
                            ? '${AppLocalizations.of(context)!.noResults}: "$_searchQuery"'
                            : AppLocalizations.of(context)!.noResults,
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
                  padding:
                      const EdgeInsets.fromLTRB(16, 4, 16, 80),
                  children: [
                    if (monthly.isNotEmpty)
                      _buildSection(
                        context,
                        AppLocalizations.of(context)!.goalMonthly,
                        monthly,
                        BrainTheme.accentGreen,
                        Icons.calendar_view_month,
                        projectsProvider,
                      ),
                    if (quarterly.isNotEmpty)
                      _buildSection(
                        context,
                        AppLocalizations.of(context)!.goalQuarterly,
                        quarterly,
                        BrainTheme.accentPurple,
                        Icons.view_week_outlined,
                        projectsProvider,
                      ),
                    if (yearly.isNotEmpty)
                      _buildSection(
                        context,
                        AppLocalizations.of(context)!.goalYearly,
                        yearly,
                        BrainTheme.accentBlue,
                        Icons.event_available_outlined,
                        projectsProvider,
                      ),
                  ],
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
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 3),
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
            projectCount: projectsProvider
                .getProjectsByGoal(goals[index].id)
                .length,
            onTap: () => Navigator.pushNamed(
              context,
              '/goal',
              arguments: goals[index].id,
            ),
            onDelete: () =>
                _deleteGoal(context, goals[index]),
          ).animate().fadeIn(
            duration: 300.ms,
            delay: (index * 60).ms,
          ).slideX(
              begin: 0.05, end: 0, curve: Curves.easeOut);
        }),
      ],
    );
  }

  Future<void> _deleteGoal(
      BuildContext context, Goal goal) async {
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
      await context
          .read<GoalsProvider>()
          .deleteGoal(goal.id);
    }
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
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
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
          color:
              BrainTheme.accentPurple.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.track_changes_rounded,
            value: '$total',
            label: AppLocalizations.of(context)!.totalTasks,
            color: BrainTheme.accentPurple,
          ),
          _StatItem(
            icon: Icons.calendar_view_month,
            value: '$monthly',
            label: AppLocalizations.of(context)!.goalMonthly,
            color: BrainTheme.accentGreen,
          ),
          _StatItem(
            icon: Icons.view_week_outlined,
            value: '$quarterly',
            label: AppLocalizations.of(context)!.goalQuarterly,
            color: BrainTheme.accentOrange,
          ),
          _StatItem(
            icon: Icons.event_available_outlined,
            value: '$yearly',
            label: AppLocalizations.of(context)!.goalYearly,
            color: BrainTheme.accentBlue,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(
        begin: -0.2, end: 0, curve: Curves.easeOut);
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

  const _FilterBar({
    required this.horizonFilter,
    required this.searchQuery,
    required this.showSearch,
    required this.sortBy,
    required this.onHorizonFilterChanged,
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
                        label: AppLocalizations.of(context)!.all,
                        selected: horizonFilter == null,
                        color: BrainTheme.accentPurple,
                        onTap: () =>
                            onHorizonFilterChanged(null),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppLocalizations.of(context)!.goalMonthly,
                        selected:
                            horizonFilter == GoalHorizon.monthly,
                        color: BrainTheme.accentGreen,
                        onTap: () =>
                            onHorizonFilterChanged(
                          horizonFilter == GoalHorizon.monthly
                              ? null
                              : GoalHorizon.monthly,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppLocalizations.of(context)!.goalQuarterly,
                        selected:
                            horizonFilter ==
                                GoalHorizon.quarterly,
                        color: BrainTheme.accentOrange,
                        onTap: () =>
                            onHorizonFilterChanged(
                          horizonFilter ==
                                  GoalHorizon.quarterly
                              ? null
                              : GoalHorizon.quarterly,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: AppLocalizations.of(context)!.goalYearly,
                        selected:
                            horizonFilter == GoalHorizon.yearly,
                        color: BrainTheme.accentBlue,
                        onTap: () =>
                            onHorizonFilterChanged(
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
                isActive:
                    showSearch || searchQuery.isNotEmpty,
                activeColor: BrainTheme.accentPurple,
                onTap: onToggleSearch,
              ),
              const SizedBox(width: 6),
              _SortDropdown(
                  sortBy: sortBy, onChanged: onSortChanged),
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
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.4)
                : BrainTheme.borderDark,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected
                ? color
                : BrainTheme.textSecondary,
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
          color: isActive
              ? activeColor
              : BrainTheme.textSecondary,
        ),
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final _GoalSortBy sortBy;
  final ValueChanged<_GoalSortBy> onChanged;

  const _SortDropdown(
      {required this.sortBy, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: BrainTheme.borderDark, width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_GoalSortBy>(
          value: sortBy,
          isDense: true,
          dropdownColor: BrainTheme.cardDark,
          icon: Icon(Icons.sort,
              size: 18, color: BrainTheme.textSecondary),
          style: TextStyle(
              fontSize: 13, color: BrainTheme.textSecondary),
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
