import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/task_card.dart';

class OverdueSection extends StatelessWidget {
  final List<Task> overdueTasks;

  const OverdueSection({super.key, required this.overdueTasks});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        _SectionHeader(
          title: l10n.overdueTasks,
          icon: Icons.warning_amber_rounded,
          count: overdueTasks.length,
          color: BrainTheme.accentRed,
        ).animate().fadeIn().slideX(begin: -0.1, end: 0),
        const SizedBox(height: 12),
        ...overdueTasks.take(2).map(
              (task) => TaskCard(
                task: task,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/task',
                  arguments: task.id,
                ),
                onToggle: () =>
                    context.read<TasksProvider>().toggleTaskStatus(task.id),
              ),
            ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = screenWidth < 400
        ? 15.0
        : screenWidth < 600
            ? 16.0
            : 18.0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: BrainTheme.textPrimary,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
