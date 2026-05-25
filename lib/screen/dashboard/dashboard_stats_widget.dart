import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/dashboard_data.dart';

import 'metrics_screens.dart';

class DashboardStatsGrid extends StatelessWidget {
  final DashboardData data;

  const DashboardStatsGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.query_stats_rounded,
                color: BrainTheme.accentGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              l10n.statistics,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BrainTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _StatsCard(
              title: l10n.tasks,
              value: '${data.activeTasksCount}',
              icon: Icons.checklist_rounded,
              color: BrainTheme.accentBlue,
              subtitle: l10n.pendingTasks,
              progress: data.tasksProgressVal,
              progressLabel: 'Completado: ${data.tasksProgressPercent}%',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const TaskMetricsScreen()),
              ),
            ),
            _StatsCard(
              title: l10n.projects,
              value: '${data.activeProjectsCount}',
              icon: Icons.folder_open_outlined,
              color: BrainTheme.accentGreen,
              subtitle: l10n.active,
              progress: data.projectsProgressVal,
              progressLabel:
                  'Finalizados: ${data.completedProjectsCount}/${data.totalProjectsCount}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProjectMetricsScreen()),
              ),
            ),
            _StatsCard(
              title: l10n.goals,
              value: '${data.activeGoalsCount}',
              icon: Icons.track_changes_outlined,
              color: BrainTheme.accentOf(context),
              subtitle: l10n.active,
              progress: data.averageGoalProgress,
              progressLabel:
                  'Progreso medio: ${data.averageGoalProgressPercent}%',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const GoalMetricsScreen()),
              ),
            ),
            _StatsCard(
              title: l10n.notes,
              value: '${data.totalNotesCount}',
              icon: Icons.sticky_note_2_outlined,
              color: BrainTheme.accentCyan,
              subtitle: l10n.sortRecent,
              progress: data.totalNotesCount == 0 ? 0.0 : 1.0,
              progressLabel:
                  'En ${data.notesNotebooksCount} cuadernos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NoteMetricsScreen()),
              ),
            ),
          ]
              .animate(interval: 50.ms)
              .fadeIn(duration: 400.ms)
              .scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutBack),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final double progress;
  final String progressLabel;
  final VoidCallback onTap;

  const _StatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.progress,
    required this.progressLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      color: BrainTheme.cardDark,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 14,
                    color: BrainTheme.textTertiary.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: color,
                  shadows: [
                    Shadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: BrainTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: BrainTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: BrainTheme.borderDark,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progressLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
