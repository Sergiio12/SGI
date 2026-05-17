import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/goal.dart';
import '../../providers/goals_provider.dart';
import '../../providers/projects_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/goal_card.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Todos'),
              Tab(text: 'Mensual'),
              Tab(text: 'Trimestral'),
              Tab(text: 'Anual'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _GoalList(),
              _GoalList(horizon: GoalHorizon.monthly),
              _GoalList(horizon: GoalHorizon.quarterly),
              _GoalList(horizon: GoalHorizon.yearly),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalList extends StatelessWidget {
  final GoalHorizon? horizon;

  const _GoalList({this.horizon});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GoalsProvider, ProjectsProvider>(
      builder: (context, goalsProvider, projectsProvider, _) {
        final goals = goalsProvider.goals.where((goal) {
          return horizon == null ? true : goal.horizon == horizon;
        }).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        if (goals.isEmpty) {
          return EmptyState(
            emoji: '◎',
            title: 'Sin objetivos',
            subtitle: 'Define el norte antes de llenar el dia de tareas.',
            actionLabel: 'Crear objetivo',
            onAction: () => Navigator.pushNamed(context, '/goal'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: goals.length,
          itemBuilder: (context, index) {
            final goal = goals[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GoalCard(
                goal: goal,
                projectCount:
                    projectsProvider.getProjectsByGoal(goal.id).length,
                onTap: () =>
                    Navigator.pushNamed(context, '/goal', arguments: goal.id),
              ),
            );
          },
        );
      },
    );
  }
}
