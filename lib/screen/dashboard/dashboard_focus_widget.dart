import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/daily_planner_provider.dart';

class FocusSection extends StatelessWidget {
  final int focusTasksCount;
  final DailyPlannerProvider planner;

  const FocusSection({
    super.key,
    required this.focusTasksCount,
    required this.planner,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final plannedCount = planner.plannedTaskIds.length;
    final timeBlockedCount = planner.timeBlocks.length;

    return Container(
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrainTheme.accentOrange.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BrainTheme.accentOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.center_focus_strong,
                size: 22, color: BrainTheme.accentOrange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.focusMode,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: BrainTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$focusTasksCount tareas en foco - $plannedCount planificadas - $timeBlockedCount con bloque',
                  style: TextStyle(
                    fontSize: 11,
                    color: BrainTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/focus'),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BrainTheme.accentOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Text(
                    'Abrir',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: BrainTheme.accentOrange,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios,
                      size: 10, color: BrainTheme.accentOrange),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}
