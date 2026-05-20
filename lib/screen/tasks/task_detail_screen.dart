import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/notification_service_v2.dart';
import '../../models/task.dart';
import '../../providers/tags_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/tag_color_picker.dart';

class TaskDetailScreen extends StatefulWidget {
  final String? taskId;

  const TaskDetailScreen({super.key, this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with SingleTickerProviderStateMixin {
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
  List<String> _linkedNoteIds = [];
  List<String> _selectedTags = [];
  bool _showForm = false;

  bool get _isEditing => widget.taskId != null;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isEditing ? 3 : 0, vsync: this);

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
            _linkedNoteIds = List.from(task.linkedNoteIds);
          });
        }
      });
    } else {
      _showForm = true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tagsProv = context.read<TagsProvider>();
      if (!tagsProv.isLoaded) tagsProv.loadTags();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    _estimatedHoursController.dispose();
    _actualHoursController.dispose();
    _reminderController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      showWarningNotification(AppLocalizations.of(context).task);
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
          linkedNoteIds: _linkedNoteIds,
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
        linkedNoteIds: _linkedNoteIds,
        subtasks: _subtasks,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final task = _isEditing
        ? context.watch<TasksProvider>().getTaskById(widget.taskId!)
        : null;

    if (_isEditing && task == null && !_showForm) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showForm || !_isEditing) {
      return _buildFormView(task);
    }

    return _buildDetailView(task!);
  }

  Widget _buildDetailView(Task task) {
    final subtaskDone = task.subtasks.where((s) => s.isDone).length;
    final subtaskProgress =
        task.subtasks.isEmpty ? 0.0 : subtaskDone / task.subtasks.length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _TaskHeaderSliver(
            task: task,
            onEdit: () => setState(() => _showForm = true),
            onDelete: () => _deleteTask(task),
            onStatusChanged: (status) {
              context.read<TasksProvider>().updateTask(task.copyWith(
                  status: status, lastActivityAt: DateTime.now()));
            },
            onToggle: () {
              context.read<TasksProvider>().toggleTaskStatus(task.id);
            },
          ),
          SliverToBoxAdapter(
            child: _TaskMetaSection(
              task: task,
              subtaskProgress: subtaskProgress,
              subtaskDone: subtaskDone,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
          ),
          SliverToBoxAdapter(
            child: const SizedBox(height: 8),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TaskTabBarDelegate(
              tabController: _tabController,
              subtaskCount: task.subtasks.length,
              noteCount: _linkedNoteIds.length,
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TaskInfoTab(task: task),
                _TaskSubtabsTab(
                  subtasks: _subtasks,
                  taskId: task.id,
                  onChanged: (subtasks) => setState(() => _subtasks = subtasks),
                ),
                _TaskNotesTab(
                  linkedNoteIds: _linkedNoteIds,
                  onChanged: (ids) => setState(() => _linkedNoteIds = ids),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormView(Task? task) {
    final isEditing = task != null;
    final subtaskDone = _subtasks.where((s) => s.isDone).length;
    final subtaskProgress =
        _subtasks.isEmpty ? 0.0 : subtaskDone / _subtasks.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing
            ? AppLocalizations.of(context).editTask
            : AppLocalizations.of(context).createTask),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: BrainTheme.accentRed),
              onPressed: () => _deleteTask(task),
            ),
          TextButton(
            onPressed: _save,
            child: Text(
              AppLocalizations.of(context).save,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: BrainTheme.accentPurple),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FormCard(
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: BrainTheme.textPrimary,
                      letterSpacing: -0.5,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).sortTitle,
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    autofocus: !isEditing,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    style: TextStyle(
                      fontSize: 14,
                      color: BrainTheme.textSecondary,
                      height: 1.4,
                    ),
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).description,
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    maxLines: null,
                    minLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _FormSection(
              title: AppLocalizations.of(context).details,
              icon: Icons.tune,
              children: [
                _buildStatusSelector(),
                const SizedBox(height: 12),
                _buildPrioritySelector(),
                const SizedBox(height: 12),
                _buildDateField(),
                const SizedBox(height: 12),
                _buildProjectField(),
              ],
            ),
            const SizedBox(height: 12),
            _FormSection(
              title: AppLocalizations.of(context).notifications,
              icon: Icons.timer_outlined,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FormTextField(
                        controller: _estimatedHoursController,
                        label: AppLocalizations.of(context).task,
                        icon: Icons.timer_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FormTextField(
                        controller: _actualHoursController,
                        label: AppLocalizations.of(context).note,
                        icon: Icons.schedule,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FormTextField(
                        controller: _reminderController,
                        label: AppLocalizations.of(context).notifications,
                        icon: Icons.notifications_outlined,
                        keyboardType: TextInputType.number,
                        hint: '60',
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _FormSection(
              title: AppLocalizations.of(context).tags,
              icon: Icons.label_outline,
              children: [
                Consumer<TagsProvider>(builder: (context, tagsProv, _) {
                  final selected = tagsProv.tags
                      .where((t) => _selectedTags.contains(t.id))
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selected.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: selected.map((tag) {
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _selectedTags.remove(tag.id)),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: tag.color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color:
                                            tag.color.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(tag.name,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: tag.color,
                                              fontWeight: FontWeight.w500)),
                                      const SizedBox(width: 4),
                                      Icon(Icons.close,
                                          size: 12, color: tag.color),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showTagPicker,
                              icon:
                                  const Icon(Icons.playlist_add, size: 16),
                              label: Text(
                                  AppLocalizations.of(context).filter),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: BrainTheme.accentPurple,
                                side: BorderSide(
                                    color: BrainTheme.accentPurple
                                        .withValues(alpha: 0.3)),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _showManageTagsModal,
                            icon: const Icon(Icons.settings, size: 16),
                            label: Text(
                                AppLocalizations.of(context).settings),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BrainTheme.textSecondary,
                              side: BorderSide(
                                  color: BrainTheme.borderDark),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            _FormSection(
              title: AppLocalizations.of(context).notes,
              icon: Icons.link,
              children: [
                Consumer<NotesProvider>(builder: (context, notesProv, _) {
                  return Column(
                    children: [
                      if (_linkedNoteIds.isNotEmpty)
                        ..._linkedNoteIds.map((id) {
                          final note = notesProv.getNoteById(id);
                          if (note == null) return const SizedBox.shrink();
                          return Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: BrainTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: BrainTheme.borderDark),
                            ),
                            child: Row(
                              children: [
                                Text(note.emoji,
                                    style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(note.title,
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color:
                                                  BrainTheme.textPrimary)),
                                      Text(note.notebook,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  BrainTheme.textTertiary)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.link_off,
                                      size: 16,
                                      color: BrainTheme.accentRed),
                                  onPressed: () => setState(
                                      () => _linkedNoteIds.remove(id)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ),
                          );
                        }),
                      OutlinedButton.icon(
                        onPressed: _showLinkNotes,
                        icon: const Icon(Icons.add, size: 16),
                        label: Text(AppLocalizations.of(context).note),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BrainTheme.accentPurple,
                          side: BorderSide(
                              color: BrainTheme.accentPurple
                                  .withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),
            _FormSection(
              title: AppLocalizations.of(context).subtasks,
              icon: Icons.checklist,
              trailing: Text(
                '$subtaskDone/${_subtasks.length}',
                style: TextStyle(
                    fontSize: 12, color: BrainTheme.textTertiary),
              ),
              children: [
                if (_subtasks.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: subtaskProgress),
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: BrainTheme.borderDark,
                          valueColor: AlwaysStoppedAnimation(
                            subtaskProgress >= 1.0
                                ? BrainTheme.accentGreen
                                : BrainTheme.accentPurple,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                ..._subtasks.asMap().entries.map((entry) {
                  final subtask = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _subtasks[entry.key] =
                                  subtask.copyWith(isDone: !subtask.isDone);
                            });
                          },
                          child: AnimatedContainer(
                            duration: 200.ms,
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: subtask.isDone
                                  ? BrainTheme.accentGreen
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(
                                color: subtask.isDone
                                    ? BrainTheme.accentGreen
                                    : BrainTheme.borderDark,
                                width: 2,
                              ),
                            ),
                            child: subtask.isDone
                                ? const Icon(Icons.check,
                                    size: 12, color: Colors.white)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            subtask.title,
                            style: TextStyle(
                              fontSize: 14,
                              color: subtask.isDone
                                  ? BrainTheme.textTertiary
                                  : BrainTheme.textPrimary,
                              decoration: subtask.isDone
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              size: 16, color: BrainTheme.textTertiary),
                          onPressed: () => setState(
                              () => _subtasks.removeAt(entry.key)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _subtaskController,
                        decoration: InputDecoration(
                          hintText:
                              AppLocalizations.of(context).addSubtask,
                          border: InputBorder.none,
                          filled: false,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addSubtask(),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add_circle,
                          color: BrainTheme.accentPurple),
                      onPressed: _addSubtask,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.flag_outlined,
            size: 16, color: BrainTheme.textTertiary),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            AppLocalizations.of(context).status,
            style:
                TextStyle(fontSize: 13, color: BrainTheme.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: BrainTheme.surfaceDark,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BrainTheme.borderDark),
            ),
            child: DropdownButton<TaskStatus>(
              value: _status,
              dropdownColor: BrainTheme.cardDark,
              underline: const SizedBox.shrink(),
              isExpanded: true,
              items: TaskStatus.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Icon(_statusIcon(s),
                                size: 16, color: _statusColor(s)),
                            const SizedBox(width: 8),
                            Text(_statusLabel(s, context)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _status = value!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.priority_high,
                size: 16, color: BrainTheme.textTertiary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).sortPriority,
              style:
                  TextStyle(fontSize: 13, color: BrainTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: TaskPriority.values.map((priority) {
            final isSelected = priority == _priority;
            final color = BrainTheme.priorityColor(priority.index);
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _priority = priority),
                child: AnimatedContainer(
                  duration: 200.ms,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : BrainTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? color.withValues(alpha: 0.5)
                          : BrainTheme.borderDark,
                    ),
                  ),
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: 200.ms,
                        width: isSelected ? 10 : 8,
                        height: isSelected ? 10 : 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                  ),
                                ]
                              : [],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _priorityLabel(priority, context),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? color : BrainTheme.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.calendar_today_outlined,
            size: 16, color: BrainTheme.textTertiary),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            AppLocalizations.of(context).dueDate,
            style:
                TextStyle(fontSize: 13, color: BrainTheme.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _dueDate ?? DateTime.now(),
                firstDate:
                    DateTime.now().subtract(const Duration(days: 365)),
                lastDate:
                    DateTime.now().add(const Duration(days: 365 * 3)),
              );
              if (date != null) setState(() => _dueDate = date);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: BrainTheme.surfaceDark,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: BrainTheme.borderDark),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _dueDate != null &&
                            _dueDate!.isBefore(DateTime.now())
                        ? Icons.error_outline
                        : Icons.event,
                    size: 14,
                    color: _dueDate != null &&
                            _dueDate!.isBefore(DateTime.now())
                        ? BrainTheme.accentRed
                        : BrainTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _dueDate != null
                        ? DateFormat('dd MMM yyyy').format(_dueDate!)
                        : AppLocalizations.of(context).noDueDate,
                    style: TextStyle(color: BrainTheme.textPrimary),
                  ),
                  if (_dueDate != null) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => _dueDate = null),
                      child: Icon(Icons.close,
                          size: 14, color: BrainTheme.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.folder_outlined,
            size: 16, color: BrainTheme.textTertiary),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            AppLocalizations.of(context).project,
            style:
                TextStyle(fontSize: 13, color: BrainTheme.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Consumer<ProjectsProvider>(
            builder: (context, projects, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: BrainTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BrainTheme.borderDark),
                ),
                child: DropdownButton<String?>(
                  value: _projectId,
                  dropdownColor: BrainTheme.cardDark,
                  underline: const SizedBox.shrink(),
                  hint: Text(
                      AppLocalizations.of(context).noDueDate),
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(
                        value: null,
                        child: Text(
                            AppLocalizations.of(context).noDueDate)),
                    ...projects.projects
                        .map((project) => DropdownMenuItem(
                              value: project.id,
                              child: Text(
                                  '${project.emoji} ${project.title}'),
                            )),
                  ],
                  onChanged: (value) =>
                      setState(() => _projectId = value),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _deleteTask(Task task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Text(AppLocalizations.of(context).delete,
            style: TextStyle(color: BrainTheme.textPrimary)),
        content: Text(AppLocalizations.of(context).taskDeleted,
            style: TextStyle(color: BrainTheme.textSecondary)),
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
      await context.read<TasksProvider>().deleteTask(task.id);
      if (mounted) Navigator.pop(context);
    }
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _subtasks.add(SubTask(id: const Uuid().v4(), title: title));
      _subtaskController.clear();
    });
  }

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: 480,
            padding: const EdgeInsets.all(16),
            child: Consumer<TagsProvider>(builder: (context, tagsProv, _) {
              final tags = tagsProv.tags;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(AppLocalizations.of(context).tags,
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: BrainTheme.textPrimary)),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: BrainTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: tags.map((t) {
                        final isSelected = _selectedTags.contains(t.id);
                        return CheckboxListTile(
                          secondary: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: t.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(t.name,
                              style:
                                  TextStyle(color: BrainTheme.textPrimary)),
                          value: isSelected,
                          activeColor: BrainTheme.accentPurple,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              if (!_selectedTags.contains(t.id))
                                _selectedTags.add(t.id);
                            } else {
                              _selectedTags.remove(t.id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      backgroundColor: BrainTheme.accentPurple,
                    ),
                    child: Text(AppLocalizations.of(context).ok),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  void _showLinkNotes() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (sCtx, setS) {
            final notesProv = context.read<NotesProvider>();
            final notes =
                query.isEmpty ? notesProv.notes : notesProv.search(query);
            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                height: 480,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(AppLocalizations.of(context).notes,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: BrainTheme.textPrimary)),
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
                      decoration: InputDecoration(
                        hintText:
                            AppLocalizations.of(context).searchInNotes,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                      onChanged: (v) => setS(() => query = v),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView(
                        children: notes.map((n) {
                          final isLinked = _linkedNoteIds.contains(n.id);
                          return ListTile(
                            leading: Text(n.emoji,
                                style: const TextStyle(fontSize: 20)),
                            title: Text(n.title,
                                style:
                                    TextStyle(color: BrainTheme.textPrimary)),
                            subtitle: Text(n.notebook,
                                style:
                                    TextStyle(color: BrainTheme.textTertiary)),
                            trailing: isLinked
                                ? Icon(Icons.check_circle,
                                    color: BrainTheme.accentGreen)
                                : null,
                            onTap: () {
                              if (!isLinked) {
                                setState(() => _linkedNoteIds.add(n.id));
                              }
                              Navigator.pop(ctx);
                            },
                          );
                        }).toList(),
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

  void _showManageTagsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final nameCtrl = TextEditingController();
        int newTagColorValue = BrainTheme.accentPurple.toARGB32();
        return StatefulBuilder(builder: (mctx, setModalState) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: 520,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(AppLocalizations.of(context).tags,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: BrainTheme.textPrimary)),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: BrainTheme.textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Consumer<TagsProvider>(
                        builder: (context, prov, _) {
                      return ListView(
                        children: prov.tags
                            .map((t) => ListTile(
                                  leading: CircleAvatar(
                                      backgroundColor: t.color, radius: 16),
                                  title: Text(t.name,
                                      style: TextStyle(
                                          color: BrainTheme.textPrimary)),
                                  trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            icon: Icon(Icons.edit,
                                                color:
                                                    BrainTheme.textSecondary),
                                            onPressed: () {
                                              int editColorValue =
                                                  t.color.toARGB32();
                                              final editNameCtrl =
                                                  TextEditingController(
                                                      text: t.name);
                                              showDialog(
                                                  context: context,
                                                  builder: (dctx) =>
                                                      StatefulBuilder(
                                                          builder: (dState,
                                                                  setDialogState) =>
                                                              AlertDialog(
                                                                backgroundColor:
                                                                    BrainTheme
                                                                        .cardDark,
                                                                title: Text(
                                                                    AppLocalizations.of(
                                                                            context)
                                                                        .tags),
                                                                content:
                                                                    SingleChildScrollView(
                                                                        child: Column(
                                                                            mainAxisSize:
                                                                                MainAxisSize.min,
                                                                            children: [
                                                                      TextField(
                                                                          controller:
                                                                              editNameCtrl,
                                                                          decoration:
                                                                              InputDecoration(hintText: AppLocalizations.of(context).tagName)),
                                                                      const SizedBox(
                                                                          height:
                                                                              16),
                                                                      TagColorPicker(
                                                                        selectedColorValue:
                                                                            editColorValue,
                                                                        onColorChanged:
                                                                            (v) =>
                                                                                setDialogState(() => editColorValue = v),
                                                                      ),
                                                                    ])),
                                                                actions: [
                                                                  TextButton(
                                                                      onPressed: () =>
                                                                          Navigator.pop(
                                                                              dctx),
                                                                      child: Text(
                                                                          AppLocalizations.of(context)
                                                                              .cancel)),
                                                                  FilledButton(
                                                                      onPressed:
                                                                          () async {
                                                                        await prov.updateTag(t.copyWith(
                                                                            name:
                                                                                editNameCtrl.text,
                                                                            color: Color(editColorValue)));
                                                                        Navigator.pop(
                                                                            dctx);
                                                                        Navigator.pop(
                                                                            ctx);
                                                                      },
                                                                      child: Text(
                                                                          AppLocalizations.of(context)
                                                                              .save))
                                                                ],
                                                              )));
                                            }),
                                        IconButton(
                                            icon: Icon(Icons.delete_outline,
                                                color: BrainTheme.accentRed),
                                            onPressed: () =>
                                                prov.deleteTag(t.id)),
                                      ]),
                                ))
                            .toList(),
                      );
                    }),
                  ),
                  const Divider(),
                  TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context).tag)),
                  const SizedBox(height: 12),
                  TagColorPicker(
                    selectedColorValue: newTagColorValue,
                    onColorChanged: (v) =>
                        setModalState(() => newTagColorValue = v),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      await context.read<TagsProvider>().addTag(
                          name: nameCtrl.text.trim(),
                          colorValue: newTagColorValue);
                      nameCtrl.clear();
                      setModalState(() => newTagColorValue =
                          BrainTheme.accentPurple.toARGB32());
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: BrainTheme.accentPurple,
                    ),
                    child:
                        Text(AppLocalizations.of(context).createTask),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
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

// ─── FORM HELPERS ────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrainTheme.borderDark),
      ),
      child: child,
    );
  }
}

class _FormTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? hint;

  const _FormTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 14),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const _FormSection({
    required this.title,
    required this.icon,
    required this.children,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrainTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: BrainTheme.accentPurple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: BrainTheme.accentPurple),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BrainTheme.textPrimary)),
              if (trailing != null) ...[
                const Spacer(),
                trailing!,
              ],
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ─── HEADER SLIVER ─────────────────────────────────────────────────────

class _TaskHeaderSliver extends StatelessWidget {
  final Task task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback onToggle;

  const _TaskHeaderSliver({
    required this.task,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final priColor = BrainTheme.priorityColor(task.priority.index);

    return SliverAppBar(
      expandedHeight: 220,
      pinned: false,
      floating: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
          ),
          onPressed: onEdit,
        ),
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
          ),
          onPressed: onDelete,
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                priColor,
                priColor.withValues(alpha: 0.5),
                BrainTheme.primaryDark,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.35, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: task.status == TaskStatus.completed
                                  ? BrainTheme.accentGreen.withValues(alpha: 0.3)
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                task.status == TaskStatus.completed
                                    ? Icons.check_circle
                                    : Icons.task_alt,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ).animate().scaleXY(
                                begin: 0,
                                end: 1,
                                duration: 500.ms,
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  task.title,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                    height: 1.1,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                                    .animate()
                                    .fadeIn(delay: 200.ms)
                                    .slideX(begin: 0.1, end: 0),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    _TaskHeaderBadge(
                                      label: _statusLabel(task.status, context),
                                      color: _statusColor(task.status),
                                      icon: _statusIcon(task.status),
                                    )
                                        .animate()
                                        .fadeIn(delay: 300.ms)
                                        .slideX(begin: 0.1, end: 0),
                                    const SizedBox(width: 6),
                                    _TaskHeaderBadge(
                                      label: _priorityLabel(task.priority, context),
                                      color: priColor,
                                      icon: Icons.flag_outlined,
                                    )
                                        .animate()
                                        .fadeIn(delay: 400.ms)
                                        .slideX(begin: 0.1, end: 0),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(delay: 500.ms),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(TaskStatus s, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (s) {
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

  Color _statusColor(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return BrainTheme.textTertiary;
      case TaskStatus.inProgress:
        return BrainTheme.accentBlue;
      case TaskStatus.inReview:
        return BrainTheme.accentOrange;
      case TaskStatus.completed:
        return BrainTheme.accentGreen;
      case TaskStatus.cancelled:
        return Colors.grey;
    }
  }

  IconData _statusIcon(TaskStatus s) {
    switch (s) {
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

  String _priorityLabel(TaskPriority p, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (p) {
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
}

class _TaskHeaderBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _TaskHeaderBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}

// ─── META SECTION ──────────────────────────────────────────────────────

class _TaskMetaSection extends StatelessWidget {
  final Task task;
  final double subtaskProgress;
  final int subtaskDone;

  const _TaskMetaSection({
    required this.task,
    required this.subtaskProgress,
    required this.subtaskDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              _MetaTile(
                icon: Icons.checklist,
                value: '${task.subtasks.length}',
                label: AppLocalizations.of(context).subtasks,
                color: BrainTheme.accentPurple,
              ),
              const SizedBox(width: 8),
              _MetaTile(
                icon: Icons.timer_outlined,
                value: '${task.estimatedHours.toStringAsFixed(0)}h',
                label: AppLocalizations.of(context).task,
                color: BrainTheme.accentBlue,
              ),
              const SizedBox(width: 8),
              _MetaTile(
                icon: Icons.schedule,
                value: task.actualHours != null
                    ? '${task.actualHours!.toStringAsFixed(0)}h'
                    : '—',
                label: AppLocalizations.of(context).note,
                color: BrainTheme.accentOrange,
              ),
              const SizedBox(width: 8),
              _MetaTile(
                icon: task.dueDate != null
                    ? (task.isOverdue ? Icons.error_outline : Icons.event)
                    : Icons.event_busy,
                value: task.dueDate != null
                    ? DateFormat('dd MMM').format(task.dueDate!)
                    : '—',
                label: AppLocalizations.of(context).dueDate,
                color: task.isOverdue
                    ? BrainTheme.accentRed
                    : BrainTheme.textTertiary,
              ),
            ],
          ),
          if (task.subtasks.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: BrainTheme.cardDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: BrainTheme.borderDark),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context).subtasks,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: BrainTheme.textPrimary)),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: subtaskProgress),
                            duration: 600.ms,
                            curve: Curves.easeOutCubic,
                            builder: (context, value, _) {
                              return LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: BrainTheme.borderDark,
                                valueColor: AlwaysStoppedAnimation(
                                  subtaskProgress >= 1.0
                                      ? BrainTheme.accentGreen
                                      : BrainTheme.accentPurple,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$subtaskDone/${task.subtasks.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: subtaskProgress >= 1.0
                          ? BrainTheme.accentGreen
                          : BrainTheme.accentPurple,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetaTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.05),
              BrainTheme.cardDark,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BrainTheme.borderDark),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: BrainTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: BrainTheme.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TAB BAR ───────────────────────────────────────────────────────────

class _TaskTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final int subtaskCount;
  final int noteCount;

  _TaskTabBarDelegate({
    required this.tabController,
    required this.subtaskCount,
    required this.noteCount,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: 52,
      color: BrainTheme.primaryDark,
      child: TabBar(
        controller: tabController,
        labelColor: BrainTheme.accentPurple,
        unselectedLabelColor: BrainTheme.textTertiary,
        indicatorColor: BrainTheme.accentPurple,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3,
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.info_outline, size: 15),
            SizedBox(width: 5),
            Text(AppLocalizations.of(context).details),
          ])),
          Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.checklist, size: 15),
            const SizedBox(width: 5),
            Text(AppLocalizations.of(context).subtasks),
            if (subtaskCount > 0) ...[
              const SizedBox(width: 4),
              _tabCount(subtaskCount),
            ],
          ])),
          Tab(
              child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.link, size: 15),
            const SizedBox(width: 5),
            Text(AppLocalizations.of(context).notes),
            if (noteCount > 0) ...[
              const SizedBox(width: 4),
              _tabCount(noteCount),
            ],
          ])),
        ],
      ),
    );
  }

  Widget _tabCount(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: BrainTheme.accentPurple.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('$count',
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: BrainTheme.accentPurple)),
    );
  }

  @override
  double get maxExtent => 52;
  @override
  double get minExtent => 52;

  @override
  bool shouldRebuild(_TaskTabBarDelegate oldDelegate) {
    return subtaskCount != oldDelegate.subtaskCount ||
        noteCount != oldDelegate.noteCount;
  }
}

