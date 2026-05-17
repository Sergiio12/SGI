import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/settings_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/projects_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/goals_provider.dart';
import 'providers/search_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/trash_provider.dart';
import 'services/notification_service.dart';
import 'utils/notification_service_v2.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init notification plugin before providers
  await NotificationService.init();

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Instantiate providers (data will be loaded inside LoadingScreen)
  final settingsProvider = SettingsProvider();
  await settingsProvider.load();

  final tasksProvider = TasksProvider();
  settingsProvider.onNotificationSettingsChanged = () =>
      NotificationService.rescheduleAll(tasksProvider.tasks);

  final projectsProvider = ProjectsProvider();
  final notesProvider = NotesProvider();
  final goalsProvider = GoalsProvider();
  final trashProvider = TrashProvider();
  trashProvider.register();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: tasksProvider),
        ChangeNotifierProvider.value(value: projectsProvider),
        ChangeNotifierProvider.value(value: notesProvider),
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
      ],
      child: const SecondBrainApp(),
    ),
  );
}
