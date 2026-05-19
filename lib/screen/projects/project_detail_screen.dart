import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../providers/goals_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../utils/notification_service_v2.dart';
import '../../widgets/note_card.dart';
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
  bool _isEditing = false;
  bool _showForm = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _isEditing = widget.projectId != null;

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
    } else {
      _showForm = true;
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
    final project = _isEditing
        ? context.watch<ProjectsProvider>().getProjectById(widget.projectId!)
        : null;

    return Scaffold(
      body: project == null && _isEditing
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(project),
    );
  }

  Widget _buildBody(Project? project) {
    if (_showForm || !_isEditing) {
      return _buildFormView(project);
    }
    return _buildDetailView(project!);
  }

  Widget _buildDetailView(Project project) {
    final tasksProvider = context.watch<TasksProvider>();
    final projectTasks = tasksProvider.getTasksByProject(project.id);
    final completedTasks =
        projectTasks.where((t) => t.status == TaskStatus.completed).length;
    final progress =
        projectTasks.isEmpty ? 0.0 : completedTasks / projectTasks.length;

    return CustomScrollView(
      slivers: [
        _HeaderSliver(
          project: project,
          progress: progress,
          onEdit: () => setState(() => _showForm = true),
          onDelete: () => _deleteProject(project),
          onStatusChanged: (status) {
            context
                .read<ProjectsProvider>()
                .updateProject(project.copyWith(status: status));
          },
        ),
        SliverToBoxAdapter(
          child: _QuickActions(project: project, progress: progress),
        ),
        SliverToBoxAdapter(
          child: _ProjectMeta(
            project: project,
            progress: progress,
            totalTasks: projectTasks.length,
            completedTasks: completedTasks,
          ),
        ),
        SliverToBoxAdapter(
          child: const SizedBox(height: 8),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabBarDelegate(
            tabController: _tabController,
            tasksCount: projectTasks.length,
            notesCount:
                context.watch<NotesProvider>().getNotesByProject(project.id).length,
          ),
        ),
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ProjectInfoTab(projectId: project.id),
              _ProjectTasksTab(projectId: project.id),
              _ProjectNotesTab(projectId: project.id),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormView(Project? project) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Editar proyecto' : 'Nuevo proyecto',
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: BrainTheme.accentRed),
              onPressed: () => _deleteProject(project!),
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
                      child: Text(_emoji, style: const TextStyle(fontSize: 28)),
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
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              style: TextStyle(
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
              style: TextStyle(
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
            Text(
              'Color',
              style: TextStyle(fontSize: 13, color: BrainTheme.textTertiary),
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
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
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
              onPriorityChanged: (value) => setState(() => _priority = value),
              onStartDateChanged: (value) => setState(() => _startDate = value),
              onDeadlineChanged: (value) => setState(() => _deadline = value),
              onGoalChanged: (value) => setState(() => _goalId = value),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Text('Eliminar proyecto',
            style: TextStyle(color: BrainTheme.textPrimary)),
        content: Text(
          'Se moverá a la papelera. ¿Deseas continuar?',
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
      await context.read<ProjectsProvider>().deleteProject(project.id);
      if (mounted) Navigator.pop(context);
    }
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

// ─── HEADER SLIVER ───────────────────────────────────────────────────────

class _HeaderSliver extends StatelessWidget {
  final Project project;
  final double progress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<ProjectStatus> onStatusChanged;

  const _HeaderSliver({
    required this.project,
    required this.progress,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final projColor = Color(project.colorValue);

    return SliverAppBar(
      expandedHeight: 280,
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
                projColor,
                projColor.withValues(alpha: 0.6),
                BrainTheme.primaryDark,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                bottom: 40,
                left: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
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
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                project.emoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                          ).animate().scaleXY(
                            begin: 0,
                            end: 1,
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project.title,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1, end: 0),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _HeaderBadge(
                                      label: _statusLabel(project.status),
                                      color: _statusColor(project.status),
                                      icon: _statusIcon(project.status),
                                    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.1, end: 0),
                                    const SizedBox(width: 8),
                                    _HeaderBadge(
                                      label: _priorityLabel(project.priority),
                                      color: BrainTheme.priorityColor(project.priority.index),
                                      icon: Icons.flag_outlined,
                                    ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (project.objective.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.track_changes, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                project.objective,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
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

  String _statusLabel(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active: return 'Activo';
      case ProjectStatus.paused: return 'Pausado';
      case ProjectStatus.completed: return 'Finalizado';
      case ProjectStatus.abandoned: return 'Abandonado';
    }
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active: return BrainTheme.accentGreen;
      case ProjectStatus.paused: return BrainTheme.accentOrange;
      case ProjectStatus.completed: return BrainTheme.accentBlue;
      case ProjectStatus.abandoned: return Colors.grey;
    }
  }

  IconData _statusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active: return Icons.play_arrow_rounded;
      case ProjectStatus.paused: return Icons.pause_rounded;
      case ProjectStatus.completed: return Icons.check_rounded;
      case ProjectStatus.abandoned: return Icons.stop_rounded;
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low: return 'Baja';
      case TaskPriority.medium: return 'Media';
      case TaskPriority.high: return 'Alta';
      case TaskPriority.urgent: return 'Urgente';
    }
  }
}

class _HeaderBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _HeaderBadge({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QUICK ACTIONS ──────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  final Project project;
  final double progress;

  const _QuickActions({required this.project, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _QuickActionButton(
            icon: Icons.check_circle_outline,
            label: 'Completar',
            color: project.status == ProjectStatus.completed
                ? BrainTheme.accentGreen
                : BrainTheme.textSecondary,
            onTap: () {
              final provider = context.read<ProjectsProvider>();
              final newStatus = project.status == ProjectStatus.completed
                  ? ProjectStatus.active
                  : ProjectStatus.completed;
              provider.updateProject(project.copyWith(status: newStatus));
            },
          ),
          const SizedBox(width: 10),
          _QuickActionButton(
            icon: project.status == ProjectStatus.paused
                ? Icons.play_circle_outline
                : Icons.pause_circle_outline,
            label: project.status == ProjectStatus.paused ? 'Reanudar' : 'Pausar',
            color: project.status == ProjectStatus.paused
                ? BrainTheme.accentGreen
                : BrainTheme.accentOrange,
            onTap: () {
              final provider = context.read<ProjectsProvider>();
              final newStatus = project.status == ProjectStatus.paused
                  ? ProjectStatus.active
                  : ProjectStatus.paused;
              provider.updateProject(project.copyWith(status: newStatus));
            },
          ),
          const SizedBox(width: 10),
          _QuickActionButton(
            icon: Icons.timer_outlined,
            label: 'Progreso',
            color: BrainTheme.accentPurple,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Progreso: ${(progress * 100).toInt()}%'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0);
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
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
      ),
    );
  }
}

// ─── PROJECT META ───────────────────────────────────────────────────────

class _ProjectMeta extends StatelessWidget {
  final Project project;
  final double progress;
  final int totalTasks;
  final int completedTasks;

  const _ProjectMeta({
    required this.project,
    required this.progress,
    required this.totalTasks,
    required this.completedTasks,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              _MetaCard(
                icon: Icons.task_alt,
                value: '$totalTasks',
                label: 'Tareas totales',
                color: BrainTheme.accentPurple,
              ),
              const SizedBox(width: 10),
              _MetaCard(
                icon: Icons.check_circle,
                value: '$completedTasks',
                label: 'Completadas',
                color: BrainTheme.accentGreen,
              ),
              const SizedBox(width: 10),
              _MetaCard(
                icon: Icons.note_outlined,
                value: '${project.noteIds.length}',
                label: 'Notas',
                color: BrainTheme.accentBlue,
              ),
            ],
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BrainTheme.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: BrainTheme.borderDark),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Progreso general',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: BrainTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${(progress * 100).toInt()}% completado',
                        style: TextStyle(
                          fontSize: 12,
                          color: BrainTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: BrainTheme.borderDark,
                          valueColor: AlwaysStoppedAnimation(
                            Color(project.colorValue),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 5,
                          backgroundColor: BrainTheme.borderDark,
                          valueColor: AlwaysStoppedAnimation(
                            Color(project.colorValue),
                          ),
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(project.colorValue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
          const SizedBox(height: 16),
          Row(
            children: [
              _DetailMeta(
                icon: Icons.calendar_today_outlined,
                label: 'Fecha inicio',
                value: DateFormat('dd MMM yyyy').format(project.startDate),
              ),
              const SizedBox(width: 10),
              _DetailMeta(
                icon: Icons.event_outlined,
                label: project.deadline != null ? 'Fecha limite' : 'Sin fecha',
                value: project.deadline != null
                    ? DateFormat('dd MMM yyyy').format(project.deadline!)
                    : '—',
                valueColor: project.deadline != null &&
                        project.deadline!.isBefore(DateTime.now())
                    ? BrainTheme.accentRed
                    : null,
              ),
            ],
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MetaCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BrainTheme.borderDark),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BrainTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: BrainTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailMeta({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BrainTheme.borderDark),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: BrainTheme.textTertiary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: BrainTheme.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? BrainTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── TAB BAR DELEGATE ───────────────────────────────────────────────────

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController tabController;
  final int tasksCount;
  final int notesCount;

  _TabBarDelegate({
    required this.tabController,
    required this.tasksCount,
    required this.notesCount,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: 56,
      color: BrainTheme.primaryDark,
      child: TabBar(
        controller: tabController,
        labelColor: BrainTheme.accentPurple,
        unselectedLabelColor: BrainTheme.textTertiary,
        indicatorColor: BrainTheme.accentPurple,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 6),
                const Text('Info'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.task_alt, size: 16),
                const SizedBox(width: 6),
                Text('Tareas'),
                if (tasksCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BrainTheme.accentPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$tasksCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: BrainTheme.accentPurple,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.note_outlined, size: 16),
                const SizedBox(width: 6),
                Text('Notas'),
                if (notesCount > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BrainTheme.accentPurple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$notesCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: BrainTheme.accentPurple,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 56;
  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) {
    return tasksCount != oldDelegate.tasksCount ||
        notesCount != oldDelegate.notesCount;
  }
}

// ─── INFO TAB ───────────────────────────────────────────────────────────

class _ProjectInfoTab extends StatelessWidget {
  final String projectId;

  const _ProjectInfoTab({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Consumer2<TasksProvider, NotesProvider>(
      builder: (context, tasks, notes, _) {
        final projectTasks = tasks.getTasksByProject(projectId);
        final projectNotes = notes.getNotesByProject(projectId);
        final completed =
            projectTasks.where((t) => t.status == TaskStatus.completed).length;
        final progress =
            projectTasks.isEmpty ? 0.0 : completed / projectTasks.length;

        final overdueTasks =
            projectTasks.where((t) => t.isOverdue).length;
        final inProgressTasks =
            projectTasks.where((t) => t.status == TaskStatus.inProgress).length;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics_outlined,
                            size: 18, color: BrainTheme.accentPurple),
                        const SizedBox(width: 8),
                        Text(
                          'Estadisticas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: BrainTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _StatTile(
                          icon: Icons.pending_outlined,
                          value: '${projectTasks.length - completed}',
                          label: 'Pendientes',
                          color: BrainTheme.accentOrange,
                        ),
                        const SizedBox(width: 8),
                        _StatTile(
                          icon: Icons.play_circle_outline,
                          value: '$inProgressTasks',
                          label: 'En progreso',
                          color: BrainTheme.accentBlue,
                        ),
                        const SizedBox(width: 8),
                        _StatTile(
                          icon: Icons.warning_amber_outlined,
                          value: '$overdueTasks',
                          label: 'Vencidas',
                          color: overdueTasks > 0
                              ? BrainTheme.accentRed
                              : BrainTheme.textTertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatTile(
                          icon: Icons.check_circle_outline,
                          value: '$completed',
                          label: 'Completadas',
                          color: BrainTheme.accentGreen,
                        ),
                        const SizedBox(width: 8),
                        _StatTile(
                          icon: Icons.notes_outlined,
                          value: '${projectNotes.length}',
                          label: 'Notas',
                          color: BrainTheme.accentPurple,
                        ),
                        const SizedBox(width: 8),
                        _StatTile(
                          icon: Icons.percent_outlined,
                          value: '${(progress * 100).toInt()}%',
                          label: 'Progreso',
                          color: Color(
                            context
                                .read<ProjectsProvider>()
                                .getProjectById(projectId)
                                ?.colorValue ?? 0xFF9D4EDD,
                          ),
                        ),
                      ],
                    ),
                    if (projectTasks.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: BrainTheme.borderDark,
                          valueColor: AlwaysStoppedAnimation(
                            Color(
                              context
                                  .read<ProjectsProvider>()
                                  .getProjectById(projectId)
                                  ?.colorValue ?? 0xFF9D4EDD,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),
            if (projectTasks.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.schedule_outlined,
                              size: 18, color: BrainTheme.accentBlue),
                          const SizedBox(width: 8),
                          Text(
                            'Distribucion de tareas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: BrainTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _taskStatusRow('Pendientes', projectTasks
                          .where((t) => t.status == TaskStatus.pending).length,
                          projectTasks.length, BrainTheme.textTertiary),
                      const SizedBox(height: 10),
                      _taskStatusRow('En progreso', projectTasks
                          .where((t) => t.status == TaskStatus.inProgress).length,
                          projectTasks.length, BrainTheme.accentBlue),
                      const SizedBox(height: 10),
                      _taskStatusRow('En revision', projectTasks
                          .where((t) => t.status == TaskStatus.inReview).length,
                          projectTasks.length, BrainTheme.accentOrange),
                      const SizedBox(height: 10),
                      _taskStatusRow('Completadas', completed,
                          projectTasks.length, BrainTheme.accentGreen),
                      const SizedBox(height: 10),
                      _taskStatusRow('Anuladas', projectTasks
                          .where((t) => t.status == TaskStatus.cancelled).length,
                          projectTasks.length, BrainTheme.accentRed),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
            ],
            if (projectNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.notes_outlined,
                              size: 18, color: BrainTheme.accentPurple),
                          const SizedBox(width: 8),
                          Text(
                            'Notas recientes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: BrainTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...projectNotes.take(3).map((note) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: BrainTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(note.emoji, style: const TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.title,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: BrainTheme.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormat('dd MMM yyyy').format(note.updatedAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: BrainTheme.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms),
            ],
          ],
        );
      },
    );
  }

  Widget _taskStatusRow(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: BrainTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: BrainTheme.borderDark,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
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
              fontSize: 10,
              color: BrainTheme.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── TASKS TAB ──────────────────────────────────────────────────────────

class _ProjectTasksTab extends StatelessWidget {
  final String projectId;

  const _ProjectTasksTab({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Consumer<TasksProvider>(
      builder: (context, provider, _) {
        final tasks = provider.getTasksByProject(projectId);
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📋', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'No hay tareas en este proyecto',
                  style: TextStyle(
                    fontSize: 16,
                    color: BrainTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea tareas desde la pantalla principal',
                  style: TextStyle(
                    fontSize: 13,
                    color: BrainTheme.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: tasks.length,
          itemBuilder: (_, index) => TaskCard(
            task: tasks[index],
            onTap: () => Navigator.pushNamed(context, '/task',
                arguments: tasks[index].id),
            onToggle: () => provider.toggleTaskStatus(tasks[index].id),
          ).animate().fadeIn(
            duration: 300.ms,
            delay: (index * 50).ms,
          ).slideX(begin: 0.05, end: 0),
        );
      },
    );
  }
}

// ─── NOTES TAB ──────────────────────────────────────────────────────────

class _ProjectNotesTab extends StatelessWidget {
  final String projectId;

  const _ProjectNotesTab({required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        final notes = provider.getNotesByProject(projectId);
        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('📝', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'No hay notas en este proyecto',
                  style: TextStyle(
                    fontSize: 16,
                    color: BrainTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crea notas desde la pantalla principal',
                  style: TextStyle(
                    fontSize: 13,
                    color: BrainTheme.textTertiary,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: notes.length,
          itemBuilder: (_, index) => NoteCard(
            note: notes[index],
            onTap: () => Navigator.pushNamed(context, '/note',
                arguments: notes[index].id),
          ).animate().fadeIn(
            duration: 300.ms,
            delay: (index * 50).ms,
          ).slideX(begin: 0.05, end: 0),
        );
      },
    );
  }
}

// ─── FORM META GRID ─────────────────────────────────────────────────────

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
                            child: Row(
                              children: [
                                Icon(_statusIcon(s), size: 16, color: _statusColor(s)),
                                const SizedBox(width: 8),
                                Text(_statusLabel(s)),
                              ],
                            ),
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
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: BrainTheme.priorityColor(p.index),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(_priorityLabel(p)),
                              ],
                            ),
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

  String _statusLabel(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.active: return 'Activo';
      case ProjectStatus.paused: return 'Pausado';
      case ProjectStatus.completed: return 'Finalizado';
      case ProjectStatus.abandoned: return 'Abandonado';
    }
  }

  Color _statusColor(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.active: return BrainTheme.accentGreen;
      case ProjectStatus.paused: return BrainTheme.accentOrange;
      case ProjectStatus.completed: return BrainTheme.accentBlue;
      case ProjectStatus.abandoned: return BrainTheme.textTertiary;
    }
  }

  IconData _statusIcon(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.active: return Icons.play_arrow_rounded;
      case ProjectStatus.paused: return Icons.pause_rounded;
      case ProjectStatus.completed: return Icons.check_rounded;
      case ProjectStatus.abandoned: return Icons.stop_rounded;
    }
  }

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.low: return 'Baja';
      case TaskPriority.medium: return 'Media';
      case TaskPriority.high: return 'Alta';
      case TaskPriority.urgent: return 'Urgente';
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
          style: TextStyle(fontSize: 13, color: BrainTheme.textTertiary),
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
