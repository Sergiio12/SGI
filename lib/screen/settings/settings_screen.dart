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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).settings),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('GENERAL'),
          _buildSettingItem(
            icon: Icons.palette_outlined,
            title: AppLocalizations.of(context).appearance,
            subtitle: 'Personaliza el tema y colores',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppearanceScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.notifications_none_rounded,
            title: AppLocalizations.of(context).notifications,
            subtitle: 'Configura tus recordatorios',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.widgets_rounded,
            title: 'Widgets',
            subtitle: 'Widget de tareas en la pantalla de inicio',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WidgetsScreen()),
              );
            },
          ),
          _buildAiSection(context),
          Divider(color: BrainTheme.borderDark, indent: 16, endIndent: 16),
          _buildSectionHeader('SISTEMA'),
          _buildSettingItem(
            icon: Icons.cloud_done_outlined,
            title: AppLocalizations.of(context).dataManagement,
            subtitle: 'Exportar, importar y gestionar tus datos',
            onTap: () => Navigator.pushNamed(context, '/data'),
          ),
          _buildResetSettingsItem(context),
          _buildSyncSection(context),
          _buildSettingItem(
            icon: Icons.bug_report_outlined,
            title: AppLocalizations.of(context).debug,
            subtitle: 'Opciones de depuración y pruebas',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DebugScreen()),
              );
            },
          ),
          _buildSettingItem(
            icon: Icons.info_outline_rounded,
            title: AppLocalizations.of(context).about,
            subtitle: 'Información de la aplicación',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: AppLocalizations.of(context).appTitle,
                applicationVersion: '1.0.1-beta',
                applicationIcon: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 48,
                    height: 48,
                  ),
                ),
                applicationLegalese: '© 2026 Sergio Asensio',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAiSection(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BrainTheme.borderDark),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BrainTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BrainTheme.borderDark),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: BrainTheme.accentPurple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asistente IA',
                          style: TextStyle(
                            color: BrainTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sugerencias inteligentes al crear tareas',
                          style: TextStyle(
                            color: BrainTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.aiSuggestionsEnabled,
                    activeThumbColor: BrainTheme.currentAccent,
                    onChanged: (value) =>
                        settings.setAiSuggestionsEnabled(value),
                  ),
                ],
              ),
              if (settings.aiSuggestionsEnabled) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Text(
                    'Las sugerencias se generan localmente en el dispositivo. '
                    'Ningún dato sale de tu teléfono.',
                    style: TextStyle(
                      color: BrainTheme.textTertiary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetSettingsItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BrainTheme.borderDark),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BrainTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BrainTheme.borderDark),
                    ),
                    child: Icon(
                      Icons.settings_backup_restore_rounded,
                      color: BrainTheme.accentRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Restablecer ajustes',
                          style: TextStyle(
                            color: BrainTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vuelve a la configuración de fábrica',
                          style: TextStyle(
                            color: BrainTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmReset(context),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Restablecer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BrainTheme.accentRed,
                    side: BorderSide(
                        color: BrainTheme.accentRed.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmReset(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Text('Restablecer ajustes',
            style: TextStyle(color: BrainTheme.textPrimary)),
        content: Text(
          'Se borrarán todas las preferencias guardadas (tema, colores, '
          'notificaciones, etc.). Los datos de tareas, proyectos, notas y '
          'objetivos no se verán afectados.',
          style: TextStyle(color: BrainTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancelar',
                style: TextStyle(color: BrainTheme.textSecondary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: BrainTheme.accentRed,
                foregroundColor: Colors.white),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final settings = context.read<SettingsProvider>();
      await settings.setThemeMode(ThemeMode.dark);
      await settings.setAccentColor(BrainTheme.accentPurple);
      await settings.setAiSuggestionsEnabled(true);
      await settings.setHapticFeedback(true);
      await settings.setNotificationsEnabled(true);
      if (context.mounted) {
        showSuccessNotification('Ajustes restablecidos');
      }
    }
  }

  Widget _buildSyncSection(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final settings = context.watch<SettingsProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: BrainTheme.borderDark),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: BrainTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: BrainTheme.borderDark),
                    ),
                    child: Icon(
                      Icons.sync_rounded,
                      color: _statusColor(sync.status),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sincronización en la nube',
                          style: TextStyle(
                            color: BrainTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusText(sync.status),
                          style: TextStyle(
                            color: _statusColor(sync.status),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: settings.cloudSyncEnabled,
                    activeThumbColor: BrainTheme.currentAccent,
                    onChanged: (value) => settings.setCloudSyncEnabled(value),
                  ),
                ],
              ),
              if (sync.lastSync != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Última sincronización: ${_formatLastSync(sync.lastSync!)}',
                  style: TextStyle(
                    color: BrainTheme.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: settings.cloudSyncEnabled
                      ? () => sync.triggerSync()
                      : null,
                  icon: const Icon(Icons.sync, size: 18),
                  label: const Text('Sincronizar ahora'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        BrainTheme.currentAccent.withValues(alpha: 0.15),
                    foregroundColor: BrainTheme.currentAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return BrainTheme.accentGreen;
      case SyncStatus.syncing:
        return BrainTheme.accentBlue;
      case SyncStatus.error:
        return BrainTheme.accentRed;
      case SyncStatus.disconnected:
        return BrainTheme.textTertiary;
    }
  }

  String _statusText(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return 'Conectado';
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.error:
        return 'Error de sincronización';
      case SyncStatus.disconnected:
        return 'Desconectado';
    }
  }

  String _formatLastSync(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inSeconds < 60) return 'ahora mismo';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: BrainTheme.textTertiary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: BrainTheme.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BrainTheme.borderDark),
        ),
        child: Icon(icon, color: BrainTheme.textSecondary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: BrainTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: BrainTheme.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: BrainTheme.textTertiary,
      ),
      onTap: onTap,
    );
  }
}
