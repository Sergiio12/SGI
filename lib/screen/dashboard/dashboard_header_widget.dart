import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../providers/daily_planner_provider.dart';

class DashboardHeader extends StatelessWidget {
  final double todayProgress;
  final int completedUpcomingTasks;
  final int totalUpcomingTasks;
  final DailyPlannerProvider planner;

  const DashboardHeader({
    super.key,
    required this.todayProgress,
    required this.completedUpcomingTasks,
    required this.totalUpcomingTasks,
    required this.planner,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos dias'
        : hour < 18
            ? 'Buenas tardes'
            : 'Buenas noches';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrainTheme.cardDark,
            BrainTheme.surfaceDark.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: BrainTheme.accentPurple.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: BrainTheme.accentPurple.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: BrainTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDateSpanish(DateTime.now()),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BrainTheme.accentPurple,
                      ),
                    ),
                  ],
                ),
              ),
              _CircularProgress(
                progress: todayProgress,
                completed: completedUpcomingTasks,
                total: totalUpcomingTasks,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _IntentionBanner(planner: planner),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, end: 0, curve: Curves.easeOut);
  }

  String _formatDateSpanish(DateTime date) {
    const weekdays = [
      'Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'
    ];
    const months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    final idx = date.weekday - 1;
    final mi = date.month - 1;
    return '${weekdays[idx]}, ${date.day} de ${months[mi]}';
  }
}

class _CircularProgress extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;

  const _CircularProgress({
    required this.progress,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: BrainTheme.surfaceDark,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(5),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 5,
            backgroundColor: BrainTheme.borderDark,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0
                  ? BrainTheme.accentGreen
                  : BrainTheme.accentPurple,
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: BrainTheme.textPrimary,
                ),
              ),
              Text(
                '$completed/$total',
                style: TextStyle(
                  fontSize: 8,
                  color: BrainTheme.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntentionBanner extends StatelessWidget {
  final DailyPlannerProvider planner;

  const _IntentionBanner({required this.planner});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showIntentionEditor(context, planner),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: BrainTheme.accentPurple.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: BrainTheme.accentPurple.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.lightbulb_outline_rounded,
                size: 14, color: BrainTheme.accentPurple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                planner.intention.isNotEmpty
                    ? planner.intention
                    : 'Cual es tu intencion para hoy?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: planner.intention.isNotEmpty
                      ? BrainTheme.textPrimary
                      : BrainTheme.textTertiary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: BrainTheme.accentPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.edit_outlined,
                  size: 12, color: BrainTheme.accentPurple),
            ),
          ],
        ),
      ),
    );
  }

  void _showIntentionEditor(
      BuildContext context, DailyPlannerProvider planner) {
    final controller = TextEditingController(text: planner.intention);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Intencion del dia',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: BrainTheme.textPrimary,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Que es lo mas importante que quieres lograr hoy?',
            hintStyle:
                TextStyle(color: BrainTheme.textTertiary, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BrainTheme.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BrainTheme.accentPurple),
            ),
            fillColor: BrainTheme.surfaceDark,
            filled: true,
          ),
          style: TextStyle(color: BrainTheme.textPrimary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
                foregroundColor: BrainTheme.textSecondary),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              planner.setIntention(controller.text);
              planner.save();
              Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
              backgroundColor: BrainTheme.accentPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
