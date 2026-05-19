import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/goal.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import '../../providers/goals_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';

class TaskMetricsScreen extends StatelessWidget {
  const TaskMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasksProvider = context.watch<TasksProvider>();
    final totalTasks = tasksProvider.tasks.length;
    final completedTasks = tasksProvider.doneTasks.length;
    final pendingTasks = tasksProvider.todoTasks.length;
    final overdueTasks = tasksProvider.overdueTasks.length;
    final dueTodayTasks = tasksProvider.todayTasks.length;
    final urgentTasks = tasksProvider.urgentTasks.length;
    final completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;
    final keyTasks = tasksProvider.focusTasks.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: BrainTheme.primaryDark.withValues(alpha: 0.95),
        title: const Text('Métricas de Tareas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 4),
          Text(
            'Vistas clave para tus tareas',
            style: TextStyle(
              fontSize: 14,
              color: BrainTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricsCard(
                label: 'Total',
                value: '$totalTasks',
                color: BrainTheme.accentBlue,
              ),
              _MetricsCard(
                label: 'Completadas',
                value: '$completedTasks',
                color: BrainTheme.accentGreen,
              ),
              _MetricsCard(
                label: 'Pendientes',
                value: '$pendingTasks',
                color: BrainTheme.accentOrange,
              ),
              _MetricsCard(
                label: 'Urgentes',
                value: '$urgentTasks',
                color: BrainTheme.accentRed,
              ),
              _MetricsCard(
                label: 'Hoy',
                value: '$dueTodayTasks',
                color: BrainTheme.accentPurple,
              ),
              _MetricsCard(
                label: 'Vencidas',
                value: '$overdueTasks',
                color: BrainTheme.accentRed.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _MetricSummaryCard(
            title: 'Progreso general',
            description:
                'Completaste el ${(completionRate * 100).toInt()}% de las tareas registradas.',
            accent: BrainTheme.accentGreen,
          ),
          const SizedBox(height: 18),
          _SectionTitle(title: 'Tareas de foco'),
          const SizedBox(height: 10),
          if (keyTasks.isEmpty)
            _EmptyMetricCard(
              icon: Icons.check_circle_outline,
              title: 'Nada urgente',
              subtitle: 'No hay tareas destacadas para enfocarte ahora.',
            )
          else
            Column(
              children: keyTasks.map((task) {
                return _TaskSummaryRow(task: task);
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class ProjectMetricsScreen extends StatelessWidget {
  const ProjectMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final projectsProvider = context.watch<ProjectsProvider>();
    final tasksProvider = context.watch<TasksProvider>();

    final totalProjects = projectsProvider.projects.length;
    final activeProjects = projectsProvider.activeProjects.length;
    final completedProjects = projectsProvider.completedProjects.length;
    final pausedProjects = projectsProvider.pausedProjects.length;
    final abandonedProjects = projectsProvider.abandonedProjects.length;
    final overdueProjectCount = tasksProvider.tasks
        .where((task) => task.projectId != null && task.isOverdue)
        .map((task) => task.projectId)
        .toSet()
        .length;
    final nextDeadlines = projectsProvider.activeProjects
        .where((project) => project.deadline != null)
        .toList()
      ..sort((a, b) => a.deadline!.compareTo(b.deadline!));
    final upcomingProjects = nextDeadlines.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: BrainTheme.primaryDark.withValues(alpha: 0.95),
        title: const Text('Métricas de Proyectos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 4),
          Text(
            'Visión completa de tus proyectos',
            style: TextStyle(
              fontSize: 14,
              color: BrainTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricsCard(
                label: 'Total',
                value: '$totalProjects',
                color: BrainTheme.accentGreen,
              ),
              _MetricsCard(
                label: 'Activos',
                value: '$activeProjects',
                color: BrainTheme.accentBlue,
              ),
              _MetricsCard(
                label: 'Completados',
                value: '$completedProjects',
                color: BrainTheme.accentPurple,
              ),
              _MetricsCard(
                label: 'Pausados',
                value: '$pausedProjects',
                color: BrainTheme.accentOrange,
              ),
              _MetricsCard(
                label: 'Abandonados',
                value: '$abandonedProjects',
                color: BrainTheme.accentRed,
              ),
              _MetricsCard(
                label: 'Con tareas vencidas',
                value: '$overdueProjectCount',
                color: BrainTheme.accentRed.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: 'Próximos plazos'),
          const SizedBox(height: 10),
          if (upcomingProjects.isEmpty)
            _EmptyMetricCard(
              icon: Icons.calendar_month_outlined,
              title: 'Sin fechas próximas',
              subtitle: 'No hay proyectos con fecha límite próxima.',
            )
          else
            Column(
              children: upcomingProjects.map((project) {
                return _ProjectSummaryRow(project: project);
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class GoalMetricsScreen extends StatelessWidget {
  const GoalMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goalsProvider = context.watch<GoalsProvider>();
    final goals = goalsProvider.goals;
    final totalGoals = goals.length;
    final completedGoals = goals.where((goal) => goal.progress >= 1).length;
    final monthlyGoals =
        goals.where((goal) => goal.horizon == GoalHorizon.monthly).length;
    final quarterlyGoals =
        goals.where((goal) => goal.horizon == GoalHorizon.quarterly).length;
    final yearlyGoals =
        goals.where((goal) => goal.horizon == GoalHorizon.yearly).length;
    final averageProgress = totalGoals == 0
        ? 0.0
        : goals.map((goal) => goal.progress).reduce((a, b) => a + b) /
            totalGoals;
    final topGoals = [...goals]
      ..sort((a, b) => b.progress.compareTo(a.progress));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: BrainTheme.primaryDark.withValues(alpha: 0.95),
        title: const Text('Métricas de Objetivos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 4),
          Text(
            'Rendimiento y progreso de tus objetivos',
            style: TextStyle(
              fontSize: 14,
              color: BrainTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricsCard(
                label: 'Total',
                value: '$totalGoals',
                color: BrainTheme.accentPurple,
              ),
              _MetricsCard(
                label: 'Completados',
                value: '$completedGoals',
                color: BrainTheme.accentGreen,
              ),
              _MetricsCard(
                label: 'Mensuales',
                value: '$monthlyGoals',
                color: BrainTheme.accentBlue,
              ),
              _MetricsCard(
                label: 'Trimestrales',
                value: '$quarterlyGoals',
                color: BrainTheme.accentOrange,
              ),
              _MetricsCard(
                label: 'Anuales',
                value: '$yearlyGoals',
                color: BrainTheme.accentCyan,
              ),
              _MetricsCard(
                label: 'Promedio',
                value: '${(averageProgress * 100).toInt()}%',
                color: BrainTheme.accentGreen.withValues(alpha: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: 'Objetivos más avanzados'),
          const SizedBox(height: 10),
          if (goals.isEmpty)
            _EmptyMetricCard(
              icon: Icons.flag_outlined,
              title: 'Sin objetivos activos',
              subtitle: 'Crea tus primeros objetivos para ver más métricas.',
            )
          else
            Column(
              children: topGoals.take(3).map((goal) {
                return _GoalSummaryRow(goal: goal);
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class NoteMetricsScreen extends StatelessWidget {
  const NoteMetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final totalNotes = notesProvider.notes.length;
    final pinnedNotes = notesProvider.pinnedNotes.length;
    final recentNotes = notesProvider.recentNotes.length;
    final notebooks = notesProvider.notebooks.length;
    final topNotebooks = notesProvider.notebooks.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: BrainTheme.primaryDark.withValues(alpha: 0.95),
        title: const Text('Métricas de Notas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 4),
          Text(
            'Resumen rápido de tus notas y cuadernos',
            style: TextStyle(
              fontSize: 14,
              color: BrainTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricsCard(
                label: 'Total',
                value: '$totalNotes',
                color: BrainTheme.accentCyan,
              ),
              _MetricsCard(
                label: 'Ancladas',
                value: '$pinnedNotes',
                color: BrainTheme.accentPurple,
              ),
              _MetricsCard(
                label: 'Recientes',
                value: '$recentNotes',
                color: BrainTheme.accentBlue,
              ),
              _MetricsCard(
                label: 'Cuadernos',
                value: '$notebooks',
                color: BrainTheme.accentGreen,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: 'Cuadernos principales'),
          const SizedBox(height: 10),
          if (topNotebooks.isEmpty)
            _EmptyMetricCard(
              icon: Icons.menu_book_outlined,
              title: 'Sin cuadernos',
              subtitle: 'Crea notas para empezar a organizar tus ideas.',
            )
          else
            Column(
              children: topNotebooks.map((notebook) {
                return _SimpleSummaryRow(
                  title: notebook,
                  subtitle: 'Cuaderno activo',
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricsCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: BrainTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              color: BrainTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricSummaryCard extends StatelessWidget {
  final String title;
  final String description;
  final Color accent;

  const _MetricSummaryCard({
    required this.title,
    required this.description,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.13), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: BrainTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: BrainTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: BrainTheme.textPrimary,
        ),
      ),
    );
  }
}

class _EmptyMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyMetricCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: BrainTheme.borderDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: BrainTheme.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: BrainTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: BrainTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskSummaryRow extends StatelessWidget {
  final Task task;

  const _TaskSummaryRow({required this.task});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrainTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BrainTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 14, color: BrainTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                task.dueDate != null
                    ? '${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}'
                    : 'Sin fecha',
                style: TextStyle(
                  fontSize: 12,
                  color: BrainTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              if (task.isOverdue)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: BrainTheme.accentRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Vencida',
                    style: TextStyle(
                      fontSize: 11,
                      color: BrainTheme.accentRed,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectSummaryRow extends StatelessWidget {
  final Project project;

  const _ProjectSummaryRow({required this.project});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrainTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BrainTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            project.deadline != null
                ? 'Entrega: ${project.deadline!.day}/${project.deadline!.month}/${project.deadline!.year}'
                : 'Sin fecha límite',
            style: TextStyle(
              fontSize: 12,
              color: BrainTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalSummaryRow extends StatelessWidget {
  final Goal goal;

  const _GoalSummaryRow({required this.goal});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrainTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BrainTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '${(goal.progress * 100).toInt()}% ${goal.metricLabel}',
                style: TextStyle(
                  fontSize: 12,
                  color: BrainTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                goal.progress >= 1 ? 'Completado' : 'En progreso',
                style: TextStyle(
                  fontSize: 12,
                  color: goal.progress >= 1
                      ? BrainTheme.accentGreen
                      : BrainTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SimpleSummaryRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SimpleSummaryRow({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BrainTheme.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: BrainTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: BrainTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
