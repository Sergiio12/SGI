import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/goals_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/stats_card.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksProvider>();
    final projects = context.watch<ProjectsProvider>();
    final goals = context.watch<GoalsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        title: const Text('Estadísticas'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOverviewCards(context, tasks, projects, goals),
          const SizedBox(height: 20),
          _buildCompletionChart(context, tasks),
          const SizedBox(height: 20),
          _buildTaskDistribution(context, tasks),
          const SizedBox(height: 20),
          _buildPriorityChart(context, tasks),
          const SizedBox(height: 20),
          _buildGoalsProgress(context, goals),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(
    BuildContext context,
    TasksProvider tasks,
    ProjectsProvider projects,
    GoalsProvider goals,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Tareas',
                value: '${tasks.totalTasks}',
                icon: Icons.checklist_rounded,
                color: BrainTheme.accentBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'Completadas',
                value: '${tasks.doneTasks.length}',
                icon: Icons.check_circle_rounded,
                color: BrainTheme.accentGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                title: 'Proyectos',
                value: '${projects.projects.length}',
                icon: Icons.folder_rounded,
                color: BrainTheme.accentOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                title: 'Objetivos',
                value: '${goals.goals.length}',
                icon: Icons.track_changes_rounded,
                color: BrainTheme.accentPurple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionChart(BuildContext context, TasksProvider tasks) {
    final done = tasks.doneTasks.length.toDouble();
    final pending = tasks.tasks.length - done;

    return Card(
      color: BrainTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasa de finalización',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BrainTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: done,
                      color: BrainTheme.accentGreen,
                      title: '${tasks.completionRate.toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      radius: 60,
                    ),
                    if (pending > 0)
                      PieChartSectionData(
                        value: pending,
                        color: BrainTheme.surfaceDark,
                        radius: 50,
                      ),
                  ],
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _legendItem(BrainTheme.accentGreen, 'Completadas'),
                _legendItem(BrainTheme.surfaceDark, 'Pendientes'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskDistribution(BuildContext context, TasksProvider tasks) {
    final statuses = {
      'Pendiente': tasks.todoTasks.length.toDouble(),
      'Progreso': tasks.inProgressTasks.length.toDouble(),
      'Revisión': tasks.inReviewTasks.length.toDouble(),
      'Completado': tasks.doneTasks.length.toDouble(),
    };

    return Card(
      color: BrainTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tareas por estado',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BrainTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: statuses.values
                          .reduce((a, b) => a > b ? a : b)
                          .clamp(1, double.infinity),
                  barGroups: statuses.entries.map((e) {
                    return BarChartGroupData(
                      x: statuses.keys.toList().indexOf(e.key),
                      barRods: [
                        BarChartRodData(
                          toY: e.value,
                          color: _statusColor(e.key),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final label = statuses.keys.elementAt(value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChart(BuildContext context, TasksProvider tasks) {
    final counts = {
      TaskPriority.urgent: 0,
      TaskPriority.high: 0,
      TaskPriority.medium: 0,
      TaskPriority.low: 0,
    };
    for (final t in tasks.tasks) {
      if (t.isActive) counts[t.priority] = (counts[t.priority] ?? 0) + 1;
    }

    return Card(
      color: BrainTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Prioridades',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BrainTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...counts.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          e.key.name,
                          style: TextStyle(
                            fontSize: 13,
                            color: BrainTheme.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: tasks.tasks.isEmpty
                                ? 0
                                : e.value / tasks.tasks.length,
                            backgroundColor:
                                BrainTheme.surfaceDark.withValues(alpha: 0.5),
                            color: BrainTheme.priorityColor(e.key.index),
                            minHeight: 8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${e.value}',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: BrainTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsProgress(BuildContext context, GoalsProvider goals) {
    return Card(
      color: BrainTheme.cardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso de objetivos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: BrainTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ...goals.goals.take(5).map((goal) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: BrainTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(goal.progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(goal.colorValue),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: goal.progress,
                          backgroundColor:
                              BrainTheme.surfaceDark.withValues(alpha: 0.5),
                          color: Color(goal.colorValue),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pendiente':
        return BrainTheme.textTertiary;
      case 'Progreso':
        return BrainTheme.accentBlue;
      case 'Revisión':
        return BrainTheme.accentOrange;
      case 'Completado':
        return BrainTheme.accentGreen;
      default:
        return BrainTheme.textTertiary;
    }
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: BrainTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}
