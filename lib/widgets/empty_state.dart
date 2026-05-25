import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: BrainTheme.surfaceDark,
                shape: BoxShape.circle,
                border: Border.all(
                  color: BrainTheme.borderDark,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: BrainTheme.accentOf(context).withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Text(emoji, style: const TextStyle(fontSize: 64)),
            ).animate().moveY(begin: -8, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
                color: BrainTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: BrainTheme.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrainTheme.accentOf(context),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: BrainTheme.accentOf(context).withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ).copyWith(
                  elevation: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.pressed)) return 0;
                    return 8;
                  }),
                ),
              ).animate().fadeIn(delay: 400.ms).scaleXY(begin: 0.8, end: 1.0, curve: Curves.easeOutBack),
            ],
          ],
        ),
      ),
    );
  }
}
