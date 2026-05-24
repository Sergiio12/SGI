import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/dashboard_data.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/daily_planner_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/skeleton_card.dart';

import 'dashboard_header_widget.dart';
import 'dashboard_calendar_widget.dart';
import 'dashboard_stats_widget.dart';
import 'dashboard_focus_widget.dart';
import 'dashboard_overdue_widget.dart';
import 'dashboard_alerts_widget.dart';
import 'dashboard_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _weekDays;
  final _scrollController = ScrollController();
  final _scrollOffsetNotifier = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _weekDays = _getCurrentWeek();
    _scrollController.addListener(() {
      _scrollOffsetNotifier.value = _scrollController.offset;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _scrollOffsetNotifier.dispose();
    super.dispose();
  }

  List<DateTime> _getCurrentWeek() {
    final today = DateTime.now();
    final list = <DateTime>[];
    for (int i = -3; i <= 3; i++) {
      final d = today.add(Duration(days: i));
      list.add(DateTime(d.year, d.month, d.day));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final dashboardData = context.select<DashboardProvider, DashboardData>(
      (p) => p.data,
    );
    final tasksLoaded = context.select<TasksProvider, bool>((p) => p.isLoaded);
    final projectsLoaded =
        context.select<ProjectsProvider, bool>((p) => p.isLoaded);
    final notesLoaded = context.select<NotesProvider, bool>((p) => p.isLoaded);
    final goalsLoaded = context.select<GoalsProvider, bool>((p) => p.isLoaded);
    final planner = context.watch<DailyPlannerProvider>();

    if (!tasksLoaded || !projectsLoaded || !notesLoaded || !goalsLoaded) {
      return _buildSkeleton();
    }

    return RefreshIndicator(
      onRefresh: () async {
        final tasks = context.read<TasksProvider>();
        final projects = context.read<ProjectsProvider>();
        final notes = context.read<NotesProvider>();
        final goals = context.read<GoalsProvider>();
        await Future.wait([
          tasks.loadTasks(),
          projects.loadProjects(),
          notes.loadNotes(),
          goals.loadGoals(),
        ]);
      },
      displacement: 80,
      edgeOffset: 20,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: ResponsiveHelper.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<double>(
              valueListenable: _scrollOffsetNotifier,
              builder: (_, offset, child) => Transform.translate(
                offset: Offset(0, -offset * 0.15),
                child: child,
              ),
              child: DashboardHeader(
                todayProgress: dashboardData.todayProgress,
                completedUpcomingTasks: dashboardData.completedUpcomingTasks,
                totalUpcomingTasks: dashboardData.totalUpcomingTasks,
                planner: planner,
              ),
            ),
            SmartAlertsSection(alerts: dashboardData.alerts),
            if (dashboardData.alerts.isNotEmpty) const SizedBox(height: 20),
            CalendarWeekRibbon(
              selectedDate: _selectedDate,
              weekDays: _weekDays,
              onDateSelected: (d) => setState(() => _selectedDate = d),
            ),
            const SizedBox(height: 20),
            TimelineAgenda(
              selectedDate: _selectedDate,
              planner: planner,
              tasksProv: context.read<TasksProvider>(),
            ),
            const SizedBox(height: 24),
            DashboardStatsGrid(data: dashboardData),
            const SizedBox(height: 20),
            if (dashboardData.last7Counts.isNotEmpty)
              ProductivitySparkline(dailyCounts: dashboardData.last7Counts),
            if (dashboardData.last7Counts.isNotEmpty)
              const SizedBox(height: 16),
            if (dashboardData.last28Counts.isNotEmpty)
              WeeklyHeatmap(dailyCounts: dashboardData.last28Counts),
            if (dashboardData.last28Counts.isNotEmpty)
              const SizedBox(height: 24),
            FocusSection(
              focusTasksCount: dashboardData.focusTasksCount,
              planner: planner,
            ),
            const SizedBox(height: 16),
            if (dashboardData.overdueTasks.isNotEmpty) ...[
              OverdueSection(overdueTasks: dashboardData.overdueTasks),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SkeletonCard(height: 160),
          const SizedBox(height: 16),
          const SkeletonCard(height: 80),
          const SizedBox(height: 16),
          SkeletonGrid(itemCount: 4, crossAxisCount: 2, itemHeight: 130),
        ],
      ),
    );
  }
}
