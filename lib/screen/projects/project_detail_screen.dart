import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/project.dart';
import '../../utils/notification_service_v2.dart';
import '../../models/task.dart';
import '../../providers/goals_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/note_card.dart';
import '../../widgets/priority_indicator.dart';
import '../../widgets/task_card.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String? projectId;

  const ProjectDetailScreen({super.key, this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _objectiveController = TextEditingController();

  String _emoji = '📁';
  int _colorValue = BrainTheme.accentBlue.toARGB32();
  ProjectStatus _status = ProjectStatus.active;
  TaskPriority _priority = TaskPriority.medium;
  DateTime _startDate = DateTime.now();
  DateTime? _deadline;
  String? _goalId;

  bool get _isEditing => widget.projectId != null;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final project =
            context.read<ProjectsProvider>().getProjectById(widget.projectId!);
        if (project != null) {
          setState(() {
            _titleController.text = project.title;
            _descController.text = project.description;
            _objectiveController.text = project.objective;
            _emoji = project.emoji;
            _colorValue = project.colorValue;
            _status = project.status;
            _priority = project.priority;
            _startDate = project.startDate;
            _deadline = project.deadline;
            _goalId = project.goalId;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _objectiveController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      showWarningNotification('El nombre del proyecto es obligatorio');
      return;
    }

    final provider = context.read<ProjectsProvider>();

    if (_isEditing) {
      final project = provider.getProjectById(widget.projectId!);
      if (project != null) {
        await provider.updateProject(project.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          objective: _objectiveController.text.trim(),
          emoji: _emoji,
          colorValue: _colorValue,
          status: _status,
          priority: _priority,
          startDate: _startDate,
          deadline: _deadline,
          goalId: _goalId,
          clearGoalId: _goalId == null,
        ));
      }
    } else {
      await provider.addProject(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        objective: _objectiveController.text.trim(),
        emoji: _emoji,
        colorValue: _colorValue,
        status: _status,
        priority: _priority,
        startDate: _startDate,
        deadline: _deadline,
        goalId: _goalId,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar proyecto' : 'Nuevo proyecto'),
        actions: [
          if (_isEditing)
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: BrainTheme.accentRed),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: BrainTheme.cardDark,
                    title: const Text('Eliminar proyecto', style: TextStyle(color: BrainTheme.textPrimary)),
                    content: const Text('Se moverá a la papelera. ¿Deseas continuar?', style: TextStyle(color: BrainTheme.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: BrainTheme.accentRed, foregroundColor: Colors.white),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await context
                      .read<ProjectsProvider>()
                      .deleteProject(widget.projectId!);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
          TextButton(
            onPressed: _save,
            child: const Text(
              'Guardar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _showEmojiPicker,
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Color(_colorValue).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              _emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Nombre del proyecto',
                            border: InputBorder.none,
                            filled: false,
                          ),
                          autofocus: !_isEditing,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: BrainTheme.textSecondary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Descripcion del proyecto...',
                      border: InputBorder.none,
                      filled: false,
                    ),
                    maxLines: null,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _objectiveController,
                    style: const TextStyle(
                      fontSize: 14,
                      color: BrainTheme.textPrimary,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Objetivo general del proyecto...',
                      border: InputBorder.none,
                      filled: false,
                    ),
                    maxLines: null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Color',
                    style: TextStyle(
                      fontSize: 13,
                      color: BrainTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: BrainTheme.projectColors.map((color) {
                      final isSelected = color == _colorValue;
                      return GestureDetector(
                        onTap: () => setState(() => _colorValue = color),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(color),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2.5)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  _ProjectMetaGrid(
                    status: _status,
                    priority: _priority,
                    startDate: _startDate,
                    deadline: _deadline,
                    goalId: _goalId,
                    onStatusChanged: (value) => setState(() => _status = value),
                    onPriorityChanged: (value) =>
                        setState(() => _priority = value),
                    onStartDateChanged: (value) =>
                        setState(() => _startDate = value),
                    onDeadlineChanged: (value) =>
                        setState(() => _deadline = value),
                    onGoalChanged: (value) => setState(() => _goalId = value),
                  ),
                ],
              ),
            ),
            if (_isEditing) ...[
              const Divider(color: BrainTheme.borderDark),
              TabBar(
                controller: _tabController,
                labelColor: BrainTheme.accentPurple,
                unselectedLabelColor: BrainTheme.textTertiary,
                indicatorColor: BrainTheme.accentPurple,
                tabs: const [
                  Tab(text: 'Info'),
                  Tab(text: 'Tareas'),
                  Tab(text: 'Notas'),
                ],
              ),
              SizedBox(
                height: 430,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ProjectInfoTab(projectId: widget.projectId!),
                    _ProjectTasksTab(projectId: widget.projectId!),
                    _ProjectNotesTab(projectId: widget.projectId!),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Elegir icono',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: BrainTheme.projectEmojis.map((emoji) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _emoji = emoji);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: BrainTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: emoji == _emoji
                            ? BrainTheme.accentPurple
                            : BrainTheme.borderDark,
                      ),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectMetaGrid extends StatelessWidget {
  final ProjectStatus status;
  final TaskPriority priority;
  final DateTime startDate;
  final DateTime? deadline;
  final String? goalId;
  final ValueChanged<ProjectStatus> onStatusChanged;
  final ValueChanged<TaskPriority> onPriorityChanged;
  final ValueChanged<DateTime> onStartDateChanged;
  final ValueChanged<DateTime?> onDeadlineChanged;
  final ValueChanged<String?> onGoalChanged;

  const _ProjectMetaGrid({
    required this.status,
    required this.priority,
    required this.startDate,
    required this.deadline,
    required this.goalId,
    required this.onStatusChanged,
    required this.onPriorityChanged,
    required this.onStartDateChanged,
    required this.onDeadlineChanged,
    required this.onGoalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetaField(
                label: 'Estado',
                child: DropdownButton<ProjectStatus>(
                  value: status,
                  isExpanded: true,
                  dropdownColor: BrainTheme.cardDark,
                  underline: const SizedBox.shrink(),
                  items: ProjectStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(_statusLabel(s)),
                          ))
                      .toList(),
                  onChanged: (value) => onStatusChanged(value!),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetaField(
                label: 'Prioridad',
                child: DropdownButton<TaskPriority>(
                  value: priority,
                  isExpanded: true,
                  dropdownColor: BrainTheme.cardDark,
                  underline: const SizedBox.shrink(),
                  items: TaskPriority.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: PriorityIndicator(priority: p),
                          ))
                      .toList(),
                  onChanged: (value) => onPriorityChanged(value!),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _DateField(
                label: 'Inicio',
                date: startDate,
                onChanged: (value) {
                  if (value != null) onStartDateChanged(value);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DateField(
                label: 'Fin estimado',
                date: deadline,
                nullable: true,
                onChanged: onDeadlineChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MetaField(
          label: 'Objetivo asociado',
          child: Consumer<GoalsProvider>(
            builder: (context, goals, _) {
              return DropdownButton<String?>(
                value: goalId,
                isExpanded: true,
                dropdownColor: BrainTheme.cardDark,
                underline: const SizedBox.shrink(),
                hint: const Text('Sin objetivo'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Sin objetivo'),
                  ),
                  ...goals.goals.map(
                    (goal) => DropdownMenuItem(
                      value: goal.id,
                      child: Text(goal.title),
                    ),
                  ),
                ],
                onChanged: onGoalChanged,
              );
            },
          ),
        ),
      ],
    );
  }

  String _statusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return 'Activo';
      case ProjectStatus.paused:
        return 'Pausado';
      case ProjectStatus.completed:
        return 'Finalizado';
      case ProjectStatus.abandoned:
        return 'Abandonado';
    }
  }
}

class _MetaField extends StatelessWidget {
  final String label;
  final Widget child;

  const _MetaField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: BrainTheme.textTertiary),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: BrainTheme.surfaceDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BrainTheme.borderDark),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool nullable;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    required this.date,
    required this.onChanged,
    this.nullable = false,
  });

  @override
  Widget build(BuildContext context) {
    return _MetaField(
      label: label,
      child: InkWell(
        onTap: () async {
          final selected = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
            lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
          );
          if (selected != null) onChanged(selected);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  date != null
                      ? DateFormat('dd MMM yyyy').format(date!)
                      : 'Sin fecha',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (nullable && date != null)
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: const Icon(Icons.close, size: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectInfoTab extends StatelessWidget {
  final String projectId;

  const _ProjectInfoTab({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TasksProvider, NotesProvider>(
      builder: (context, tasks, notes, _) {
        final projectTasks = tasks.getTasksByProject(projectId);
        final completed =
            projectTasks.where((t) => t.status == TaskStatus.completed).length;
        final progress =
            projectTasks.isEmpty ? 0.0 : completed / projectTasks.length;
        final estimatedHours = projectTasks.fold<double>(
          0,
          (total, task) => total + task.estimatedHours,
        );
        final actualHours = projectTasks.fold<double>(
          0,
          (total, task) => total + (task.actualHours ?? 0),
        );

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Progreso general',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: BrainTheme.accentPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: BrainTheme.borderDark,
                          valueColor: const AlwaysStoppedAnimation(
                            BrainTheme.accentPurple,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoStat('Total', '${projectTasks.length}'),
                          _InfoStat(
                            'Pendientes',
                            '${projectTasks.length - completed}',
                          ),
                          _InfoStat('Notas',
                              '${notes.getNotesByProject(projectId).length}'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoStat('Estimadas',
                              '${estimatedHours.toStringAsFixed(1)}h'),
                          _InfoStat(
                              'Reales', '${actualHours.toStringAsFixed(1)}h'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoStat extends StatelessWidget {
  final String label;
  final String value;

  const _InfoStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: BrainTheme.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: BrainTheme.textTertiary),
        ),
      ],
    );
  }
}

class _ProjectTasksTab extends StatelessWidget {
  final String projectId;

  const _ProjectTasksTab({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Consumer<TasksProvider>(
      builder: (context, provider, _) {
        final tasks = provider.getTasksByProject(projectId);
        if (tasks.isEmpty) {
          return const Center(
            child: Text(
              'No hay tareas en este proyecto',
              style: TextStyle(color: BrainTheme.textTertiary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: tasks.length,
          itemBuilder: (_, index) => TaskCard(
            task: tasks[index],
            onTap: () => Navigator.pushNamed(context, '/task',
                arguments: tasks[index].id),
            onToggle: () => provider.toggleTaskStatus(tasks[index].id),
          ),
        );
      },
    );
  }
}

class _ProjectNotesTab extends StatelessWidget {
  final String projectId;

  const _ProjectNotesTab({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        final notes = provider.getNotesByProject(projectId);
        if (notes.isEmpty) {
          return const Center(
            child: Text(
              'No hay notas en este proyecto',
              style: TextStyle(color: BrainTheme.textTertiary),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          itemBuilder: (_, index) => NoteCard(
            note: notes[index],
            onTap: () => Navigator.pushNamed(context, '/note',
                arguments: notes[index].id),
          ),
        );
      },
    );
  }
}
