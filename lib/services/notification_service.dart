import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/recurrence_rule.dart';
import '../models/task.dart';

const _kChannelId = 'brain_task_reminders';
const _kChannelName = 'Recordatorios de tareas';
const _kChannelDesc =
    'Notificaciones cuando una tarea se acerca a su fecha límite';
const _kSummaryChannelId = 'brain_daily_summary';
const _kSummaryChannelName = 'Resumen diario';
const _kSummaryChannelDesc =
    'Resumen diario de tareas programado por el usuario';

int _notificationId(String key) => key.hashCode.abs() % 2147483647;

class _Settings {
  bool notificationsEnabled;
  bool remind24h;
  bool remind1h;
  int defaultReminderMinutes;
  bool quietHoursEnabled;
  int quietStartHour;
  int quietStartMinute;
  int quietEndHour;
  int quietEndMinute;
  String timezone;
  bool dailyNotificationEnabled;
  int dailyNotificationHour;
  int dailyNotificationMinute;

  _Settings({
    this.notificationsEnabled = true,
    this.remind24h = true,
    this.remind1h = true,
    this.defaultReminderMinutes = 30,
    this.quietHoursEnabled = false,
    this.quietStartHour = 22,
    this.quietStartMinute = 0,
    this.quietEndHour = 8,
    this.quietEndMinute = 0,
    this.timezone = 'America/Mexico_City',
    this.dailyNotificationEnabled = true,
    this.dailyNotificationHour = 7,
    this.dailyNotificationMinute = 0,
  });

