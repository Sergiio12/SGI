import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/daily_planner_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/projects_provider.dart';
import 'providers/search_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/tags_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/trash_provider.dart';
import 'services/interfaces/storage_service_interface.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'utils/haptic_helper.dart';
import 'utils/notification_service_v2.dart';

class AppBootstrap {
  static Future<Widget> build() async {
    final storageService = HiveStorageService();

    final settingsProvider = SettingsProvider();
    await settingsProvider.load();
    setHapticSettings(settingsProvider);

    final tasksProvider = TasksProvider(storage: storageService);
    settingsProvider.onNotificationSettingsChanged =
        () => NotificationService.rescheduleAll(tasksProvider.tasks);

    final projectsProvider = ProjectsProvider(storage: storageService);
    final notesProvider = NotesProvider(storage: storageService);
    final tagsProvider = TagsProvider(storage: storageService);
    final goalsProvider = GoalsProvider(storage: storageService);
    final trashProvider = TrashProvider(storage: storageService);
    trashProvider.register();

    final dailyPlannerProvider =
        DailyPlannerProvider(tasksProvider: tasksProvider, storage: storageService);

    return MultiProvider(
      providers: [
        Provider<IStorageService>.value(value: storageService),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: tasksProvider),
        ChangeNotifierProvider.value(value: projectsProvider),
        ChangeNotifierProvider.value(value: notesProvider),
        ChangeNotifierProvider.value(value: tagsProvider),
        ChangeNotifierProvider.value(value: goalsProvider),
        ChangeNotifierProvider.value(value: trashProvider),
        ChangeNotifierProvider(create: (_) {
          final controller = NotificationController();
          setGlobalNotificationController(controller);
          return controller;
        }),
        ChangeNotifierProvider(create: (_) => SearchProvider()),
        ChangeNotifierProxyProvider2<TasksProvider, ProjectsProvider,
            DashboardProvider>(
          create: (context) => DashboardProvider(
            tasksProvider: context.read<TasksProvider>(),
            projectsProvider: context.read<ProjectsProvider>(),
          ),
          update: (context, tasks, projects, previous) {
            if (previous == null) {
              return DashboardProvider(
                tasksProvider: tasks,
                projectsProvider: projects,
              );
            }
            previous.updateProviders(
              tasksProvider: tasks,
              projectsProvider: projects,
            );
            return previous;
          },
        ),
        ChangeNotifierProvider.value(value: dailyPlannerProvider),
      ],
      child: const SecondBrainApp(),
    );
  }
}
