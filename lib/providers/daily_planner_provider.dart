import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/time_block.dart';
import '../services/interfaces/storage_service_interface.dart';
import 'tasks_provider.dart';

class DailyPlannerProvider extends ChangeNotifier {
  final TasksProvider _tasksProvider;
  final IStorageService _storage;

  DailyPlannerProvider({
    required TasksProvider tasksProvider,
    required IStorageService storage,
  })  : _tasksProvider = tasksProvider,
        _storage = storage;

  String _intention = '';
  DateTime _selectedDate = DateTime.now();
  final Set<String> _plannedTaskIds = {};
  final List<TimeBlock> _timeBlocks = [];
  bool _isLoaded = false;

  final _uuid = const Uuid();

  // ─── Getters ────────────────────────────────────────────────────────

  String get intention => _intention;
  DateTime get selectedDate => _selectedDate;
  Set<String> get plannedTaskIds => Set.unmodifiable(_plannedTaskIds);
  List<TimeBlock> get timeBlocks => List.unmodifiable(_timeBlocks);
  bool get isLoaded => _isLoaded;

  String get _dateKey {
    final d = _selectedDate;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  List<TimeBlock> get sortedTimeBlocks =>
      List.from(_timeBlocks)..sort((a, b) {
          final aMin = a.startHour * 60 + a.startMinute;
          final bMin = b.startHour * 60 + b.startMinute;
          return aMin.compareTo(bMin);
        });

  // ─── Data loading / saving ─────────────────────────────────────────

  Future<void> load() async {
    final intentions = await _storage.loadDailyIntentions();
    final plans = await _storage.loadDailyPlans();
    final blocks = await _storage.loadDailyTimeBlocks();

    _intention = intentions[_dateKey] ?? '';
    _plannedTaskIds
      ..clear()
      ..addAll(plans[_dateKey] ?? []);
    _timeBlocks.clear();
    final raw = blocks[_dateKey];
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      for (final e in list) {
        _timeBlocks.add(TimeBlock.fromJson(e as Map<String, dynamic>));
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    final allIntentions = await _storage.loadDailyIntentions();
    allIntentions[_dateKey] = _intention;
    await _storage.saveDailyIntentions(allIntentions);

    final allPlans = await _storage.loadDailyPlans();
    allPlans[_dateKey] = _plannedTaskIds.toList();
    await _storage.saveDailyPlans(allPlans);

    final allBlocks = await _storage.loadDailyTimeBlocks();
    allBlocks[_dateKey] =
        jsonEncode(_timeBlocks.map((b) => b.toJson()).toList());
    await _storage.saveDailyTimeBlocks(allBlocks);
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setIntention(String text) {
    _intention = text.trim();
    notifyListeners();
  }

  void addTaskToDay(String taskId) {
    if (_plannedTaskIds.contains(taskId)) return;
    _plannedTaskIds.add(taskId);
    notifyListeners();
  }

  void removeTaskFromDay(String taskId) {
    _plannedTaskIds.remove(taskId);
    _timeBlocks.removeWhere((b) => b.taskId == taskId);
    notifyListeners();
  }

  bool isTaskPlanned(String taskId) => _plannedTaskIds.contains(taskId);

  void toggleTaskInDay(String taskId) {
    if (_plannedTaskIds.contains(taskId)) {
      removeTaskFromDay(taskId);
    } else {
      addTaskToDay(taskId);
    }
  }

  TimeBlock? getTimeBlockForTask(String taskId) {
    try {
      return _timeBlocks.firstWhere((b) => b.taskId == taskId);
    } catch (_) {
      return null;
    }
  }

  void setTimeBlock(TimeBlock block) {
    _timeBlocks.removeWhere((b) => b.taskId == block.taskId);
    _timeBlocks.add(block);
    notifyListeners();
  }

  void removeTimeBlock(String taskId) {
    _timeBlocks.removeWhere((b) => b.taskId == taskId);
    notifyListeners();
  }

  void toggleTimeBlockCompleted(String taskId) {
    final index = _timeBlocks.indexWhere((b) => b.taskId == taskId);
    if (index == -1) return;
    final block = _timeBlocks[index];
    _timeBlocks[index] = block.copyWith(isCompleted: !block.isCompleted);
    notifyListeners();
  }

  void createTimeBlock({
    required String taskId,
    required int startHour,
    required int startMinute,
    required int endHour,
    required int endMinute,
  }) {
    final block = TimeBlock(
      id: _uuid.v4(),
      taskId: taskId,
      startHour: startHour,
      startMinute: startMinute,
      endHour: endHour,
      endMinute: endMinute,
    );
    setTimeBlock(block);
  }

  void addSuggestedTasks() {
    final overdue = _tasksProvider.overdueTasks;
    final today = _tasksProvider.todayTasks;
    final urgent = _tasksProvider.urgentTasks;

    final suggested = <String>{};
    for (final task in [
      ...overdue,
      ...urgent,
      ...today,
    ]) {
      if (task.isActive) suggested.add(task.id);
    }
    for (final id in suggested) {
      _plannedTaskIds.add(id);
    }
    if (suggested.isNotEmpty) notifyListeners();
  }
}
