import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/result.dart';
import '../models/goal.dart';
import '../services/interfaces/storage_service_interface.dart';
import '../utils/debouncer.dart';
import '../utils/haptic_helper.dart';
import '../utils/notification_service_v2.dart';

class GoalsProvider extends ChangeNotifier {
  final IStorageService _storage;
  List<Goal> _goals = [];
  final _uuid = const Uuid();
  bool _isLoaded = false;
  final _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

  GoalsProvider({required IStorageService storage}) : _storage = storage;

  List<Goal>? __monthlyGoals;
  List<Goal>? __quarterlyGoals;
  List<Goal>? __yearlyGoals;

  List<Goal> get goals => _goals;
  bool get isLoaded => _isLoaded;

  List<Goal> get monthlyGoals =>
      __monthlyGoals ??= _goals.where((g) => g.horizon == GoalHorizon.monthly).toList();
  List<Goal> get quarterlyGoals =>
      __quarterlyGoals ??= _goals.where((g) => g.horizon == GoalHorizon.quarterly).toList();
  List<Goal> get yearlyGoals =>
      __yearlyGoals ??= _goals.where((g) => g.horizon == GoalHorizon.yearly).toList();

  Goal? getGoalById(String id) {
    try {
      return _goals.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  Result<Goal> getGoalByIdResult(String id) {
    try {
      return Result.success(_goals.firstWhere((g) => g.id == id));
    } catch (_) {
      return Result.failure(AppException(
        message: 'Objetivo no encontrado: $id',
        code: 'GOAL_NOT_FOUND',
      ));
    }
  }

  Future<void> loadGoals() async {
    _goals = await _storage.loadGoals();
    _markDirty();
    _isLoaded = true;
    notifyListeners();
  }

  void _markDirty() {
    __monthlyGoals = null;
    __quarterlyGoals = null;
    __yearlyGoals = null;
  }

  void _notifyAndScheduleSave() {
    _markDirty();
    notifyListeners();
    _saveDebouncer.call(() => _storage.saveGoals(_goals));
  }

  Future<Result<Goal>> addGoal({
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
      _notifyAndScheduleSave();
      HapticHelper.light();
      showSuccessNotification('Objetivo creado: ${goal.title}');
      return Result.success(goal);
    } catch (e, s) {
      final error = AppException(
        message: 'Error al crear objetivo',
        code: 'ADD_GOAL',
        stackTrace: s,
      );
      error.log();
      showErrorNotification(error.message);
      return Result.failure(error);
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      final index = _goals.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _goals[index] = goal;
        _notifyAndScheduleSave();
        showSuccessNotification('Objetivo actualizado');
      }
    } catch (e, s) {
      AppException(message: 'Error al actualizar objetivo', code: 'UPDATE_GOAL', stackTrace: s).log();
      showErrorNotification('Error al actualizar objetivo');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      final index = _goals.indexWhere((g) => g.id == goalId);
      if (index == -1) return;
      final goal = _goals.removeAt(index);
      final trash = await _storage.loadTrashGoals();
      trash.add(goal);
      await _storage.saveTrashGoals(trash);
      _notifyAndScheduleSave();
      HapticHelper.medium();
    } catch (e, s) {
      AppException(message: 'Error al eliminar objetivo', code: 'DELETE_GOAL', stackTrace: s).log();
      showErrorNotification('Error al eliminar objetivo');
    }
  }

  Future<void> restoreGoal(String goalId) async {
    try {
      final trash = await _storage.loadTrashGoals();
      final index = trash.indexWhere((g) => g.id == goalId);
      if (index != -1) {
        final goal = trash.removeAt(index);
        _goals.add(goal);
        await _storage.saveTrashGoals(trash);
        _notifyAndScheduleSave();
        HapticHelper.light();
        showSuccessNotification('Objetivo restaurado');
      }
    } catch (e, s) {
      AppException(message: 'Error al restaurar objetivo', code: 'RESTORE_GOAL', stackTrace: s).log();
      showErrorNotification('Error al restaurar objetivo');
    }
  }

  Future<void> permanentDeleteGoal(String goalId) async {
    try {
      final trash = await _storage.loadTrashGoals();
      trash.removeWhere((g) => g.id == goalId);
      await _storage.saveTrashGoals(trash);
      showSuccessNotification('Objetivo eliminado permanentemente');
    } catch (e, s) {
      AppException(message: 'Error al eliminar objetivo permanentemente', code: 'PERM_DELETE_GOAL', stackTrace: s).log();
      showErrorNotification('Error al eliminar objetivo');
    }
  }

  Future<void> replaceAll(List<Goal> goals) async {
    _goals = goals;
    _notifyAndScheduleSave();
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }
}
