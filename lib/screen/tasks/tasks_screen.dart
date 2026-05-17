import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
              hintText: 'Buscar tareas...',
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
            children: [
              _TaskList(filter: TaskStatus.pending, searchQuery: _searchQuery),
              _TaskList(
                  filter: TaskStatus.inProgress, searchQuery: _searchQuery),
              _TaskList(filter: TaskStatus.inReview, searchQuery: _searchQuery),
              _TaskList(
                  filter: TaskStatus.completed, searchQuery: _searchQuery),
              _TaskList(searchQuery: _searchQuery),
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskList extends StatefulWidget {
  final TaskStatus? filter;
  final String searchQuery;

  const _TaskList({this.filter, this.searchQuery = ''});

  @override
  State<_TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<_TaskList> {
  static const int _pageSize = 15;
  int _currentPage = 0;

  @override
  void didUpdateWidget(_TaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery ||
        oldWidget.filter != widget.filter) {
      setState(() => _currentPage = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TasksProvider>(
      builder: (context, provider, _) {
        var tasks = provider.tasks.where((task) {
          final matchesFilter =
              widget.filter == null ? true : task.status == widget.filter;
          final matchesSearch = widget.searchQuery.isEmpty ||
              task.title.toLowerCase().contains(widget.searchQuery) ||
              task.description.toLowerCase().contains(widget.searchQuery);
          return matchesFilter && matchesSearch;
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
            subtitle: widget.searchQuery.isNotEmpty
                ? 'No hay tareas que coincidan con "${widget.searchQuery}"'
                : widget.filter == null
                    ? 'No hay tareas registradas. Pulsa + para capturar una nueva.'
                    : 'No hay tareas en este estado.',
            actionLabel: 'Nueva Tarea',
            onAction: () => Navigator.pushNamed(context, '/task'),
          );
        }

        final totalPages = (tasks.length / _pageSize).ceil();
        final start = _currentPage * _pageSize;
        final end = (start + _pageSize).clamp(0, tasks.length);
        final pageTasks = tasks.sublist(start, end);

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: pageTasks.length,
                itemBuilder: (context, index) {
                  final task = pageTasks[index];
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
              ),
            ),
            PaginationBar(
              currentPage: _currentPage,
              totalPages: totalPages,
              onPageChanged: (p) => setState(() => _currentPage = p),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}
