import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';

class TaskTodaySummary extends StatelessWidget {
  final int pending;
  final int inProgress;
  final int done;
  final int overdue;
  final int cancelled;
  final int total;

  const TaskTodaySummary({
    required this.pending,
    required this.inProgress,
    required this.done,
    required this.overdue,
    required this.cancelled,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(now);

    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: BrainTheme.borderDark.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month,
                  size: 13, color: BrainTheme.textTertiary),
              const SizedBox(width: 6),
              Text(
                l10n.today,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: BrainTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                dateStr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: BrainTheme.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SummaryChip(
                  icon: Icons.circle_outlined,
                  count: pending,
                  label: l10n.statusPending,
                  color: BrainTheme.statusColor(TaskStatus.pending)),
              const SizedBox(width: 8),
              SummaryChip(
                  icon: Icons.play_circle_outline,
                  count: inProgress,
                  label: l10n.statusInProgress,
                  color: BrainTheme.statusColor(TaskStatus.inProgress)),
              const SizedBox(width: 8),
              SummaryChip(
                  icon: Icons.check_circle,
                  count: done,
                  label: l10n.statusCompleted,
                  color: BrainTheme.statusColor(TaskStatus.completed)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SummaryChip(
                  icon: Icons.warning_amber_rounded,
                  count: overdue,
                  label: l10n.overdueTasks,
                  color: overdue > 0
                      ? BrainTheme.statusColor(TaskStatus.cancelled)
                      : BrainTheme.textTertiary),
              const SizedBox(width: 8),
              SummaryChip(
                  icon: Icons.cancel_outlined,
                  count: cancelled,
                  label: l10n.statusCancelled,
                  color: cancelled > 0
                      ? BrainTheme.statusColor(TaskStatus.cancelled)
                      : BrainTheme.textTertiary),
              const SizedBox(width: 8),
              SummaryChip(
                  icon: Icons.task_alt,
                  count: total,
                  label: l10n.all,
                  color: BrainTheme.textTertiary),
            ],
          ),
        ],
      ),
    );
  }
}

class SummaryChip extends StatelessWidget {
  final IconData icon;
  final int count;
  final String label;
  final Color color;

  const SummaryChip({
    required this.icon,
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1.1,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
