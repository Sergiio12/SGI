import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../services/smart_alerts_service.dart';

class SmartAlertsSection extends StatelessWidget {
  final List<SmartAlert> alerts;

  const SmartAlertsSection({super.key, required this.alerts});

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.psychology_rounded, size: 18, color: BrainTheme.accentPurple),
              const SizedBox(width: 8),
              Text(
                'Alertas Inteligentes',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: BrainTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        ...alerts.asMap().entries.map((entry) => _AlertCard(alert: entry.value)
          .animate()
          .fadeIn(duration: 300.ms, delay: (50 * entry.key).ms)
          .slideX(begin: -0.05, end: 0, curve: Curves.easeOutCubic)),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final SmartAlert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    final (Color color, IconData icon) = switch (alert.severity) {
      SmartAlertSeverity.danger => (BrainTheme.accentRed, Icons.error_rounded),
      SmartAlertSeverity.warning =>
        (BrainTheme.accentOrange, Icons.warning_amber_rounded),
      SmartAlertSeverity.info => (BrainTheme.accentBlue, Icons.info_rounded),
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  alert.message,
                  style: TextStyle(
                    fontSize: 12,
                    color: BrainTheme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
