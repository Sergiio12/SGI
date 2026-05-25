import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../../models/time_block.dart';
import '../../providers/daily_planner_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../widgets/task_card.dart';

// ─── TIMELINE AGENDA ─────────────────────────────────────────────────

class TimelineAgenda extends StatelessWidget {
  final DateTime selectedDate;
  final DailyPlannerProvider planner;
  final TasksProvider tasksProv;

  const TimelineAgenda({
    super.key,
    required this.selectedDate,
    required this.planner,
    required this.tasksProv,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final blocks = planner.sortedTimeBlocks;
    final allTasks = tasksProv.tasks;
    final isToday = _isSameDay(selectedDate, DateTime.now());

    final dateString = isToday
        ? l10n.today
        : '${_dayAbbr(selectedDate)} ${selectedDate.day}';

    final blockedTaskIds = blocks.map((b) => b.taskId).toSet();
    final unscheduledIds =
        planner.plannedTaskIds.difference(blockedTaskIds);
    final unscheduledTasks = unscheduledIds
        .map((id) => allTasks.where((t) => t.id == id).firstOrNull)
        .whereType<Task>()
        .toList();

    final completedBlocks = blocks.where((b) => b.isCompleted).length;
    final totalBlocks = blocks.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          Row(
            children: [
              Icon(Icons.schedule_rounded,
                  color: BrainTheme.accentBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Agenda para $dateString',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BrainTheme.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              if (totalBlocks > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '$completedBlocks/$totalBlocks',
                  style: TextStyle(
                    fontSize: 12,
                    color: BrainTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        const SizedBox(height: 12),
        if (blocks.isEmpty && unscheduledTasks.isEmpty)
          _emptyAgenda(context)
        else ...[
          if (blocks.isNotEmpty) ...[
            _buildTimeline(context, blocks, allTasks, l10n),
            const SizedBox(height: 16),
          ],
          if (unscheduledTasks.isNotEmpty) ...[
            _buildUnscheduledSection(context, unscheduledTasks, l10n),
          ],
        ],
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  Widget _emptyAgenda(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.03),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy_rounded,
              size: 32,
              color: BrainTheme.textTertiary.withValues(alpha: 0.3)),
          const SizedBox(height: 8),
          Text(
            'Día despejado',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: BrainTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No tienes tareas programadas para esta fecha.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: BrainTheme.textTertiary,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/task'),
            icon: const Icon(Icons.add, size: 14),
            label: Text(l10n.createTask),
            style: ElevatedButton.styleFrom(
              backgroundColor: BrainTheme.accentBlue.withValues(alpha: 0.15),
              foregroundColor: BrainTheme.accentBlue,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              textStyle:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(
    BuildContext context,
    List<TimeBlock> blocks,
    List<Task> allTasks,
    AppLocalizations l10n,
  ) {
    const startHour = 6;
    const endHour = 23;
    final hourCount = endHour - startHour;

    return Container(
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.03),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: SizedBox(
        height: hourCount * 60.0 + 20,
        child: Stack(
          children: [
            for (int h = startHour; h <= endHour; h++)
              Positioned(
                top: (h - startHour) * 60.0,
                left: 0,
                right: 0,
                height: 1,
                child: Container(
                  margin: const EdgeInsets.only(left: 52, right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                        alpha: h == DateTime.now().hour ? 0.08 : 0.03),
                    border: h == DateTime.now().hour
                        ? Border(
                            top: BorderSide(
                              color: BrainTheme.accentOf(context)
                                  .withValues(alpha: 0.3),
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            for (int h = startHour; h <= endHour; h++)
              Positioned(
                top: (h - startHour) * 60.0 - 6,
                left: 8,
                child: SizedBox(
                  width: 36,
                  child: Text(
                    '${h.toString().padLeft(2, '0')}:00',
                    style: TextStyle(
                      fontSize: 9,
                      color: BrainTheme.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            for (final block in blocks)
              _buildBlockBanner(context, block, allTasks, startHour),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockBanner(
    BuildContext context,
    TimeBlock block,
    List<Task> allTasks,
    int startHour,
  ) {
    final task =
        allTasks.where((t) => t.id == block.taskId).firstOrNull;
    final top = (block.startHour - startHour) * 60.0 +
        block.startMinute;
    final height = block.durationMinutes.toDouble();

    return Positioned(
      top: top,
      left: 52,
      right: 8,
      height: height.clamp(28, 200),
      child: GestureDetector(
        onTap: task != null
            ? () => Navigator.pushNamed(
                  context,
                  '/task',
                  arguments: task.id,
                )
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: (block.isCompleted
                    ? BrainTheme.accentGreen
                    : _colorForTask(task))
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (block.isCompleted
                      ? BrainTheme.accentGreen
                      : _colorForTask(task))
                  .withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => planner.toggleTimeBlockCompleted(block.taskId),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: block.isCompleted
                        ? BrainTheme.accentGreen
                        : Colors.transparent,
                    border: Border.all(
                      color: block.isCompleted
                          ? BrainTheme.accentGreen
                          : BrainTheme.textTertiary,
                      width: 1.5,
                    ),
                  ),
                  child: block.isCompleted
                      ? Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task?.title ?? '(tarea eliminada)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: block.isCompleted
                            ? BrainTheme.textTertiary
                            : BrainTheme.textPrimary,
                        decoration: block.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      '${block.startLabel} - ${block.endLabel}',
                      style: TextStyle(
                        fontSize: 9,
                        color: BrainTheme.textTertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (task != null)
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _priorityColor(task.priority),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForTask(Task? task) {
    if (task == null) return BrainTheme.textTertiary;
    if (task.isOverdue) return BrainTheme.accentRed;
    switch (task.priority) {
      case TaskPriority.urgent:
        return BrainTheme.accentRed;
      case TaskPriority.high:
        return BrainTheme.accentOrange;
      case TaskPriority.medium:
        return BrainTheme.accentBlue;
      case TaskPriority.low:
        return BrainTheme.textTertiary;
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return BrainTheme.textTertiary;
      case TaskPriority.medium:
        return BrainTheme.accentBlue;
      case TaskPriority.high:
        return BrainTheme.accentOrange;
      case TaskPriority.urgent:
        return BrainTheme.accentRed;
    }
  }

  Widget _buildUnscheduledSection(
    BuildContext context,
    List<Task> tasks,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.inbox_rounded,
                size: 14, color: BrainTheme.textTertiary),
            const SizedBox(width: 6),
            Text(
              l10n.unscheduled,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BrainTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: BrainTheme.textTertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${tasks.length}',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: BrainTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          children: tasks.map((task) {
            return TaskCard(
              task: task,
              compact: true,
              onTap: () => Navigator.pushNamed(
                context,
                '/task',
                arguments: task.id,
              ),
              onToggle: () => planner.toggleTaskInDay(task.id),
            );
          }).toList(),
        ),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayAbbr(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Lun';
      case DateTime.tuesday:
        return 'Mar';
      case DateTime.wednesday:
        return 'Mié';
      case DateTime.thursday:
        return 'Jue';
      case DateTime.friday:
        return 'Vie';
      case DateTime.saturday:
        return 'Sáb';
      case DateTime.sunday:
        return 'Dom';
      default:
        return '';
    }
  }
}

// ─── PRODUCTIVITY SPARKLINE ──────────────────────────────────────────

class ProductivitySparkline extends StatelessWidget {
  final List<int> dailyCounts;

  const ProductivitySparkline({super.key, required this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxVal = dailyCounts.reduce((a, b) => a > b ? a : b).toDouble();
    final spots = <FlSpot>[];
    for (int i = 0; i < dailyCounts.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyCounts[i].toDouble()));
    }

    return Container(
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.03),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded,
                  size: 16, color: BrainTheme.accentGreen),
              const SizedBox(width: 8),
              Text(
                l10n.productivityTrend,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: BrainTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  '${l10n.last7Days} · ${dailyCounts.reduce((a, b) => a + b)} ${l10n.completedTasks.toLowerCase()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: BrainTheme.textTertiary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: spots.length < 2
                ? Center(
                    child: Text(
                      l10n.noData,
                      style: TextStyle(
                        fontSize: 11,
                        color: BrainTheme.textTertiary,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxVal < 1 ? 2 : maxVal * 1.3,
                      gridData: FlGridData(
                        show: true,
                        horizontalInterval: maxVal < 2 ? 1 : null,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.03),
                          strokeWidth: 1,
                        ),
                        drawVerticalLine: false,
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                              final idx = value.toInt();
                              if (idx < 0 || idx >= days.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  days[idx],
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: BrainTheme.textTertiary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: BrainTheme.accentGreen,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: 2.5,
                                color: BrainTheme.accentGreen,
                                strokeWidth: 0,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: BrainTheme.accentGreen
                                .withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}

// ─── WEEKLY HEATMAP ─────────────────────────────────────────────────

class WeeklyHeatmap extends StatelessWidget {
  final List<int> dailyCounts;

  const WeeklyHeatmap({super.key, required this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final maxVal = dailyCounts.isEmpty
        ? 1
        : dailyCounts.reduce((a, b) => a > b ? a : b);
    final weeks = <List<int>>[];
    for (int w = 0; w < 4; w++) {
      final week = <int>[];
      for (int d = 0; d < 7; d++) {
        final idx = w * 7 + d;
        week.add(idx < dailyCounts.length ? dailyCounts[idx] : 0);
      }
      weeks.add(week);
    }

    return Container(
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.03),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_view_rounded,
                  size: 16, color: BrainTheme.accentOf(context)),
              const SizedBox(width: 8),
              Text(
                l10n.heatmap,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: BrainTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (dailyCounts.isNotEmpty)
                Flexible(
                  child: Text(
                    '${dailyCounts.reduce((a, b) => a + b)} ${l10n.completedTasks.toLowerCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: BrainTheme.textTertiary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: weeks.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: entry.value.asMap().entries.map((cell) {
                    final count = cell.value;
                    final intensity = maxVal == 0
                        ? 0.0
                        : count / maxVal;
                    return Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: count == 0
                            ? BrainTheme.surfaceDark
                            : BrainTheme.accentGreen
                                .withValues(alpha: 0.15 + intensity * 0.6),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: count == 0
                              ? Colors.white.withValues(alpha: 0.04)
                              : BrainTheme.accentGreen
                                  .withValues(alpha: 0.2 + intensity * 0.4),
                          width: 0.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        count == 0 ? '' : '$count',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: count > 0
                              ? Colors.white.withValues(alpha: 0.7)
                              : Colors.transparent,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}


