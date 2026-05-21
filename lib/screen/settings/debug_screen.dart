import 'package:flutter/material.dart';
import 'package:second_brain/l10n/app_localizations.dart';
import '../../config/theme.dart';
import '../../services/notification_service.dart';
import '../../utils/haptic_helper.dart';
import '../../utils/notification_service_v2.dart';
import '../../utils/undo_helper.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).debug),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DebugCard(
            title: 'Notificaciones locales',
            description: 'Prueba el sistema de notificaciones del sistema.',
            icon: Icons.notifications_active_outlined,
            buttonLabel: 'Probar notificaciones',
            onPressed: () async {
              try {
                await NotificationService.showInstantNotification(
                  title: 'Prueba de SGI',
                  body: '¡Notificación de prueba!',
                );
                showSuccessNotification('Notificación enviada');
              } catch (e) {
                showErrorNotification('Error al enviar: $e');
              }
            },
          ),
          const SizedBox(height: 16),
          _DebugCard(
            title: 'Notificaciones In-App',
            description: 'Prueba el sistema de notificaciones visuales internas.',
            icon: Icons.message_outlined,
            buttonLabel: 'Probar In-App',
            onPressed: () {
              showInfoNotification('Notificación in-app de prueba');
            },
          ),
          const SizedBox(height: 16),
          _DebugCard(
            title: 'Modal de error',
            description: 'Simula un error para probar el modal de error.',
            icon: Icons.error_outline_rounded,
            iconColor: BrainTheme.accentRed,
            buttonLabel: 'Probar modal',
            onPressed: () => _simulateError(context),
          ),
          const SizedBox(height: 16),
          _DebugCard(
            title: 'SnackBar de deshacer',
            description: 'Muestra el mensaje de deshacer en la parte inferior.',
            icon: Icons.undo_rounded,
            iconColor: BrainTheme.accentOrange,
            buttonLabel: 'Mostrar SnackBar',
            onPressed: () {
              showUndoSnackBar(
                context,
                message: 'Elemento eliminado de prueba',
                onUndo: () => showSuccessNotification('Deshecho correctamente'),
              );
            },
          ),
          const SizedBox(height: 16),
          _DebugCard(
            title: 'Feedback háptico',
            description: 'Prueba las vibraciones hápticas (ligera, selección, media).',
            icon: Icons.vibration_rounded,
            iconColor: BrainTheme.accentPurple,
            buttonLabel: 'Probar hápticos',
            onPressed: () {
              HapticHelper.light();
              Future.delayed(const Duration(milliseconds: 300), HapticHelper.selection);
              Future.delayed(const Duration(milliseconds: 600), HapticHelper.medium);
            },
          ),
        ],
      ),
    );
  }

  void _simulateError(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      throw FlutterError(
        'Error simulado desde depurador\n\n'
        'Esto es una prueba del sistema de gestión de errores.',
      );
    });
  }
}

class _DebugCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color? iconColor;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _DebugCard({
    required this.title,
    required this.description,
    required this.icon,
    this.iconColor,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? BrainTheme.accentPurple),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: BrainTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: BrainTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: iconColor ?? BrainTheme.accentPurple,
                ),
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
