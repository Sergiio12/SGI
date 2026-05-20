import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../../models/project.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/daily_planner_provider.dart';
import '../../utils/undo_helper.dart';
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
  final _projectSearchController = TextEditingController();
  String _searchQuery = '';
  String _projectSearchQuery = '';
  Timer? _searchDebounce;
  Set<TaskPriority> _selectedPriorities = TaskPriority.values.toSet();
  _TaskDueDateFilter _dueDateFilter = _TaskDueDateFilter.all;
  bool _onlyWithDescription = false;
  bool _onlyWithProject = false;
  String? _selectedProjectId;
  Set<TaskStatus> _visibleBoardColumns = TaskStatus.values.toSet();
  _TaskSortOption _sortOption = _TaskSortOption.priority;
  int _wipLimit = 15;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _projectSearchController.dispose();
    super.dispose();
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

  List<Task> _boardTaskList(TasksProvider provider, TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return provider.todoTasks;
      case TaskStatus.inProgress:
        return provider.inProgressTasks;
      case TaskStatus.inReview:
        return provider.inReviewTasks;
      case TaskStatus.completed:
        return provider.doneTasks;
      case TaskStatus.cancelled:
        return provider.cancelledTasks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<TasksProvider, DailyPlannerProvider>(
      builder: (context, provider, planner, _) {
        if (!provider.isLoaded) return const SkeletonList();
        return Column(
          children: [
            _TodaySummaryBar(provider: provider)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.2, end: 0, curve: Curves.easeOut),
            _SearchFilterBar(
              searchQuery: _searchQuery,
              searchController: _searchController,
              onSearchChanged: (v) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 200), () {
                  setState(() => _searchQuery = v.toLowerCase());
                });
              },
              onAdvancedFilters: _showAdvancedFilters,
              activeFilterCount: _activeFilterCount(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: _ProjectSelector(
                selectedProjectId: _selectedProjectId,
                searchQuery: _projectSearchQuery,
                searchController: _projectSearchController,
                onSearchChanged: (v) =>
                    setState(() => _projectSearchQuery = v),
                onProjectChanged: (v) {
                  setState(() {
                    _selectedProjectId = v;
                    _projectSearchQuery = '';
                    _projectSearchController.clear();
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildBoard(context, provider, planner),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBoard(
      BuildContext context, TasksProvider provider, DailyPlannerProvider planner) {
    final visibleColumns = TaskStatus.values
        .where((status) => _visibleBoardColumns.contains(status))
        .toList();
    final columns = <TaskStatus, List<Task>>{};
    for (final status in visibleColumns) {
      final statusTasks = _boardTaskList(provider, status);
      columns[status] = _filteredTasks(statusTasks)..sort(_compareTasks);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = visibleColumns.isEmpty
            ? constraints.maxWidth
            : max((290 + 34) * visibleColumns.length.toDouble(),
                constraints.maxWidth);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${columns.values.fold(0, (s, l) => s + l.length)} ${AppLocalizations.of(context).tasks}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: BrainTheme.textTertiary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '• ${_sortLabel(context)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: BrainTheme.textTertiary.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'WIP: $_wipLimit',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: BrainTheme.textTertiary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // ── Drag-to-Today zone ──
            DragTarget<Task>(
              onAcceptWithDetails: (details) {
                planner.addTaskToDay(details.data.id);
              },
              builder: (context, candidateData, rejectedData) {
                final hovering = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: hovering ? 40 : 0,
                  decoration: BoxDecoration(
                    color: hovering
                        ? BrainTheme.accentPurple.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: hovering
                        ? Border.all(
                            color: BrainTheme.accentPurple
                                .withValues(alpha: 0.3),
                          )
                        : null,
                  ),
                  child: hovering
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add,
                                size: 14, color: BrainTheme.accentPurple),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context).dropToAddToMyDay,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: BrainTheme.accentPurple,
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(),
                );
              },
            ),
            // ── Board ──
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: boardWidth,
                  child: visibleColumns.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.filter_alt_off_outlined,
                                    size: 48,
                                    color: BrainTheme.textTertiary
                                        .withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text(
                                  AppLocalizations.of(context).filterAll,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: BrainTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: visibleColumns.map((status) {
                            final colTasks = columns[status]!;
                            final overWip = _wipLimit > 0 &&
                                colTasks.length > _wipLimit;
                            return _TaskBoardColumn(
                              status: status,
                              title: _statusLabel(status, context),
                              tasks: colTasks,
                              overWip: overWip,
                              onTaskMoved: (task) =>
                                  provider.moveTaskToStatus(task.id, status),
                              onCreateTask: () =>
                                  _showInlineCreateTask(context, status, provider),
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

  Future<void> _showInlineCreateTask(
    BuildContext context,
    TaskStatus status,
    TasksProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final titleCtl = TextEditingController();
    var priority = TaskPriority.medium;
    var dueDate = DateTime.now().add(const Duration(days: 1));

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 24,
                        decoration: BoxDecoration(
                          color: _statusColor(status),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppLocalizations.of(context).newTaskWithStatus(_statusLabel(status, context)),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BrainTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: BrainTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: l10n.createTask,
                      filled: true,
                      fillColor: BrainTheme.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: BrainTheme.borderDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: TaskPriority.values.map((p) {
                      final selected = priority == p;
                      final color = BrainTheme.priorityColor(p.index);
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(_priorityLabel(p, context)),
                          selected: selected,
                          selectedColor: color.withValues(alpha: 0.15),
                          backgroundColor: BrainTheme.cardDark,
                          labelStyle: TextStyle(
                            color: selected ? color : BrainTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          side: BorderSide(
                            color: selected
                                ? color.withValues(alpha: 0.4)
                                : BrainTheme.borderDark,
                          ),
                          onSelected: (_) =>
                              setModalState(() => priority = p),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          size: 14, color: BrainTheme.textTertiary),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 30)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setModalState(() => dueDate = picked);
                          }
                        },
                        child: Text(
                          DateFormat('dd/MM/yyyy').format(dueDate),
                          style: TextStyle(
                            fontSize: 13,
                            color: BrainTheme.accentBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () {
                          if (titleCtl.text.trim().isEmpty) return;
                          provider.addTask(
                            title: titleCtl.text.trim(),
                            priority: priority,
                            dueDate: dueDate,
                          ).then((result) {
                            final task = result.valueOrNull;
                            if (task != null && status != TaskStatus.pending) {
                              provider.moveTaskToStatus(task.id, status);
                            }
                          });
                          Navigator.pop(ctx, true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: BrainTheme.accentPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(l10n.createTask),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
    if (result == true && mounted) setState(() {});
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
                    const SizedBox(height: 16),
                    _FilterSection(
                      icon: Icons.priority_high,
                      title: AppLocalizations.of(context).sortPriority,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TaskPriority.values.map((priority) {
                          final active = selectedPriorities.contains(priority);
                          final color = BrainTheme.priorityColor(priority.index);
                          return FilterChip(
                            label: Text(_priorityLabel(priority, context)),
                            selected: active,
                            selectedColor: color.withValues(alpha: 0.15),
                            backgroundColor: BrainTheme.cardDark,
                            labelStyle: TextStyle(
                              color: active ? color : BrainTheme.textSecondary,
                              fontWeight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                            ),
                            side: BorderSide(
                              color: active
                                  ? color.withValues(alpha: 0.4)
                                  : BrainTheme.borderDark,
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
                    ),
                    const SizedBox(height: 16),
                    _FilterSection(
                      icon: Icons.calendar_today,
                      title: AppLocalizations.of(context).sortDueDate,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _TaskDueDateFilter.values.map((filter) {
                          final selected = dueDateFilter == filter;
                          return ChoiceChip(
                            label: Text(_dueDateFilterLabelFor(filter, context)),
                            selected: selected,
                            selectedColor:
                                BrainTheme.accentBlue.withValues(alpha: 0.15),
                            backgroundColor: BrainTheme.cardDark,
                            labelStyle: TextStyle(
                              color: selected
                                  ? BrainTheme.accentBlue
                                  : BrainTheme.textSecondary,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? BrainTheme.accentBlue.withValues(alpha: 0.4)
                                  : BrainTheme.borderDark,
                            ),
                            onSelected: (_) {
                              setModalState(() => dueDateFilter = filter);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FilterSection(
                      icon: Icons.tune,
                      title: 'Filtros extra',
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: onlyWithDescription,
                            activeThumbColor: BrainTheme.accentPurple,
                            title: Text(
                                AppLocalizations.of(context)
                                    .onlyWithDescription,
                                style: TextStyle(
                                    color: BrainTheme.textPrimary,
                                    fontSize: 14)),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            onChanged: (value) {
                              setModalState(
                                  () => onlyWithDescription = value);
                            },
                          ),
                          SwitchListTile(
                            value: onlyWithProject,
                            activeThumbColor: BrainTheme.accentPurple,
                            title: Text(
                                AppLocalizations.of(context).onlyWithProject,
                                style: TextStyle(
                                    color: BrainTheme.textPrimary,
                                    fontSize: 14)),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            onChanged: (value) {
                              setModalState(() => onlyWithProject = value);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FilterSection(
                      icon: Icons.view_column,
                      title: AppLocalizations.of(context).status,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TaskStatus.values.map((status) {
                          final selected =
                              visibleBoardColumns.contains(status);
                          final color = _statusColor(status);
                          return FilterChip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_statusIcon(status),
                                    size: 14, color: color),
                                const SizedBox(width: 4),
                                Text(_statusLabel(status, context)),
                              ],
                            ),
                            selected: selected,
                            selectedColor: color.withValues(alpha: 0.15),
                            backgroundColor: BrainTheme.cardDark,
                            labelStyle: TextStyle(
                              color:
                                  selected ? color : BrainTheme.textSecondary,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            side: BorderSide(
                              color: selected
                                  ? color.withValues(alpha: 0.4)
                                  : BrainTheme.borderDark,
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
                    ),
                    const SizedBox(height: 16),
                    _FilterSection(
                      icon: Icons.sort,
                      title: AppLocalizations.of(context).sortBy,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: BrainTheme.cardDark,
                          borderRadius: BorderRadius.circular(12),
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
                                child: Text(
                                    _sortOptionLabel(option, context)),
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
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
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
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: BrainTheme.borderDark),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                                AppLocalizations.of(context).clearFilters),
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child:
                                Text(AppLocalizations.of(context).save),
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

  Color _statusColor(TaskStatus status) => BrainTheme.statusColor(status);

  Widget _buildTaskCard(Task task, TasksProvider provider) {
    final planner = context.read<DailyPlannerProvider>();
    final isPlanned = planner.isTaskPlanned(task.id);
    return Padding(
      padding: const EdgeInsets.only(right: 28),
      child: Stack(
        children: [
          TaskCard(
            task: task,
            enableSlide: false,
            compact: true,
            onTap: () =>
                Navigator.pushNamed(context, '/task', arguments: task.id),
            onDismissed: () {
              final tid = task.id;
              provider.deleteTask(tid);
              showUndoSnackBar(context,
                message: 'Tarea movida a la papelera',
                onUndo: () => provider.restoreTask(tid),
              );
            },
          ),
          Positioned(
            right: -24,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (isPlanned) {
                    planner.removeTaskFromDay(task.id);
                  } else {
                    planner.addTaskToDay(task.id);
                  }
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isPlanned
                        ? BrainTheme.accentPurple.withValues(alpha: 0.2)
                        : BrainTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isPlanned
                          ? BrainTheme.accentPurple
                          : BrainTheme.borderDark,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    isPlanned ? Icons.check : Icons.add,
                    size: 12,
                    color: isPlanned
                        ? BrainTheme.accentPurple
                        : BrainTheme.textTertiary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TODAY SUMMARY BAR ─────────────────────────────────────────────────

class _TodaySummaryBar extends StatelessWidget {
  final TasksProvider provider;

  const _TodaySummaryBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(now);
    final pending = provider.todoTasks.length;
    final inProgress = provider.inProgressTasks.length;
    final done = provider.doneTasks.length;
    final overdue = provider.overdueTasks.length;
    final cancelled = provider.cancelledTasks.length;
    final total = provider.totalTasks;

    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrainTheme.borderDark.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month,
                  size: 13, color: BrainTheme.textTertiary),
              const SizedBox(width: 6),
              Text(
                l10n.today,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BrainTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: BrainTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SummaryChip(
                  icon: Icons.circle_outlined,
                  count: pending,
                  label: l10n.statusPending,
                  color: BrainTheme.statusColor(TaskStatus.pending)),
              const SizedBox(width: 8),
              _SummaryChip(
                  icon: Icons.play_circle_outline,
                  count: inProgress,
                  label: l10n.statusInProgress,
                  color: BrainTheme.statusColor(TaskStatus.inProgress)),
              const SizedBox(width: 8),
              _SummaryChip(
                  icon: Icons.check_circle,
                  count: done,
                  label: l10n.statusCompleted,
                  color: BrainTheme.statusColor(TaskStatus.completed)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _SummaryChip(
                  icon: Icons.warning_amber_rounded,
                  count: overdue,
                  label: l10n.overdueTasks,
                  color: overdue > 0
                      ? BrainTheme.statusColor(TaskStatus.cancelled)
                      : BrainTheme.textTertiary),
              const SizedBox(width: 8),
              _SummaryChip(
                  icon: Icons.cancel_outlined,
                  count: cancelled,
                  label: l10n.statusCancelled,
                  color: cancelled > 0
                      ? BrainTheme.statusColor(TaskStatus.cancelled)
                      : BrainTheme.textTertiary),
              const SizedBox(width: 8),
              _SummaryChip(
                  icon: Icons.task_alt,
                  count: total,
                  label: l10n.all,
                  color: BrainTheme.textTertiary),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const _SummaryChip({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PROJECT SELECTOR ──────────────────────────────────────────────────

class _ProjectSelector extends StatelessWidget {
  final String? selectedProjectId;
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onProjectChanged;

  const _ProjectSelector({
    required this.selectedProjectId,
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onProjectChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ProjectsProvider>(
      builder: (context, projectsProvider, _) {
        final projects = projectsProvider.projects;
        Project? selectedProject;
        if (selectedProjectId != null) {
          try {
            selectedProject =
                projects.firstWhere((p) => p.id == selectedProjectId);
          } catch (_) {}
        }

        return GestureDetector(
          onTap: () => _showProjectPicker(context, projects),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: BrainTheme.cardDark,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BrainTheme.borderDark),
            ),
            child: Row(
              children: [
                Icon(Icons.folder_outlined,
                    size: 16, color: BrainTheme.textTertiary),
                const SizedBox(width: 8),
                Expanded(
                child: Text(
                  selectedProject != null
                      ? '${selectedProject.emoji} ${selectedProject.title}'
                      : 'Todos los proyectos',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selectedProject != null
                        ? Color(selectedProject.colorValue)
                        : BrainTheme.textSecondary,
                  ),
                ),
                ),
                Icon(Icons.arrow_drop_down,
                    size: 20, color: BrainTheme.textTertiary),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showProjectPicker(BuildContext context, List<Project> projects) {
    String localQuery = searchQuery;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setS) {
            final filtered = localQuery.isEmpty
                ? projects
                : projects
                    .where((p) => p.title
                        .toLowerCase()
                        .contains(localQuery.toLowerCase()))
                    .toList();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                height: 420,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Seleccionar proyecto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: BrainTheme.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: BrainTheme.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      onChanged: (v) => setS(() => localQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Buscar proyecto...',
                        prefixIcon:
                            const Icon(Icons.search, size: 18),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        filled: true,
                        fillColor: BrainTheme.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: BrainTheme.borderDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: [
                          ListTile(
                            dense: true,
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: BrainTheme.accentPurple
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.folder_off_outlined,
                                  size: 16,
                                  color: BrainTheme.accentPurple),
                            ),
                            title: Text(
                              'Todos los proyectos',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    selectedProjectId == null
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                color: BrainTheme.textPrimary,
                              ),
                            ),
                            trailing: selectedProjectId == null
                                ? Icon(Icons.check,
                                    size: 18,
                                    color: BrainTheme.accentGreen)
                                : null,
                            onTap: () {
                              onProjectChanged(null);
                              Navigator.pop(ctx);
                            },
                          ),
                          ...filtered.map((project) {
                            final isSelected =
                                project.id == selectedProjectId;
                            return ListTile(
                              dense: true,
                              leading: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(project.colorValue)
                                      .withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(project.emoji,
                                      style:
                                          const TextStyle(fontSize: 16)),
                                ),
                              ),
                              title: Text(
                                project.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                  color: BrainTheme.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                '${project.taskIds.length} tareas',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: BrainTheme.textTertiary,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check,
                                      size: 18,
                                      color: BrainTheme.accentGreen)
                                  : null,
                              onTap: () {
                                onProjectChanged(project.id);
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── FILTER SECTION ──────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _FilterSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: BrainTheme.textTertiary),
            const SizedBox(width: 6),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: BrainTheme.textPrimary)),
          ],
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

// ─── SEARCH + FILTER BAR ───────────────────────────────────────────────

class _SearchFilterBar extends StatelessWidget {
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAdvancedFilters;
  final int activeFilterCount;

  const _SearchFilterBar({
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onAdvancedFilters,
    required this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchTasks,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: BrainTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: BrainTheme.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: BrainTheme.borderDark),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _ActionButton(
            icon: Icons.filter_list,
            isActive: activeFilterCount > 0,
            activeColor: BrainTheme.statusColor(TaskStatus.inProgress),
            onTap: onAdvancedFilters,
          ),
        ],
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
        padding: const EdgeInsets.all(10),
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

// ─── BOARD COLUMN ──────────────────────────────────────────────────────

class _TaskBoardColumn extends StatelessWidget {
  final TaskStatus status;
  final String title;
  final List<Task> tasks;
  final bool overWip;
  final ValueChanged<Task> onTaskMoved;
  final VoidCallback onCreateTask;
  final Widget Function(Task) taskBuilder;

  const _TaskBoardColumn({
    required this.status,
    required this.title,
    required this.tasks,
    this.overWip = false,
    required this.onTaskMoved,
    required this.onCreateTask,
    required this.taskBuilder,
  });

  Color get _columnColor => BrainTheme.statusColor(status);

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
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final task = details.data;
        return task.status != status;
      },
      onAcceptWithDetails: (details) => onTaskMoved(details.data),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          width: 290,
          margin: const EdgeInsets.only(left: 8, right: 8),
          decoration: BoxDecoration(
            color: BrainTheme.surfaceDark.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHovered
                  ? _columnColor.withValues(alpha: 0.35)
                  : BrainTheme.borderDark.withValues(alpha: 0.4),
              width: isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              if (isHovered)
                BoxShadow(
                  color: _columnColor.withValues(alpha: 0.05),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ColumnHeader(
                color: _columnColor,
                icon: _columnIcon,
                title: title,
                count: tasks.length,
                overWip: overWip,
                onCreateTask: onCreateTask,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: tasks.isEmpty
                    ? _EmptyColumn(icon: _columnIcon, color: _columnColor)
                    : PaginatedList<Task>(
                        items: tasks,
                        pageSize: 30,
                        initialPageSize: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemBuilder: (context, task, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: LongPressDraggable<Task>(
                              data: task,
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: 270,
                                  child: Transform.scale(
                                    scale: 1.03,
                                    child: Card(
                                      elevation: 6,
                                      shadowColor:
                                          _columnColor.withValues(alpha: 0.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: _columnColor
                                              .withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: taskBuilder(task),
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.2,
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

class _ColumnHeader extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final int count;
  final bool overWip;
  final VoidCallback onCreateTask;

  const _ColumnHeader({
    required this.color,
    required this.icon,
    required this.title,
    required this.count,
    this.overWip = false,
    required this.onCreateTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BrainTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: overWip
                  ? BrainTheme.accentRed.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                color: overWip ? BrainTheme.accentRed : color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onCreateTask,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.add, size: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyColumn extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _EmptyColumn({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).emptyState,
            style: TextStyle(
              color: BrainTheme.textTertiary.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
