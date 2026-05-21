import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';

class TaskBoardColumn extends StatelessWidget {
  final TaskStatus status;
  final String title;
  final IconData icon;
  final Color color;
  final List<Task> tasks;
  final bool overWip;
  final VoidCallback onCreateTask;
  final Widget Function(Task) taskBuilder;
  final void Function(Task, TaskStatus)? onTaskDropped;

  const TaskBoardColumn({
    required this.status,
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
    this.overWip = false,
    required this.onCreateTask,
    required this.taskBuilder,
    this.onTaskDropped,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final task = details.data;
        return task.status != status;
      },
      onAcceptWithDetails: (details) =>
          onTaskDropped?.call(details.data, status),
      builder: (context, candidateData, rejectedData) {
        final isHovered = candidateData.isNotEmpty;
        return Container(
          width: 290,
          margin: const EdgeInsets.only(left: 8, right: 8),
          decoration: BoxDecoration(
            color: BrainTheme.surfaceDark.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHovered
                  ? color.withValues(alpha: 0.35)
                  : BrainTheme.borderDark.withValues(alpha: 0.4),
              width: isHovered ? 1.5 : 1,
            ),
            boxShadow: [
              if (isHovered)
                BoxShadow(
                  color: color.withValues(alpha: 0.05),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ColumnHeader(
                color: color,
                icon: icon,
                title: title,
                count: tasks.length,
                overWip: overWip,
                onCreateTask: onCreateTask,
              ),
              const SizedBox(height: 4),
              Expanded(
                child: tasks.isEmpty
                    ? EmptyColumn(icon: icon, color: color)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: LongPressDraggable<Task>(
                              data: task,
                              feedback: Material(
                                color: Colors.transparent,
                                child: SizedBox(
                                  width: 270,
                                  child: Transform.scale(
                                    scale: 1.03,
                                    child: Card(
                                      elevation: 6,
                                      shadowColor:
                                          color.withValues(alpha: 0.2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        side: BorderSide(
                                          color: color.withValues(alpha: 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: taskBuilder(task),
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.2,
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

class ColumnHeader extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final int count;
  final bool overWip;
  final VoidCallback onCreateTask;

  const ColumnHeader({
    required this.color,
    required this.icon,
    required this.title,
    required this.count,
    this.overWip = false,
    required this.onCreateTask,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BrainTheme.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: overWip
                  ? BrainTheme.accentRed.withValues(alpha: 0.15)
                  : color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                color: overWip ? BrainTheme.accentRed : color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onCreateTask,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.add, size: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyColumn extends StatelessWidget {
  final IconData icon;
  final Color color;

  const EmptyColumn({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color.withValues(alpha: 0.3)),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalizations.of(context).emptyState,
            style: TextStyle(
              color: BrainTheme.textTertiary.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
