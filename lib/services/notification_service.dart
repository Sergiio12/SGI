import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';

const _kChannelId = 'brain_task_reminders';
const _kChannelName = 'Recordatorios de tareas';
const _kChannelDesc =
    'Notificaciones cuando una tarea se acerca a su fecha límite';

int _notificationId(String key) => key.hashCode.abs() % 2147483647;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

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

  // ─── API pública ───────────────────────────────────────────────────────────

  static Future<void> scheduleTaskReminders(Task task) async {
    if (!_initialized) return;
    await cancelTaskReminders(task.id);

    final dueDate = task.dueDate;
    if (dueDate == null || !task.isActive) return;

    final now = tz.TZDateTime.now(tz.local);
    final tzDue = tz.TZDateTime.from(dueDate, tz.local);
    if (tzDue.isBefore(now)) return;

    // 1️⃣ Recordatorio personalizado
    final remind = task.reminderMinutesBefore;
    if (remind != null && remind > 0) {
      final trigger = tzDue.subtract(Duration(minutes: remind));
      if (trigger.isAfter(now)) {
        await _schedule(
          id: _notificationId('${task.id}_custom'),
          title: '⏰ Recordatorio: ${task.title}',
          body: _timeUntil(dueDate),
          scheduledDate: trigger,
          payload: task.id,
        );
      }
    }

    // 2️⃣ 24 horas antes
    final minus24h = tzDue.subtract(const Duration(hours: 24));
    if (minus24h.isAfter(now)) {
      await _schedule(
        id: _notificationId('${task.id}_24h'),
        title: '📅 Vence mañana: ${task.title}',
        body: 'La tarea vence el ${_formatDate(dueDate)}.',
        scheduledDate: minus24h,
        payload: task.id,
      );
    }

    // 3️⃣ 1 hora antes
    final minus1h = tzDue.subtract(const Duration(hours: 1));
    if (minus1h.isAfter(now)) {
      await _schedule(
        id: _notificationId('${task.id}_1h'),
        title: '🔔 ¡Vence en 1 hora!: ${task.title}',
        body: 'Tienes poco tiempo para completar esta tarea.',
        scheduledDate: minus1h,
        payload: task.id,
      );
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

  static String _timeUntil(DateTime dueDate) {
    final diff = dueDate.difference(DateTime.now());
    if (diff.inDays > 0) return 'Vence en ${diff.inDays} día(s).';
    if (diff.inHours > 0) return 'Vence en ${diff.inHours} hora(s).';
    return 'Vence en ${diff.inMinutes} minuto(s).';
  }
}
