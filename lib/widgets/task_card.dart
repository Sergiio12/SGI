import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final subtaskProgress = task.subtasks.isEmpty
        ? (isDone ? 1.0 : 0.0)
        : task.subtasks.where((s) => s.isDone).length / task.subtasks.length;
    final hasSubtasks = task.subtasks.isNotEmpty;

    final borderColor = isCancelled
        ? BrainTheme.accentRed.withValues(alpha: 0.2)
        : isDone
            ? BrainTheme.accentGreen.withValues(alpha: 0.15)
            : BrainTheme.borderDark.withValues(alpha: 0.5);

    final stripColor = isDone
        ? BrainTheme.accentGreen.withValues(alpha: 0.5)
        : isCancelled
            ? BrainTheme.accentRed.withValues(alpha: 0.5)
            : priColor;

    final card = Semantics(
      label: '${task.title}, ${task.status.name}',
      button: true,
      onTapHint: onTap != null ? l10n.details : null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: ShapeDecoration(
          color: BrainTheme.cardDark.withValues(alpha: isDimmed ? 0.5 : 0.9),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderColor, width: 1),
          ),
          shadows: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 3, color: stripColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(13, 9, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            height: 1.2,
                            color: isDimmed
                                ? BrainTheme.textTertiary
                                : BrainTheme.textPrimary,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDimmed
                            ? BrainTheme.textTertiary.withValues(alpha: 0.6)
                            : BrainTheme.textSecondary,
                        height: 1.2,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _MetadataRow(
                    task: task,
                    isDimmed: isDimmed,
                    priColor: priColor,
                    hasSubtasks: hasSubtasks,
                    subtaskProgress: subtaskProgress,
                  ),
                  if (hasSubtasks) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: subtaskProgress),
                        duration: 600.ms,
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) {
                          return LinearProgressIndicator(
                            value: value,
                            minHeight: 2,
                            backgroundColor:
                                BrainTheme.borderDark.withValues(alpha: 0.4),
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
                ],
              ),
            ),
          ],
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
            backgroundColor: BrainTheme.accentRed.withValues(alpha: 0.15),
            foregroundColor: BrainTheme.accentRed,
            icon: Icons.delete_outline,
            label: AppLocalizations.of(context).delete,
            borderRadius: BorderRadius.circular(14),
          ),
        ],
      ),
      child: card,
    );
  }

}

class _MetadataRow extends StatelessWidget {
  final Task task;
  final bool isDimmed;
  final Color priColor;
  final bool hasSubtasks;
  final double subtaskProgress;

  const _MetadataRow({
    required this.task,
    required this.isDimmed,
    required this.priColor,
    required this.hasSubtasks,
    required this.subtaskProgress,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDimmed
        ? BrainTheme.textTertiary.withValues(alpha: 0.6)
        : BrainTheme.textTertiary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 5, height: 5,
          decoration: BoxDecoration(
            color: priColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          _priorityLabel(task.priority, context),
          style: TextStyle(
            fontSize: 10,
            color: priColor,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.calendar_today, size: 9, color: textColor),
        const SizedBox(width: 2),
        Text(
          DateFormat('dd/MM/yy').format(task.createdAt),
          style: TextStyle(fontSize: 10, color: textColor, height: 1.1),
        ),
        if (task.dueDate != null) ...[
          const SizedBox(width: 8),
          Icon(
            task.isOverdue ? Icons.error_outline : Icons.event,
            size: 9,
            color: task.isOverdue ? BrainTheme.accentRed : textColor,
          ),
          const SizedBox(width: 2),
          Text(
            DateFormat('dd/MM/yy').format(task.dueDate!),
            style: TextStyle(
              fontSize: 10,
              color: task.isOverdue ? BrainTheme.accentRed : textColor,
              fontWeight: task.isOverdue ? FontWeight.w600 : FontWeight.w400,
              height: 1.1,
            ),
          ),
        ],
        if (hasSubtasks) ...[
          const SizedBox(width: 8),
          Icon(Icons.checklist, size: 9, color: textColor),
          const SizedBox(width: 2),
          Text(
            '${task.subtasks.where((s) => s.isDone).length}/${task.subtasks.length}',
            style: TextStyle(fontSize: 10, color: textColor, height: 1.1),
          ),
        ],
        if (task.projectId != null) ...[
          const SizedBox(width: 8),
          _ProjectBadgeCompact(projectId: task.projectId!),
        ],
      ],
    );
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

class _ProjectBadgeCompact extends StatelessWidget {
  final String projectId;

  const _ProjectBadgeCompact({required this.projectId});

  @override
  Widget build(BuildContext context) {
    final project = context.select<ProjectsProvider, Project?>(
      (p) => p.getProjectById(projectId),
    );
    if (project == null) return const SizedBox.shrink();
    final color = Color(project.colorValue);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          project.title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
            height: 1.1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
