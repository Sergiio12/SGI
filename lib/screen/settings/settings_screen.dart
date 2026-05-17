import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'debug_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader('GENERAL'),
          _buildSettingItem(
            icon: Icons.palette_outlined,
            title: 'Apariencia',
            subtitle: 'Personaliza el tema y colores',
            onTap: () {
              // TODO: Implementar
            },
          ),
          _buildSettingItem(
            icon: Icons.notifications_none_rounded,
            title: 'Notificaciones',
            subtitle: 'Configura tus recordatorios',
            onTap: () {
              // TODO: Implementar
            },
          ),
          const Divider(color: BrainTheme.borderDark, indent: 16, endIndent: 16),
          _buildSectionHeader('SISTEMA'),
          _buildSettingItem(
            icon: Icons.bug_report_outlined,
            title: 'Debug',
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
            title: 'Acerca de',
            subtitle: 'Información de la aplicación',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Sistema de gestión integral',
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
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
        style: const TextStyle(
          color: BrainTheme.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: BrainTheme.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: BrainTheme.textTertiary,
      ),
      onTap: onTap,
    );
  }
}
