import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';

class SettingsProvider extends ChangeNotifier {
  static const _kThemeMode = 'theme_mode';
  static const _kNotificationsEnabled = 'notifications_enabled';
  static const _kRemind24h = 'remind_24h';
  static const _kRemind1h = 'remind_1h';
  static const _kDefaultReminderMinutes = 'default_reminder_minutes';
  static const _kQuietHoursEnabled = 'quiet_hours_enabled';
  static const _kQuietStartHour = 'quiet_start_hour';
  static const _kQuietStartMinute = 'quiet_start_minute';
  static const _kQuietEndHour = 'quiet_end_hour';
  static const _kQuietEndMinute = 'quiet_end_minute';
  static const _kNotifyOnComplete = 'notify_on_complete';
  static const _kNotifyOnOverdue = 'notify_on_overdue';

  late SharedPreferences _prefs;
  bool _isLoaded = false;

  VoidCallback? onNotificationSettingsChanged;

  ThemeMode _themeMode = ThemeMode.dark;
  bool _notificationsEnabled = true;
  bool _remind24h = true;
  bool _remind1h = true;
  int _defaultReminderMinutes = 30;
  bool _quietHoursEnabled = false;
  int _quietStartHour = 22;
  int _quietStartMinute = 0;
  int _quietEndHour = 8;
  int _quietEndMinute = 0;
  bool _notifyOnComplete = true;
  bool _notifyOnOverdue = true;

  bool get isLoaded => _isLoaded;
  ThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get remind24h => _remind24h;
  bool get remind1h => _remind1h;
  int get defaultReminderMinutes => _defaultReminderMinutes;
  bool get quietHoursEnabled => _quietHoursEnabled;
  int get quietStartHour => _quietStartHour;
  int get quietStartMinute => _quietStartMinute;
  int get quietEndHour => _quietEndHour;
  int get quietEndMinute => _quietEndMinute;
  bool get notifyOnComplete => _notifyOnComplete;
  bool get notifyOnOverdue => _notifyOnOverdue;

  TimeOfDay get quietStart => TimeOfDay(hour: _quietStartHour, minute: _quietStartMinute);
  TimeOfDay get quietEnd => TimeOfDay(hour: _quietEndHour, minute: _quietEndMinute);

  bool get isNowQuietHours {
    if (!_quietHoursEnabled) return false;
    final now = TimeOfDay.now();
    final startMinutes = _quietStartHour * 60 + _quietStartMinute;
    final endMinutes = _quietEndHour * 60 + _quietEndMinute;
    final nowMinutes = now.hour * 60 + now.minute;

    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    }
    return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();

    _themeMode = _themeModeFromString(_prefs.getString(_kThemeMode) ?? 'dark');
    _notificationsEnabled = _prefs.getBool(_kNotificationsEnabled) ?? true;
    _remind24h = _prefs.getBool(_kRemind24h) ?? true;
    _remind1h = _prefs.getBool(_kRemind1h) ?? true;
    _defaultReminderMinutes = _prefs.getInt(_kDefaultReminderMinutes) ?? 30;
    _quietHoursEnabled = _prefs.getBool(_kQuietHoursEnabled) ?? false;
    _quietStartHour = _prefs.getInt(_kQuietStartHour) ?? 22;
    _quietStartMinute = _prefs.getInt(_kQuietStartMinute) ?? 0;
    _quietEndHour = _prefs.getInt(_kQuietEndHour) ?? 8;
    _quietEndMinute = _prefs.getInt(_kQuietEndMinute) ?? 0;
    _notifyOnComplete = _prefs.getBool(_kNotifyOnComplete) ?? true;
    _notifyOnOverdue = _prefs.getBool(_kNotifyOnOverdue) ?? true;

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _prefs.setString(_kThemeMode, _themeModeToString(mode));
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    _syncNotificationService();
    notifyListeners();
    await _prefs.setBool(_kNotificationsEnabled, value);
  }

  Future<void> setRemind24h(bool value) async {
    _remind24h = value;
    _syncNotificationService();
    notifyListeners();
    await _prefs.setBool(_kRemind24h, value);
  }

  Future<void> setRemind1h(bool value) async {
    _remind1h = value;
    _syncNotificationService();
    notifyListeners();
    await _prefs.setBool(_kRemind1h, value);
  }

  Future<void> setDefaultReminderMinutes(int minutes) async {
    _defaultReminderMinutes = minutes;
    _syncNotificationService();
    notifyListeners();
    await _prefs.setInt(_kDefaultReminderMinutes, minutes);
  }

  Future<void> setQuietHoursEnabled(bool value) async {
    _quietHoursEnabled = value;
    _syncNotificationService();
    notifyListeners();
    await _prefs.setBool(_kQuietHoursEnabled, value);
  }

  Future<void> setQuietStart(TimeOfDay time) async {
    _quietStartHour = time.hour;
    _quietStartMinute = time.minute;
    _syncNotificationService();
    notifyListeners();
    await _prefs.setInt(_kQuietStartHour, time.hour);
    await _prefs.setInt(_kQuietStartMinute, time.minute);
  }

  Future<void> setQuietEnd(TimeOfDay time) async {
    _quietEndHour = time.hour;
    _quietEndMinute = time.minute;
    _syncNotificationService();
    notifyListeners();
    await _prefs.setInt(_kQuietEndHour, time.hour);
    await _prefs.setInt(_kQuietEndMinute, time.minute);
  }

  Future<void> setNotifyOnComplete(bool value) async {
    _notifyOnComplete = value;
    notifyListeners();
    await _prefs.setBool(_kNotifyOnComplete, value);
  }

  Future<void> setNotifyOnOverdue(bool value) async {
    _notifyOnOverdue = value;
    notifyListeners();
    await _prefs.setBool(_kNotifyOnOverdue, value);
  }

  void _syncNotificationService() {
    NotificationService.configure(
      notificationsEnabled: _notificationsEnabled,
      remind24h: _remind24h,
      remind1h: _remind1h,
      defaultReminderMinutes: _defaultReminderMinutes,
      quietHoursEnabled: _quietHoursEnabled,
      quietStartHour: _quietStartHour,
      quietStartMinute: _quietStartMinute,
      quietEndHour: _quietEndHour,
      quietEndMinute: _quietEndMinute,
    );
    onNotificationSettingsChanged?.call();
  }

  static ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
