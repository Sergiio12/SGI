import 'package:device_calendar_plus/device_calendar_plus.dart';

import '../models/task.dart';

class CalendarIntegrationService {
  static const _calendarName = 'SGI';
  static String? _calendarId;

  static DeviceCalendar get _instance => DeviceCalendar.instance;

  static Future<String?> ensureCalendarExists() async {
    try {
      final plugin = _instance;

      final permissionStatus = await plugin.hasPermissions();
      if (permissionStatus != CalendarPermissionStatus.granted) {
        final result = await plugin.requestPermissions();
        if (result != CalendarPermissionStatus.granted) {
          return null;
        }
      }

      final calendars = await plugin.listCalendars();

      Calendar? existing;
      for (final c in calendars) {
        if (c.name == _calendarName && c.id != null) {
          existing = c;
          break;
        }
      }

      if (existing != null) {
        _calendarId = existing.id;
        return _calendarId;
      }

      final calendarId = await plugin.createCalendar(name: _calendarName);
      _calendarId = calendarId;
      return _calendarId;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> addTaskEvent({
    required String taskId,
    required String title,
    required String description,
    required DateTime dueDate,
    int? reminderMinutes,
  }) async {
    try {
      final calendarId = _calendarId ?? await ensureCalendarExists();
      if (calendarId == null) return null;

      final start = dueDate;
      final end = dueDate.add(const Duration(hours: 1));

      final eventId = await _instance.createEvent(
        calendarId: calendarId,
        title: title,
        description: description,
        startDate: start,
        endDate: end,
      );

      return eventId;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> updateTaskEvent(
    String taskId, {
    String? calendarEventId,
    String? title,
    String? description,
    DateTime? dueDate,
    int? reminderMinutes,
  }) async {
    try {
      if (calendarEventId == null) return false;

      await _instance.updateEvent(
        eventId: calendarEventId,
        title: title,
        description: description,
        startDate: dueDate,
        endDate: dueDate?.add(const Duration(hours: 1)),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> removeTaskEvent(
      String taskId, String? calendarEventId) async {
    try {
      if (calendarEventId == null) return false;

      await _instance.deleteEvent(eventId: calendarEventId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> syncAllTasks(List<Task> tasks) async {
    final calendarId = await ensureCalendarExists();
    if (calendarId == null) return;

    for (final task in tasks) {
      if (task.dueDate != null && task.isActive) {
        if (task.calendarEventId != null) {
          await updateTaskEvent(
            task.id,
            calendarEventId: task.calendarEventId,
            title: task.title,
            description: task.description,
            dueDate: task.dueDate,
            reminderMinutes: task.reminderMinutesBefore,
          );
        } else {
          await addTaskEvent(
            taskId: task.id,
            title: task.title,
            description: task.description,
            dueDate: task.dueDate!,
            reminderMinutes: task.reminderMinutesBefore,
          );
        }
      } else if (task.calendarEventId != null) {
        await removeTaskEvent(task.id, task.calendarEventId);
      }
    }
  }
}
