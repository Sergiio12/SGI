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
import 'providers/sync_provider.dart';
import 'providers/tags_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/trash_provider.dart';
import 'providers/ai_provider.dart';
import 'services/cloud/firebase_sync_service.dart';
import 'services/cloud/local_first_storage_service.dart';
import 'services/interfaces/storage_service_interface.dart';
import 'services/home_widget_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'utils/haptic_helper.dart';
import 'utils/notification_service_v2.dart';

class AppBootstrap {
  static Future<Widget> build() async {
    final localStorage = HiveStorageService();
    final firebaseSync = FirebaseSyncService();
    await firebaseSync.init();

    final storageService = LocalFirstStorageService(localStorage, firebaseSync);

    await HomeWidgetService.init();

    final settingsProvider = SettingsProvider();
    await settingsProvider.load();
    setHapticSettings(settingsProvider);

    final syncProvider = SyncProvider(
      syncService: firebaseSync,
      storage: storageService,
    );

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

    final aiProvider = AiProvider(settings: settingsProvider);

    return MultiProvider(
      providers: [
        Provider<IStorageService>.value(value: storageService),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: syncProvider),
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
        ChangeNotifierProvider.value(value: aiProvider),
      ],
      child: const SecondBrainApp(),
    );
  }
}
