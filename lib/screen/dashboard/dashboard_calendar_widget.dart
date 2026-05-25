import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/tasks_provider.dart';

class CalendarWeekRibbon extends StatelessWidget {
  final DateTime selectedDate;
  final List<DateTime> weekDays;
  final ValueChanged<DateTime> onDateSelected;

  const CalendarWeekRibbon({
    super.key,
    required this.selectedDate,
    required this.weekDays,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = context.select<TasksProvider, List<Task>>((p) => p.tasks);
    final isToday = _isSameDay(selectedDate, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.date_range_rounded,
                color: BrainTheme.accentOf(context), size: 18),
            const SizedBox(width: 8),
            Text(
              'Calendario Semanal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BrainTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            if (!isToday)
              GestureDetector(
                onTap: () {
                  final today = DateTime.now();
                  onDateSelected(
                      DateTime(today.year, today.month, today.day));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        BrainTheme.accentOf(context).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            BrainTheme.accentOf(context).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.today,
                          size: 12, color: BrainTheme.accentOf(context)),
                      const SizedBox(width: 4),
                      Text(
                        'Hoy',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: BrainTheme.accentOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: weekDays.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final day = weekDays[index];
              final isSelected = _isSameDay(day, selectedDate);
              final isDayToday = _isSameDay(day, DateTime.now());
              final hasTasks = tasks.any((t) =>
                  t.isActive &&
                  t.dueDate != null &&
                  _isSameDay(t.dueDate!, day));

              return GestureDetector(
                onTap: () => onDateSelected(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 50,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              BrainTheme.accentOf(context),
                              Color(0xFF6D28D9)
                            ],
                          )
                        : null,
                    color: isSelected ? null : BrainTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : isDayToday
                              ? BrainTheme.accentOf(context).withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.05),
                      width: isDayToday ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: BrainTheme.accentOf(context)
                                  .withValues(alpha: 0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayNameAbbr(day),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : BrainTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isDayToday
                                  ? BrainTheme.accentOf(context)
                                  : BrainTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasTasks
                              ? (isSelected
                                  ? Colors.white
                                  : BrainTheme.accentOf(context))
                              : Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _getDayNameAbbr(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Lun';
      case DateTime.tuesday:
        return 'Mar';
      case DateTime.wednesday:
        return 'Mie';
      case DateTime.thursday:
        return 'Jue';
      case DateTime.friday:
        return 'Vie';
      case DateTime.saturday:
        return 'Sab';
      case DateTime.sunday:
        return 'Dom';
      default:
        return '';
    }
  }
}
