import 'package:flutter/material.dart';
import 'package:second_brain/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_card.dart';
import 'pomodoro_timer.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).focusMode),
      ),
      body: SafeArea(
        child: Consumer<TasksProvider>(
          builder: (context, provider, _) {
          final tasks = provider.focusTasks;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              const PomodoroTimer(),
              const SizedBox(height: 24),
              Row(
                children: [
                  Icon(Icons.checklist_rounded, size: 16, color: BrainTheme.textTertiary),
                  const SizedBox(width: 8),
                  Text(
                    'Tareas en foco',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: BrainTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: BrainTheme.accentOf(context).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${tasks.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BrainTheme.accentOf(context),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (tasks.isEmpty)
                EmptyState(
                  emoji: '🧘',
                  title: 'Sin tareas en foco',
                  subtitle: 'Las tareas urgentes y en progreso aparecerán aquí automáticamente.',
                )
              else
                ...tasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TaskCard(
                      task: task,
                      onTap: () =>
                          Navigator.pushNamed(context, '/task', arguments: task.id),
                      onToggle: () => provider.toggleTaskStatus(task.id),
                    ),
                  ),
                ),
            ],
          );
          },
        ),
      ),
    );
  }
}
