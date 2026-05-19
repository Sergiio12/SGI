import 'package:flutter/material.dart';
import 'package:second_brain/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.today)),
      body: Consumer<TasksProvider>(
        builder: (context, provider, _) {
          final overdue = provider.overdueTasks;
          final todayTasks = provider.todayTasks;
          final inProgress = provider.inProgressTasks;

          if (overdue.isEmpty && todayTasks.isEmpty && inProgress.isEmpty) {
            return EmptyState(
              emoji: '🎉',
              title: AppLocalizations.of(context)!.noTasks,
              subtitle: AppLocalizations.of(context)!.emptyStateDescription,
            );
          }

          final sections = <_Section>[];

          if (overdue.isNotEmpty) {
            sections.add(_Section(
              title: AppLocalizations.of(context)!.overdueTasks,
              icon: Icons.warning_amber_rounded,
              color: BrainTheme.accentRed,
              tasks: overdue,
            ));
          }

          if (todayTasks.isNotEmpty) {
            sections.add(_Section(
              title: AppLocalizations.of(context)!.todayView,
              icon: Icons.today_rounded,
              color: BrainTheme.accentOrange,
              tasks: todayTasks,
            ));
          }

          if (inProgress.isNotEmpty) {
            sections.add(_Section(
              title: AppLocalizations.of(context)!.statusInProgress,
              icon: Icons.play_circle_outline,
              color: BrainTheme.accentBlue,
              tasks: inProgress,
            ));
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _TodayHeader(
                overdueCount: overdue.length,
                todayCount: todayTasks.length,
                inProgressCount: inProgress.length,
              ),
              const SizedBox(height: 20),
              ...sections.map(
                (section) => _TaskSection(
                  section: section,
                  onTaskTap: (task) => Navigator.pushNamed(
                    context,
                    '/task',
                    arguments: task.id,
                  ),
                  onTaskToggle: (task) =>
                      provider.toggleTaskStatus(task.id),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TodayHeader extends StatelessWidget {
  final int overdueCount;
  final int todayCount;
  final int inProgressCount;

  const _TodayHeader({
    required this.overdueCount,
    required this.todayCount,
    required this.inProgressCount,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dayName = _dayNames[now.weekday - 1];
    final formattedDate = '${now.day} de ${_months[now.month - 1]}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BrainTheme.accentPurple, BrainTheme.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dayName[0].toUpperCase() + dayName.substring(1),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _HeaderStat(
                count: overdueCount,
                label: AppLocalizations.of(context)!.overdueTasks,
                color: Colors.white.withValues(alpha: 0.9),
                bgColor: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 12),
              _HeaderStat(
                count: todayCount,
                label: AppLocalizations.of(context)!.todayView,
                color: Colors.white,
                bgColor: Colors.white.withValues(alpha: 0.15),
              ),
              const SizedBox(width: 12),
              _HeaderStat(
                count: inProgressCount,
                label: AppLocalizations.of(context)!.statusInProgress,
                color: Colors.white,
                bgColor: Colors.white.withValues(alpha: 0.15),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color bgColor;

  const _HeaderStat({
    required this.count,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String title;
  final IconData icon;
  final Color color;
  final List<Task> tasks;

  _Section({
    required this.title,
    required this.icon,
    required this.color,
    required this.tasks,
  });
}

const _dayNames = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];

const _months = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

class _TaskSection extends StatelessWidget {
  final _Section section;
  final void Function(Task) onTaskTap;
  final void Function(Task) onTaskToggle;

  const _TaskSection({
    required this.section,
    required this.onTaskTap,
    required this.onTaskToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(section.icon, size: 18, color: section.color),
              const SizedBox(width: 8),
              Text(
                section.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: section.color,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${section.tasks.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: section.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...section.tasks.map(
            (task) => TaskCard(
              task: task,
              onTap: () => onTaskTap(task),
              onToggle: () => onTaskToggle(task),
            ),
          ),
        ],
      ),
    );
  }
}
