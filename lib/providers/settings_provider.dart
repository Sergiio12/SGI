import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';
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
  static const _kHapticFeedback = 'haptic_feedback';
  static const _kLanguageCode = 'language_code';
  static const _kAccentColor = 'accent_color';
  static const _kCalendarSyncEnabled = 'calendar_sync_enabled';
  static const _kDefaultCalendarReminderMinutes =
      'default_calendar_reminder_minutes';
  static const _kCloudSyncEnabled = 'cloud_sync_enabled';
  static const _kWidgetEnabled = 'widget_enabled';
  static const _kTimezone = 'timezone';
  static const _kDailyNotificationEnabled = 'daily_notification_enabled';
  static const _kDailyNotificationHour = 'daily_notification_hour';
  static const _kDailyNotificationMinute = 'daily_notification_minute';

  late SharedPreferences _prefs;
  bool _isLoaded = false;

  VoidCallback? onNotificationSettingsChanged;

  ThemeMode _themeMode = ThemeMode.dark;
  Color _accentColor = BrainTheme.accentPurple;
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
  bool _hapticFeedback = true;
  bool _widgetEnabled = true;
  String _languageCode = 'es';
  bool _calendarSyncEnabled = false;
  int _defaultCalendarReminderMinutes = 30;
  bool _cloudSyncEnabled = false;
  String _timezone = 'America/Mexico_City';
  bool _dailyNotificationEnabled = true;
  int _dailyNotificationHour = 7;
  int _dailyNotificationMinute = 0;

  bool get isLoaded => _isLoaded;
  bool get hapticFeedback => _hapticFeedback;
  bool get widgetEnabled => _widgetEnabled;
  Locale get locale => Locale(_languageCode);
  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;
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
  bool get calendarSyncEnabled => _calendarSyncEnabled;
  int get defaultCalendarReminderMinutes => _defaultCalendarReminderMinutes;
  bool get cloudSyncEnabled => _cloudSyncEnabled;
  String get timezone => _timezone;
  bool get dailyNotificationEnabled => _dailyNotificationEnabled;
  int get dailyNotificationHour => _dailyNotificationHour;
  int get dailyNotificationMinute => _dailyNotificationMinute;
  TimeOfDay get dailyNotificationTime =>
      TimeOfDay(hour: _dailyNotificationHour, minute: _dailyNotificationMinute);

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
    _hapticFeedback = _prefs.getBool(_kHapticFeedback) ?? true;
    _widgetEnabled = _prefs.getBool(_kWidgetEnabled) ?? true;
    _languageCode = _prefs.getString(_kLanguageCode) ?? 'es';
    _accentColor = Color(_prefs.getInt(_kAccentColor) ?? BrainTheme.accentPurple.toARGB32());
    _calendarSyncEnabled = _prefs.getBool(_kCalendarSyncEnabled) ?? false;
    _defaultCalendarReminderMinutes =
        _prefs.getInt(_kDefaultCalendarReminderMinutes) ?? 30;
    _cloudSyncEnabled = _prefs.getBool(_kCloudSyncEnabled) ?? false;
    _timezone = _prefs.getString(_kTimezone) ?? 'America/Mexico_City';
    _dailyNotificationEnabled = _prefs.getBool(_kDailyNotificationEnabled) ?? true;
    _dailyNotificationHour = _prefs.getInt(_kDailyNotificationHour) ?? 7;
    _dailyNotificationMinute = _prefs.getInt(_kDailyNotificationMinute) ?? 0;

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

  Future<void> setHapticFeedback(bool value) async {
    _hapticFeedback = value;
    notifyListeners();
    await _prefs.setBool(_kHapticFeedback, value);
  }

  Future<void> setWidgetEnabled(bool value) async {
    _widgetEnabled = value;
    notifyListeners();
    await _prefs.setBool(_kWidgetEnabled, value);
  }

  Future<void> setCalendarSyncEnabled(bool value) async {
    _calendarSyncEnabled = value;
    notifyListeners();
    await _prefs.setBool(_kCalendarSyncEnabled, value);
  }

  Future<void> setDefaultCalendarReminderMinutes(int minutes) async {
    _defaultCalendarReminderMinutes = minutes;
    notifyListeners();
    await _prefs.setInt(_kDefaultCalendarReminderMinutes, minutes);
  }

  Future<void> setLocale(Locale locale) async {
    _languageCode = locale.languageCode;
    notifyListeners();
    await _prefs.setString(_kLanguageCode, locale.languageCode);
  }

  Future<void> setCloudSyncEnabled(bool value) async {
    _cloudSyncEnabled = value;
    notifyListeners();
    await _prefs.setBool(_kCloudSyncEnabled, value);
  }

  Future<void> setTimezone(String value) async {
    _timezone = value;
    _syncNotificationService();
    notifyListeners();
    await _prefs.setString(_kTimezone, value);
  }

  Future<void> setDailyNotificationEnabled(bool value) async {
    _dailyNotificationEnabled = value;
    _syncNotificationService();
    notifyListeners();
    await _prefs.setBool(_kDailyNotificationEnabled, value);
  }

  Future<void> setDailyNotificationTime(TimeOfDay time) async {
    _dailyNotificationHour = time.hour;
    _dailyNotificationMinute = time.minute;
    _syncNotificationService();
    notifyListeners();
    await _prefs.setInt(_kDailyNotificationHour, time.hour);
    await _prefs.setInt(_kDailyNotificationMinute, time.minute);
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    BrainTheme.updateAccentColor(color);
    notifyListeners();
    await _prefs.setInt(_kAccentColor, color.toARGB32());
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
      timezone: _timezone,
      dailyNotificationEnabled: _dailyNotificationEnabled,
      dailyNotificationHour: _dailyNotificationHour,
      dailyNotificationMinute: _dailyNotificationMinute,
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
