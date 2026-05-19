import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../providers/projects_provider.dart';
import 'package:provider/provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDismissed;
  final Widget? action;
  final bool enableSlide;
  final bool compact;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggle,
    this.onDismissed,
    this.action,
    this.enableSlide = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.completed;
    final isCancelled = task.status == TaskStatus.cancelled;
    final isDimmed = isDone || isCancelled;
    final priColor = BrainTheme.priorityColor(task.priority.index);
    final borderColor = isCancelled
        ? BrainTheme.accentRed.withValues(alpha: 0.3)
        : isDone
            ? Colors.transparent
            : priColor.withValues(alpha: 0.25);
    final leftBarColor = isCancelled
        ? BrainTheme.accentRed.withValues(alpha: 0.5)
        : isDone
            ? Colors.transparent
            : priColor;

    final card = Semantics(
      label: '${task.title}, ${task.status.name}',
      value: isDone ? 'Completada' : isCancelled ? 'Anulada' : 'Activa',
      button: true,
      onTapHint: onTap != null ? 'Abrir detalles' : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: borderColor, width: 1.2),
        ),
        color: isDone
            ? BrainTheme.surfaceDark.withValues(alpha: 0.5)
            : isCancelled
                ? BrainTheme.surfaceDark.withValues(alpha: 0.3)
                : BrainTheme.cardDark,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: leftBarColor,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 10 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                maxLines: compact ? 1 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: compact ? 13 : 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: isDimmed
                                      ? BrainTheme.textTertiary
                                      : BrainTheme.textPrimary,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                            if (action != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: action,
                              ),
                          ],
                        ),
                        if (task.description.isNotEmpty && !compact) ...[
                          const SizedBox(height: 6),
                          Text(
                            task.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: BrainTheme.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _StatusBadge(status: task.status),
                            _PriorityBadge(priority: task.priority),
                            if (task.dueDate != null)
                              _DateBadge(date: task.dueDate!, isOverdue: task.isOverdue),
                            if (task.subtasks.isNotEmpty)
                              _subtabsBadge(task),
                            if (task.projectId != null)
                              _ProjectBadge(projectId: task.projectId!),
                            _DateBadge(
                              date: task.createdAt,
                              isOverdue: false,
                              compact: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.03, end: 0);

    if (!enableSlide) return card;

    return Slidable(
      key: Key(task.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => onDismissed?.call(),
            backgroundColor: BrainTheme.accentRed.withValues(alpha: 0.2),
            foregroundColor: BrainTheme.accentRed,
            icon: Icons.delete_outline,
            label: 'Eliminar',
            borderRadius: BorderRadius.circular(18),
          ),
        ],
      ),
      child: card,
    );
  }

  Widget _subtabsBadge(Task task) {
    final done = task.subtasks.where((s) => s.isDone).length;
    final total = task.subtasks.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: BrainTheme.accentPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.checklist, size: 10, color: BrainTheme.accentPurple),
          const SizedBox(width: 3),
          Text(
            '$done/$total',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: BrainTheme.accentPurple,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TaskStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final data = _statusData(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 10, color: data.color),
          const SizedBox(width: 3),
          Text(
            data.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: data.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusData _statusData(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return _StatusData(Icons.circle_outlined, BrainTheme.textTertiary, 'Pendiente');
      case TaskStatus.inProgress:
        return _StatusData(Icons.play_circle_outline, BrainTheme.accentBlue, 'Progreso');
      case TaskStatus.inReview:
        return _StatusData(Icons.rate_review_outlined, BrainTheme.accentOrange, 'Revision');
      case TaskStatus.completed:
        return _StatusData(Icons.check_circle, BrainTheme.accentGreen, 'Listo');
      case TaskStatus.cancelled:
        return _StatusData(Icons.cancel_outlined, BrainTheme.accentRed, 'Anulada');
    }
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = BrainTheme.priorityColor(priority.index);
    String label;
    switch (priority) {
      case TaskPriority.low: label = 'Baja';
      case TaskPriority.medium: label = 'Media';
      case TaskPriority.high: label = 'Alta';
      case TaskPriority.urgent: label = 'Urgente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  final DateTime date;
  final bool isOverdue;
  final bool compact;

  const _DateBadge({
    required this.date,
    required this.isOverdue,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: BrainTheme.textTertiary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          DateFormat('dd/MM').format(date),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: BrainTheme.textTertiary,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isOverdue
            ? BrainTheme.accentRed.withValues(alpha: 0.1)
            : BrainTheme.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOverdue ? Icons.error_outline : Icons.schedule,
            size: 10,
            color: isOverdue ? BrainTheme.accentRed : BrainTheme.accentBlue,
          ),
          const SizedBox(width: 3),
          Text(
            DateFormat('dd MMM').format(date),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isOverdue ? BrainTheme.accentRed : BrainTheme.accentBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectBadge extends StatelessWidget {
  final String projectId;

  const _ProjectBadge({required this.projectId});

  @override
  Widget build(BuildContext context) {
    final project = context.select<ProjectsProvider, Project?>(
      (p) => p.getProjectById(projectId),
    );
    if (project == null) return const SizedBox.shrink();
    return Semantics(
      label: 'Proyecto: ${project.title}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Color(project.colorValue).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          '${project.emoji} ${project.title}',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(project.colorValue),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _StatusData {
  final IconData icon;
  final Color color;
  final String label;

  const _StatusData(this.icon, this.color, this.label);
}
