import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/settings_provider.dart';

class WidgetsScreen extends StatelessWidget {
  const WidgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widgets'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _buildSectionHeader('WIDGET DE HOY'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: BrainTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: BrainTheme.borderDark),
                          ),
                          child: Icon(
                            Icons.widgets_rounded,
                            color: BrainTheme.accentBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Widget de tareas del día',
                                style: TextStyle(
                                  color: BrainTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Muestra el resumen de tus tareas en la pantalla de inicio',
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
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: BrainTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: BrainTheme.borderDark),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(
                                BrainTheme.accentBlue,
                                'Tareas',
                                '42',
                              ),
                              _buildStatItem(
                                BrainTheme.accentGreen,
                                'Completadas',
                                '28',
                              ),
                              _buildStatItem(
                                BrainTheme.accentRed,
                                'Vencidas',
                                '3',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: 28 / 42,
                              backgroundColor: BrainTheme.borderDark,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                BrainTheme.accentGreen,
                              ),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '66% completado',
                            style: TextStyle(
                              color: BrainTheme.textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildSectionHeader('CONFIGURACIÓN'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  SwitchListTile(
                    title: Text(
                      'Widget habilitado',
                      style: TextStyle(
                        color: BrainTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      'Actualizar widget automáticamente',
                      style: TextStyle(
                        color: BrainTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    value: settings.widgetEnabled,
                    onChanged: (value) => settings.setWidgetEnabled(value),
                    activeThumbColor: BrainTheme.accentBlue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('CÓMO INSTALAR'),
          _buildInstructionCard(
            icon: Icons.android_rounded,
            platform: 'Android',
            steps: [
              'Mantén presionado un espacio vacío en la pantalla de inicio',
              'Selecciona "Widgets" o "Añadir widgets"',
              'Busca "SGI" en la lista de widgets',
              'Arrastra el widget "Tareas de Hoy" a tu pantalla',
            ],
          ),
          const SizedBox(height: 12),
          _buildInstructionCard(
            icon: Icons.apple_rounded,
            platform: 'iOS',
            steps: [
              'Mantén presionado un espacio vacío en la pantalla de inicio',
              'Toca el botón "+" en la esquina superior',
              'Busca "SGI" en la lista de widgets',
              'Selecciona el tamaño deseado y añádelo',
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatItem(Color color, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: BrainTheme.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionCard({
    required IconData icon,
    required String platform,
    required List<String> steps,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: BrainTheme.textPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    platform,
                    style: TextStyle(
                      color: BrainTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: BrainTheme.accentBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: BrainTheme.accentBlue,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          steps[i],
                          style: TextStyle(
                            color: BrainTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
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
}
