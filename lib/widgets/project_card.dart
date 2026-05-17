import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../providers/tasks_provider.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const ProjectCard({super.key, required this.project, this.onTap});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksProvider>();
    final projectTasks = tasks.getTasksByProject(project.id);
    final completedTasks =
        projectTasks.where((t) => t.status == TaskStatus.completed).length;
    final progress =
        projectTasks.isEmpty ? 0.0 : completedTasks / projectTasks.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: Color(project.colorValue).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: BrainTheme.cardDark,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color(project.colorValue).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Color(project.colorValue).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        project.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            color: BrainTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusColor(project.status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _statusLabel(project.status),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _statusColor(project.status),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _PriorityDot(priority: project.priority),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (project.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  project.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: BrainTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (project.objective.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.track_changes, size: 14, color: BrainTheme.textTertiary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        project.objective,
                        style: const TextStyle(
                          fontSize: 12,
                          color: BrainTheme.textTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: BrainTheme.borderDark,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(project.colorValue),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(project.colorValue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniStat(
                    icon: Icons.task_alt,
                    value: '$completedTasks/${projectTasks.length}',
                    label: 'tareas',
                  ),
                  const SizedBox(width: 16),
                  _MiniStat(
                    icon: Icons.note_outlined,
                    value: '${project.noteIds.length}',
                    label: 'notas',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
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

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return BrainTheme.accentGreen;
      case ProjectStatus.paused:
        return BrainTheme.accentOrange;
      case ProjectStatus.completed:
        return BrainTheme.accentBlue;
      case ProjectStatus.abandoned:
        return BrainTheme.textTertiary;
    }
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: BrainTheme.textTertiary),
        const SizedBox(width: 6),
        Text(
          '$value $label',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: BrainTheme.textTertiary,
          ),
        ),
      ],
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final TaskPriority priority;

  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: BrainTheme.priorityColor(priority.index),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: BrainTheme.priorityColor(priority.index).withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          )
        ],
      ),
    );
  }
}
