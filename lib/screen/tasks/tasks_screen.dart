import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/daily_planner_provider.dart';
import '../../utils/haptic_helper.dart';
import '../../utils/notification_service_v2.dart';
import '../../widgets/skeleton_card.dart';
import '../../widgets/task_card.dart';
import '../../widgets/task_board_column.dart';
import '../../widgets/task_filter_bar.dart';
import '../../widgets/task_project_selector.dart';
import '../../widgets/task_today_summary.dart';

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
  DateRangeFilter _dateRangeFilter = DateRangeFilter.all;

  bool _selectionMode = false;
  final Set<String> _selectedTaskIds = {};

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
            if (_selectionMode) _buildBatchBar(context, provider) else const SizedBox.shrink(),
            TaskTodaySummary(
              pending: provider.todoTasks.length,
              inProgress: provider.inProgressTasks.length,
              done: provider.doneTasks.length,
              overdue: provider.overdueTasks.length,
              cancelled: provider.cancelledTasks.length,
              total: provider.totalTasks,
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.2, end: 0, curve: Curves.easeOut),
            TaskFilterBar(
              searchQuery: _searchQuery,
              searchController: _searchController,
              onSearchChanged: (v) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 200), () {
                  setState(() => _searchQuery = v.toLowerCase());
                });
              },
              onClearSearch: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              onToggleFilters: _showAdvancedFilters,
              activeFilterCount: _activeFilterCount(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: Consumer<ProjectsProvider>(
                builder: (context, projectsProvider, _) {
                  return TaskProjectSelector(
                    projects: projectsProvider.projects,
                    selectedProjectId: _selectedProjectId,
                    searchQuery: _projectSearchQuery,
                    onSelected: (v) {
                      setState(() {
                        _selectedProjectId = v;
                        _projectSearchQuery = '';
                        _projectSearchController.clear();
                      });
                    },
                    onSearchChanged: (v) =>
                        setState(() => _projectSearchQuery = v),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: DateRangeFilter.values.map((filter) {
                  final selected = _dateRangeFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_dateRangeFilterLabel(filter, context)),
                      selected: selected,
                      selectedColor:
                          BrainTheme.accentBlue.withValues(alpha: 0.15),
                      backgroundColor: Colors.transparent,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: selected
                            ? BrainTheme.accentBlue
                            : BrainTheme.textTertiary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      side: BorderSide(
                        color: selected
                            ? BrainTheme.accentBlue.withValues(alpha: 0.4)
                            : BrainTheme.borderDark,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _dateRangeFilter = filter;
                          _dueDateFilter = _mapDateRangeToDueDate(filter);
                        });
                        provider.setDateRangeFilter(filter);
                      },
                    ),
                  );
                }).toList(),
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

  String _dateRangeFilterLabel(DateRangeFilter filter, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (filter) {
      case DateRangeFilter.all:
        return 'Todo';
      case DateRangeFilter.today:
        return l10n.today;
      case DateRangeFilter.thisWeek:
        return l10n.thisWeek;
      case DateRangeFilter.overdue:
        return l10n.overdueTasks;
    }
  }

  Widget _buildBoard(BuildContext context, TasksProvider provider,
      DailyPlannerProvider planner) {
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
                            color:
                                BrainTheme.accentPurple.withValues(alpha: 0.3),
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
                            final overWip =
                                _wipLimit > 0 && colTasks.length > _wipLimit;
                            return TaskBoardColumn(
                              status: status,
                              title: _statusLabel(status, context),
                              icon: _statusIcon(status),
                              color: _statusColor(status),
                              tasks: colTasks,
                              overWip: overWip,
                              onTaskDropped: (task, s) =>
                                  provider.moveTaskToStatus(task.id, s),
                              onCreateTask: () => _showInlineCreateTask(
                                  context, status, provider),
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
      useSafeArea: true,
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
                        AppLocalizations.of(context)
                            .newTaskWithStatus(_statusLabel(status, context)),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BrainTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon:
                            Icon(Icons.close, color: BrainTheme.textSecondary),
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
                        borderSide: BorderSide(color: BrainTheme.borderDark),
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
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                          side: BorderSide(
                            color: selected
                                ? color.withValues(alpha: 0.4)
                                : BrainTheme.borderDark,
                          ),
                          onSelected: (_) => setModalState(() => priority = p),
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
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
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
                          provider
                              .addTask(
                            title: titleCtl.text.trim(),
                            priority: priority,
                            dueDate: dueDate,
                          )
                              .then((result) {
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
                          final color =
                              BrainTheme.priorityColor(priority.index);
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
                            label:
                                Text(_dueDateFilterLabelFor(filter, context)),
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
                              setModalState(() => onlyWithDescription = value);
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
                      const SizedBox(height: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          context
                              .read<TasksProvider>()
                              .autoArchive();
                          Navigator.pop(context);
                          showSuccessNotification(
                              'Tareas antiguas archivadas');
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10),
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined,
                                  size: 16,
                                  color: BrainTheme.accentOrange),
                              const SizedBox(width: 8),
                              Text(
                                'Archivar tareas antiguas',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: BrainTheme.accentOrange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right,
                                  size: 16,
                                  color: BrainTheme.textTertiary),
                            ],
                          ),
                        ),
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
                          final selected = visibleBoardColumns.contains(status);
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
                              side: BorderSide(color: BrainTheme.borderDark),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
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

  _TaskDueDateFilter _mapDateRangeToDueDate(DateRangeFilter filter) {
    switch (filter) {
      case DateRangeFilter.all:
        return _TaskDueDateFilter.all;
      case DateRangeFilter.today:
        return _TaskDueDateFilter.today;
      case DateRangeFilter.thisWeek:
        return _TaskDueDateFilter.thisWeek;
      case DateRangeFilter.overdue:
        return _TaskDueDateFilter.overdue;
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

  void _toggleSelection(String taskId) {
    setState(() {
      if (_selectedTaskIds.contains(taskId)) {
        _selectedTaskIds.remove(taskId);
        if (_selectedTaskIds.isEmpty) _selectionMode = false;
      } else {
        _selectedTaskIds.add(taskId);
      }
    });
  }

  Widget _buildBatchBar(BuildContext context, TasksProvider provider) {
    final count = _selectedTaskIds.length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BrainTheme.accentPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BrainTheme.accentPurple.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() {
              _selectionMode = false;
              _selectedTaskIds.clear();
            }),
            child: Icon(Icons.close, size: 16, color: BrainTheme.textSecondary),
          ),
          const SizedBox(width: 10),
          Text(
            '$count seleccionada(s)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BrainTheme.accentPurple,
            ),
          ),
          const Spacer(),
          _BatchAction(
            icon: Icons.check_circle_outline,
            color: BrainTheme.accentGreen,
            label: 'Completar',
            onTap: () {
              provider.batchComplete(_selectedTaskIds.toList());
              setState(() {
                _selectionMode = false;
                _selectedTaskIds.clear();
              });
            },
          ),
          const SizedBox(width: 4),
          _BatchAction(
            icon: Icons.delete_outline,
            color: BrainTheme.accentRed,
            label: 'Eliminar',
            onTap: () {
              provider.batchDelete(_selectedTaskIds.toList());
              setState(() {
                _selectionMode = false;
                _selectedTaskIds.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task, TasksProvider provider) {
    final planner = context.read<DailyPlannerProvider>();
    final isPlanned = planner.isTaskPlanned(task.id);
    return Padding(
      padding: const EdgeInsets.only(right: 28),
      child: Stack(
        children: [
          if (_selectionMode)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () => _toggleSelection(task.id),
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: _selectedTaskIds.contains(task.id)
                          ? BrainTheme.accentPurple
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _selectedTaskIds.contains(task.id)
                            ? BrainTheme.accentPurple
                            : BrainTheme.borderDark,
                        width: 1.5,
                      ),
                    ),
                    child: _selectedTaskIds.contains(task.id)
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
          TaskCard(
            task: task,
            enableSlide: !_selectionMode,
            compact: true,
            onTap: _selectionMode
                ? () => _toggleSelection(task.id)
                : () => Navigator.pushNamed(context, '/task', arguments: task.id),
            onLongPress: _selectionMode
                ? null
                : () {
                    HapticHelper.medium();
                    setState(() {
                      _selectionMode = true;
                      _selectedTaskIds.add(task.id);
                    });
                  },
            onDismissed: _selectionMode
                ? null
                : () {
                    final tid = task.id;
                    provider.deleteTask(tid);
                    showSuccessNotification(
                      'Tarea movida a la papelera',
                      actionLabel: AppLocalizations.of(context).undo,
                      onAction: () => provider.restoreTask(tid),
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

// ─── FILTER SECTION ──────────────────────────────────────────────────────

class _BatchAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _BatchAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
