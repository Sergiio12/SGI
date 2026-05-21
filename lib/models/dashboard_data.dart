import '../models/task.dart';
import '../services/smart_alerts_service.dart';

class DashboardData {
  final int activeTasksCount;
  final int totalTasksCount;
  final double tasksProgressVal;
  final int tasksProgressPercent;

  final int activeProjectsCount;
  final int totalProjectsCount;
  final double projectsProgressVal;
  final int projectsProgressPercent;
  final int completedProjectsCount;

  final int activeGoalsCount;
  final double averageGoalProgress;
  final int averageGoalProgressPercent;

  final int totalNotesCount;
  final int notesNotebooksCount;

  final double todayProgress;
  final int completedUpcomingTasks;
  final int totalUpcomingTasks;

  final List<int> last28Counts;
  final List<int> last7Counts;

  final List<Task> overdueTasks;
  final int focusTasksCount;

  final List<SmartAlert> alerts;

  const DashboardData({
    required this.activeTasksCount,
    required this.totalTasksCount,
    required this.tasksProgressVal,
    required this.tasksProgressPercent,
    required this.activeProjectsCount,
    required this.totalProjectsCount,
    required this.projectsProgressVal,
    required this.projectsProgressPercent,
    required this.completedProjectsCount,
    required this.activeGoalsCount,
    required this.averageGoalProgress,
    required this.averageGoalProgressPercent,
    required this.totalNotesCount,
    required this.notesNotebooksCount,
    required this.todayProgress,
    required this.completedUpcomingTasks,
    required this.totalUpcomingTasks,
    required this.last28Counts,
    required this.last7Counts,
    required this.overdueTasks,
    required this.focusTasksCount,
    required this.alerts,
  });

  factory DashboardData.empty() => const DashboardData(
        activeTasksCount: 0,
        totalTasksCount: 0,
        tasksProgressVal: 0,
        tasksProgressPercent: 0,
        activeProjectsCount: 0,
        totalProjectsCount: 0,
        projectsProgressVal: 0,
        projectsProgressPercent: 0,
        completedProjectsCount: 0,
        activeGoalsCount: 0,
        averageGoalProgress: 0,
        averageGoalProgressPercent: 0,
        totalNotesCount: 0,
        notesNotebooksCount: 0,
        todayProgress: 0,
        completedUpcomingTasks: 0,
        totalUpcomingTasks: 0,
        last28Counts: const [],
        last7Counts: const [],
        overdueTasks: const [],
        focusTasksCount: 0,
        alerts: const [],
      );
}
