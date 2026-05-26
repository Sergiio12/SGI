import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';
import '../../config/theme.dart';
import '../../providers/settings_provider.dart';
import '../../providers/sync_provider.dart';
import '../../utils/notification_service_v2.dart';
import 'appearance_screen.dart';
import 'debug_screen.dart';
import 'notifications_screen.dart';
import 'widgets_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final sync = context.watch<SyncProvider>();

    final sections = _buildSections(context, settings, sync);
    final filtered = _searchQuery.isEmpty
        ? sections
        : sections
            .map((section) => _SettingSection(
                  title: section.title,
                  icon: section.icon,
                  items: section.items.where((item) =>
                      item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                      item.subtitle.toLowerCase().contains(_searchQuery.toLowerCase())).toList(),
                ))
            .where((s) => s.items.isNotEmpty)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            ),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.settingsSearch,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        )
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                if (_searchQuery.isNotEmpty && filtered.isEmpty)
                  _buildNoResults()
                else
                  ...filtered.expand((section) => [
                    _buildSectionHeader(section.icon, section.title),
                    ...section.items.map((item) => _buildSettingItem(
                      icon: item.icon,
                      title: item.title,
                      subtitle: item.subtitle,
                      trailing: item.trailing,
                      onTap: item.onTap,
                    )),
                  ]),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildNoResults() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: BrainTheme.textTertiary),
          const SizedBox(height: 16),
          Text(
            l10n.settingsNoResults,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: BrainTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.settingsNoResultsFor(_searchQuery),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: BrainTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  List<_SettingSection> _buildSections(
    BuildContext context,
    SettingsProvider settings,
    SyncProvider sync,
  ) {
    final l10n = AppLocalizations.of(context);
    return [
      _SettingSection(
        title: l10n.settingsAppearance,
        icon: Icons.palette_outlined,
        items: [
          _SettingItem(
            icon: Icons.palette_outlined,
            title: 'Apariencia',
            subtitle: 'Tema, color de acento y personalización visual',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearanceScreen())),
          ),
          _SettingItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notificaciones',
            subtitle: 'Recordatorios, horario silencioso y preferencias',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          _SettingItem(
            icon: Icons.widgets_rounded,
            title: 'Widgets',
            subtitle: 'Widget de tareas en la pantalla de inicio',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WidgetsScreen())),
          ),
        ],
      ),
      _SettingSection(
        title: l10n.settingsData,
        icon: Icons.cloud_outlined,
        items: [
          _SettingItem(
            icon: Icons.cloud_done_outlined,
            title: 'Gestión de datos',
            subtitle: 'Exportar, importar y gestionar datos',
            onTap: () => Navigator.pushNamed(context, '/data'),
          ),
          _SettingItem(
            icon: Icons.sync_rounded,
            title: 'Sincronización en la nube',
            subtitle: _syncStatusText(sync),
            trailing: Switch(
              value: settings.cloudSyncEnabled,
              activeTrackColor: BrainTheme.currentAccent.withValues(alpha: 0.5),
              activeThumbColor: BrainTheme.currentAccent,
              onChanged: (v) => settings.setCloudSyncEnabled(v),
            ),
            // TODO: Implementar sincronización real
            onTap: settings.cloudSyncEnabled ? () => sync.triggerSync() : null,
          ),
        ],
      ),
      _SettingSection(
        title: l10n.settingsSystem,
        icon: Icons.settings_outlined,
        items: [
          _SettingItem(
            icon: Icons.settings_backup_restore_rounded,
            title: 'Restablecer ajustes',
            subtitle: 'Vuelve a la configuración de fábrica',
            onTap: () => _confirmReset(context),
          ),
          _SettingItem(
            icon: Icons.bug_report_outlined,
            title: 'Debug',
            subtitle: 'Pruebas y diagnóstico',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DebugScreen())),
          ),
          _SettingItem(
            icon: Icons.info_outline_rounded,
            title: 'Acerca de',
            subtitle: 'Información de la aplicación',
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    ];
  }

  String _syncStatusText(SyncProvider sync) {
    switch (sync.status) {
      case SyncStatus.synced:
        final last = sync.lastSync;
        if (last == null) return 'Conectado';
        final diff = DateTime.now().difference(last);
        if (diff.inSeconds < 60) return 'Sincronizado ahora';
        if (diff.inMinutes < 60) return 'Sincronizado hace ${diff.inMinutes} min';
        return 'Sincronizado hace ${diff.inHours} h';
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.error:
        return 'Error de sincronización';
      case SyncStatus.disconnected:
        return 'Desconectado';
    }
  }

  void _confirmReset(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: BrainTheme.accentOrange, size: 22),
            const SizedBox(width: 8),
            Text('Restablecer ajustes', style: TextStyle(color: BrainTheme.textPrimary)),
          ],
        ),
        content: Text(
          'Se borrarán todas las preferencias guardadas (tema, colores, '
          'notificaciones, etc.). Los datos no se verán afectados.',
          style: TextStyle(color: BrainTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar', style: TextStyle(color: BrainTheme.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: BrainTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final s = context.read<SettingsProvider>();
      await s.setThemeMode(ThemeMode.dark);
      await s.setAccentColor(BrainTheme.accentOf(context));
      await s.setHapticFeedback(true);
      await s.setNotificationsEnabled(true);
      await s.setRemind24h(true);
      await s.setRemind1h(true);
      await s.setDefaultReminderMinutes(30);
      await s.setQuietHoursEnabled(false);
      await s.setQuietStart(const TimeOfDay(hour: 22, minute: 0));
      await s.setQuietEnd(const TimeOfDay(hour: 8, minute: 0));
      await s.setNotifyOnComplete(true);
      await s.setNotifyOnOverdue(true);
      await s.setWidgetEnabled(true);
      await s.setCalendarSyncEnabled(false);
      await s.setDefaultCalendarReminderMinutes(30);
      await s.setCloudSyncEnabled(false);
      await s.setCompactMode(false);
      await s.setReduceMotion(false);
      await s.setDefaultTaskView('board');
      await s.setDefaultNoteView('grid');
      await s.setDailyNotificationEnabled(true);
      await s.setDailyNotificationTime(const TimeOfDay(hour: 7, minute: 0));
      if (context.mounted) {
        showSuccessNotification('Ajustes restablecidos');
      }
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppLocalizations.of(context).appTitle,
      applicationVersion: '1.0.1+2',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset('assets/app_icon.png', width: 48, height: 48),
      ),
      applicationLegalese: '© 2026 Sergio Asensio',
      children: [
        const SizedBox(height: 16),
        Text(
          'Tu segundo cerebro digital para organizar tareas, '
          'proyectos, objetivos y notas.',
          style: TextStyle(fontSize: 13, color: BrainTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: BrainTheme.textTertiary),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: BrainTheme.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: BrainTheme.borderDark.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: BrainTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: BrainTheme.accentOf(context), size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: BrainTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: BrainTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else if (onTap != null)
                  Icon(Icons.chevron_right_rounded, color: BrainTheme.textTertiary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingSection {
  final String title;
  final IconData icon;
  final List<_SettingItem> items;
  const _SettingSection({required this.title, required this.icon, required this.items});
}

class _SettingItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  const _SettingItem({required this.icon, required this.title, required this.subtitle, this.trailing, this.onTap});
}
