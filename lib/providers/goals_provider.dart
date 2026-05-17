import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/goal.dart';
import '../services/storage_service.dart';
import '../utils/notification_service_v2.dart';

class GoalsProvider extends ChangeNotifier {
  List<Goal> _goals = [];
  final _uuid = const Uuid();
  bool _isLoaded = false;

  List<Goal> get goals => _goals;
  bool get isLoaded => _isLoaded;

  List<Goal> get monthlyGoals =>
      _goals.where((g) => g.horizon == GoalHorizon.monthly).toList();
  List<Goal> get quarterlyGoals =>
      _goals.where((g) => g.horizon == GoalHorizon.quarterly).toList();
  List<Goal> get yearlyGoals =>
      _goals.where((g) => g.horizon == GoalHorizon.yearly).toList();

  Goal? getGoalById(String id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadGoals() async {
    _goals = await StorageService.loadGoals();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    await StorageService.saveGoals(_goals);
    notifyListeners();
  }

  Future<Goal> addGoal({
    required String title,
    String description = '',
    GoalHorizon horizon = GoalHorizon.quarterly,
    List<String> projectIds = const [],
    String metricLabel = 'Progreso',
    double targetValue = 100,
    double currentValue = 0,
    int colorValue = 0xFF8B5CF6,
    List<String> tags = const [],
  }) async {
    try {
      final now = DateTime.now();
      final goal = Goal(
        id: _uuid.v4(),
        title: title,
        description: description,
        horizon: horizon,
        projectIds: projectIds,
        metricLabel: metricLabel,
        targetValue: targetValue,
        currentValue: currentValue,
        colorValue: colorValue,
        tags: tags,
        createdAt: now,
        updatedAt: now,
      );
      _goals.add(goal);
      await _save();
      showSuccessNotification('Objetivo creado: ${goal.title}');
      return goal;
    } catch (e) {
      showErrorNotification('Error al crear objetivo');
      rethrow;
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
        await _save();
        showSuccessNotification('Objetivo actualizado');
      }
    } catch (e) {
      showErrorNotification('Error al actualizar objetivo');
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      _goals.removeWhere((g) => g.id == goalId);
      await _save();
      showSuccessNotification('Objetivo eliminado');
    } catch (e) {
      showErrorNotification('Error al eliminar objetivo');
      rethrow;
    }
  }

  Future<void> replaceAll(List<Goal> goals) async {
    _goals = goals;
    await _save();
  }
}
