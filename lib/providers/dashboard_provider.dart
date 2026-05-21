import 'dart:async';
import 'package:flutter/material.dart';

import '../models/dashboard_data.dart';
import '../models/goal.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../core/result.dart';
import '../services/smart_alerts_service.dart';
import 'goals_provider.dart';
import 'notes_provider.dart';
import 'projects_provider.dart';
import 'tasks_provider.dart';

class DashboardProvider extends ChangeNotifier {
  TasksProvider _tasksProvider;
  ProjectsProvider _projectsProvider;
  NotesProvider _notesProvider;
  GoalsProvider _goalsProvider;

  DashboardData? _data;
  bool _dirty = true;
  bool _isComputing = false;

  DashboardProvider({
    required TasksProvider tasksProvider,
    required ProjectsProvider projectsProvider,
    required NotesProvider notesProvider,
    required GoalsProvider goalsProvider,
  })  : _tasksProvider = tasksProvider,
        _projectsProvider = projectsProvider,
        _notesProvider = notesProvider,
        _goalsProvider = goalsProvider {
    tasksProvider.addListener(_onDataChanged);
    projectsProvider.addListener(_onDataChanged);
    notesProvider.addListener(_onDataChanged);
    goalsProvider.addListener(_onDataChanged);
  }

  DashboardData get data {
    if (_dirty && !_isComputing) {
      _scheduleCompute();
    }
    return _data ?? _computeSync();
  }

  void updateProviders({
    required TasksProvider tasksProvider,
    required ProjectsProvider projectsProvider,
    required NotesProvider notesProvider,
    required GoalsProvider goalsProvider,
  }) {
    _tasksProvider.removeListener(_onDataChanged);
    _projectsProvider.removeListener(_onDataChanged);
    _notesProvider.removeListener(_onDataChanged);
    _goalsProvider.removeListener(_onDataChanged);
    _tasksProvider = tasksProvider;
    _projectsProvider = projectsProvider;
    _notesProvider = notesProvider;
    _goalsProvider = goalsProvider;
    tasksProvider.addListener(_onDataChanged);
    projectsProvider.addListener(_onDataChanged);
    notesProvider.addListener(_onDataChanged);
    goalsProvider.addListener(_onDataChanged);
    _onDataChanged();
  }

  Timer? _debounceTimer;

  void _onDataChanged() {
    _dirty = true;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _computeAsync();
    });
  }

  void _scheduleCompute() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(Duration.zero, _computeAsync);
  }

  Future<void> _computeAsync() async {
    if (_isComputing) return;
    _isComputing = true;

    try {
      final tasks = List<Task>.from(_tasksProvider.tasks);
      final projects = List<Project>.from(_projectsProvider.projects);
      final notes = _notesProvider.notes;
      final goals = _goalsProvider.goals;

      final alerts = await SmartAlertsService.buildAlerts(
        tasks: tasks,
        projects: projects,
      );

      _data = _buildDashboardData(tasks, projects, notes, goals, alerts);
      _dirty = false;
    } catch (e, s) {
      AppException(
        message: 'Error al calcular datos del dashboard',
        code: 'DASHBOARD_DATA',
        stackTrace: s,
      ).log();
    } finally {
      _isComputing = false;
      notifyListeners();
    }
  }

  DashboardData _computeSync() {
    final tasks = List<Task>.from(_tasksProvider.tasks);
    final projects = List<Project>.from(_projectsProvider.projects);
    final notes = _notesProvider.notes;
    final goals = _goalsProvider.goals;

    return _buildDashboardData(tasks, projects, notes, goals, []);
  }

  DashboardData _buildDashboardData(
    List<Task> tasks,
    List<Project> projects,
    List<Note> notes,
    List<Goal> goals,
    List<SmartAlert> alerts,
  ) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    final last28Counts = List.generate(28, (i) {
      final day = today.subtract(Duration(days: 27 - i));
      return tasks
          .where((t) =>
              t.status == TaskStatus.completed &&
              t.updatedAt.year == day.year &&
              t.updatedAt.month == day.month &&
              t.updatedAt.day == day.day)
          .length;
    });
    final last7Counts = last28Counts.sublist(21);

    final upcomingTasks = tasks.where((t) {
      final d = t.dueDate;
      return d != null && !d.isBefore(todayStart);
    }).toList();
    final completedUpcoming =
        upcomingTasks.where((t) => t.status == TaskStatus.completed).length;
    final totalUpcoming = upcomingTasks.length;
    final todayProgress =
        totalUpcoming == 0 ? 0.0 : (completedUpcoming / totalUpcoming);

    final activeTasksCount = tasks.where((t) => t.isActive).length;
    final totalTasksCount = tasks.length;
    final doneTasksCount =
        tasks.where((t) => t.status == TaskStatus.completed).length;
    final tasksProgressVal =
        totalTasksCount == 0 ? 0.0 : (doneTasksCount / totalTasksCount);
    final tasksProgressPercent = (tasksProgressVal * 100).toInt();

    final activeProjectsCount =
        projects.where((p) => p.status == ProjectStatus.active).length;
    final totalProjectsCount = projects.length;
    final completedProjectsCount =
        projects.where((p) => p.status == ProjectStatus.completed).length;
    final projectsProgressVal = totalProjectsCount == 0
        ? 0.0
        : (completedProjectsCount / totalProjectsCount);
    final projectsProgressPercent = (projectsProgressVal * 100).toInt();

    final activeGoalsCount = goals.length;
    final averageGoalProgress = goals.isEmpty
        ? 0.0
        : (goals.map((g) => g.progress).reduce((a, b) => a + b)) /
            goals.length;
    final averageGoalProgressPercent = (averageGoalProgress * 100).toInt();

    final totalNotesCount = notes.length;
    final notesNotebooksCount =
        notes.map((n) => n.notebook).toSet().length;

    final overdueTasks = tasks.where((t) => t.isOverdue).toList();

    final focusTasksCount = tasks.where((task) {
      if (!task.isActive) return false;
      if (task.status == TaskStatus.inProgress) return true;
      if (task.priority == TaskPriority.urgent) return true;
      if (task.priority == TaskPriority.high && task.dueDate != null) {
        return true;
      }
      return false;
    }).length;

    return DashboardData(
      activeTasksCount: activeTasksCount,
      totalTasksCount: totalTasksCount,
      tasksProgressVal: tasksProgressVal,
      tasksProgressPercent: tasksProgressPercent,
      activeProjectsCount: activeProjectsCount,
      totalProjectsCount: totalProjectsCount,
      projectsProgressVal: projectsProgressVal,
      projectsProgressPercent: projectsProgressPercent,
      completedProjectsCount: completedProjectsCount,
      activeGoalsCount: activeGoalsCount,
      averageGoalProgress: averageGoalProgress,
      averageGoalProgressPercent: averageGoalProgressPercent,
      totalNotesCount: totalNotesCount,
      notesNotebooksCount: notesNotebooksCount,
      todayProgress: todayProgress,
      completedUpcomingTasks: completedUpcoming,
      totalUpcomingTasks: totalUpcoming,
      last28Counts: last28Counts,
      last7Counts: last7Counts,
      overdueTasks: overdueTasks,
      focusTasksCount: focusTasksCount,
      alerts: alerts,
    );
  }

  @override
  void dispose() {
    _tasksProvider.removeListener(_onDataChanged);
    _projectsProvider.removeListener(_onDataChanged);
    _notesProvider.removeListener(_onDataChanged);
    _goalsProvider.removeListener(_onDataChanged);
    _debounceTimer?.cancel();
    super.dispose();
  }
}
