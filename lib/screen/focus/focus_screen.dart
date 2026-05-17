import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_card.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo foco'),
      ),
      body: Consumer<TasksProvider>(
        builder: (context, provider, _) {
          final tasks = provider.focusTasks;
          if (tasks.isEmpty) {
            return const EmptyState(
              emoji: '✨',
              title: 'Nada crítico ahora',
              subtitle:
                  'Tu lista de foco aparecerá cuando haya tareas urgentes, altas o en progreso.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BrainTheme.accentOrange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: BrainTheme.accentOrange.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.center_focus_strong,
                      color: BrainTheme.accentOrange,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Solo lo esencial: urgente, alta prioridad cercana o trabajo ya iniciado.',
                        style: TextStyle(color: BrainTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...tasks.map(
                (task) => TaskCard(
                  task: task,
                  onTap: () =>
                      Navigator.pushNamed(context, '/task', arguments: task.id),
                  onToggle: () => provider.toggleTaskStatus(task.id),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
