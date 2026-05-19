import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/models/goal.dart';
import 'package:second_brain/providers/goals_provider.dart';

import '../helpers/mock_storage_service.dart';

void main() {
  late MockStorageService storage;
  late GoalsProvider provider;

  setUp(() async {
    storage = MockStorageService();
    provider = GoalsProvider(storage: storage);
    await provider.loadGoals();
  });

  group('GoalsProvider - CRUD', () {
    test('loadGoals loads empty list by default', () {
      expect(provider.goals, isEmpty);
      expect(provider.isLoaded, isTrue);
    });

    test('addGoal creates a goal', () async {
      final result = await provider.addGoal(title: 'Test Goal');
      expect(result.isSuccess, isTrue);
      final goal = result.unwrap();
      expect(goal.title, 'Test Goal');
      expect(provider.goals.length, 1);
    });

    test('addGoal with all fields', () async {
      final result = await provider.addGoal(
        title: 'Full Goal',
        description: 'A measurable goal',
        horizon: GoalHorizon.yearly,
        metricLabel: 'Sales',
        targetValue: 1000,
        currentValue: 250,
        colorValue: 0xFF00FF00,
        tags: ['business'],
      );
      expect(result.isSuccess, isTrue);
      final goal = result.unwrap();
      expect(goal.description, 'A measurable goal');
      expect(goal.horizon, GoalHorizon.yearly);
      expect(goal.metricLabel, 'Sales');
      expect(goal.targetValue, 1000);
      expect(goal.currentValue, 250);
      expect(goal.tags, ['business']);
    });

    test('updateGoal modifies goal', () async {
      final result = await provider.addGoal(title: 'Original');
      final goal = result.unwrap();
      final updated = goal.copyWith(title: 'Updated');
      await provider.updateGoal(updated);
      expect(provider.getGoalById(goal.id)?.title, 'Updated');
    });

    test('getGoalById returns null for missing id', () {
      expect(provider.getGoalById('missing'), isNull);
    });
  });

  group('GoalsProvider - Horizon filters', () {
    test('goals are filtered by horizon', () async {
      await provider.addGoal(title: 'Monthly', horizon: GoalHorizon.monthly);
      await provider.addGoal(
        title: 'Quarterly',
        horizon: GoalHorizon.quarterly,
      );
      await provider.addGoal(title: 'Yearly', horizon: GoalHorizon.yearly);

      expect(provider.monthlyGoals.length, 1);
      expect(provider.quarterlyGoals.length, 1);
      expect(provider.yearlyGoals.length, 1);
    });
  });

  group('GoalsProvider - Trash Lifecycle', () {
    test('deleteGoal moves to trash', () async {
      final result = await provider.addGoal(title: 'Delete me');
      final goal = result.unwrap();
      await provider.deleteGoal(goal.id);
      expect(provider.goals, isEmpty);
    });

    test('restoreGoal retrieves from trash', () async {
      final result = await provider.addGoal(title: 'Restore me');
      final goal = result.unwrap();
      await provider.deleteGoal(goal.id);
      await provider.restoreGoal(goal.id);
      expect(provider.goals.length, 1);
    });

    test('permanentDeleteGoal removes from trash', () async {
      final result = await provider.addGoal(title: 'Forever');
      final goal = result.unwrap();
      await provider.deleteGoal(goal.id);
      await provider.permanentDeleteGoal(goal.id);
    });
  });
}
