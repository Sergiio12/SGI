import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/notification_service_v2.dart';

class TasksProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  final _uuid = const Uuid();
  bool _isLoaded = false;

  // Listas pre-calculadas para mejorar la fluidez
  List<Task> _todoTasks = [];
  List<Task> _inProgressTasks = [];
  List<Task> _inReviewTasks = [];
  List<Task> _doneTasks = [];
  List<Task> _overdueTasks = [];
  List<Task> _urgentTasks = [];
  List<Task> _todayTasks = [];
  List<Task> _focusTasks = [];

  List<Task> get tasks => _tasks;
  bool get isLoaded => _isLoaded;

  List<Task> get todoTasks => _todoTasks;
  List<Task> get inProgressTasks => _inProgressTasks;
  List<Task> get inReviewTasks => _inReviewTasks;
  List<Task> get doneTasks => _doneTasks;
  List<Task> get overdueTasks => _overdueTasks;
  List<Task> get urgentTasks => _urgentTasks;
  List<Task> get todayTasks => _todayTasks;
  List<Task> get focusTasks => _focusTasks;

  Future<void> loadTasks() async {
    _tasks = await StorageService.loadTasks();
    await _updateComputedLists();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> _updateComputedLists() async {
    // Si hay pocas tareas, calculamos en el hilo principal para evitar overhead de Isolate
    if (_tasks.length < 50) {
      _performUpdateSync();
    } else {
      // Para muchas tareas, usamos un Isolate
      final results = await Isolate.run(() => _performUpdateSyncInternal(_tasks));
      _applyResults(results);
    }
  }

  void _performUpdateSync() {
    final results = _performUpdateSyncInternal(_tasks);
    _applyResults(results);
  }

  void _applyResults(_ComputedTasks results) {
    _todoTasks = results.todoTasks;
    _inProgressTasks = results.inProgressTasks;
    _inReviewTasks = results.inReviewTasks;
    _doneTasks = results.doneTasks;
    _overdueTasks = results.overdueTasks;
    _urgentTasks = results.urgentTasks;
    _todayTasks = results.todayTasks;
    _focusTasks = results.focusTasks;
  }

  static _ComputedTasks _performUpdateSyncInternal(List<Task> allTasks) {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    final todo = allTasks.where((t) => t.status == TaskStatus.pending).toList();
    final inProgress =
        allTasks.where((t) => t.status == TaskStatus.inProgress).toList();
    final inReview =
        allTasks.where((t) => t.status == TaskStatus.inReview).toList();
    final done =
        allTasks.where((t) => t.status == TaskStatus.completed).toList();
    final overdue = allTasks.where((t) => t.isOverdue).toList();
    final urgent = allTasks
        .where((t) => t.priority == TaskPriority.urgent && t.isActive)
        .toList();

    final today = allTasks.where((t) {
      final dueDate = t.dueDate;
      return dueDate != null &&
          dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day &&
          t.isActive;
    }).toList();

    final focus = allTasks.where((task) {
      if (!task.isActive) return false;
      if (task.status == TaskStatus.inProgress) return true;
      if (task.priority == TaskPriority.urgent) return true;
      if (task.priority == TaskPriority.high &&
          task.dueDate != null &&
          task.dueDate!.isBefore(nextWeek)) {
        return true;
      }
      return false;
    }).toList();

    focus.sort((a, b) {
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return (a.dueDate ?? DateTime(9999))
          .compareTo(b.dueDate ?? DateTime(9999));
    });

    return _ComputedTasks(
      todoTasks: todo,
      inProgressTasks: inProgress,
      inReviewTasks: inReview,
      doneTasks: done,
      overdueTasks: overdue,
      urgentTasks: urgent,
      todayTasks: today,
      focusTasks: focus,
    );
  }

  Future<void> _save() async {
    await StorageService.saveTasks(_tasks);
    await _updateComputedLists();
    notifyListeners();
  }

  List<Task> getTasksByProject(String projectId) =>
      _tasks.where((t) => t.projectId == projectId).toList();

  List<Task> getTasksByTag(String tag) =>
      _tasks.where((t) => t.tags.contains(tag)).toList();

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Task> addTask({
    required String title,
    String description = '',
    TaskPriority priority = TaskPriority.medium,
    DateTime? dueDate,
    double estimatedHours = 1,
    double? actualHours,
    int? reminderMinutesBefore,
    String? projectId,
    List<String> tags = const [],
    List<SubTask> subtasks = const [],
  }) async {
    try {
      final task = Task(
        id: _uuid.v4(),
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        estimatedHours: estimatedHours,
        actualHours: actualHours,
        reminderMinutesBefore: reminderMinutesBefore,
        projectId: projectId,
        subtasks: subtasks,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _tasks.add(task);
      await _save();
      await NotificationService.scheduleTaskReminders(task);
      showSuccessNotification('Tarea creada: ${task.title}');
      return task;
    } catch (e) {
      showErrorNotification('Error al crear tarea');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = task;
        await _save();
        await NotificationService.scheduleTaskReminders(task);
        showSuccessNotification('Tarea actualizada');
      }
    } catch (e) {
      showErrorNotification('Error al actualizar tarea');
      rethrow;
    }
  }

  Future<void> toggleTaskStatus(String taskId) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final task = _tasks[index];
        final newStatus = task.status == TaskStatus.completed
            ? TaskStatus.pending
            : TaskStatus.completed;
        final updated = task.copyWith(
          status: newStatus,
          lastActivityAt: DateTime.now(),
        );
        _tasks[index] = updated;
        await _save();
        if (newStatus == TaskStatus.completed) {
          await NotificationService.cancelTaskReminders(taskId);
          showSuccessNotification('Tarea completada');
        } else {
          await NotificationService.scheduleTaskReminders(updated);
          showSuccessNotification('Tarea reabierta');
        }
      }
    } catch (e) {
      showErrorNotification('Error al cambiar estado de tarea');
      rethrow;
    }
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newSubtasks = task.subtasks.map((s) {
        if (s.id == subtaskId) return s.copyWith(isDone: !s.isDone);
        return s;
      }).toList();
      _tasks[index] = task.copyWith(
        subtasks: newSubtasks,
        lastActivityAt: DateTime.now(),
      );
      await _save();
    }
  }

  Future<void> addSubtask(String taskId, String subtaskTitle) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _tasks[index];
      final newSubtasks = [
        ...task.subtasks,
        SubTask(id: _uuid.v4(), title: subtaskTitle),
      ];
      _tasks[index] = task.copyWith(
        subtasks: newSubtasks,
        lastActivityAt: DateTime.now(),
      );
      await _save();
    }
  }

  Future<void> replaceAll(List<Task> tasks) async {
    _tasks = tasks;
    await _save();
  }

  Future<void> deleteTask(String taskId) async {
    try {
      _tasks.removeWhere((t) => t.id == taskId);
      await _save();
      await NotificationService.cancelTaskReminders(taskId);
      showSuccessNotification('Tarea eliminada');
    } catch (e) {
      showErrorNotification('Error al eliminar tarea');
      rethrow;
    }
  }

  // Estadísticas
  int get totalTasks => _tasks.length;
  int get completedToday => _tasks
      .where((t) =>
          t.status == TaskStatus.completed &&
          t.updatedAt.day == DateTime.now().day &&
          t.updatedAt.month == DateTime.now().month &&
          t.updatedAt.year == DateTime.now().year)
      .length;

  double get completionRate {
    if (_tasks.isEmpty) return 0;
    return _doneTasks.length / _tasks.length;
  }
}

class _ComputedTasks {
  final List<Task> todoTasks;
  final List<Task> inProgressTasks;
  final List<Task> inReviewTasks;
  final List<Task> doneTasks;
  final List<Task> overdueTasks;
  final List<Task> urgentTasks;
  final List<Task> todayTasks;
  final List<Task> focusTasks;

  _ComputedTasks({
    required this.todoTasks,
    required this.inProgressTasks,
    required this.inReviewTasks,
    required this.doneTasks,
    required this.overdueTasks,
    required this.urgentTasks,
    required this.todayTasks,
    required this.focusTasks,
  });
}
