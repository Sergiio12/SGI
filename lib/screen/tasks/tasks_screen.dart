import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: BrainTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BrainTheme.borderDark),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: BoxDecoration(
              color: BrainTheme.accentPurple.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: BrainTheme.accentPurple,
            unselectedLabelColor: BrainTheme.textTertiary,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Pendiente'),
              Tab(text: 'Progreso'),
              Tab(text: 'Revision'),
              Tab(text: 'Finalizada'),
              Tab(text: 'Todas'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _TaskList(filter: TaskStatus.pending),
              _TaskList(filter: TaskStatus.inProgress),
              _TaskList(filter: TaskStatus.inReview),
              _TaskList(filter: TaskStatus.completed),
              _TaskList(),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskList extends StatelessWidget {
  final TaskStatus? filter;

  const _TaskList({this.filter});

  @override
  Widget build(BuildContext context) {
    return Consumer<TasksProvider>(
      builder: (context, provider, _) {
        final tasks = provider.tasks.where((task) {
          return filter == null ? true : task.status == filter;
        }).toList()
          ..sort((a, b) {
            final priorityCompare =
                b.priority.index.compareTo(a.priority.index);
            if (priorityCompare != 0) return priorityCompare;
            return (a.dueDate ?? DateTime(9999))
                .compareTo(b.dueDate ?? DateTime(9999));
          });

        if (tasks.isEmpty) {
          return EmptyState(
            emoji: '🎯',
            title: 'Todo despejado',
            subtitle: filter == null
                ? 'No hay tareas registradas. Pulsa + para capturar una nueva.'
                : 'No hay tareas en este estado.',
            actionLabel: 'Nueva Tarea',
            onAction: () => Navigator.pushNamed(context, '/task'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TaskCard(
                task: task,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/task',
                  arguments: task.id,
                ),
                onToggle: () => provider.toggleTaskStatus(task.id),
                onDismissed: () => provider.deleteTask(task.id),
              ),
            );
          },
        );
      },
    );
  }
}
