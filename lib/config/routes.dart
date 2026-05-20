import 'package:flutter/material.dart';

import '../screen/calendar/calendar_screen.dart';
import '../screen/data/data_screen.dart';
import '../screen/focus/focus_screen.dart';
import '../screen/goals/goal_detail_screen.dart';
import '../screen/home_screen.dart';
import '../screen/loading/loading_screen.dart';
import '../screen/notes/note_editor_screen.dart';
import '../screen/progress/progress_screen.dart';
import '../screen/projects/project_detail_screen.dart';
import '../screen/stats/stats_screen.dart';
import '../screen/search/search_screen.dart';
import '../screen/settings/settings_screen.dart';
import '../screen/tasks/task_detail_screen.dart';
import '../screen/today/daily_review_screen.dart';
import '../screen/today/today_screen.dart';
import '../screen/trash/trash_screen.dart';

class AppRoutes {
  static const String loading = '/';
  static const String home = '/home';
  static const String taskDetail = '/task';
  static const String projectDetail = '/project';
  static const String goalDetail = '/goal';
  static const String noteEditor = '/note';
  static const String search = '/search';
  static const String focus = '/focus';
  static const String today = '/today';
  static const String calendar = '/calendar';
  static const String progress = '/progress';
  static const String data = '/data';
  static const String settings = '/settings';
  static const String trash = '/trash';
  static const String stats = '/stats';
  static const String dailyReview = '/daily-review';

  static Map<String, WidgetBuilder> get routes => {
        loading: (_) => const LoadingScreen(),
        search: (_) => const SearchScreen(),
        focus: (_) => const FocusScreen(),
        today: (_) => const TodayScreen(),
        dailyReview: (_) => const DailyReviewScreen(),
        calendar: (_) => const CalendarScreen(),
        progress: (_) => const ProgressScreen(),
        data: (_) => const DataScreen(),
        settings: (_) => const SettingsScreen(),
        trash: (_) => const TrashScreen(),
        stats: (_) => const StatsScreen(),
      };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
      case taskDetail:
        final taskId = _safeStringArg(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => TaskDetailScreen(taskId: taskId),
        );
      case projectDetail:
        final projectId = _safeStringArg(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(projectId: projectId),
        );
      case goalDetail:
        final goalId = _safeStringArg(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => GoalDetailScreen(goalId: goalId),
        );
      case noteEditor:
        final noteId = _safeStringArg(settings.arguments);
        return MaterialPageRoute(
          builder: (_) => NoteEditorScreen(noteId: noteId),
        );
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }

  static String? _safeStringArg(Object? arg) {
    if (arg is String) return arg;
    return null;
  }
}