// ─── INFO TAB ──────────────────────────────────────────────────────────

class _TaskInfoTab extends StatelessWidget {
  final Task task;

  const _TaskInfoTab({required this.task});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoCard(
          icon: Icons.description_outlined,
          iconColor: BrainTheme.accentPurple,
          title: AppLocalizations.of(context).description,
          child: Text(
            task.description.isNotEmpty
                ? task.description
                : AppLocalizations.of(context).noData,
            style: TextStyle(
              fontSize: 14,
              color: task.description.isNotEmpty
                  ? BrainTheme.textSecondary
                  : BrainTheme.textTertiary,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _InfoCard(
          icon: Icons.info_outline,
          iconColor: BrainTheme.accentBlue,
          title: AppLocalizations.of(context).details,
          child: Column(
            children: [
              _detailRow(
                  Icons.flag_outlined,
                  AppLocalizations.of(context).status,
                  _statusLabel(task.status, context)),
              const Divider(height: 16),
              _detailRow(
                  Icons.priority_high,
                  AppLocalizations.of(context).sortPriority,
                  _priorityLabel(task.priority, context)),
              const Divider(height: 16),
              _detailRow(
                Icons.calendar_today_outlined,
                AppLocalizations.of(context).itemCreated,
                DateFormat('dd MMM yyyy, HH:mm').format(task.createdAt),
              ),
              if (task.dueDate != null) ...[
                const Divider(height: 16),
                _detailRow(
                  task.isOverdue ? Icons.error_outline : Icons.event,
                  AppLocalizations.of(context).dueDate,
                  DateFormat('dd MMM yyyy').format(task.dueDate!),
                  valueColor:
                      task.isOverdue ? BrainTheme.accentRed : null,
                ),
              ],
              if (task.projectId != null) ...[
                const Divider(height: 16),
                Consumer<ProjectsProvider>(builder: (context, pp, _) {
                  final project = pp.getProjectById(task.projectId!);
                  return _detailRow(
                    Icons.folder_outlined,
                    AppLocalizations.of(context).project,
                    project != null
                        ? '${project.emoji} ${project.title}'
                        : '—',
                  );
                }),
              ],
              const Divider(height: 16),
              _detailRow(
                  Icons.timer_outlined,
                  AppLocalizations.of(context).task,
                  '${task.estimatedHours.toStringAsFixed(1)}h'),
              if (task.actualHours != null) ...[
                const Divider(height: 16),
                _detailRow(Icons.schedule,
                    AppLocalizations.of(context).note,
                    '${task.actualHours!.toStringAsFixed(1)}h'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _statusLabel(TaskStatus s, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (s) {
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

  String _priorityLabel(TaskPriority p, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (p) {
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

  Widget _detailRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 15, color: BrainTheme.textTertiary),
        const SizedBox(width: 10),
        SizedBox(
          width: 80,
          child: Text(label,
              style:
                  TextStyle(fontSize: 12, color: BrainTheme.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: valueColor ?? BrainTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrainTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 14, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: BrainTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

// ─── SUBTASKS TAB ──────────────────────────────────────────────────────

class _TaskSubtabsTab extends StatelessWidget {
  final List<SubTask> subtasks;
  final String taskId;
  final ValueChanged<List<SubTask>> onChanged;

  const _TaskSubtabsTab({
    required this.subtasks,
    required this.taskId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (subtasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📋', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).noTasks,
                style: TextStyle(
                    fontSize: 16, color: BrainTheme.textSecondary)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).emptyStateDescription,
                style:
                    TextStyle(fontSize: 13, color: BrainTheme.textTertiary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: subtasks.length,
      itemBuilder: (_, index) {
        final subtask = subtasks[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: BrainTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BrainTheme.borderDark),
          ),
          child: ListTile(
            dense: true,
            leading: GestureDetector(
              onTap: () {
                final updated = [...subtasks];
                updated[index] = subtask.copyWith(isDone: !subtask.isDone);
                onChanged(updated);
              },
              child: AnimatedContainer(
                duration: 200.ms,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: subtask.isDone
                      ? BrainTheme.accentGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: subtask.isDone
                        ? BrainTheme.accentGreen
                        : BrainTheme.borderDark,
                    width: 2,
                  ),
                ),
                child: subtask.isDone
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
            ),
            title: Text(
              subtask.title,
              style: TextStyle(
                fontSize: 13,
                color: subtask.isDone
                    ? BrainTheme.textTertiary
                    : BrainTheme.textPrimary,
                decoration: subtask.isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── NOTES TAB ─────────────────────────────────────────────────────────

class _TaskNotesTab extends StatelessWidget {
  final List<String> linkedNoteIds;
  final ValueChanged<List<String>> onChanged;

  const _TaskNotesTab({
    required this.linkedNoteIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (linkedNoteIds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔗', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).noData,
                style: TextStyle(
                    fontSize: 16, color: BrainTheme.textSecondary)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).emptyStateDescription,
                style:
                    TextStyle(fontSize: 13, color: BrainTheme.textTertiary)),
          ],
        ),
      );
    }

    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: linkedNoteIds.length,
          itemBuilder: (_, index) {
            final note = provider.getNoteById(linkedNoteIds[index]);
            if (note == null) return const SizedBox.shrink();
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BrainTheme.cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BrainTheme.borderDark),
              ),
              child: Row(
                children: [
                  Text(note.emoji,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(note.title,
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: BrainTheme.textPrimary,
                                fontSize: 14)),
                        Text(note.notebook,
                            style: TextStyle(
                                color: BrainTheme.textTertiary,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.link_off,
                        color: BrainTheme.accentRed, size: 18),
                    onPressed: () {
                      final updated = List<String>.from(linkedNoteIds)
                        ..removeAt(index);
                      onChanged(updated);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
