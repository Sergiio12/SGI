import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/config/theme.dart';
import 'package:second_brain/models/task.dart';
import 'package:second_brain/providers/projects_provider.dart';
import 'package:second_brain/providers/settings_provider.dart';
import 'package:second_brain/services/interfaces/storage_service_interface.dart';
import 'package:second_brain/widgets/task_card.dart';
import '../helpers/mock_storage_service.dart';

Widget createTestWidget(Widget child) {
  return MaterialApp(
    theme: BrainTheme.darkTheme,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<ProjectsProvider>(
          create: (_) => ProjectsProvider(
            storage: MockStorageService() as IStorageService,
          ),
        ),
      ],
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('TaskCard', () {
    final baseTask = Task(
      id: '1',
      title: 'Test Task Title',
      description: 'Test description',
      priority: TaskPriority.high,
      status: TaskStatus.pending,
      createdAt: DateTime(2026, 5, 19),
      updatedAt: DateTime(2026, 5, 19),
    );

    testWidgets('renders title and description', (tester) async {
      await tester.pumpWidget(
        createTestWidget(TaskCard(task: baseTask)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Task Title'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('shows status badge', (tester) async {
      await tester.pumpWidget(
        createTestWidget(TaskCard(task: baseTask)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Pendiente'), findsWidgets);
    });

    testWidgets('shows priority badge', (tester) async {
      await tester.pumpWidget(
        createTestWidget(TaskCard(task: baseTask)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Alta'), findsWidgets);
    });

    testWidgets('shows strikethrough when completed', (tester) async {
      final completedTask = baseTask.copyWith(
        status: TaskStatus.completed,
      );
      await tester.pumpWidget(
        createTestWidget(TaskCard(task: completedTask)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Task Title'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        createTestWidget(TaskCard(
          task: baseTask,
          onTap: () => tapped = true,
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Task Title'));
      expect(tapped, isTrue);
    });

    testWidgets('shows date badge', (tester) async {
      final taskWithDate = baseTask.copyWith(
        dueDate: DateTime(2026, 5, 25),
      );
      await tester.pumpWidget(
        createTestWidget(TaskCard(task: taskWithDate)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('25'), findsWidgets);
    });

    testWidgets('renders without slide when disabled', (tester) async {
      await tester.pumpWidget(
        createTestWidget(TaskCard(task: baseTask, enableSlide: false)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Task Title'), findsOneWidget);
    });
  });
}