  bool get isNowQuietHours {
    if (!quietHoursEnabled) return false;
    final now = TimeOfDay.now();
    final start = quietStartHour * 60 + quietStartMinute;
    final end = quietEndHour * 60 + quietEndMinute;
    final nowM = now.hour * 60 + now.minute;
    if (start <= end) return nowM >= start && nowM <= end;
    return nowM >= start || nowM <= end;
  }
}

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static _Settings _settings = _Settings();

  static void configure({
    bool? notificationsEnabled,
    bool? remind24h,
    bool? remind1h,
    int? defaultReminderMinutes,
    bool? quietHoursEnabled,
    int? quietStartHour,
    int? quietStartMinute,
    int? quietEndHour,
    int? quietEndMinute,
    String? timezone,
    bool? dailyNotificationEnabled,
    int? dailyNotificationHour,
    int? dailyNotificationMinute,
  }) {
    _settings = _Settings(
      notificationsEnabled: notificationsEnabled ?? _settings.notificationsEnabled,
      remind24h: remind24h ?? _settings.remind24h,
      remind1h: remind1h ?? _settings.remind1h,
      defaultReminderMinutes: defaultReminderMinutes ?? _settings.defaultReminderMinutes,
      quietHoursEnabled: quietHoursEnabled ?? _settings.quietHoursEnabled,
      quietStartHour: quietStartHour ?? _settings.quietStartHour,
      quietStartMinute: quietStartMinute ?? _settings.quietStartMinute,
      quietEndHour: quietEndHour ?? _settings.quietEndHour,
      quietEndMinute: quietEndMinute ?? _settings.quietEndMinute,
      timezone: timezone ?? _settings.timezone,
      dailyNotificationEnabled: dailyNotificationEnabled ?? _settings.dailyNotificationEnabled,
      dailyNotificationHour: dailyNotificationHour ?? _settings.dailyNotificationHour,
      dailyNotificationMinute: dailyNotificationMinute ?? _settings.dailyNotificationMinute,
    );
  }

  // ─── Inicialización ────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final localTz = tz.local.name;
      if (localTz.isNotEmpty) tz.setLocalLocation(tz.getLocation(localTz));
    } catch (_) {}

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // v21: initialize usa named parameter "settings"
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: _onTap,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _kChannelId,
          _kChannelName,
          description: _kChannelDesc,
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          _kSummaryChannelId,
          _kSummaryChannelName,
          description: _kSummaryChannelDesc,
          importance: Importance.defaultImportance,
          enableVibration: false,
          playSound: false,
        ),
      );
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  static void _onTap(NotificationResponse response) {
    debugPrint('Notificación tocada: ${response.payload}');
  }

  // ─── Detalles ──────────────────────────────────────────────────────────────

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _kChannelId,
      _kChannelName,
      channelDescription: _kChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static const NotificationDetails _summaryDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _kSummaryChannelId,
      _kSummaryChannelName,
      channelDescription: _kSummaryChannelDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      enableVibration: false,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    ),
  );

  // ─── API pública ───────────────────────────────────────────────────────────

  static Future<void> scheduleTaskReminders(Task task) async {
    if (!_initialized) return;
    if (!_settings.notificationsEnabled) return;
    await cancelTaskReminders(task.id);

    final dueDate = task.dueDate;
    if (dueDate == null || !task.isActive) return;

    final now = tz.TZDateTime.now(tz.local);
    final tzDue = tz.TZDateTime.from(dueDate, tz.local);
    if (tzDue.isBefore(now)) return;

    // 1️⃣ Recordatorio personalizado
    final remind = task.reminderMinutesBefore ?? _settings.defaultReminderMinutes;
    if (remind > 0) {
      final trigger = tzDue.subtract(Duration(minutes: remind));
      if (trigger.isAfter(now) && !_isQuietTime(trigger)) {
        await _schedule(
          id: _notificationId('${task.id}_custom'),
          title: '⏰ Recordatorio: ${task.title}',
          body: _timeUntil(dueDate),
          scheduledDate: trigger,
          payload: task.id,
        );
      }
    }

    // 2️⃣ 24 horas antes (solo si está habilitado)
    if (_settings.remind24h) {
      final minus24h = tzDue.subtract(const Duration(hours: 24));
      if (minus24h.isAfter(now) && !_isQuietTime(minus24h)) {
        await _schedule(
          id: _notificationId('${task.id}_24h'),
          title: '📅 Vence mañana: ${task.title}',
          body: 'La tarea vence el ${_formatDate(dueDate)}.',
          scheduledDate: minus24h,
          payload: task.id,
        );
      }
    }

    // 3️⃣ 1 hora antes (solo si está habilitado)
    if (_settings.remind1h) {
      final minus1h = tzDue.subtract(const Duration(hours: 1));
      if (minus1h.isAfter(now) && !_isQuietTime(minus1h)) {
        await _schedule(
          id: _notificationId('${task.id}_1h'),
          title: '🔔 ¡Vence en 1 hora!: ${task.title}',
          body: 'Tienes poco tiempo para completar esta tarea.',
          scheduledDate: minus1h,
          payload: task.id,
        );
      }
    }
  }

  static Future<void> cancelTaskReminders(String taskId) async {
    if (!_initialized) return;
    await Future.wait([
      _plugin.cancel(id: _notificationId('${taskId}_custom')),
      _plugin.cancel(id: _notificationId('${taskId}_24h')),
      _plugin.cancel(id: _notificationId('${taskId}_1h')),
    ]);
  }

  static Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  static Future<void> scheduleRecurringReminders(
    RecurrenceRule rule,
    String taskId,
    String title,
    DateTime dueDate,
  ) async {
    if (!_initialized) return;
    if (!_settings.notificationsEnabled) return;
    await cancelRecurringReminders(taskId);

    final now = tz.TZDateTime.now(tz.local);
    const maxOccurrences = 20;

    DateTime? current = rule.nextOccurrence(dueDate);
    int idx = 0;

    while (current != null && idx < maxOccurrences) {
      final tzCurrent = tz.TZDateTime.from(current, tz.local);
      if (tzCurrent.isAfter(now) && !_isQuietTime(tzCurrent)) {
        await _schedule(
          id: _notificationId('${taskId}_recur_$idx'),
          title: '🔄 $title',
          body: 'Vence el ${_formatDate(current)}.',
          scheduledDate: tzCurrent,
          payload: taskId,
        );
        idx++;
      }
      current = rule.nextOccurrence(current);
    }
  }

  static Future<void> cancelRecurringReminders(String taskId) async {
    if (!_initialized) return;
    await Future.wait(
      List.generate(20, (i) => _plugin.cancel(
        id: _notificationId('${taskId}_recur_$i'),
      )),
    );
  }

  static Future<void> scheduleDailySummary(int todayTaskCount) async {
    if (!_initialized) return;
    if (!_settings.notificationsEnabled || !_settings.dailyNotificationEnabled) {
      await cancelDailySummary();
      return;
    }

    await cancelDailySummary();

    try {
      final location = tz.getLocation(_settings.timezone);
      final now = tz.TZDateTime.now(location);
      var scheduledDate = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        _settings.dailyNotificationHour,
        _settings.dailyNotificationMinute,
      );
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      final body = todayTaskCount > 0
          ? 'Tienes $todayTaskCount tarea(s) para hoy'
          : 'No tienes tareas pendientes para hoy';

      await _plugin.zonedSchedule(
        id: _notificationId('daily_summary'),
        title: '☀️ Resumen diario',
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _summaryDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: 'daily_summary',
      );
    } catch (e) {
      debugPrint('Error programando resumen diario: $e');
    }
  }

  static Future<void> cancelDailySummary() async {
    if (!_initialized) return;
    await _plugin.cancel(id: _notificationId('daily_summary'));
  }

  static Future<void> rescheduleAll(List<Task> tasks) async {
    if (!_initialized) return;
    await _plugin.cancelAll();
    for (final task in tasks) {
      await scheduleTaskReminders(task);
    }
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: _details,
      payload: payload,
    );
  }

  // ─── Helpers privados ──────────────────────────────────────────────────────

  static Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    String? payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error programando notificación $id: $e');
    }
  }

  static String _formatDate(DateTime date) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre',
    ];
    return '${date.day} de ${months[date.month - 1]}'
        ' a las ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  static bool _isQuietTime(tz.TZDateTime date) {
    if (!_settings.quietHoursEnabled) return false;
    final minutes = date.hour * 60 + date.minute;
    final start = _settings.quietStartHour * 60 + _settings.quietStartMinute;
    final end = _settings.quietEndHour * 60 + _settings.quietEndMinute;
    if (start <= end) return minutes >= start && minutes <= end;
    return minutes >= start || minutes <= end;
  }

  static String _timeUntil(DateTime dueDate) {
    final diff = dueDate.difference(DateTime.now());
    if (diff.inDays > 0) return 'Vence en ${diff.inDays} día(s).';
    if (diff.inHours > 0) return 'Vence en ${diff.inHours} hora(s).';
    return 'Vence en ${diff.inMinutes} minuto(s).';
  }
}
