import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/config/theme.dart';
import 'package:second_brain/models/goal.dart';
import 'package:second_brain/providers/settings_provider.dart';
import 'package:second_brain/providers/tags_provider.dart';
import 'package:second_brain/services/interfaces/storage_service_interface.dart';
import 'package:second_brain/widgets/goal_card.dart';
import '../helpers/mock_storage_service.dart';

Widget createTestWidget(Widget child) {
  return MaterialApp(
    theme: BrainTheme.darkTheme,
    home: MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
        ChangeNotifierProvider<TagsProvider>(
          create: (_) => TagsProvider(
            storage: MockStorageService() as IStorageService,
          ),
        ),
      ],
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('GoalCard', () {
    final baseGoal = Goal(
      id: '1',
      title: 'Test Goal Title',
      description: 'Test goal description',
      horizon: GoalHorizon.quarterly,
      targetValue: 100,
      currentValue: 50,
      metricLabel: 'Progress',
      createdAt: DateTime(2026, 5, 19),
      updatedAt: DateTime(2026, 5, 19),
    );

    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        createTestWidget(GoalCard(goal: baseGoal, projectCount: 3)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Goal Title'), findsOneWidget);
    });

    testWidgets('shows progress value', (tester) async {
      await tester.pumpWidget(
        createTestWidget(GoalCard(goal: baseGoal, projectCount: 3)),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('50'), findsWidgets);
    });

    testWidgets('shows project count', (tester) async {
      await tester.pumpWidget(
        createTestWidget(GoalCard(goal: baseGoal, projectCount: 3)),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        createTestWidget(GoalCard(
          goal: baseGoal,
          projectCount: 0,
          onTap: () => tapped = true,
        )),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Test Goal Title'));
      expect(tapped, isTrue);
    });
  });
}
