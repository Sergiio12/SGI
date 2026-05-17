import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso')),
      body: Consumer4<TasksProvider, ProjectsProvider, NotesProvider,
          GoalsProvider>(
        builder: (context, tasks, projects, notes, goals, _) {
          final activeTasks = tasks.tasks.where((t) => t.isActive).length;
          final completed = tasks.doneTasks.length;
          final estimatedHours = tasks.tasks.fold<double>(
            0,
            (total, task) => total + task.estimatedHours,
          );
          final actualHours = tasks.tasks.fold<double>(
            0,
            (total, task) => total + (task.actualHours ?? 0),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.1,
                children: [
                  StatsCard(
                    title: 'Activas',
                    value: '$activeTasks',
                    icon: Icons.task_alt_outlined,
                    color: BrainTheme.accentBlue,
                    subtitle: '$completed finalizadas',
                  ),
                  StatsCard(
                    title: 'Proyectos',
                    value: '${projects.activeProjects.length}',
                    icon: Icons.folder_open_outlined,
                    color: BrainTheme.accentGreen,
                    subtitle: '${projects.completedProjects.length} cerrados',
                  ),
                  StatsCard(
                    title: 'Notas',
                    value: '${notes.notes.length}',
                    icon: Icons.sticky_note_2_outlined,
                    color: BrainTheme.accentCyan,
                    subtitle: '${notes.pinnedNotes.length} fijadas',
                  ),
                  StatsCard(
                    title: 'Horas',
                    value: actualHours.toStringAsFixed(1),
                    icon: Icons.timer_outlined,
                    color: BrainTheme.accentOrange,
                    subtitle: '${estimatedHours.toStringAsFixed(1)} estimadas',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text(
                'Objetivos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: BrainTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (goals.goals.isEmpty)
                const Text(
                  'No hay objetivos definidos.',
                  style: TextStyle(color: BrainTheme.textTertiary),
                )
              else
                ...goals.goals.map(
                  (goal) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GoalCard(
                      goal: goal,
                      projectCount: projects.getProjectsByGoal(goal.id).length,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/goal',
                        arguments: goal.id,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }
}
