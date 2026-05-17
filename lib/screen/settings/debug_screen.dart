import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/notification_service.dart';
import '../../utils/notification_service_v2.dart';

class DebugScreen extends StatelessWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DebugCard(
            title: 'Notificaciones locales',
            description: 'Prueba el sistema de notificaciones del sistema (Push notifications locales).',
            icon: Icons.notifications_active_outlined,
            buttonLabel: 'Probar notificaciones',
            onPressed: () async {
              try {
                await NotificationService.showInstantNotification(
                  title: 'Prueba de SGI',
                  body: '¡Funciona! Esta es una notificación de prueba.',
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
            description: 'Prueba el sistema de notificaciones visuales internas de la aplicación.',
            icon: Icons.message_outlined,
            buttonLabel: 'Probar In-App',
            onPressed: () {
              showInfoNotification('Esto es una notificación in-app de prueba');
            },
          ),
        ],
      ),
    );
  }
}

class _DebugCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _DebugCard({
    required this.title,
    required this.description,
    required this.icon,
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
                Icon(icon, color: BrainTheme.accentPurple),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
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
              style: const TextStyle(
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
                  backgroundColor: BrainTheme.accentPurple,
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
