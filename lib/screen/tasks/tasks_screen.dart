import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
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

  String _sortLabel() {
    switch (_sortOption) {
      case _TaskSortOption.priority:
        return 'Prioridad';
      case _TaskSortOption.dueDate:
        return 'Fecha límite';
      case _TaskSortOption.createdAt:
        return 'Creación';
      case _TaskSortOption.title:
        return 'Título';
    }
  }

  String _dueDateFilterLabel() => _dueDateFilterLabelFor(_dueDateFilter);

  String _dueDateFilterLabelFor(_TaskDueDateFilter filter) {
    switch (filter) {
      case _TaskDueDateFilter.all:
        return 'Todas';
      case _TaskDueDateFilter.today:
        return 'Hoy';
      case _TaskDueDateFilter.thisWeek:
        return 'Esta semana';
      case _TaskDueDateFilter.overdue:
        return 'Vencidas';
      case _TaskDueDateFilter.noDate:
        return 'Sin fecha';
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return 'Baja';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pendiente';
      case TaskStatus.inProgress:
        return 'En progreso';
      case TaskStatus.inReview:
        return 'Revisión';
      case TaskStatus.completed:
        return 'Finalizada';
      case TaskStatus.cancelled:
        return 'Anulada';
    }
  }

  TaskStatus _boardStatus(TaskStatus status) {
    return status;
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
                          'Filtros avanzados',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BrainTheme.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon:
                            Icon(Icons.close, color: BrainTheme.textSecondary),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Prioridad',
                    style: TextStyle(color: BrainTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TaskPriority.values.map((priority) {
                      final active = selectedPriorities.contains(priority);
                      return FilterChip(
                        label: Text(_priorityLabel(priority)),
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
                  Text(
                    'Fecha limite',
                    style: TextStyle(color: BrainTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _TaskDueDateFilter.values.map((filter) {
                      final selected = dueDateFilter == filter;
                      return ChoiceChip(
                        label: Text(_dueDateFilterLabelFor(filter)),
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
                      'Solo con descripción',
                      style: TextStyle(color: BrainTheme.textPrimary),
                    ),
                    subtitle: Text(
                      'Muestra únicamente las tareas con texto en la descripción.',
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
                    title: Text(
                      'Solo tareas con proyecto',
                      style: TextStyle(color: BrainTheme.textPrimary),
                    ),
                    subtitle: Text(
                      'Filtra las tareas que están asociadas a un proyecto.',
                      style: TextStyle(
                          color: BrainTheme.textSecondary, fontSize: 12),
                    ),
                    onChanged: (value) {
                      setModalState(() => onlyWithProject = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Columnas visibles',
                    style: TextStyle(color: BrainTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: TaskStatus.values.map((status) {
                      final selected = visibleBoardColumns.contains(status);
                      return FilterChip(
                        label: Text(_statusLabel(status)),
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
                  Text(
                    'Ordenar por',
                    style: TextStyle(color: BrainTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<_TaskSortOption>(
                    initialValue: sortOption,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: BrainTheme.cardDark,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: BrainTheme.borderDark),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: _TaskSortOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(_sortOptionLabel(option)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setModalState(() => sortOption = value);
                      }
                    },
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
                          child: const Text('Limpiar'),
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
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ));
          },
        );
      },
    );
  }

  String _sortOptionLabel(_TaskSortOption option) {
    switch (option) {
      case _TaskSortOption.priority:
        return 'Prioridad';
      case _TaskSortOption.dueDate:
        return 'Fecha límite';
      case _TaskSortOption.createdAt:
        return 'Fecha de creación';
      case _TaskSortOption.title:
        return 'Título';
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectsProvider = context.watch<ProjectsProvider>();
    final selectedProject = _selectedProjectId == null
        ? null
        : projectsProvider.getProjectById(_selectedProjectId!);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      setState(() => _searchQuery = v.toLowerCase()),
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Buscar tareas...',
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    filled: true,
                    fillColor: BrainTheme.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: BrainTheme.borderDark),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: _showAdvancedFilters,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BrainTheme.cardDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BrainTheme.borderDark),
                  ),
                  child:
                      Icon(Icons.filter_list, color: BrainTheme.accentPurple),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Consumer<ProjectsProvider>(
          builder: (context, projectsProvider, _) {
            final projectItems = [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos los proyectos'),
              ),
              ...projectsProvider.projects.map(
                (project) => DropdownMenuItem<String?>(
                  value: project.id,
                  child: Text(project.title),
                ),
              ),
            ];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownButtonFormField<String?>(
                initialValue: _selectedProjectId,
                decoration: InputDecoration(
                  labelText: 'Proyecto',
                  labelStyle: TextStyle(color: BrainTheme.textSecondary),
                  filled: true,
                  fillColor: BrainTheme.cardDark,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: BrainTheme.borderDark),
                  ),
                ),
                items: projectItems,
                onChanged: (value) {
                  setState(() => _selectedProjectId = value);
                },
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        if (_activeFilterCount() > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildFilterChips(),
            ),
          ),
        const SizedBox(height: 10),
        Expanded(
          child: Consumer<TasksProvider>(
            builder: (context, provider, _) {
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
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '${selectedProject != null ? 'Tablero: ${selectedProject.title}' : 'Tablero de tareas'} • ${filteredTasks.length} tareas • Ordenado por ${_sortLabel()}',
                          style: TextStyle(
                            fontSize: 13,
                            color: BrainTheme.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: boardWidth,
                            child: visibleColumns.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 24),
                                      child: Text(
                                        'Selecciona al menos una columna visible para mostrar el tablero.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: BrainTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: visibleColumns.map((status) {
                                      final title = _statusLabel(status);
                                      return _TaskBoardColumn(
                                        status: status,
                                        title: title,
                                        tasks: columns[status]!,
                                        onTaskMoved: (task) => provider
                                            .moveTaskToStatus(task.id, status),
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
            },
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFilterChips() {
    final chips = <Widget>[];
    if (_searchQuery.isNotEmpty) {
      chips.add(_buildFilterChip('Búsqueda: "$_searchQuery"', () {
        _searchController.clear();
        setState(() => _searchQuery = '');
      }));
    }
    if (_selectedPriorities.length != TaskPriority.values.length) {
      chips.add(_buildFilterChip(
        'Prioridades: ${_selectedPriorities.map(_priorityLabel).join(', ')}',
        () => setState(() => _selectedPriorities = TaskPriority.values.toSet()),
      ));
    }
    if (_dueDateFilter != _TaskDueDateFilter.all) {
      chips.add(_buildFilterChip('Fecha: ${_dueDateFilterLabel()}', () {
        setState(() => _dueDateFilter = _TaskDueDateFilter.all);
      }));
    }
    if (_onlyWithDescription) {
      chips.add(_buildFilterChip('Con descripción', () {
        setState(() => _onlyWithDescription = false);
      }));
    }
    if (_onlyWithProject) {
      chips.add(_buildFilterChip('Con proyecto', () {
        setState(() => _onlyWithProject = false);
      }));
    }
    chips.add(
        _buildFilterChip('Ordenar: ${_sortLabel()}', _showAdvancedFilters));
    return chips;
  }

  int _activeFilterCount() {
    var count = 0;
    if (_searchQuery.isNotEmpty) count++;
    if (_selectedPriorities.length != TaskPriority.values.length) count++;
    if (_dueDateFilter != _TaskDueDateFilter.all) count++;
    if (_onlyWithDescription) count++;
    if (_onlyWithProject) count++;
    return count;
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return InputChip(
      label: Text(label),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 18),
      backgroundColor: BrainTheme.cardDark,
      labelStyle: TextStyle(color: BrainTheme.textPrimary),
    );
  }

  Widget _buildTaskAction(Task task, TasksProvider provider) {
    return PopupMenuButton<TaskStatus>(
      icon: Icon(Icons.more_vert, color: BrainTheme.textTertiary, size: 20),
      itemBuilder: (context) {
        return TaskStatus.values
            .where((status) => status != task.status)
            .map((status) {
          return PopupMenuItem<TaskStatus>(
            value: status,
            child: Text(_statusLabel(status)),
          );
        }).toList();
      },
      onSelected: (status) {
        provider.moveTaskToStatus(task.id, status);
      },
    );
  }

  Widget _buildTaskCard(
    Task task,
    TasksProvider provider,
  ) {
    return TaskCard(
      task: task,
      enableSlide: false,
      action: _buildTaskAction(task, provider),
      onTap: () => Navigator.pushNamed(context, '/task', arguments: task.id),
      onToggle: () => provider.toggleTaskStatus(task.id),
      onDismissed: () => provider.deleteTask(task.id),
    );
  }
}

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
          width: 280,
          margin: const EdgeInsets.only(left: 16, right: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: BrainTheme.surfaceDark,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isHovered
                  ? BrainTheme.accentPurple.withValues(alpha: 0.3)
                  : BrainTheme.borderDark,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: BrainTheme.textTertiary.withValues(alpha: 0.08),
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: BrainTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BrainTheme.accentPurple.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        color: BrainTheme.accentPurple,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Arrastra tareas aquí o usa los tres puntos en la tarjeta',
                style: TextStyle(
                  fontSize: 12,
                  color: BrainTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Text(
                          'Vacío',
                          style: TextStyle(
                            color: BrainTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: LongPressDraggable<Task>(
                              data: task,
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: 260,
                                  child: taskBuilder(task),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.5,
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
