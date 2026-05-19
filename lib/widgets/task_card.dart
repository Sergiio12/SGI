import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDismissed;
  final Widget? action;
  final bool enableSlide;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggle,
    this.onDismissed,
    this.action,
    this.enableSlide = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.completed;
    final card = Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDone
              ? Colors.transparent
              : BrainTheme.priorityColor(task.priority.index)
                  .withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: isDone
          ? BrainTheme.surfaceDark.withValues(alpha: 0.5)
          : BrainTheme.cardDark,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                              color: isDone
                                  ? BrainTheme.textTertiary
                                  : BrainTheme.textPrimary,
                              decoration:
                                  isDone ? TextDecoration.lineThrough : null,
                            ),
                          ),
                        ),
                        if (task.dueDate != null) ...[
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: task.isOverdue
                                  ? BrainTheme.accentRed.withValues(alpha: 0.12)
                                  : BrainTheme.accentBlue
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              DateFormat('dd MMM').format(task.dueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: task.isOverdue
                                    ? BrainTheme.accentRed
                                    : BrainTheme.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (task.description.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        task.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: BrainTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _statusColor(task.status)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusLabel(task.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(task.status),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: BrainTheme.priorityColor(task.priority.index)
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            task.priority.name[0].toUpperCase() +
                                task.priority.name.substring(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color:
                                  BrainTheme.priorityColor(task.priority.index),
                            ),
                          ),
                        ),
                        if (task.subtasks.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: BrainTheme.accentPurple
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${task.subtasks.where((s) => s.isDone).length}/${task.subtasks.length} subtareas',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: BrainTheme.accentPurple,
                              ),
                            ),
                          ),
                        if (task.tags.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: BrainTheme.textSecondary
                                  .withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${task.tags.length} etiquetas',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: BrainTheme.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (action != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: action,
                ),
            ],
          ),
        ),
      ),
    );

    return enableSlide
        ? Slidable(
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
                  borderRadius: BorderRadius.circular(20),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            child: card,
          )
        : card;
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

String _statusLabel(TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return 'Pendiente';
    case TaskStatus.inProgress:
      return 'Progreso';
    case TaskStatus.inReview:
      return 'Revision';
    case TaskStatus.completed:
      return 'Finalizada';
    case TaskStatus.cancelled:
      return 'Anulada';
  }
}
