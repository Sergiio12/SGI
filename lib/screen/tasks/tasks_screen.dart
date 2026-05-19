import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/paginated_list.dart';
import '../../widgets/skeleton_card.dart';
import '../../widgets/task_card.dart';

enum _TaskSortOption { priority, dueDate, createdAt, title }

enum _TaskDueDateFilter { all, today, thisWeek, overdue, noDate }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Set<TaskPriority> _selectedPriorities = TaskPriority.values.toSet();
  _TaskDueDateFilter _dueDateFilter = _TaskDueDateFilter.all;
  bool _onlyWithDescription = false;
  bool _onlyWithProject = false;
  String? _selectedProjectId;
  Set<TaskStatus> _visibleBoardColumns = TaskStatus.values.toSet();
  _TaskSortOption _sortOption = _TaskSortOption.priority;
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedPriorities = TaskPriority.values.toSet();
      _dueDateFilter = _TaskDueDateFilter.all;
      _onlyWithDescription = false;
      _onlyWithProject = false;
      _selectedProjectId = null;
      _visibleBoardColumns = TaskStatus.values.toSet();
      _sortOption = _TaskSortOption.priority;
    });
  }

  bool _matchesSearch(Task task) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    return task.title.toLowerCase().contains(query) ||
        task.description.toLowerCase().contains(query);
  }

  bool _matchesPriority(Task task) =>
      _selectedPriorities.contains(task.priority);

  bool _matchesDueDate(Task task) {
    final dueDate = task.dueDate;
    switch (_dueDateFilter) {
      case _TaskDueDateFilter.all:
        return true;
      case _TaskDueDateFilter.today:
        return dueDate != null && _isSameDay(dueDate, DateTime.now());
      case _TaskDueDateFilter.thisWeek:
        return dueDate != null && _isWithinNextWeek(dueDate);
      case _TaskDueDateFilter.overdue:
        return task.isOverdue;
      case _TaskDueDateFilter.noDate:
        return dueDate == null;
    }
  }

  bool _matchesDescription(Task task) {
    return !_onlyWithDescription || task.description.isNotEmpty;
  }

  bool _matchesProject(Task task) {
    return !_onlyWithProject || task.projectId != null;
  }

  bool _matchesSelectedProject(Task task) {
    return _selectedProjectId == null || task.projectId == _selectedProjectId;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isWithinNextWeek(DateTime date) {
    final today = DateTime.now();
    final weekEnd = today.add(const Duration(days: 7));
    return !date.isBefore(DateTime(today.year, today.month, today.day)) &&
        date.isBefore(DateTime(weekEnd.year, weekEnd.month, weekEnd.day + 1));
  }

  List<Task> _filteredTasks(List<Task> tasks) {
    return tasks.where((task) {
      return _matchesSearch(task) &&
          _matchesPriority(task) &&
          _matchesDueDate(task) &&
          _matchesDescription(task) &&
          _matchesProject(task) &&
          _matchesSelectedProject(task);
    }).toList();
  }

  int _compareTasks(Task a, Task b) {
    switch (_sortOption) {
      case _TaskSortOption.priority:
        final priorityCompare = b.priority.index.compareTo(a.priority.index);
        if (priorityCompare != 0) return priorityCompare;
        break;
      case _TaskSortOption.dueDate:
        final aDate = a.dueDate ?? DateTime(9999);
        final bDate = b.dueDate ?? DateTime(9999);
        final dueDateCompare = aDate.compareTo(bDate);
        if (dueDateCompare != 0) return dueDateCompare;
        break;
      case _TaskSortOption.createdAt:
        return b.createdAt.compareTo(a.createdAt);
      case _TaskSortOption.title:
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    }
    return b.createdAt.compareTo(a.createdAt);
  }

  String _sortLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (_sortOption) {
      case _TaskSortOption.priority:
        return l10n.sortPriority;
      case _TaskSortOption.dueDate:
        return l10n.sortDueDate;
      case _TaskSortOption.createdAt:
        return l10n.sortCreatedAt;
      case _TaskSortOption.title:
        return l10n.sortTitle;
    }
  }

  String _dueDateFilterLabel(BuildContext context) =>
      _dueDateFilterLabelFor(_dueDateFilter, context);

  String _dueDateFilterLabelFor(
      _TaskDueDateFilter filter, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (filter) {
      case _TaskDueDateFilter.all:
        return l10n.all;
      case _TaskDueDateFilter.today:
        return l10n.today;
      case _TaskDueDateFilter.thisWeek:
        return l10n.thisWeek;
      case _TaskDueDateFilter.overdue:
        return l10n.overdueTasks;
      case _TaskDueDateFilter.noDate:
        return l10n.noDueDate;
    }
  }

  String _priorityLabel(TaskPriority priority, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (priority) {
      case TaskPriority.low:
        return l10n.priorityLow;
      case TaskPriority.medium:
        return l10n.priorityMedium;
      case TaskPriority.high:
        return l10n.priorityHigh;
      case TaskPriority.urgent:
        return l10n.priorityUrgent;
    }
  }

  String _statusLabel(TaskStatus status, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (status) {
      case TaskStatus.pending:
        return l10n.statusPending;
      case TaskStatus.inProgress:
        return l10n.statusInProgress;
      case TaskStatus.inReview:
        return l10n.statusInReview;
      case TaskStatus.completed:
        return l10n.statusCompleted;
      case TaskStatus.cancelled:
        return l10n.statusCancelled;
    }
  }

  TaskStatus _boardStatus(TaskStatus status) {
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TasksProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) return const SkeletonList();
        return Column(
          children: [
            _StatsBar(provider: provider),
            _SearchFilterBar(
              searchQuery: _searchQuery,
              showSearch: _showSearch,
              searchController: _searchController,
              onSearchChanged: (v) =>
                  setState(() => _searchQuery = v.toLowerCase()),
              onToggleSearch: () => setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              }),
              onAdvancedFilters: _showAdvancedFilters,
              activeFilterCount: _activeFilterCount(),
              selectedProjectId: _selectedProjectId,
              onProjectChanged: (v) => setState(() => _selectedProjectId = v),
            ),
            if (_activeFilterCount() > 0)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: _buildFilterChips(context),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildBoard(context, provider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBoard(
    BuildContext context,
    TasksProvider provider,
  ) {
    final filteredTasks = _filteredTasks(provider.tasks);
    final sortedTasks = [...filteredTasks]..sort(_compareTasks);
    final visibleColumns = TaskStatus.values
        .where((status) => _visibleBoardColumns.contains(status))
        .toList();
    final columns = Map.fromEntries(
      visibleColumns.map((status) => MapEntry(status, <Task>[])),
    );

    for (final task in sortedTasks) {
      final boardStatus = _boardStatus(task.status);
      if (columns.containsKey(boardStatus)) {
        columns[boardStatus]!.add(task);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = visibleColumns.isEmpty
            ? constraints.maxWidth
            : max((280 + 32) * visibleColumns.length.toDouble(),
                constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context).tasks,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: BrainTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BrainTheme.accentPurple.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${filteredTasks.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: BrainTheme.accentPurple,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _sortLabel(context),
                    style: TextStyle(
                      fontSize: 11,
                      color: BrainTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: boardWidth,
                  child: visibleColumns.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              AppLocalizations.of(context).filterAll,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: BrainTheme.textSecondary,
                              ),
                            ),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: visibleColumns.map((status) {
                            final colTasks = columns[status]!;
                            return _TaskBoardColumn(
                              status: status,
                              title: _statusLabel(status, context),
                              tasks: colTasks,
                              onTaskMoved: (task) =>
                                  provider.moveTaskToStatus(task.id, status),
                              taskBuilder: (task) =>
                                  _buildTaskCard(task, provider),
                            );
                          }).toList(),
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAdvancedFilters() async {
    final selectedPriorities = _selectedPriorities.toSet();
    var dueDateFilter = _dueDateFilter;
    var onlyWithDescription = _onlyWithDescription;
    var onlyWithProject = _onlyWithProject;
    final visibleBoardColumns = _visibleBoardColumns.toSet();
    var sortOption = _sortOption;

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
                            AppLocalizations.of(context).filter,
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
                    const SizedBox(height: 12),
                    Text(AppLocalizations.of(context).sortPriority,
                        style: TextStyle(color: BrainTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TaskPriority.values.map((priority) {
                        final active = selectedPriorities.contains(priority);
                        return FilterChip(
                          label: Text(_priorityLabel(priority, context)),
                          selected: active,
                          selectedColor:
                              BrainTheme.accentPurple.withValues(alpha: 0.12),
                          backgroundColor: BrainTheme.cardDark,
                          labelStyle: TextStyle(
                            color: active
                                ? BrainTheme.accentPurple
                                : BrainTheme.textSecondary,
                          ),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedPriorities.add(priority);
                              } else {
                                selectedPriorities.remove(priority);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context).sortDueDate,
                        style: TextStyle(color: BrainTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _TaskDueDateFilter.values.map((filter) {
                        final selected = dueDateFilter == filter;
                        return ChoiceChip(
                          label: Text(_dueDateFilterLabelFor(filter, context)),
                          selected: selected,
                          selectedColor:
                              BrainTheme.accentBlue.withValues(alpha: 0.18),
                          backgroundColor: BrainTheme.cardDark,
                          labelStyle: TextStyle(
                            color: selected
                                ? BrainTheme.accentBlue
                                : BrainTheme.textSecondary,
                          ),
                          onSelected: (_) {
                            setModalState(() => dueDateFilter = filter);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: onlyWithDescription,
                      activeThumbColor: BrainTheme.accentPurple,
                      title: Text(
                          AppLocalizations.of(context).onlyWithDescription,
                          style: TextStyle(color: BrainTheme.textPrimary)),
                      subtitle: Text(
                        AppLocalizations.of(context).description,
                        style: TextStyle(
                            color: BrainTheme.textSecondary, fontSize: 12),
                      ),
                      onChanged: (value) {
                        setModalState(() => onlyWithDescription = value);
                      },
                    ),
                    SwitchListTile(
                      value: onlyWithProject,
                      activeThumbColor: BrainTheme.accentPurple,
                      title: Text(AppLocalizations.of(context).onlyWithProject,
                          style: TextStyle(color: BrainTheme.textPrimary)),
                      subtitle: Text(
                        AppLocalizations.of(context).project,
                        style: TextStyle(
                            color: BrainTheme.textSecondary, fontSize: 12),
                      ),
                      onChanged: (value) {
                        setModalState(() => onlyWithProject = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context).filterStatus,
                        style: TextStyle(color: BrainTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TaskStatus.values.map((status) {
                        final selected = visibleBoardColumns.contains(status);
                        return FilterChip(
                          label: Text(_statusLabel(status, context)),
                          selected: selected,
                          selectedColor:
                              BrainTheme.accentPurple.withValues(alpha: 0.12),
                          backgroundColor: BrainTheme.cardDark,
                          labelStyle: TextStyle(
                            color: selected
                                ? BrainTheme.accentPurple
                                : BrainTheme.textSecondary,
                          ),
                          onSelected: (isSelected) {
                            setModalState(() {
                              if (isSelected) {
                                visibleBoardColumns.add(status);
                              } else {
                                visibleBoardColumns.remove(status);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(AppLocalizations.of(context).sortBy,
                        style: TextStyle(color: BrainTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: BrainTheme.cardDark,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: BrainTheme.borderDark),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<_TaskSortOption>(
                          value: sortOption,
                          isExpanded: true,
                          dropdownColor: BrainTheme.cardDark,
                          items: _TaskSortOption.values.map((option) {
                            return DropdownMenuItem(
                              value: option,
                              child: Text(_sortOptionLabel(option, context)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setModalState(() => sortOption = value);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              _clearFilters();
                              setModalState(() {
                                selectedPriorities
                                  ..clear()
                                  ..addAll(TaskPriority.values);
                                dueDateFilter = _TaskDueDateFilter.all;
                                onlyWithDescription = false;
                                onlyWithProject = false;
                                visibleBoardColumns
                                  ..clear()
                                  ..addAll(TaskStatus.values);
                                sortOption = _TaskSortOption.priority;
                              });
                            },
                            child:
                                Text(AppLocalizations.of(context).clearFilters),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedPriorities = selectedPriorities;
                                _dueDateFilter = dueDateFilter;
                                _onlyWithDescription = onlyWithDescription;
                                _onlyWithProject = onlyWithProject;
                                _visibleBoardColumns = visibleBoardColumns;
                                _sortOption = sortOption;
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
                            child: Text(AppLocalizations.of(context).save),
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

  String _sortOptionLabel(_TaskSortOption option, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (option) {
      case _TaskSortOption.priority:
        return l10n.sortPriority;
      case _TaskSortOption.dueDate:
        return l10n.sortDueDate;
      case _TaskSortOption.createdAt:
        return l10n.sortCreatedAt;
      case _TaskSortOption.title:
        return l10n.sortTitle;
    }
  }

  List<Widget> _buildFilterChips(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final chips = <Widget>[];
    if (_searchQuery.isNotEmpty) {
      chips.add(_buildFilterChip('${l10n.search}: "$_searchQuery"', () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      }));
    }
    if (_selectedPriorities.length != TaskPriority.values.length) {
      chips.add(_buildFilterChip(
        '${l10n.sortPriority}: ${_selectedPriorities.map((p) => _priorityLabel(p, context)).join(', ')}',
        () => setState(() => _selectedPriorities = TaskPriority.values.toSet()),
      ));
    }
    if (_dueDateFilter != _TaskDueDateFilter.all) {
      chips.add(_buildFilterChip(
          '${l10n.dueDate}: ${_dueDateFilterLabel(context)}', () {
        setState(() => _dueDateFilter = _TaskDueDateFilter.all);
      }));
    }
    if (_onlyWithDescription) {
      chips.add(_buildFilterChip(l10n.onlyWithDescription, () {
        setState(() => _onlyWithDescription = false);
      }));
    }
    if (_onlyWithProject) {
      chips.add(_buildFilterChip(l10n.onlyWithProject, () {
        setState(() => _onlyWithProject = false);
      }));
    }
    if (_selectedProjectId != null) {
      chips.add(_buildFilterChip(l10n.project, () {
        setState(() => _selectedProjectId = null);
      }));
    }
    chips.add(_buildFilterChip(
        '${l10n.sortBy}: ${_sortLabel(context)}', _showAdvancedFilters));
    return chips;
  }

  int _activeFilterCount() {
    var count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedPriorities.length != TaskPriority.values.length) count++;
    if (_dueDateFilter != _TaskDueDateFilter.all) count++;
    if (_onlyWithDescription) count++;
    if (_onlyWithProject) count++;
    if (_selectedProjectId != null) count++;
    return count;
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

  Widget _buildTaskAction(Task task, TasksProvider provider) {
    final availableStatuses =
        TaskStatus.values.where((s) => s != task.status).toList();

    return PopupMenuButton<TaskStatus>(
      icon: Icon(Icons.more_horiz, color: BrainTheme.textTertiary, size: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: BrainTheme.cardDark,
      elevation: 8,
      itemBuilder: (context) => [
        PopupMenuItem<TaskStatus>(
          enabled: false,
          height: 32,
          child: Text(
            AppLocalizations.of(context).filterStatus,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: BrainTheme.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...availableStatuses.map((status) {
          return PopupMenuItem<TaskStatus>(
            value: status,
            height: 42,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(_statusIcon(status),
                      size: 14, color: _statusColor(status)),
                ),
                const SizedBox(width: 10),
                Text(
                  _statusLabel(status, context),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: BrainTheme.textPrimary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onSelected: (status) {
        provider.moveTaskToStatus(task.id, status);
      },
    );
  }

  IconData _statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.circle_outlined;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.inReview:
        return Icons.rate_review_outlined;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  Color _statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return BrainTheme.textTertiary;
      case TaskStatus.inProgress:
        return BrainTheme.accentBlue;
      case TaskStatus.inReview:
        return BrainTheme.accentOrange;
      case TaskStatus.completed:
        return BrainTheme.accentGreen;
      case TaskStatus.cancelled:
        return BrainTheme.accentRed;
    }
  }

  Widget _buildTaskCard(Task task, TasksProvider provider) {
    return TaskCard(
      task: task,
      enableSlide: false,
      action: _buildTaskAction(task, provider),
      compact: true,
      onTap: () => Navigator.pushNamed(context, '/task', arguments: task.id),
      onDismissed: () => provider.deleteTask(task.id),
    );
  }
}

// ─── STATS BAR ─────────────────────────────────────────────────────────

class _StatsBar extends StatelessWidget {
  final TasksProvider provider;

  const _StatsBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final total = provider.totalTasks;
    final overdue = provider.overdueTasks.length;
    final today = provider.todayTasks.length;
    final doneToday = provider.completedToday;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            icon: Icons.task_alt,
            value: '$total',
            label: AppLocalizations.of(context).totalTasks,
            color: BrainTheme.accentPurple,
          ),
          _StatItem(
            icon: Icons.warning_amber_rounded,
            value: '$overdue',
            label: AppLocalizations.of(context).overdueTasks,
            color: overdue > 0 ? BrainTheme.accentRed : BrainTheme.textTertiary,
          ),
          _StatItem(
            icon: Icons.calendar_today,
            value: '$today',
            label: AppLocalizations.of(context).today,
            color:
                today > 0 ? BrainTheme.accentOrange : BrainTheme.textTertiary,
          ),
          _StatItem(
            icon: Icons.check_circle,
            value: '$doneToday',
            label: AppLocalizations.of(context).completedTasks,
            color: BrainTheme.accentGreen,
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
        Icon(icon, size: 16, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: BrainTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: BrainTheme.textTertiary,
          ),
        ),
      ],
    );
  }
}

// ─── SEARCH + FILTER BAR ───────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final String searchQuery;
  final bool showSearch;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSearch;
  final VoidCallback onAdvancedFilters;
  final int activeFilterCount;
  final String? selectedProjectId;
  final ValueChanged<String?> onProjectChanged;

  const _SearchFilterBar({
    required this.searchQuery,
    required this.showSearch,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleSearch,
    required this.onAdvancedFilters,
    required this.activeFilterCount,
    required this.selectedProjectId,
    required this.onProjectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  onChanged: onSearchChanged,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).searchTasks,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              searchController.clear();
                              onSearchChanged('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: BrainTheme.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: BrainTheme.borderDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.filter_list,
                isActive: activeFilterCount > 0,
                activeColor: BrainTheme.accentPurple,
                onTap: onAdvancedFilters,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: Consumer<ProjectsProvider>(
              builder: (context, projectsProvider, _) {
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _QuickChip(
                      label: AppLocalizations.of(context).all,
                      selected:
                          selectedProjectId == null && activeFilterCount == 0,
                      color: BrainTheme.accentPurple,
                      onTap: () => onProjectChanged(null),
                    ),
                    const SizedBox(width: 6),
                    _QuickChip(
                      label: AppLocalizations.of(context).today,
                      selected: false,
                      color: BrainTheme.accentOrange,
                      onTap: () {},
                    ),
                    const SizedBox(width: 6),
                    _QuickChip(
                      label: AppLocalizations.of(context).overdueTasks,
                      selected: false,
                      color: BrainTheme.accentRed,
                      onTap: () {},
                    ),
                    const SizedBox(width: 6),
                    ...projectsProvider.projects.take(5).map((project) {
                      final isSelected = selectedProjectId == project.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _QuickChip(
                          label: '${project.emoji} ${project.title}',
                          selected: isSelected,
                          color: Color(project.colorValue),
                          onTap: () =>
                              onProjectChanged(isSelected ? null : project.id),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _QuickChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? color : BrainTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _ActionButton({
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.3)
                : BrainTheme.borderDark,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? activeColor : BrainTheme.textSecondary,
        ),
      ),
    );
  }
}

// ─── BOARD COLUMN ──────────────────────────────────────────────────────

class _TaskBoardColumn extends StatelessWidget {
  final TaskStatus status;
  final String title;
  final List<Task> tasks;
  final ValueChanged<Task> onTaskMoved;
  final Widget Function(Task) taskBuilder;

  const _TaskBoardColumn({
    required this.status,
    required this.title,
    required this.tasks,
    required this.onTaskMoved,
    required this.taskBuilder,
  });

  Color get _columnColor {
    switch (status) {
      case TaskStatus.pending:
        return BrainTheme.textTertiary;
      case TaskStatus.inProgress:
        return BrainTheme.accentBlue;
      case TaskStatus.inReview:
        return BrainTheme.accentOrange;
      case TaskStatus.completed:
        return BrainTheme.accentGreen;
      case TaskStatus.cancelled:
        return BrainTheme.accentRed;
    }
  }

  IconData get _columnIcon {
    switch (status) {
      case TaskStatus.pending:
        return Icons.circle_outlined;
      case TaskStatus.inProgress:
        return Icons.play_circle_outline;
      case TaskStatus.inReview:
        return Icons.rate_review_outlined;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverLimit = tasks.length > 15;

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final task = details.data;
        return task.status != status;
      },
      onAcceptWithDetails: (details) => onTaskMoved(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          width: 270,
          margin: const EdgeInsets.only(left: 12, right: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BrainTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isHovered
                  ? _columnColor.withValues(alpha: 0.4)
                  : BrainTheme.borderDark,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: BrainTheme.textTertiary.withValues(alpha: 0.06),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _columnColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(_columnIcon, size: 16, color: _columnColor),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: BrainTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _columnColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: _columnColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isOverLimit) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.warning_amber,
                        size: 14, color: BrainTheme.accentOrange),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_columnIcon,
                                size: 28,
                                color: BrainTheme.textTertiary
                                    .withValues(alpha: 0.3)),
                            const SizedBox(height: 6),
                            Text(
                              AppLocalizations.of(context).emptyState,
                              style: TextStyle(
                                color: BrainTheme.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    : PaginatedList<Task>(
                        items: tasks,
                        pageSize: 20,
                        initialPageSize: 30,
                        padding: EdgeInsets.zero,
                        itemBuilder: (context, task, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: LongPressDraggable<Task>(
                              data: task,
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: 250,
                                  child: Card(
                                    elevation: 8,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: BorderSide(
                                        color:
                                            _columnColor.withValues(alpha: 0.4),
                                        width: 2,
                                      ),
                                    ),
                                    child: taskBuilder(task),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.4,
                                child: taskBuilder(task),
                              ),
                              child: taskBuilder(task),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
