import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/result.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/interfaces/storage_service_interface.dart';
import '../utils/debouncer.dart';
import '../utils/notification_service_v2.dart';

class TasksProvider extends ChangeNotifier {
  final IStorageService _storage;
  List<Task> _tasks = [];
  final _uuid = const Uuid();
  bool _isLoaded = false;
  final _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

  static const int pageSize = 50;
  int _page = 1;

  bool get hasMore => _page * pageSize < _tasks.length;
  int get page => _page;
  List<Task> get pagedTasks => _tasks.take(_page * pageSize).toList();

  void loadNextPage() {
    if (!hasMore) return;
    _page++;
    notifyListeners();
  }

  void resetPage() {
    _page = 1;
    notifyListeners();
  }

  TasksProvider({required IStorageService storage}) : _storage = storage;

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
    _tasks = await _storage.loadTasks();
    _page = 1;
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
    _doneTasks = _tasks.where((t) => t.status == TaskStatus.completed).toList();
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
    _saveDebouncer.call(() => _storage.saveTasks(_tasks));
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

  Result<Task> getTaskByIdResult(String id) {
    try {
      return Result.success(_tasks.firstWhere((t) => t.id == id));
    } catch (_) {
      return Result.failure(AppException(
        message: 'Tarea no encontrada: $id',
        code: 'TASK_NOT_FOUND',
      ));
    }
  }

  Future<Result<Task>> addTask({
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
    List<String> linkedNoteIds = const [],
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
        linkedNoteIds: linkedNoteIds,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _tasks.add(task);
      _notifyAndScheduleSave();
      await NotificationService.scheduleTaskReminders(task);
      showSuccessNotification('Tarea creada: ${task.title}');
      return Result.success(task);
    } catch (e, s) {
      final error = AppException(
        message: 'Error al crear tarea',
        code: 'ADD_TASK',
        stackTrace: s,
      );
      error.log();
      showErrorNotification(error.message);
      return Result.failure(error);
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
    } catch (e, s) {
      AppException(message: 'Error al actualizar tarea', code: 'UPDATE_TASK', stackTrace: s).log();
      showErrorNotification('Error al actualizar tarea');
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
    } catch (e, s) {
      AppException(message: 'Error al cambiar estado de tarea', code: 'TOGGLE_TASK', stackTrace: s).log();
      showErrorNotification('Error al cambiar estado de tarea');
    }
  }

  Future<void> moveTaskToStatus(String taskId, TaskStatus status) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index == -1) return;
      final task = _tasks[index];
      if (task.status == status) return;
      final updated = task.copyWith(
        status: status,
        lastActivityAt: DateTime.now(),
      );
      _tasks[index] = updated;
      _notifyAndScheduleSave();
      if (status == TaskStatus.completed || status == TaskStatus.cancelled) {
        await NotificationService.cancelTaskReminders(taskId);
      } else {
        await NotificationService.scheduleTaskReminders(updated);
      }
      final message = status == TaskStatus.completed
          ? 'Tarea completada'
          : status == TaskStatus.cancelled
              ? 'Tarea anulada'
              : 'Tarea actualizada';
      showSuccessNotification(message);
    } catch (e, s) {
      AppException(message: 'Error al mover tarea', code: 'MOVE_TASK', stackTrace: s).log();
      showErrorNotification('Error al mover tarea');
    }
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    try {
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
    } catch (e, s) {
      AppException(message: 'Error al cambiar subtarea', code: 'TOGGLE_SUBTASK', stackTrace: s).log();
    }
  }

  Future<void> addSubtask(String taskId, String subtaskTitle) async {
    try {
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
    } catch (e, s) {
      AppException(message: 'Error al añadir subtarea', code: 'ADD_SUBTASK', stackTrace: s).log();
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
      final trash = await _storage.loadTrashTasks();
      trash.add(task);
      await _storage.saveTrashTasks(trash);
      _notifyAndScheduleSave();
      await NotificationService.cancelTaskReminders(taskId);
      showSuccessNotification('Tarea movida a la papelera');
    } catch (e, s) {
      AppException(message: 'Error al eliminar tarea', code: 'DELETE_TASK', stackTrace: s).log();
      showErrorNotification('Error al eliminar tarea');
    }
  }

  Future<void> restoreTask(String taskId) async {
    try {
      final trash = await _storage.loadTrashTasks();
      final index = trash.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        final task = trash.removeAt(index);
        _tasks.add(task);
        await _storage.saveTrashTasks(trash);
        _notifyAndScheduleSave();
        showSuccessNotification('Tarea restaurada');
      }
    } catch (e, s) {
      AppException(message: 'Error al restaurar tarea', code: 'RESTORE_TASK', stackTrace: s).log();
      showErrorNotification('Error al restaurar tarea');
    }
  }

  Future<void> permanentDeleteTask(String taskId) async {
    try {
      final trash = await _storage.loadTrashTasks();
      trash.removeWhere((t) => t.id == taskId);
      await _storage.saveTrashTasks(trash);
      showSuccessNotification('Tarea eliminada permanentemente');
    } catch (e, s) {
      AppException(message: 'Error al eliminar tarea permanentemente', code: 'PERM_DELETE_TASK', stackTrace: s).log();
      showErrorNotification('Error al eliminar tarea');
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
