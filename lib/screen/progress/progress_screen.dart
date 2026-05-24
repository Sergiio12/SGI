import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/goals_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/goal_card.dart';
import '../../widgets/stats_card.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Consumer4<TasksProvider, ProjectsProvider, NotesProvider,
          GoalsProvider>(
        builder: (context, tasks, projects, notes, goals, _) {
          final activeTasks = tasks.tasks.where((t) => t.isActive).length;
          final completed = tasks.doneTasks.length;
          final totalTasks = tasks.tasks.length;
          final estimatedHours = tasks.tasks.fold<double>(
            0,
            (total, task) => total + task.estimatedHours,
          );
          final actualHours = tasks.tasks.fold<double>(
            0,
            (total, task) => total + (task.actualHours ?? 0),
          );

          return ListView(
            padding: const EdgeInsets.only(bottom: 100),
            children: [
              _buildHeader(
                context,
                totalTasks,
                projects.activeProjects.length,
                notes.notes.length,
                goals.goals.length,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // Stats grid
                    _SectionLabel(
                      icon: Icons.bar_chart_rounded,
                      label: l10n.statistics,
                    ),
                    const SizedBox(height: 12),
                    _buildStatsGrid(
                      context,
                      activeTasks: activeTasks,
                      completedTasks: completed,
                      activeProjects: projects.activeProjects.length,
                      completedProjects: projects.completedProjects.length,
                      totalNotes: notes.notes.length,
                      pinnedNotes: notes.pinnedNotes.length,
                      actualHours: actualHours,
                      estimatedHours: estimatedHours,
                    ),

                    const SizedBox(height: 24),

                    // Task breakdown
                    _SectionLabel(
                      icon: Icons.pie_chart_rounded,
                      label: l10n.tasksByStatus,
                    ),
                    const SizedBox(height: 12),
                    _buildTaskBreakdown(context, tasks),

                    const SizedBox(height: 24),

                    // Goals section
                    _SectionLabel(
                      icon: Icons.flag_rounded,
                      label: l10n.goalsProgress,
                    ),
                    const SizedBox(height: 12),
                    if (goals.goals.isEmpty)
                      _buildEmptyGoals(context)
                    else
                      ...goals.goals.map(
                        (goal) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GoalCard(
                            goal: goal,
                            projectCount:
                                projects.getProjectsByGoal(goal.id).length,
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/goal',
                              arguments: goal.id,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int totalTasks,
    int activeProjects,
    int totalNotes,
    int totalGoals,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrainTheme.accentPurple.withValues(alpha: 0.9),
            BrainTheme.accentBlue.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).statistics,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _HeaderStat(
                      value: '$totalTasks',
                      label: AppLocalizations.of(context).tasks,
                    ),
                  ),
                  Expanded(
                    child: _HeaderStat(
                      value: '$activeProjects',
                      label: AppLocalizations.of(context).activeProjects,
                    ),
                  ),
                  Expanded(
                    child: _HeaderStat(
                      value: '$totalNotes',
                      label: AppLocalizations.of(context).notes,
                    ),
                  ),
                  Expanded(
                    child: _HeaderStat(
                      value: '$totalGoals',
                      label: AppLocalizations.of(context).goals,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatsGrid(
    BuildContext context, {
    required int activeTasks,
    required int completedTasks,
    required int activeProjects,
    required int completedProjects,
    required int totalNotes,
    required int pinnedNotes,
    required double actualHours,
    required double estimatedHours,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 1.25,
      children: [
        StatsCard(
          title: AppLocalizations.of(context).tasks,
          value: '$activeTasks',
          icon: Icons.task_alt_outlined,
          color: BrainTheme.accentBlue,
          subtitle: '$completedTasks ${AppLocalizations.of(context).taskCompleted.toLowerCase()}',
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
        StatsCard(
          title: AppLocalizations.of(context).projects,
          value: '$activeProjects',
          icon: Icons.folder_open_outlined,
          color: BrainTheme.accentGreen,
          subtitle: '$completedProjects cerrados',
        ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1),
        StatsCard(
          title: AppLocalizations.of(context).notes,
          value: '$totalNotes',
          icon: Icons.sticky_note_2_outlined,
          color: BrainTheme.accentCyan,
          subtitle: '$pinnedNotes fijadas',
        ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),
        StatsCard(
          title: 'Horas',
          value: actualHours.toStringAsFixed(1),
          icon: Icons.timer_outlined,
          color: BrainTheme.accentOrange,
          subtitle: '${estimatedHours.toStringAsFixed(1)} estimadas',
        ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildTaskBreakdown(BuildContext context, TasksProvider tasks) {
    final total = tasks.tasks.length;
    final pending = tasks.todoTasks.length;
    final inProgress = tasks.inProgressTasks.length;
    final inReview = tasks.inReviewTasks.length;
    final done = tasks.doneTasks.length;
    final cancelled = tasks.cancelledTasks.length;

    if (total == 0) {
      return _buildEmptyBreakdown(context);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrainTheme.borderDark.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatusSegment(
                label: AppLocalizations.of(context).statusPending,
                count: pending,
                color: BrainTheme.accentBlue,
                total: total,
              ),
              const SizedBox(width: 8),
              _StatusSegment(
                label: AppLocalizations.of(context).statusInProgress,
                count: inProgress,
                color: BrainTheme.accentOrange,
                total: total,
              ),
              const SizedBox(width: 8),
              _StatusSegment(
                label: AppLocalizations.of(context).statusInReview,
                count: inReview,
                color: BrainTheme.accentCyan,
                total: total,
              ),
              const SizedBox(width: 8),
              _StatusSegment(
                label: AppLocalizations.of(context).statusCompleted,
                count: done,
                color: BrainTheme.accentGreen,
                total: total,
              ),
              const SizedBox(width: 8),
              _StatusSegment(
                label: AppLocalizations.of(context).statusCancelled,
                count: cancelled,
                color: BrainTheme.accentRed.withValues(alpha: 0.7),
                total: total,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  if (pending > 0)
                    Expanded(
                      flex: pending,
                      child: Container(
                        color: BrainTheme.accentBlue,
                      ),
                    ),
                  if (inProgress > 0)
                    Expanded(
                      flex: inProgress,
                      child: Container(
                        color: BrainTheme.accentOrange,
                      ),
                    ),
                  if (inReview > 0)
                    Expanded(
                      flex: inReview,
                      child: Container(
                        color: BrainTheme.accentCyan,
                      ),
                    ),
                  if (done > 0)
                    Expanded(
                      flex: done,
                      child: Container(
                        color: BrainTheme.accentGreen,
                      ),
                    ),
                  if (cancelled > 0)
                    Expanded(
                      flex: cancelled,
                      child: Container(
                        color: BrainTheme.accentRed.withValues(alpha: 0.7),
                      ),
                    ),
                  if (pending + inProgress + inReview + done + cancelled == 0)
                    Expanded(
                      child: Container(
                        color: BrainTheme.borderDark,
                      ),
                    ),
                ],
              ),
            ),
          ).animate().scaleX(begin: 0, end: 1, duration: 600.ms, curve: Curves.easeOutCubic),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }

  Widget _buildEmptyBreakdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrainTheme.borderDark.withValues(alpha: 0.6),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.inbox_rounded,
              size: 40,
              color: BrainTheme.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).emptyState,
              style: TextStyle(
                fontSize: 13,
                color: BrainTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGoals(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: BrainTheme.borderDark.withValues(alpha: 0.6),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.flag_outlined,
              size: 40,
              color: BrainTheme.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No hay objetivos definidos.',
              style: TextStyle(
                fontSize: 13,
                color: BrainTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: BrainTheme.accentPurple),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: BrainTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeaderStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ).animate().scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 500.ms,
          curve: Curves.easeOutBack,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _StatusSegment extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final int total;

  const _StatusSegment({
    required this.label,
    required this.count,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100).round() : 0;

    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: BrainTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
