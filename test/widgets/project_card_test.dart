import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/config/theme.dart';
import 'package:second_brain/models/project.dart';
import 'package:second_brain/providers/projects_provider.dart';
import 'package:second_brain/providers/settings_provider.dart';
import 'package:second_brain/providers/tags_provider.dart';
import 'package:second_brain/providers/tasks_provider.dart';
import 'package:second_brain/services/interfaces/storage_service_interface.dart';
import 'package:second_brain/widgets/project_card.dart';
import '../helpers/mock_storage_service.dart';

Widget createTestWidget(Widget child) {
  final storage = MockStorageService();
  return MaterialApp(
    theme: BrainTheme.darkTheme,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<ProjectsProvider>(
          create: (_) => ProjectsProvider(
            storage: storage as IStorageService,
          ),
        ),
        ChangeNotifierProvider<TagsProvider>(
          create: (_) => TagsProvider(
            storage: storage as IStorageService,
          ),
        ),
        ChangeNotifierProvider<TasksProvider>(
          create: (_) => TasksProvider(
            storage: storage as IStorageService,
          ),
        ),
      ],
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('ProjectCard', () {
    final baseProject = Project(
      id: '1',
      title: 'Test Project',
      description: 'Project description',
      emoji: '📁',
      colorValue: 0xFF2196F3,
      status: ProjectStatus.active,
      createdAt: DateTime(2026, 5, 19),
      updatedAt: DateTime(2026, 5, 19),
    );

    testWidgets('renders title and emoji', (tester) async {
      await tester.pumpWidget(
        createTestWidget(ProjectCard(project: baseProject)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Project'), findsOneWidget);
      expect(find.text('📁'), findsOneWidget);
    });

    testWidgets('shows active status', (tester) async {
      await tester.pumpWidget(
        createTestWidget(ProjectCard(project: baseProject)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Activo'), findsWidgets);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        createTestWidget(ProjectCard(
          project: baseProject,
          onTap: () => tapped = true,
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Project'));
      expect(tapped, isTrue);
    });
  });
}
