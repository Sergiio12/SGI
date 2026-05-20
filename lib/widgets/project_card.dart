import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:second_brain/l10n/app_localizations.dart';

import '../config/theme.dart';
import '../models/project.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../providers/projects_provider.dart';
import '../providers/tags_provider.dart';
import '../providers/tasks_provider.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final taskCount = context.select<TasksProvider, int>(
      (p) => p.getTasksByProject(project.id).length,
    );
    final completedTasks = context.select<TasksProvider, int>(
      (p) => p
          .getTasksByProject(project.id)
          .where((t) => t.status == TaskStatus.completed)
          .length,
    );
    final progress = taskCount == 0 ? 0.0 : completedTasks / taskCount;

    final card = Semantics(
      label: '${project.title}, ${AppLocalizations.of(context).project}',
      child: Card(
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
          onLongPress: () => _showQuickActions(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProjectAvatar(project: project, progress: progress),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.title,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.3,
                              color: BrainTheme.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _StatusBadge(project: project),
                              const SizedBox(width: 8),
                              _PriorityDot(priority: project.priority),
                              if (project.deadline != null) ...[
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd MMM')
                                      .format(project.deadline!),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: project.deadline!
                                            .isBefore(DateTime.now())
                                        ? BrainTheme.accentRed
                                        : BrainTheme.textTertiary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<_QuickAction>(
                      icon: Icon(Icons.more_horiz,
                          color: BrainTheme.textTertiary, size: 20),
                      onSelected: (action) =>
                          _handleQuickAction(context, action),
                      itemBuilder: (_) => [
                        _popupItem(_QuickAction.edit, Icons.edit_outlined,
                            AppLocalizations.of(context).editProject),
                        _popupItem(_QuickAction.duplicate, Icons.copy_outlined,
                            'Duplicar'),
                        _popupItem(_QuickAction.changeStatus, Icons.swap_horiz,
                            'Cambiar estado'),
                        _popupItem(
                          _QuickAction.delete,
                          Icons.delete_outline,
                          AppLocalizations.of(context).delete,
                          color: BrainTheme.accentRed,
                        ),
                      ],
                    ),
                  ],
                ),
                if (project.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    project.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: BrainTheme.textSecondary,
                      height: 1.3,
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
                      Icon(Icons.track_changes,
                          size: 14, color: BrainTheme.textTertiary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          project.objective,
                          style: TextStyle(
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
                if (project.tags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Consumer<TagsProvider>(builder: (context, tp, _) {
                    final tags = project.tags
                        .map((id) => tp.getById(id))
                        .whereType<Tag>()
                        .take(3)
                        .toList();
                    if (tags.isEmpty) return const SizedBox.shrink();
                    return Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: tags
                          .map((tag) => Container(
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
                              ))
                          .toList(),
                    );
                  }),
                ],
                const SizedBox(height: 14),
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
                      value: '$completedTasks/$taskCount',
                      label: 'tareas',
                    ),
                    const SizedBox(width: 16),
                    _MiniStat(
                      icon: Icons.note_outlined,
                      value: '${project.noteIds.length}',
                      label: 'notas',
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM yyyy').format(project.updatedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: BrainTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);

    return Slidable(
      key: Key(project.id),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        extentRatio: 0.3,
        children: [
          SlidableAction(
            onPressed: (_) =>
                _handleQuickAction(context, _QuickAction.changeStatus),
            backgroundColor: BrainTheme.accentBlue.withValues(alpha: 0.2),
            foregroundColor: BrainTheme.accentBlue,
            icon: Icons.swap_horiz,
            label: AppLocalizations.of(context).status,
            borderRadius: BorderRadius.circular(20),
          ),
          SlidableAction(
            onPressed: (_) => onDelete?.call(),
            backgroundColor: BrainTheme.accentRed.withValues(alpha: 0.2),
            foregroundColor: BrainTheme.accentRed,
            icon: Icons.delete_outline,
            label: AppLocalizations.of(context).delete,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      ),
      child: card,
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                project.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BrainTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _actionTile(ctx, Icons.edit_outlined,
                  AppLocalizations.of(context).editProject, () {
                Navigator.pop(ctx);
                onTap?.call();
              }),
              _actionTile(ctx, Icons.swap_horiz, 'Cambiar estado', () {
                Navigator.pop(ctx);
                _showStatusPicker(context);
              }),
              _actionTile(ctx, Icons.copy_outlined, 'Duplicar', () {
                Navigator.pop(ctx);
                _duplicateProject(context);
              }),
              _actionTile(ctx, Icons.delete_outline,
                  AppLocalizations.of(context).itemDeleted, () {
                Navigator.pop(ctx);
                onDelete?.call();
              }, isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionTile(
      BuildContext context, IconData icon, String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon,
          color: isDestructive ? BrainTheme.accentRed : BrainTheme.textPrimary),
      title: Text(label,
          style: TextStyle(
              color: isDestructive
                  ? BrainTheme.accentRed
                  : BrainTheme.textPrimary)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _handleQuickAction(BuildContext context, _QuickAction action) {
    switch (action) {
      case _QuickAction.edit:
        onTap?.call();
      case _QuickAction.duplicate:
        _duplicateProject(context);
      case _QuickAction.changeStatus:
        _showStatusPicker(context);
      case _QuickAction.delete:
        onDelete?.call();
    }
  }

  void _duplicateProject(BuildContext context) {
    final provider = context.read<ProjectsProvider>();
    provider.addProject(
      title: '${project.title} (copia)',
      description: project.description,
      emoji: project.emoji,
      colorValue: project.colorValue,
      status: project.status,
      startDate: project.startDate,
      deadline: project.deadline,
      priority: project.priority,
      objective: project.objective,
    );
  }

  void _showStatusPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).status,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: BrainTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ...ProjectStatus.values.map((status) {
                final isActive = status == project.status;
                return ListTile(
                  leading: Icon(
                    _statusIcon(status),
                    color: _statusColor(status),
                  ),
                  title: Text(
                    _statusLabel(status, context),
                    style: TextStyle(
                      color: isActive
                          ? _statusColor(status)
                          : BrainTheme.textPrimary,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  trailing: isActive
                      ? Icon(Icons.check, color: _statusColor(status))
                      : null,
                  onTap: () {
                    final provider = context.read<ProjectsProvider>();
                    provider.updateProject(project.copyWith(status: status));
                    Navigator.pop(ctx);
                  },
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_QuickAction> _popupItem(
    _QuickAction action,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return PopupMenuItem(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 18, color: color ?? BrainTheme.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  IconData _statusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return Icons.play_circle_outline;
      case ProjectStatus.paused:
        return Icons.pause_circle_outline;
      case ProjectStatus.completed:
        return Icons.check_circle_outline;
      case ProjectStatus.abandoned:
        return Icons.cancel_outlined;
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

  String _statusLabel(ProjectStatus status, BuildContext context) {
    switch (status) {
      case ProjectStatus.active:
        return AppLocalizations.of(context).active;
      case ProjectStatus.paused:
        return 'Pausado';
      case ProjectStatus.completed:
        return AppLocalizations.of(context).statusCompleted;
      case ProjectStatus.abandoned:
        return 'Abandonado';
    }
  }
}

class _ProjectAvatar extends StatelessWidget {
  final Project project;
  final double progress;

  const _ProjectAvatar({required this.project, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Color(project.colorValue).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Color(project.colorValue).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(project.emoji, style: const TextStyle(fontSize: 20)),
            if (progress >= 1.0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                decoration: BoxDecoration(
                  color: BrainTheme.accentGreen.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.check, size: 8, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final Project project;

  _StatusBadge({required this.project});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    switch (project.status) {
      case ProjectStatus.active:
        color = BrainTheme.accentGreen;
        label = AppLocalizations.of(context).active;
        icon = Icons.play_arrow_rounded;
      case ProjectStatus.paused:
        color = BrainTheme.accentOrange;
        label = 'Pausado';
        icon = Icons.pause_rounded;
      case ProjectStatus.completed:
        color = BrainTheme.accentBlue;
        label = AppLocalizations.of(context).statusCompleted;
        icon = Icons.check_rounded;
      case ProjectStatus.abandoned:
        color = BrainTheme.textTertiary;
        label = 'Abandonado';
        icon = Icons.stop_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
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
    );
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
          style: TextStyle(
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
            color:
                BrainTheme.priorityColor(priority.index).withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          )
        ],
      ),
    );
  }
}

enum _QuickAction { edit, duplicate, changeStatus, delete }
