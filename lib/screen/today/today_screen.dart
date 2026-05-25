import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/task.dart';
import '../../models/time_block.dart';
import '../../providers/daily_planner_provider.dart';
import '../../providers/tasks_provider.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  late TextEditingController _intentionController;

  @override
  void initState() {
    super.initState();
    _intentionController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final intention = context.read<DailyPlannerProvider>().intention;
    if (_intentionController.text != intention) {
      _intentionController.text = intention;
    }
  }

  @override
  void dispose() {
    _intentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).today)),
      body: Consumer2<DailyPlannerProvider, TasksProvider>(
        builder: (context, planner, tasksProv, _) {
          final l10n = AppLocalizations.of(context);
          final now = DateTime.now();
          final dayName = _dayNames[now.weekday - 1];
          final dateStr = DateFormat("d 'de' MMMM", 'es').format(now);

          final plannedIds = planner.plannedTaskIds;
          final timeBlocks = planner.sortedTimeBlocks;
          final intention = planner.intention;

          final blockedTaskIds =
              timeBlocks.map((b) => b.taskId).toSet();
          final unscheduledIds =
              plannedIds.difference(blockedTaskIds);

          final allTasks = tasksProv.tasks;
          final unscheduledTasks = allTasks
              .where((t) => unscheduledIds.contains(t.id))
              .toList();
          final overdue = tasksProv.overdueTasks;
          final todayTasks = tasksProv.todayTasks;
          final inProgress = tasksProv.inProgressTasks;

          if (plannedIds.isEmpty &&
              overdue.isEmpty &&
              todayTasks.isEmpty &&
              inProgress.isEmpty) {
            return _buildEmptyState(context, planner);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _buildHeader(context, dayName, dateStr, planner, overdue.length,
                  todayTasks.length, intention),
              const SizedBox(height: 20),
              // Intention card
              _buildIntentionCard(context, planner, intention, l10n),
              const SizedBox(height: 20),
              // Time-blocked agenda
              if (timeBlocks.isNotEmpty) ...[
                _buildSectionTitle(
                    context, Icons.schedule, Colors.blue, l10n.statusInProgress),
                const SizedBox(height: 8),
                ...timeBlocks.map((block) {
                  final task =
                      allTasks.where((t) => t.id == block.taskId).firstOrNull;
                  return _TimeBlockCard(
                    block: block,
                    task: task,
                    onToggle: () => planner.toggleTimeBlockCompleted(block.taskId),
                    onRemove: () => planner.removeTimeBlock(block.taskId),
                    onTap: task != null
                        ? () => Navigator.pushNamed(context, '/task',
                            arguments: task.id)
                        : null,
                  );
                }),
                const SizedBox(height: 20),
              ],
              // Unscheduled tasks for today
              if (unscheduledTasks.isNotEmpty) ...[
                _buildSectionTitle(context, Icons.event_note, Colors.orange,
                    l10n.todayView),
                const SizedBox(height: 8),
                ...unscheduledTasks.map(
                  (task) => _PlannedTaskCard(
                    task: task,
                    onTap: () => Navigator.pushNamed(context, '/task',
                        arguments: task.id),
                    onRemove: () => planner.removeTaskFromDay(task.id),
                    onTimeBlock: () => _showTimeBlockPicker(context, planner, task),
                    onToggle: () => tasksProv.toggleTaskStatus(task.id),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // Overdue section
              if (overdue.isNotEmpty) ...[
                _buildSectionTitle(context, Icons.warning_amber_rounded,
                    Colors.red, l10n.overdueTasks),
                const SizedBox(height: 8),
                ...overdue.map(
                  (task) => _PlannedTaskCard(
                    task: task,
                    onTap: () => Navigator.pushNamed(context, '/task',
                        arguments: task.id),
                    onRemove: () => planner.removeTaskFromDay(task.id),
                    onTimeBlock: () => _showTimeBlockPicker(context, planner, task),
                    onToggle: () => tasksProv.toggleTaskStatus(task.id),
                    isOverdue: true,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              // End of day review button
              Center(
                child: TextButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/daily-review'),
                  icon: Icon(Icons.nightlight_round,
                      size: 16, color: BrainTheme.textTertiary),
                  label: Text(
                    'Revisión de fin de día',
                    style: TextStyle(
                        fontSize: 13, color: BrainTheme.textTertiary),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, DailyPlannerProvider planner) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌟', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Planifica tu día',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BrainTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Añade tareas a tu plan diario desde el tablero Kanban\no usando el botón "Añadir a Mi Día".',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: BrainTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => planner.addSuggestedTasks(),
              icon: const Icon(Icons.auto_awesome, size: 18),
              label: const Text('Sugerir tareas'),
              style: FilledButton.styleFrom(
                backgroundColor: BrainTheme.accentPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String dayName,
    String dateStr,
    DailyPlannerProvider planner,
    int overdueCount,
    int todayCount,
    String intention,
  ) {
    final planned = planner.plannedTaskIds.length;
    final done =
        planner.timeBlocks.where((b) => b.isCompleted).length;
    final total = planner.timeBlocks.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [BrainTheme.accentPurple, BrainTheme.accentBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dayName[0].toUpperCase() + dayName.substring(1),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
              if (total > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$done/$total',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          if (intention.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.format_quote,
                      size: 14, color: Colors.white.withValues(alpha: 0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      intention,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _HeaderStat(
                  count: planned,
                  label: 'Planificadas',
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(width: 12),
              _HeaderStat(
                  count: overdueCount,
                  label: 'Vencidas',
                  color: Colors.white.withValues(alpha: 0.9),
                  bgColor: Colors.white.withValues(alpha: 0.15)),
              const SizedBox(width: 12),
              _HeaderStat(
                  count: todayCount,
                  label: 'Hoy',
                  color: Colors.white,
                  bgColor: Colors.white.withValues(alpha: 0.15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIntentionCard(
    BuildContext context,
    DailyPlannerProvider planner,
    String intention,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: BrainTheme.borderDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.track_changes,
                  size: 16, color: BrainTheme.accentPurple),
              const SizedBox(width: 8),
              Text(
                'Intención del día',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: BrainTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _intentionController,
            decoration: InputDecoration(
              hintText: '¿Qué es lo más importante hoy?',
              hintStyle:
                  TextStyle(color: BrainTheme.textTertiary, fontSize: 14),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
            style: TextStyle(
              fontSize: 15,
              color: BrainTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            onChanged: (v) => planner.setIntention(v),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      BuildContext context, IconData icon, Color color, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
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

  void _showTimeBlockPicker(
      BuildContext context, DailyPlannerProvider planner, Task task) {
    var startHour = DateTime.now().hour;
    var startMinute = DateTime.now().minute;
    var endHour = startHour + 1;
    var endMinute = startMinute;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: BrainTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bloque de tiempo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: BrainTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 14,
                        color: BrainTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _TimePickerField(
                            label: 'Inicio',
                            hour: startHour,
                            minute: startMinute,
                            onChanged: (h, m) => setSheetState(() {
                              startHour = h;
                              startMinute = m;
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _TimePickerField(
                            label: 'Fin',
                            hour: endHour,
                            minute: endMinute,
                            onChanged: (h, m) => setSheetState(() {
                              endHour = h;
                              endMinute = m;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          planner.createTimeBlock(
                            taskId: task.id,
                            startHour: startHour,
                            startMinute: startMinute,
                            endHour: endHour,
                            endMinute: endMinute,
                          );
                          Navigator.pop(ctx);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: BrainTheme.accentPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Asignar bloque'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Header stat ────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final Color bgColor;

  const _HeaderStat({
    required this.count,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Time block card ────────────────────────────────────────────────

class _TimeBlockCard extends StatelessWidget {
  final TimeBlock block;
  final Task? task;
  final VoidCallback onToggle;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const _TimeBlockCard({
    required this.block,
    required this.task,
    required this.onToggle,
    required this.onRemove,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = block.isCompleted;
    final color = isDone
        ? BrainTheme.accentGreen
        : task != null
            ? BrainTheme.priorityColor(task!.priority.index)
            : BrainTheme.textTertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: isDone ? 0.5 : 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone
                    ? BrainTheme.accentGreen
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDone
                      ? BrainTheme.accentGreen
                      : BrainTheme.borderDark,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${block.startLabel} – ${block.endLabel}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDone
                      ? BrainTheme.textTertiary
                      : BrainTheme.textPrimary,
                ),
              ),
              if (task != null)
                GestureDetector(
                  onTap: onTap,
                  child: Text(
                    task!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDone
                          ? BrainTheme.textTertiary
                          : BrainTheme.textPrimary,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.close,
                size: 16, color: BrainTheme.textTertiary),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.02, end: 0);
  }
}

// ─── Planned task card ──────────────────────────────────────────────

class _PlannedTaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final VoidCallback onTimeBlock;
  final VoidCallback? onToggle;
  final bool isOverdue;

  const _PlannedTaskCard({
    required this.task,
    required this.onTap,
    required this.onRemove,
    required this.onTimeBlock,
    this.onToggle,
    this.isOverdue = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.completed;
    final priColor = BrainTheme.priorityColor(task.priority.index);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOverdue
              ? BrainTheme.accentRed.withValues(alpha: 0.2)
              : BrainTheme.borderDark.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          if (onToggle != null)
            GestureDetector(
              onTap: onToggle,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: isDone
                      ? BrainTheme.accentGreen
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDone
                        ? BrainTheme.accentGreen
                        : BrainTheme.borderDark,
                    width: 2,
                  ),
                ),
                child: isDone
                    ? Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
          if (onToggle != null) const SizedBox(width: 10),
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: priColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDone
                          ? BrainTheme.textTertiary
                          : BrainTheme.textPrimary,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (task.description.isNotEmpty)
                    Text(
                      task.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: BrainTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.schedule_send,
                size: 16, color: BrainTheme.accentPurple),
            onPressed: onTimeBlock,
            tooltip: 'Asignar bloque',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.close,
                size: 14, color: BrainTheme.textTertiary),
            onPressed: onRemove,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.02, end: 0);
  }
}

// ─── Time picker field ──────────────────────────────────────────────

class _TimePickerField extends StatelessWidget {
  final String label;
  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  const _TimePickerField({
    required this.label,
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: BrainTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: BrainTheme.cardDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BrainTheme.borderDark),
          ),
          child: Row(
            children: [
              DropdownButton<int>(
                value: hour.clamp(0, 23),
                underline: const SizedBox.shrink(),
                dropdownColor: BrainTheme.cardDark,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: BrainTheme.textPrimary,
                ),
                items: List.generate(
                  24,
                  (i) => DropdownMenuItem(
                    value: i,
                    child: Text(i.toString().padLeft(2, '0')),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) onChanged(v, minute);
                },
              ),
              Text(':', style: TextStyle(color: BrainTheme.textTertiary)),
              DropdownButton<int>(
                value: minute.clamp(0, 59),
                underline: const SizedBox.shrink(),
                dropdownColor: BrainTheme.cardDark,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: BrainTheme.textPrimary,
                ),
                items: List.generate(
                  12,
                  (i) => DropdownMenuItem(
                    value: i * 5,
                    child: Text((i * 5).toString().padLeft(2, '0')),
                  ),
                ),
                onChanged: (v) {
                  if (v != null) onChanged(hour, v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

const _dayNames = [
  'Lunes',
  'Martes',
  'Miércoles',
  'Jueves',
  'Viernes',
  'Sábado',
  'Domingo',
];
