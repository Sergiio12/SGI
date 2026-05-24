import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';

import '../../config/theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../services/calendar_integration_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).notifications)),
      body: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingsSwitch(
                icon: Icons.notifications_active_rounded,
                title: AppLocalizations.of(context).notifications,
                subtitle: 'Activar o desactivar todas las notificaciones',
                value: settings.notificationsEnabled,
                onChanged: (v) => settings.setNotificationsEnabled(v),
              ),
              if (!settings.notificationsEnabled)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: BrainTheme.accentOrange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: BrainTheme.accentOrange.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: BrainTheme.accentOrange, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Las notificaciones están desactivadas. No recibirás recordatorios de tareas.',
                          style: TextStyle(
                            fontSize: 13,
                            color: BrainTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'RECORDATORIOS DE TAREAS'),
              const SizedBox(height: 8),
              Opacity(
                opacity: settings.notificationsEnabled ? 1.0 : 0.4,
                child: Column(
                  children: [
                    _SettingsSwitch(
                      icon: Icons.schedule,
                      title: '24 horas antes',
                      subtitle:
                          'Recibir notificación un día antes del vencimiento',
                      value: settings.remind24h,
                      onChanged: (v) => settings.setRemind24h(v),
                    ),
                    const SizedBox(height: 4),
                    _SettingsSwitch(
                      icon: Icons.timer_outlined,
                      title: '1 hora antes',
                      subtitle:
                          'Recibir notificación una hora antes del vencimiento',
                      value: settings.remind1h,
                      onChanged: (v) => settings.setRemind1h(v),
                    ),
                    const SizedBox(height: 4),
                    _ReminderMinutesPicker(
                      minutes: settings.defaultReminderMinutes,
                      onChanged: (v) => settings.setDefaultReminderMinutes(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'HORARIO SILENCIOSO'),
              const SizedBox(height: 8),
              Opacity(
                opacity: settings.notificationsEnabled ? 1.0 : 0.4,
                child: Column(
                  children: [
                    _SettingsSwitch(
                      icon: Icons.nightlight_round,
                      title: 'Horario silencioso',
                      subtitle:
                          'No recibir notificaciones durante este período',
                      value: settings.quietHoursEnabled,
                      onChanged: (v) => settings.setQuietHoursEnabled(v),
                    ),
                    if (settings.quietHoursEnabled) ...[
                      const SizedBox(height: 4),
                      _TimeRangePicker(
                        start: settings.quietStart,
                        end: settings.quietEnd,
                        onStartChanged: (t) => settings.setQuietStart(t),
                        onEndChanged: (t) => settings.setQuietEnd(t),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'PREFERENCIAS'),
              const SizedBox(height: 8),
              Opacity(
                opacity: settings.notificationsEnabled ? 1.0 : 0.4,
                child: Column(
                  children: [
                    _SettingsSwitch(
                      icon: Icons.check_circle_outline,
                      title: AppLocalizations.of(context).taskCompleted,
                      subtitle: 'Notificar al marcar una tarea como finalizada',
                      value: settings.notifyOnComplete,
                      onChanged: (v) => settings.setNotifyOnComplete(v),
                    ),
                    const SizedBox(height: 4),
                    _SettingsSwitch(
                      icon: Icons.warning_amber_outlined,
                      title: 'Tareas vencidas',
                      subtitle: 'Notificar cuando una tarea queda vencida',
                      value: settings.notifyOnOverdue,
                      onChanged: (v) => settings.setNotifyOnOverdue(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'RESUMEN DIARIO'),
              const SizedBox(height: 8),
              Opacity(
                opacity: settings.notificationsEnabled ? 1.0 : 0.4,
                child: Column(
                  children: [
                    _SettingsSwitch(
                      icon: Icons.wb_sunny_rounded,
                      title: 'Resumen diario',
                      subtitle: 'Notificación a las 7:00 AM con tareas de hoy',
                      value: settings.dailyNotificationEnabled,
                      onChanged: (v) =>
                          settings.setDailyNotificationEnabled(v),
                    ),
                    if (settings.dailyNotificationEnabled) ...[
                      const SizedBox(height: 4),
                      Material(
                        color: Colors.transparent,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Horario de la notificación',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: BrainTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _TimeButton(
                                      label: 'Hora',
                                      time: settings.dailyNotificationTime,
                                      onTap: () async {
                                        final picked = await showTimePicker(
                                          context: context,
                                          initialTime:
                                              settings.dailyNotificationTime,
                                        );
                                        if (picked != null) {
                                          settings.setDailyNotificationTime(
                                              picked);
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _TimezoneSelector(
                                      timezone: settings.timezone,
                                      onChanged: (v) =>
                                          settings.setTimezone(v),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionHeader(title: 'CALENDARIO'),
              const SizedBox(height: 8),
              Column(
                children: [
                  _SettingsSwitch(
                    icon: Icons.calendar_month_rounded,
                    title: 'Sincronizar tareas con calendario',
                    subtitle: 'Crear eventos en el calendario del dispositivo',
                    value: settings.calendarSyncEnabled,
                    onChanged: (v) => settings.setCalendarSyncEnabled(v),
                  ),
                  const SizedBox(height: 4),
                  _ReminderMinutesPicker(
                    minutes: settings.defaultCalendarReminderMinutes,
                    onChanged: (v) =>
                        settings.setDefaultCalendarReminderMinutes(v),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        final tasksProvider = Provider.of<TasksProvider>(
                          context,
                          listen: false,
                        );
                        CalendarIntegrationService.syncAllTasks(
                          tasksProvider.tasks,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Sincronización iniciada en segundo plano',
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: BrainTheme.accentBlue
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.sync_rounded,
                                size: 20,
                                color: BrainTheme.accentBlue,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Sincronizar todas las tareas ahora',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: BrainTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BrainTheme.accentBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: BrainTheme.accentBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: BrainTheme.accentBlue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Los cambios en las notificaciones se aplicarán a las nuevas tareas. '
                        'Para aplicar los cambios a tareas existentes, reinicia la aplicación.',
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              BrainTheme.textSecondary.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: BrainTheme.textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: value
                      ? BrainTheme.accentPurple.withValues(alpha: 0.12)
                      : BrainTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color:
                      value ? BrainTheme.accentPurple : BrainTheme.textTertiary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: BrainTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: BrainTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: BrainTheme.accentPurple,
                activeTrackColor:
                    BrainTheme.accentPurple.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderMinutesPicker extends StatelessWidget {
  final int minutes;
  final ValueChanged<int> onChanged;

  const _ReminderMinutesPicker({
    required this.minutes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (5, '5 minutos'),
      (10, '10 minutos'),
      (15, '15 minutos'),
      (30, '30 minutos'),
      (60, '1 hora'),
      (120, '2 horas'),
      (1440, '1 día'),
    ];

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BrainTheme.accentOrange.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.timer_outlined,
                    size: 20,
                    color: BrainTheme.accentOrange,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recordatorio por defecto',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: BrainTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Tiempo antes del vencimiento para nuevas tareas',
                        style: TextStyle(
                          fontSize: 12,
                          color: BrainTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: minutes,
                  isExpanded: true,
                  dropdownColor: BrainTheme.cardDark,
                  style: TextStyle(color: BrainTheme.textPrimary),
                  items: options.map((o) {
                    return DropdownMenuItem(value: o.$1, child: Text(o.$2));
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) onChanged(v);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeRangePicker extends StatelessWidget {
  final TimeOfDay start;
  final TimeOfDay end;
  final ValueChanged<TimeOfDay> onStartChanged;
  final ValueChanged<TimeOfDay> onEndChanged;

  const _TimeRangePicker({
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Silenciar notificaciones entre',
              style: TextStyle(
                fontSize: 13,
                color: BrainTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: 'Inicio',
                    time: start,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: start,
                      );
                      if (picked != null) onStartChanged(picked);
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: BrainTheme.textTertiary,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: _TimeButton(
                    label: 'Fin',
                    time: end,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: end,
                      );
                      if (picked != null) onEndChanged(picked);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimezoneSelector extends StatelessWidget {
  final String timezone;
  final ValueChanged<String> onChanged;

  static const _timezones = [
    'America/Mexico_City',
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Argentina/Buenos_Aires',
    'America/Bogota',
    'America/Santiago',
    'America/Lima',
    'America/Caracas',
    'Europe/Madrid',
    'Europe/London',
    'Europe/Paris',
    'Europe/Berlin',
    'Europe/Rome',
    'Atlantic/Canary',
  ];

  const _TimezoneSelector({
    required this.timezone,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPicker(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: BrainTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              'Zona horaria',
              style: TextStyle(
                fontSize: 11,
                color: BrainTheme.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              timezone.split('/').last.replaceAll('_', ' '),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: BrainTheme.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Seleccionar zona horaria',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BrainTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: BrainTheme.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(),
              SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: _timezones.length,
                  itemBuilder: (context, index) {
                    final tz = _timezones[index];
                    final selected = tz == timezone;
                    return ListTile(
                      title: Text(
                        tz.split('/').last.replaceAll('_', ' '),
                        style: TextStyle(
                          color: selected
                              ? BrainTheme.accentPurple
                              : BrainTheme.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      subtitle: Text(
                        tz,
                        style: TextStyle(
                          fontSize: 11,
                          color: BrainTheme.textTertiary,
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check,
                              color: BrainTheme.accentPurple, size: 18)
                          : null,
                      onTap: () {
                        onChanged(tz);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: BrainTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: BrainTheme.textTertiary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$hour:$minute',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: BrainTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
