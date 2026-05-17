import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/theme.dart';
import '../../models/tag.dart';
import '../../utils/notification_service_v2.dart';
import '../../models/task.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/priority_indicator.dart';

class TaskDetailScreen extends StatefulWidget {
  final String? taskId;

  const TaskDetailScreen({super.key, this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _subtaskController = TextEditingController();
  final _estimatedHoursController = TextEditingController(text: '1');
  final _actualHoursController = TextEditingController();
  final _reminderController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  TaskStatus _status = TaskStatus.pending;
  DateTime? _dueDate;
  String? _projectId;
  List<SubTask> _subtasks = [];
  List<String> _selectedTags = [];

  bool get _isEditing => widget.taskId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final task = context.read<TasksProvider>().getTaskById(widget.taskId!);
        if (task != null) {
          setState(() {
            _titleController.text = task.title;
            _descController.text = task.description;
            _priority = task.priority;
            _status = task.status;
            _dueDate = task.dueDate;
            _estimatedHoursController.text = _formatNumber(task.estimatedHours);
            _actualHoursController.text = task.actualHours != null
                ? _formatNumber(task.actualHours!)
                : '';
            _reminderController.text =
                task.reminderMinutesBefore?.toString() ?? '';
            _projectId = task.projectId;
            _subtasks = List.from(task.subtasks);
            _selectedTags = List.from(task.tags);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    _estimatedHoursController.dispose();
    _actualHoursController.dispose();
    _reminderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      showWarningNotification('El titulo es obligatorio');
      return;
    }

    final provider = context.read<TasksProvider>();
    final estimatedHours = _readDouble(_estimatedHoursController.text, 1);
    final actualHours = _readNullableDouble(_actualHoursController.text);
    final reminderMinutes = _readNullableInt(_reminderController.text);

    if (_isEditing) {
      final task = provider.getTaskById(widget.taskId!);
      if (task != null) {
        await provider.updateTask(task.copyWith(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          priority: _priority,
          status: _status,
          dueDate: _dueDate,
          estimatedHours: estimatedHours,
          actualHours: actualHours,
          reminderMinutesBefore: reminderMinutes,
          clearActualHours: actualHours == null,
          clearReminder: reminderMinutes == null,
          lastActivityAt: DateTime.now(),
          projectId: _projectId,
          clearProjectId: _projectId == null,
          subtasks: _subtasks,
          tags: _selectedTags,
        ));
      }
    } else {
      await provider.addTask(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        priority: _priority,
        dueDate: _dueDate,
        estimatedHours: estimatedHours,
        actualHours: actualHours,
        reminderMinutesBefore: reminderMinutes,
        projectId: _projectId,
        tags: _selectedTags,
        subtasks: _subtasks,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _subtasks.add(SubTask(id: const Uuid().v4(), title: title));
      _subtaskController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar tarea' : 'Nueva tarea'),
        actions: [
          if (_isEditing)
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: BrainTheme.accentRed),
              onPressed: () async {
                await context.read<TasksProvider>().deleteTask(widget.taskId!);
                if (mounted) Navigator.pop(context);
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: BrainTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: 'Titulo de la tarea...',
                border: InputBorder.none,
                filled: false,
              ),
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              style: const TextStyle(
                fontSize: 15,
                color: BrainTheme.textSecondary,
              ),
              decoration: const InputDecoration(
                hintText: 'Descripcion opcional...',
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: null,
            ),
            const SizedBox(height: 16),
            const Divider(color: BrainTheme.borderDark),
            const SizedBox(height: 16),
            _PropertyRow(
              icon: Icons.flag_outlined,
              label: 'Estado',
              child: DropdownButton<TaskStatus>(
                value: _status,
                dropdownColor: BrainTheme.cardDark,
                underline: const SizedBox.shrink(),
                items: TaskStatus.values
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(_statusLabel(status)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _status = value!),
              ),
            ),
            const SizedBox(height: 12),
            _PropertyRow(
              icon: Icons.priority_high,
              label: 'Prioridad',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskPriority.values.map((priority) {
                  final isSelected = priority == _priority;
                  return GestureDetector(
                    onTap: () => setState(() => _priority = priority),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? BrainTheme.priorityColor(priority.index)
                                .withValues(alpha: 0.2)
                            : BrainTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? BrainTheme.priorityColor(priority.index)
                              : BrainTheme.borderDark,
                        ),
                      ),
                      child: PriorityIndicator(priority: priority),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            _PropertyRow(
              icon: Icons.calendar_today_outlined,
              label: 'Deadline',
              child: GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
                child: _InlinePill(
                  text: _dueDate != null
                      ? DateFormat('dd MMM yyyy').format(_dueDate!)
                      : 'Sin fecha',
                  trailing: _dueDate != null
                      ? GestureDetector(
                          onTap: () => setState(() => _dueDate = null),
                          child: const Icon(Icons.close, size: 16),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PropertyRow(
              icon: Icons.timer_outlined,
              label: 'Tiempo',
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _estimatedHoursController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Estimado (h)',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _actualHoursController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Real (h)',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _PropertyRow(
              icon: Icons.notifications_outlined,
              label: 'Aviso',
              child: TextField(
                controller: _reminderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Minutos antes',
                  hintText: 'Ej. 60',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _PropertyRow(
              icon: Icons.folder_outlined,
              label: 'Proyecto',
              child: Consumer<ProjectsProvider>(
                builder: (context, projects, _) {
                  return DropdownButton<String?>(
                    value: _projectId,
                    dropdownColor: BrainTheme.cardDark,
                    underline: const SizedBox.shrink(),
                    hint: const Text('Sin proyecto'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Sin proyecto'),
                      ),
                      ...projects.projects.map((project) => DropdownMenuItem(
                            value: project.id,
                            child: Text('${project.emoji} ${project.title}'),
                          )),
                    ],
                    onChanged: (value) => setState(() => _projectId = value),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: BrainTheme.borderDark),
            const SizedBox(height: 12),
            const _SectionTitle('Etiquetas'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: Tag.defaultTags.map((tag) {
                final isSelected = _selectedTags.contains(tag.id);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag.id);
                      } else {
                        _selectedTags.add(tag.id);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tag.color.withValues(alpha: 0.2)
                          : BrainTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? tag.color : BrainTheme.borderDark,
                      ),
                    ),
                    child: Text(
                      tag.name,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isSelected ? tag.color : BrainTheme.textSecondary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Divider(color: BrainTheme.borderDark),
            const SizedBox(height: 12),
            Row(
              children: [
                const _SectionTitle('Subtareas'),
                const Spacer(),
                Text(
                  '${_subtasks.where((s) => s.isDone).length}/${_subtasks.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: BrainTheme.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._subtasks.asMap().entries.map((entry) {
              final subtask = entry.value;
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(
                  value: subtask.isDone,
                  onChanged: (value) {
                    setState(() {
                      _subtasks[entry.key] =
                          subtask.copyWith(isDone: value ?? false);
                    });
                  },
                  activeColor: BrainTheme.accentGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                title: Text(
                  subtask.title,
                  style: TextStyle(
                    color: subtask.isDone
                        ? BrainTheme.textTertiary
                        : BrainTheme.textPrimary,
                    decoration:
                        subtask.isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () =>
                      setState(() => _subtasks.removeAt(entry.key)),
                ),
              );
            }),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: const InputDecoration(
                      hintText: 'Anadir subtarea...',
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: BrainTheme.accentPurple,
                  ),
                  onPressed: _addSubtask,
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  String _statusLabel(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pendiente';
      case TaskStatus.inProgress:
        return 'En progreso';
      case TaskStatus.inReview:
        return 'En revision';
      case TaskStatus.completed:
        return 'Finalizada';
      case TaskStatus.cancelled:
        return 'Anulada';
    }
  }

  double _readDouble(String value, double fallback) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? fallback;
  }

  double? _readNullableDouble(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text.replaceAll(',', '.'));
  }

  int? _readNullableInt(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _PropertyRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _PropertyRow({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: BrainTheme.textTertiary),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: BrainTheme.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}

class _InlinePill extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const _InlinePill({required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: BrainTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BrainTheme.borderDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(color: BrainTheme.textPrimary)),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: BrainTheme.textSecondary,
      ),
    );
  }
}
