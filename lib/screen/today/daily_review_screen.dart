import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/daily_planner_provider.dart';
import '../../providers/tasks_provider.dart';

class DailyReviewScreen extends StatefulWidget {
  const DailyReviewScreen({super.key});

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Revisión del día'),
      ),
      body: SafeArea(child: Consumer2<DailyPlannerProvider, TasksProvider>(
        builder: (context, planner, tasksProv, _) {
          final now = DateTime.now();
          final dateStr = DateFormat("d 'de' MMMM", 'es').format(now);

          final plannedIds = planner.plannedTaskIds;
          final allTasks = tasksProv.tasks;
          final plannedTasks =
              allTasks.where((t) => plannedIds.contains(t.id)).toList();
          final total = plannedTasks.length;
          final completed = plannedTasks
              .where((t) => t.status == TaskStatus.completed)
              .length;
          final pending = plannedTasks
              .where((t) => t.status != TaskStatus.completed)
              .length;
          final completionRate = total > 0 ? completed / total : 0.0;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Header with completion ring
              _buildHeader(context, dateStr, completed, total, completionRate),
              const SizedBox(height: 24),

              // Intention recap
              if (planner.intention.isNotEmpty) ...[
                _buildIntentionRecap(context, planner.intention),
                const SizedBox(height: 20),
              ],

              // Completed tasks
              if (completed > 0) ...[
                _buildSectionTitle(
                    context, 'Completadas', BrainTheme.accentGreen),
                const SizedBox(height: 8),
                ...plannedTasks
                    .where((t) => t.status == TaskStatus.completed)
                    .map((t) => _ReviewTaskCard(task: t, isCompleted: true)),
                const SizedBox(height: 20),
              ],

              // Pending tasks
              if (pending > 0) ...[
                _buildSectionTitle(
                    context, 'Pendientes', BrainTheme.accentOrange),
                const SizedBox(height: 8),
                ...plannedTasks
                    .where((t) => t.status != TaskStatus.completed)
                    .map((t) => _ReviewTaskCard(task: t, isCompleted: false)),
                const SizedBox(height: 20),
              ],

              // Stats summary
              _buildStatsCard(
                  context, completed, pending, total, plannedIds.length),
              const SizedBox(height: 24),

              // Reflection prompt
              _buildReflectionCard(context),
              const SizedBox(height: 40),
            ],
          );
        },
      )),
    );
  }

  Widget _buildHeader(BuildContext context, String dateStr, int completed,
      int total, double rate) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BrainTheme.accentOf(context).withValues(alpha: 0.9),
            BrainTheme.accentBlue.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Icon(Icons.nightlight_round,
              size: 32, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(height: 12),
          Text(
            'Resumen del día',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: rate,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      rate >= 0.8
                          ? BrainTheme.accentGreen
                          : rate >= 0.5
                              ? BrainTheme.accentOrange
                              : BrainTheme.accentRed,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$completed',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'de $total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildIntentionRecap(BuildContext context, String intention) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: BrainTheme.accentOf(context).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote, size: 18, color: BrainTheme.accentOf(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Intención del día',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: BrainTheme.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  intention,
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: BrainTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildSectionTitle(BuildContext context, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, int completed, int pending,
      int total, int planned) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrainTheme.borderDark.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estadísticas',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BrainTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatItem(
                icon: Icons.check_circle,
                value: '$completed',
                label: 'Completadas',
                color: BrainTheme.accentGreen,
              ),
              _StatItem(
                icon: Icons.pending,
                value: '$pending',
                label: 'Pendientes',
                color: BrainTheme.accentOrange,
              ),
              _StatItem(
                icon: Icons.event_note,
                value: '$planned',
                label: 'Planificadas',
                color: BrainTheme.accentBlue,
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: total > 0 ? completed / total : 0.0,
                minHeight: 6,
                backgroundColor: BrainTheme.borderDark.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation(
                  completed == total
                      ? BrainTheme.accentGreen
                      : BrainTheme.accentOf(context),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildReflectionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrainTheme.borderDark.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories,
                  size: 18, color: BrainTheme.accentOf(context)),
              const SizedBox(width: 8),
              Text(
                'Reflexión',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BrainTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '¿Qué fue bien hoy? ¿Qué podrías mejorar mañana?',
            style: TextStyle(
              fontSize: 13,
              color: BrainTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BrainTheme.surfaceDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Escribe tu reflexión aquí...',
                hintStyle:
                    TextStyle(fontSize: 13, color: BrainTheme.textTertiary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              style: TextStyle(
                fontSize: 13,
                color: BrainTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}

class _ReviewTaskCard extends StatelessWidget {
  final dynamic task;
  final bool isCompleted;

  const _ReviewTaskCard({
    required this.task,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCompleted
              ? BrainTheme.accentGreen.withValues(alpha: 0.15)
              : BrainTheme.borderDark.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color:
                isCompleted ? BrainTheme.accentGreen : BrainTheme.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isCompleted
                    ? BrainTheme.textTertiary
                    : BrainTheme.textPrimary,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: BrainTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
