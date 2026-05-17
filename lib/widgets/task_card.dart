import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../providers/tags_provider.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onToggle;
  final VoidCallback? onDismissed;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onToggle,
    this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.completed;

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
            borderRadius: BorderRadius.circular(20),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
      child: Card(
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
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          isDone ? BrainTheme.accentGreen : Colors.transparent,
                      border: Border.all(
                        color: isDone
                            ? BrainTheme.accentGreen
                            : BrainTheme.priorityColor(task.priority.index),
                        width: 2,
                      ),
                      boxShadow: isDone
                          ? [
                              BoxShadow(
                                color: BrainTheme.accentGreen
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: -2,
                              )
                            ]
                          : null,
                    ),
                    child: isDone
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                          color: isDone
                              ? BrainTheme.textTertiary
                              : BrainTheme.textPrimary,
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      // Description hidden by default; show preview button
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: BrainTheme.cardDark,
                                title: Text('Descripción',
                                    style: TextStyle(
                                        color: BrainTheme.textPrimary)),
                                content: SingleChildScrollView(
                                  child: Text(task.description,
                                      style: TextStyle(
                                          color: BrainTheme.textSecondary)),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text('Cerrar')),
                                ],
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 14, color: BrainTheme.textTertiary),
                              const SizedBox(width: 6),
                              Text('Ver descripción',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: BrainTheme.textTertiary)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor(task.status)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _statusIcon(task.status),
                                  size: 12,
                                  color: _statusColor(task.status),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _statusLabel(task.status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _statusColor(task.status),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Due date
                          if (task.dueDate != null) ...[
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: task.isOverdue
                                  ? BrainTheme.accentRed
                                  : BrainTheme.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('dd MMM').format(task.dueDate!),
                              style: TextStyle(
                                fontSize: 12,
                                color: task.isOverdue
                                    ? BrainTheme.accentRed
                                    : BrainTheme.textTertiary,
                                fontWeight:
                                    task.isOverdue ? FontWeight.w600 : null,
                              ),
                            ),
                          ],

                          // Subtasks progress
                          if (task.subtasks.isNotEmpty) ...[
                            Icon(
                              Icons.checklist,
                              size: 14,
                              color: BrainTheme.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${task.subtasks.where((s) => s.isDone).length}/${task.subtasks.length}',
                              style: TextStyle(
                                fontSize: 12,
                                color: BrainTheme.textTertiary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (task.tags.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Consumer<TagsProvider>(builder: (context, tp, _) {
                            final tags = task.tags
                                .map((id) => tp.getById(id))
                                .whereType<Tag>()
                                .take(3)
                                .toList();
                            if (tags.isEmpty) return const SizedBox.shrink();
                            return Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: tags.map((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: tag.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tag.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: tag.color,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )).toList(),
                            );
                          }),
                        ],
                      ],
                      ),
                    ),

                // Progress indicator for subtasks
                if (task.subtasks.isNotEmpty)
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      value: task.progress,
                      strokeWidth: 3,
                      backgroundColor: BrainTheme.borderDark,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        task.progress == 1.0
                            ? BrainTheme.accentGreen
                            : BrainTheme.accentPurple,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

IconData _statusIcon(TaskStatus status) {
  switch (status) {
    case TaskStatus.pending:
      return Icons.radio_button_unchecked;
    case TaskStatus.inProgress:
      return Icons.play_circle_outline;
    case TaskStatus.inReview:
      return Icons.rate_review_outlined;
    case TaskStatus.completed:
      return Icons.check_circle_outline;
    case TaskStatus.cancelled:
      return Icons.cancel_outlined;
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
