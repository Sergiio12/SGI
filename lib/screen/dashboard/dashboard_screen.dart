import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';

import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/daily_planner_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/skeleton_card.dart';
import '../../widgets/task_card.dart';

import '../../providers/dashboard_provider.dart';
import 'dashboard_widgets.dart';
import 'metrics_screens.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _weekDays;
  final _scrollController = ScrollController();
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _weekDays = _getCurrentWeek();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(() {});
    _scrollController.dispose();
    super.dispose();
  }

  List<DateTime> _getCurrentWeek() {
    final today = DateTime.now();
    final list = <DateTime>[];
    for (int i = -3; i <= 3; i++) {
      final d = today.add(Duration(days: i));
      list.add(DateTime(d.year, d.month, d.day));
    }
    return list;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateSpanish(DateTime date) {
    final weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    final months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return '${weekdays[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
  }

  String _getDayNameAbbr(DateTime date) {
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

  bool _hasTasksOnDate(List<Task> tasks, DateTime date) {
    return tasks.any(
        (t) => t.isActive && t.dueDate != null && _isSameDay(t.dueDate!, date));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer6<TasksProvider, ProjectsProvider, NotesProvider,
        GoalsProvider, DashboardProvider, DailyPlannerProvider>(
      builder: (context, tasks, projects, notes, goals, dashboard, planner, _) {
        final today = DateTime.now();
        // Computar completados por día para sparklines y heatmap (últimos 28 días)
        final last28Counts = List.generate(28, (i) {
          final day = today.subtract(Duration(days: 27 - i));
          return tasks.tasks.where((t) =>
            t.status == TaskStatus.completed &&
            t.updatedAt.year == day.year &&
            t.updatedAt.month == day.month &&
            t.updatedAt.day == day.day
          ).length;
        });
        final last7Counts = last28Counts.sublist(21);

        if (!tasks.isLoaded || !projects.isLoaded || !notes.isLoaded || !goals.isLoaded) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                SkeletonCard(height: 160),
                SizedBox(height: 16),
                SkeletonCard(height: 80),
                SizedBox(height: 16),
                SkeletonGrid(itemCount: 4, crossAxisCount: 2, itemHeight: 130),
              ],
            ),
          );
        }
        // Calculo de productividad real: tareas con fecha de finalización hoy o adelante.
        final todayStart = DateTime(today.year, today.month, today.day);
        final upcomingTasks = tasks.tasks.where((t) {
          final d = t.dueDate;
          return d != null && !d.isBefore(todayStart);
        }).toList();

        final completedUpcomingTasks =
            upcomingTasks.where((t) => t.status == TaskStatus.completed).length;
        final totalUpcomingTasks = upcomingTasks.length;
        final todayProgress = totalUpcomingTasks == 0
            ? 0.0
            : (completedUpcomingTasks / totalUpcomingTasks);

        // Calculos de metrics avanzadas para stats cards
        final activeTasksCount = tasks.tasks.where((t) => t.isActive).length;
        final totalTasksCount = tasks.tasks.length;
        final tasksProgressVal = totalTasksCount == 0
            ? 0.0
            : (tasks.doneTasks.length / totalTasksCount);

        final activeProjectsCount = projects.activeProjects.length;
        final totalProjectsCount = projects.projects.length;
        final projectsProgressVal = totalProjectsCount == 0
            ? 0.0
            : (projects.completedProjects.length / totalProjectsCount);

        final activeGoalsCount = goals.goals.length;
        final averageGoalProgress = goals.goals.isEmpty
            ? 0.0
            : goals.goals.map((g) => g.progress).reduce((a, b) => a + b) /
                goals.goals.length;

        final totalNotesCount = notes.notes.length;
        final notesNotebooksCount = notes.notebooks.length;

        return RefreshIndicator(
          onRefresh: () => Future.wait([
            tasks.loadTasks(),
            projects.loadProjects(),
            notes.loadNotes(),
            goals.loadGoals(),
          ]),
          displacement: 80,
          edgeOffset: 20,
          child: SingleChildScrollView(
          controller: _scrollController,
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER: INTELLIGENT GREETING + INTENTION + RADIAL PROGRESS
              Transform.translate(
                offset: Offset(0, -_scrollOffset * 0.15),
                child: _buildMindGreetingHeader(
                  context,
                  todayProgress,
                  completedUpcomingTasks,
                  totalUpcomingTasks,
                  planner,
                ),
              ),

              const SizedBox(height: 20),

              // 2. CALENDAR WEEK RIBBON (INTERACTIVE)
              _buildCalendarWeekRibbon(tasks),

              const SizedBox(height: 20),

              // 3. TIMELINE AGENDA WITH TIME BLOCKS
              TimelineAgenda(
                selectedDate: _selectedDate,
                planner: planner,
                tasksProv: tasks,
              ),

              const SizedBox(height: 24),

              // 4. PREMIUM STATS GRID
              _buildPremiumStatsGrid(
                context,
                tasks,
                projects,
                goals,
                notes,
                activeTasksCount,
                tasksProgressVal,
                activeProjectsCount,
                projectsProgressVal,
                activeGoalsCount,
                averageGoalProgress,
                totalNotesCount,
                notesNotebooksCount,
              ),

              const SizedBox(height: 20),

              // 5. PRODUCTIVITY SPARKLINE
              ProductivitySparkline(dailyCounts: last7Counts),

              const SizedBox(height: 16),

              // 6. WEEKLY HEATMAP
              WeeklyHeatmap(dailyCounts: last28Counts),

              const SizedBox(height: 24),

              // 7. FOCUS MODE SHORTCUT
              _buildFocusSection(context, tasks, planner, today),

              const SizedBox(height: 16),

              // 8. OVERDUE SECTION
              if (tasks.overdueTasks.isNotEmpty) ...[
                _SectionHeader(
                  title: AppLocalizations.of(context).overdueTasks,
                  icon: Icons.warning_amber_rounded,
                  count: tasks.overdueTasks.length,
                  color: BrainTheme.accentRed,
                ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                const SizedBox(height: 12),
                ...tasks.overdueTasks.take(2).map(
                      (task) => TaskCard(
                        task: task,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/task',
                          arguments: task.id,
                        ),
                        onToggle: () => tasks.toggleTaskStatus(task.id),
                      ),
                    ),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      );
    },
  );
  }

  // WIDGET: Mind Greeting Header + Daily Intention
  Widget _buildMindGreetingHeader(
    BuildContext context,
    double todayProgress,
    int completedUpcomingTasks,
    int totalUpcomingTasks,
    DailyPlannerProvider planner,
  ) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
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
              // Circular Progress Radial
              Container(
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
                      value: todayProgress,
                      strokeWidth: 5,
                      backgroundColor: BrainTheme.borderDark,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        todayProgress == 1.0
                            ? BrainTheme.accentGreen
                            : BrainTheme.accentPurple,
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(todayProgress * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: BrainTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '$completedUpcomingTasks/$totalUpcomingTasks',
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
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Daily Intention Banner
          GestureDetector(
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
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 14,
                    color: BrainTheme.accentPurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      planner.intention.isNotEmpty
                          ? planner.intention
                          : '¿Cuál es tu intención para hoy?',
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
                    child: Icon(
                      Icons.edit_outlined,
                      size: 12,
                      color: BrainTheme.accentPurple,
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
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, end: 0, curve: Curves.easeOut);
  }

  void _showIntentionEditor(BuildContext context, DailyPlannerProvider planner) {
    final controller = TextEditingController(text: planner.intention);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Intención del día',
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
            hintText: '¿Qué es lo más importante que quieres lograr hoy?',
            hintStyle: TextStyle(color: BrainTheme.textTertiary, fontSize: 13),
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
            style: TextButton.styleFrom(foregroundColor: BrainTheme.textSecondary),
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

  // WIDGET: Calendar Week Ribbon
  Widget _buildCalendarWeekRibbon(TasksProvider tasksProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.date_range_rounded,
                color: BrainTheme.accentPurple, size: 18),
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
            if (!_isSameDay(_selectedDate, DateTime.now()))
              GestureDetector(
                onTap: () {
                  setState(() {
                    final today = DateTime.now();
                    _selectedDate =
                        DateTime(today.year, today.month, today.day);
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: BrainTheme.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: BrainTheme.accentPurple.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.today,
                          size: 12, color: BrainTheme.accentPurple),
                      SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context).today,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: BrainTheme.accentPurple,
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
            itemCount: _weekDays.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final day = _weekDays[index];
              final isSelected = _isSameDay(day, _selectedDate);
              final isToday = _isSameDay(day, DateTime.now());
              final hasTasks = _hasTasksOnDate(tasksProvider.tasks, day);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = day;
                  });
                },
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
                              BrainTheme.accentPurple,
                              Color(0xFF6D28D9)
                            ],
                          )
                        : null,
                    color: isSelected ? null : BrainTheme.cardDark,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : isToday
                              ? BrainTheme.accentPurple.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.05),
                      width: isToday ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: BrainTheme.accentPurple
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
                              : isToday
                                  ? BrainTheme.accentPurple
                                  : BrainTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Glow dot for tasks
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hasTasks
                              ? (isSelected
                                  ? Colors.white
                                  : BrainTheme.accentPurple)
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

  // WIDGET: Premium Stats Grid
  Widget _buildPremiumStatsGrid(
    BuildContext context,
    TasksProvider tasks,
    ProjectsProvider projects,
    GoalsProvider goals,
    NotesProvider notes,
    int activeTasksCount,
    double tasksProgressVal,
    int activeProjectsCount,
    double projectsProgressVal,
    int activeGoalsCount,
    double averageGoalProgress,
    int totalNotesCount,
    int notesNotebooksCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.query_stats_rounded,
                color: BrainTheme.accentGreen, size: 18),
            SizedBox(width: 8),
            Text(
              AppLocalizations.of(context).statistics,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BrainTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            _PremiumStatsCard(
              title: AppLocalizations.of(context).tasks,
              value: '$activeTasksCount',
              icon: Icons.checklist_rounded,
              color: BrainTheme.accentBlue,
              subtitle: AppLocalizations.of(context).pendingTasks,
              progress: tasksProgressVal,
              progressLabel: 'Completado: ${(tasksProgressVal * 100).toInt()}%',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TaskMetricsScreen(),
                ),
              ),
            ),
            _PremiumStatsCard(
              title: AppLocalizations.of(context).projects,
              value: '$activeProjectsCount',
              icon: Icons.folder_open_outlined,
              color: BrainTheme.accentGreen,
              subtitle: AppLocalizations.of(context).active,
              progress: projectsProgressVal,
              progressLabel:
                  'Finalizados: ${projects.completedProjects.length}/${projects.projects.length}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProjectMetricsScreen(),
                ),
              ),
            ),
            _PremiumStatsCard(
              title: AppLocalizations.of(context).goals,
              value: '$activeGoalsCount',
              icon: Icons.track_changes_outlined,
              color: BrainTheme.accentPurple,
              subtitle: AppLocalizations.of(context).active,
              progress: averageGoalProgress,
              progressLabel:
                  'Progreso medio: ${(averageGoalProgress * 100).toInt()}%',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const GoalMetricsScreen(),
                ),
              ),
            ),
            _PremiumStatsCard(
              title: AppLocalizations.of(context).notes,
              value: '$totalNotesCount',
              icon: Icons.sticky_note_2_outlined,
              color: BrainTheme.accentCyan,
              subtitle: AppLocalizations.of(context).sortRecent,
              progress: notes.notes.isEmpty ? 0.0 : 1.0,
              progressLabel: 'En $notesNotebooksCount cuadernos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NoteMetricsScreen(),
                ),
              ),
            ),
          ]
              .animate(interval: 50.ms)
              .fadeIn(duration: 400.ms)
              .scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutBack),
        ),
      ],
    );
  }

  Widget _buildFocusSection(
    BuildContext context,
    TasksProvider tasks,
    DailyPlannerProvider planner,
    DateTime today,
  ) {
    final l10n = AppLocalizations.of(context);
    final plannedCount = planner.plannedTaskIds.length;
    final timeBlockedCount = planner.timeBlocks.length;

    return Container(
      decoration: BoxDecoration(
        color: BrainTheme.cardDark.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: BrainTheme.accentOrange.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: BrainTheme.accentOrange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                Icon(Icons.center_focus_strong, size: 22, color: BrainTheme.accentOrange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.focusMode,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: BrainTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${tasks.focusTasks.length} tareas en foco · $plannedCount planificadas · $timeBlockedCount con bloque',
                  style: TextStyle(
                    fontSize: 11,
                    color: BrainTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/focus'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: BrainTheme.accentOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    'Abrir',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: BrainTheme.accentOrange,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios,
                      size: 10, color: BrainTheme.accentOrange),
                ],
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }
}

// PREMIUM STATS CARD COMPONENT (INLINE FOR CONSISTENCY)
class _PremiumStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final double progress;
  final String progressLabel;
  final VoidCallback onTap;

  const _PremiumStatsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.progress,
    required this.progressLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      color: BrainTheme.cardDark,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 14,
                    color: BrainTheme.textTertiary.withValues(alpha: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  color: color,
                  shadows: [
                    Shadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: BrainTheme.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: BrainTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              // Mini progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: BrainTheme.borderDark,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progressLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final int? count;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final titleFontSize = screenWidth < 400
        ? 15.0
        : screenWidth < 600
            ? 16.0
            : 18.0;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: BrainTheme.textPrimary,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],

      ],
    );
  }
}
