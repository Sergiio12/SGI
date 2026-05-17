import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../utils/debouncer.dart';
import '../utils/notification_service_v2.dart';

class TasksProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  final _uuid = const Uuid();
  bool _isLoaded = false;
  final _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

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
    _updateComputedLists();
    _isLoaded = true;
    notifyListeners();
  }

  void _updateComputedLists() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));

    _todoTasks = _tasks.where((t) => t.status == TaskStatus.pending).toList();
    _inProgressTasks =
        _tasks.where((t) => t.status == TaskStatus.inProgress).toList();
    _inReviewTasks =
        _tasks.where((t) => t.status == TaskStatus.inReview).toList();
    _doneTasks =
        _tasks.where((t) => t.status == TaskStatus.completed).toList();
    _overdueTasks = _tasks.where((t) => t.isOverdue).toList();
    _urgentTasks = _tasks
        .where((t) => t.priority == TaskPriority.urgent && t.isActive)
        .toList();
    _todayTasks = _tasks.where((t) {
      final dueDate = t.dueDate;
      return dueDate != null &&
          dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day &&
          t.isActive;
    }).toList();
    _focusTasks = _tasks.where((task) {
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
    _focusTasks.sort((a, b) {
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return (a.dueDate ?? DateTime(9999))
          .compareTo(b.dueDate ?? DateTime(9999));
    });
  }

  void _notifyAndScheduleSave() {
    _updateComputedLists();
    notifyListeners();
    _saveDebouncer.call(() => StorageService.saveTasks(_tasks));
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
      _notifyAndScheduleSave();
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
        _notifyAndScheduleSave();
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
        _notifyAndScheduleSave();
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
      _notifyAndScheduleSave();
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
      _notifyAndScheduleSave();
    }
  }

  Future<void> replaceAll(List<Task> tasks) async {
    _tasks = tasks;
    _notifyAndScheduleSave();
  }

  Future<void> deleteTask(String taskId) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index == -1) return;
      final task = _tasks.removeAt(index);
      final trash = await StorageService.loadTrashTasks();
      trash.add(task);
      await StorageService.saveTrashTasks(trash);
      _notifyAndScheduleSave();
      await NotificationService.cancelTaskReminders(taskId);
      showSuccessNotification('Tarea movida a la papelera');
    } catch (e) {
      showErrorNotification('Error al eliminar tarea');
      rethrow;
    }
  }

  Future<void> restoreTask(String taskId) async {
    try {
      final trash = await StorageService.loadTrashTasks();
      final index = trash.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final task = trash.removeAt(index);
        _tasks.add(task);
        await StorageService.saveTrashTasks(trash);
        _notifyAndScheduleSave();
        showSuccessNotification('Tarea restaurada');
      }
    } catch (e) {
      showErrorNotification('Error al restaurar tarea');
      rethrow;
    }
  }

  Future<void> permanentDeleteTask(String taskId) async {
    try {
      final trash = await StorageService.loadTrashTasks();
      trash.removeWhere((t) => t.id == taskId);
      await StorageService.saveTrashTasks(trash);
      showSuccessNotification('Tarea eliminada permanentemente');
    } catch (e) {
      showErrorNotification('Error al eliminar tarea');
      rethrow;
    }
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }

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
