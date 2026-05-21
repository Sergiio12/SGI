import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/result.dart';
import '../models/recurrence_rule.dart';
import '../models/task.dart';
import '../services/calendar_integration_service.dart';
import '../services/home_widget_service.dart';
import '../services/notification_service.dart';
import '../services/interfaces/storage_service_interface.dart';
import '../utils/debouncer.dart';
import '../utils/haptic_helper.dart';
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

  List<Task>? __todoTasks;
  List<Task>? __inProgressTasks;
  List<Task>? __inReviewTasks;
  List<Task>? __doneTasks;
  List<Task>? __overdueTasks;
  List<Task>? __urgentTasks;
  List<Task>? __todayTasks;
  List<Task>? __focusTasks;
  List<Task>? __cancelledTasks;

  List<Task> get tasks => _tasks;
  bool get isLoaded => _isLoaded;

  List<Task> get todoTasks =>
      __todoTasks ??= _tasks.where((t) => t.status == TaskStatus.pending).toList();
  List<Task> get inProgressTasks =>
      __inProgressTasks ??= _tasks.where((t) => t.status == TaskStatus.inProgress).toList();
  List<Task> get inReviewTasks =>
      __inReviewTasks ??= _tasks.where((t) => t.status == TaskStatus.inReview).toList();
  List<Task> get doneTasks =>
      __doneTasks ??= _tasks.where((t) => t.status == TaskStatus.completed).toList();
  List<Task> get overdueTasks =>
      __overdueTasks ??= _tasks.where((t) => t.isOverdue).toList();
  List<Task> get urgentTasks =>
      __urgentTasks ??= _tasks.where((t) => t.priority == TaskPriority.urgent && t.isActive).toList();
  List<Task> get todayTasks {
    if (__todayTasks != null) return __todayTasks!;
    final now = DateTime.now();
    __todayTasks = _tasks.where((t) {
      final dueDate = t.dueDate;
      return dueDate != null &&
          dueDate.year == now.year &&
          dueDate.month == now.month &&
          dueDate.day == now.day &&
          t.isActive;
    }).toList();
    return __todayTasks!;
  }

  List<Task> get focusTasks {
    if (__focusTasks != null) return __focusTasks!;
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    __focusTasks = _tasks.where((task) {
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
    __focusTasks!.sort((a, b) {
      final priorityCompare = b.priority.index.compareTo(a.priority.index);
      if (priorityCompare != 0) return priorityCompare;
      return (a.dueDate ?? DateTime(9999))
          .compareTo(b.dueDate ?? DateTime(9999));
    });
    return __focusTasks!;
  }

  List<Task> get cancelledTasks =>
      __cancelledTasks ??= _tasks.where((t) => t.status == TaskStatus.cancelled).toList();

  Future<void> loadTasks() async {
    _tasks = await _storage.loadTasks();
    _page = 1;
    _markDirty();
    _isLoaded = true;
    notifyListeners();
    _updateWidget();
  }

  void _markDirty() {
    __todoTasks = null;
    __inProgressTasks = null;
    __inReviewTasks = null;
    __doneTasks = null;
    __overdueTasks = null;
    __urgentTasks = null;
    __todayTasks = null;
    __focusTasks = null;
    __cancelledTasks = null;
  }

  void _notifyAndScheduleSave() {
    _markDirty();
    notifyListeners();
    _saveDebouncer.call(() => _storage.saveTasks(_tasks));
  }

  void _syncCalendarForTask(Task task) {
    if (task.dueDate == null || !task.isActive) {
      if (task.calendarEventId != null) {
        unawaited(
          CalendarIntegrationService.removeTaskEvent(
            task.id,
            task.calendarEventId,
          ).then((_) {
            final idx = _tasks.indexWhere((t) => t.id == task.id);
            if (idx != -1) {
              _tasks[idx] =
                  _tasks[idx].copyWith(clearCalendarEventId: true);
              _notifyAndScheduleSave();
            }
          }),
        );
      }
      return;
    }
    if (task.calendarEventId != null) {
      unawaited(
        CalendarIntegrationService.updateTaskEvent(
          task.id,
          calendarEventId: task.calendarEventId,
          title: task.title,
          description: task.description,
          dueDate: task.dueDate,
          reminderMinutes: task.reminderMinutesBefore,
        ),
      );
    } else {
      unawaited(
        CalendarIntegrationService.addTaskEvent(
          taskId: task.id,
          title: task.title,
          description: task.description,
          dueDate: task.dueDate!,
          reminderMinutes: task.reminderMinutesBefore,
        ).then((eventId) {
          if (eventId != null) {
            final idx = _tasks.indexWhere((t) => t.id == task.id);
            if (idx != -1) {
              _tasks[idx] =
                  _tasks[idx].copyWith(calendarEventId: eventId);
              _notifyAndScheduleSave();
            }
          }
        }),
      );
    }
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
    RecurrenceRule? recurrence,
    String? sourceTaskId,
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
        recurrence: recurrence,
        sourceTaskId: sourceTaskId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _tasks.add(task);
      _notifyAndScheduleSave();
      _syncCalendarForTask(task);
      await NotificationService.scheduleTaskReminders(task);
      if (task.recurrence != null && task.dueDate != null) {
        await NotificationService.scheduleRecurringReminders(
          task.recurrence!,
          task.id,
          task.title,
          task.dueDate!,
        );
      }
      HapticHelper.light();
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
        _syncCalendarForTask(task);
        await NotificationService.scheduleTaskReminders(task);
        showSuccessNotification('Tarea actualizada');
      }
    } catch (e, s) {
      AppException(
              message: 'Error al actualizar tarea',
              code: 'UPDATE_TASK',
              stackTrace: s)
          .log();
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
          _syncCalendarForTask(updated);
          await NotificationService.cancelTaskReminders(taskId);
          await _generateNextRecurrence(task);
          HapticHelper.light();
          showSuccessNotification('Tarea completada');
        } else {
          _syncCalendarForTask(updated);
          await NotificationService.scheduleTaskReminders(updated);
          HapticHelper.light();
          showSuccessNotification('Tarea reabierta');
        }
      }
    } catch (e, s) {
      AppException(
              message: 'Error al cambiar estado de tarea',
              code: 'TOGGLE_TASK',
              stackTrace: s)
          .log();
      showErrorNotification('Error al cambiar estado de tarea');
    }
  }

  Future<void> moveTaskToStatus(String taskId, TaskStatus status) async {
    try {
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index == -1) return;
      final task = _tasks[index];
      if (task.status == status) return;
      final isBeingCompleted = status == TaskStatus.completed && task.status != TaskStatus.completed;
      final updated = task.copyWith(
        status: status,
        lastActivityAt: DateTime.now(),
      );
      _tasks[index] = updated;
      _notifyAndScheduleSave();
      _syncCalendarForTask(updated);
      if (status == TaskStatus.completed || status == TaskStatus.cancelled) {
        await NotificationService.cancelTaskReminders(taskId);
        if (isBeingCompleted) {
          await _generateNextRecurrence(task);
        }
      } else {
        await NotificationService.scheduleTaskReminders(updated);
      }
      final message = status == TaskStatus.completed
          ? 'Tarea completada'
          : status == TaskStatus.cancelled
              ? 'Tarea anulada'
              : 'Tarea actualizada';
      HapticHelper.light();
      showSuccessNotification(message);
    } catch (e, s) {
      AppException(
              message: 'Error al mover tarea', code: 'MOVE_TASK', stackTrace: s)
          .log();
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
      AppException(
              message: 'Error al cambiar subtarea',
              code: 'TOGGLE_SUBTASK',
              stackTrace: s)
          .log();
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
      AppException(
              message: 'Error al añadir subtarea',
              code: 'ADD_SUBTASK',
              stackTrace: s)
          .log();
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
      final task = _tasks[index];
      if (task.calendarEventId != null) {
        unawaited(
          CalendarIntegrationService.removeTaskEvent(
            task.id,
            task.calendarEventId,
          ),
        );
      }
      _tasks.removeAt(index);
      final trash = await _storage.loadTrashTasks();
      trash.add(task);
      await _storage.saveTrashTasks(trash);
      _notifyAndScheduleSave();
      await NotificationService.cancelTaskReminders(taskId);
      HapticHelper.medium();
      showSuccessNotification(
        'Tarea movida a la papelera',
        title: 'Tarea eliminada',
        actionLabel: 'Deshacer',
        onAction: () async => restoreTask(task.id),
      );
    } catch (e, s) {
      AppException(
              message: 'Error al eliminar tarea',
              code: 'DELETE_TASK',
              stackTrace: s)
          .log();
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
        HapticHelper.light();
        showSuccessNotification('Tarea restaurada');
      }
    } catch (e, s) {
      AppException(
              message: 'Error al restaurar tarea',
              code: 'RESTORE_TASK',
              stackTrace: s)
          .log();
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
      AppException(
              message: 'Error al eliminar tarea permanentemente',
              code: 'PERM_DELETE_TASK',
              stackTrace: s)
          .log();
      showErrorNotification('Error al eliminar tarea');
    }
  }

  void _updateWidget() {
    final done = doneTasks;
    final overdue = overdueTasks;
    HomeWidgetService.updateTodayWidget(
      totalTasks: _tasks.length,
      completedTasks: done.length,
      overdueTasks: overdue.length,
    );
  }

  Future<void> _generateNextRecurrence(Task completedTask) async {
    final rule = completedTask.recurrence;
    if (rule == null) return;
    if (completedTask.dueDate == null) return;

    final nextDue = rule.nextOccurrence(completedTask.dueDate!);
    if (nextDue == null) return;

    final nextTask = Task(
      id: _uuid.v4(),
      title: completedTask.title,
      description: completedTask.description,
      priority: completedTask.priority,
      status: TaskStatus.pending,
      dueDate: nextDue,
      estimatedHours: completedTask.estimatedHours,
      reminderMinutesBefore: completedTask.reminderMinutesBefore,
      projectId: completedTask.projectId,
      subtasks: completedTask.subtasks,
      linkedNoteIds: completedTask.linkedNoteIds,
      tags: completedTask.tags,
      recurrence: rule,
      sourceTaskId: completedTask.sourceTaskId ?? completedTask.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks.add(nextTask);
    _notifyAndScheduleSave();
    _syncCalendarForTask(nextTask);
    await NotificationService.scheduleTaskReminders(nextTask);
    if (nextTask.recurrence != null && nextTask.dueDate != null) {
      await NotificationService.scheduleRecurringReminders(
        nextTask.recurrence!,
        nextTask.id,
        nextTask.title,
        nextTask.dueDate!,
      );
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
    return doneTasks.length / _tasks.length;
  }
}
