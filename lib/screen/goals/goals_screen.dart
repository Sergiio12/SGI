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
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar objetivos...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
            children: [
              _GoalList(searchQuery: _searchQuery),
              _GoalList(
                  horizon: GoalHorizon.monthly, searchQuery: _searchQuery),
              _GoalList(
                  horizon: GoalHorizon.quarterly, searchQuery: _searchQuery),
              _GoalList(horizon: GoalHorizon.yearly, searchQuery: _searchQuery),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoalList extends StatelessWidget {
  final GoalHorizon? horizon;
  final String searchQuery;

  const _GoalList({this.horizon, this.searchQuery = ''});

  @override
  Widget build(BuildContext context) {
    return Consumer2<GoalsProvider, ProjectsProvider>(
      builder: (context, goalsProvider, projectsProvider, _) {
        final goals = goalsProvider.goals.where((goal) {
          final matchesHorizon =
              horizon == null ? true : goal.horizon == horizon;
          final matchesSearch = searchQuery.isEmpty ||
              goal.title.toLowerCase().contains(searchQuery) ||
              goal.description.toLowerCase().contains(searchQuery);
          return matchesHorizon && matchesSearch;
        }).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        if (goals.isEmpty) {
          return EmptyState(
            emoji: searchQuery.isNotEmpty ? '🔍' : '◎',
            title: searchQuery.isNotEmpty
                ? 'Sin resultados'
                : 'Sin objetivos',
            subtitle: searchQuery.isNotEmpty
                ? 'No hay objetivos que coincidan con "$searchQuery"'
                : 'Define el norte antes de llenar el dia de tareas.',
            actionLabel: searchQuery.isNotEmpty ? null : 'Crear objetivo',
            onAction: searchQuery.isNotEmpty
                ? null
                : () => Navigator.pushNamed(context, '/goal'),
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
