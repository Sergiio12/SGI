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
import '../services/storage_service.dart';
import '../utils/debouncer.dart';
import '../utils/haptic_helper.dart';
import '../utils/notification_service_v2.dart';

class TasksProvider extends ChangeNotifier {
  final IStorageService _storage;
  List<Task> _tasks = [];
  List<Task> _archivedTasks = [];
  final _uuid = const Uuid();
  bool _isLoaded = false;
  final _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

  String? _projectFilter;
  DateRangeFilter _dateRangeFilter = DateRangeFilter.all;

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
  List<Task> get archivedTasks => _archivedTasks;
  bool get isLoaded => _isLoaded;
  String? get projectFilter => _projectFilter;
  DateRangeFilter get dateRangeFilter => _dateRangeFilter;

  List<Task> get filteredTasks {
    var result = _tasks.where((t) => !t.isArchived);
    if (_projectFilter != null) {
      result = result.where((t) => t.projectId == _projectFilter);
    }
    final now = DateTime.now();
    switch (_dateRangeFilter) {
      case DateRangeFilter.all:
        break;
      case DateRangeFilter.today:
        result = result.where((t) =>
            t.dueDate != null &&
            t.dueDate!.year == now.year &&
            t.dueDate!.month == now.month &&
            t.dueDate!.day == now.day);
        break;
      case DateRangeFilter.thisWeek: {
        final weekEnd = now.add(const Duration(days: 7));
        result = result.where((t) =>
            t.dueDate != null &&
            !t.dueDate!.isBefore(DateTime(now.year, now.month, now.day)) &&
            t.dueDate!
                .isBefore(DateTime(weekEnd.year, weekEnd.month, weekEnd.day + 1)));
        break;
      }
      case DateRangeFilter.overdue:
        result = result.where((t) => t.isOverdue);
        break;
    }
    return result.toList();
  }

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
    await loadArchivedTasks();
    autoArchive();
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
    _saveDebouncer.call(() async {
      await _storage.saveTasks(_tasks);
      await _saveArchived();
    });
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
    List<String> linkedGoalIds = const [],
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
        linkedGoalIds: linkedGoalIds,
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
        } else {
          _syncCalendarForTask(updated);
          await NotificationService.scheduleTaskReminders(updated);
          HapticHelper.light();
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
      HapticHelper.light();
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

  Future<void> batchDelete(List<String> taskIds) async {
    final trash = await _storage.loadTrashTasks();
    for (final taskId in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index == -1) continue;
      final task = _tasks.removeAt(index);
      trash.add(task);
      if (task.calendarEventId != null) {
        unawaited(CalendarIntegrationService.removeTaskEvent(task.id, task.calendarEventId));
      }
      await NotificationService.cancelTaskReminders(taskId);
    }
    await _storage.saveTrashTasks(trash);
    _notifyAndScheduleSave();
    HapticHelper.medium();
  }

  Future<void> batchComplete(List<String> taskIds) async {
    for (final taskId in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index == -1) continue;
      final task = _tasks[index];
      _tasks[index] = task.copyWith(
        status: TaskStatus.completed,
        lastActivityAt: DateTime.now(),
      );
      await NotificationService.cancelTaskReminders(taskId);
      await _generateNextRecurrence(task);
    }
    _notifyAndScheduleSave();
    HapticHelper.light();
  }

  Future<void> batchMoveToStatus(List<String> taskIds, TaskStatus status) async {
    for (final taskId in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index == -1) continue;
      final task = _tasks[index];
      _tasks[index] = task.copyWith(
        status: status,
        lastActivityAt: DateTime.now(),
      );
      if (status == TaskStatus.completed || status == TaskStatus.cancelled) {
        await NotificationService.cancelTaskReminders(taskId);
      }
    }
    _notifyAndScheduleSave();
    HapticHelper.light();
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

  // ─── Filtros ────────────────────────────────────────────────────────────────

  void setProjectFilter(String? projectId) {
    _projectFilter = projectId;
    notifyListeners();
  }

  void setDateRangeFilter(DateRangeFilter filter) {
    _dateRangeFilter = filter;
    notifyListeners();
  }

  // ─── Archivado ──────────────────────────────────────────────────────────────

  Future<void> loadArchivedTasks() async {
    if (_storage is HiveStorageService) {
      _archivedTasks = await (_storage as HiveStorageService).loadArchivedTasks();
    }
  }

  Future<void> archiveTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final task = _tasks.removeAt(index);
    final archived = task.copyWith(isArchived: true, lastActivityAt: DateTime.now());
    _archivedTasks.add(archived);
    _notifyAndScheduleSave();
    await _saveArchived();
    HapticHelper.light();
  }

  Future<void> unarchiveTask(String taskId) async {
    final index = _archivedTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;
    final task = _archivedTasks.removeAt(index);
    _tasks.add(task.copyWith(isArchived: false, lastActivityAt: DateTime.now()));
    _notifyAndScheduleSave();
    await _saveArchived();
    HapticHelper.light();
  }

  Future<void> autoArchive() async {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final toArchive = <Task>[];
    for (final task in _tasks) {
      if (task.isArchived) continue;
      if ((task.status == TaskStatus.completed || task.status == TaskStatus.cancelled) &&
          task.updatedAt.isBefore(cutoff)) {
        toArchive.add(task);
      }
    }
    if (toArchive.isEmpty) return;
    for (final task in toArchive) {
      _tasks.removeWhere((t) => t.id == task.id);
      _archivedTasks.add(task.copyWith(isArchived: true));
    }
    _notifyAndScheduleSave();
    await _saveArchived();
  }

  Future<void> _saveArchived() async {
    if (_storage is HiveStorageService) {
      await (_storage as HiveStorageService).saveArchivedTasks(_archivedTasks);
    }
  }
}

enum DateRangeFilter { all, today, thisWeek, overdue }
