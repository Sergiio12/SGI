import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:second_brain/l10n/app_localizations.dart';
import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_card.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.calendar)),
      body: Consumer<TasksProvider>(
        builder: (context, provider, _) {
          final grouped = _groupTasks(provider.tasks);
          if (grouped.isEmpty) {
            return const EmptyState(
              emoji: '📅',
              title: 'Sin fechas planificadas',
              subtitle: 'Las tareas con deadline aparecerán aquí.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: grouped.entries.map((entry) {
              final date = entry.key;
              final tasks = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _dateColor(date).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              DateFormat('dd').format(date),
                              style: TextStyle(
                                color: _dateColor(date),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dateTitle(date, context),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: BrainTheme.textPrimary,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, dd MMM').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: BrainTheme.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...tasks.map(
                      (task) => TaskCard(
                        task: task,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/task',
                          arguments: task.id,
                        ),
                        onToggle: () => provider.toggleTaskStatus(task.id),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Map<DateTime, List<Task>> _groupTasks(List<Task> tasks) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 30));
    final grouped = <DateTime, List<Task>>{};

    for (final task in tasks) {
      final dueDate = task.dueDate;
      if (dueDate == null || !task.isActive) continue;
      final day = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (day.isBefore(start) || day.isAfter(end)) continue;
      grouped.putIfAbsent(day, () => []).add(task);
    }

    for (final value in grouped.values) {
      value.sort((a, b) => b.priority.index.compareTo(a.priority.index));
    }

    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  String _dateTitle(DateTime date, BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (date == today) return AppLocalizations.of(context)!.today;
    if (date == tomorrow) return 'Mañana';
    return DateFormat('dd MMM').format(date);
  }

  Color _dateColor(DateTime date) {
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    if (date == currentDay) return BrainTheme.accentOrange;
    if (date.difference(currentDay).inDays <= 3) return BrainTheme.accentBlue;
    return BrainTheme.accentPurple;
  }
}
