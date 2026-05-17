import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/task.dart';
import '../../providers/goals_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../services/smart_alerts_service.dart';
import '../../utils/responsive_helper.dart';
import '../../utils/notification_service_v2.dart';
import '../../widgets/task_card.dart';

import '../../providers/dashboard_provider.dart';
import '../tasks/tasks_screen.dart';
import '../projects/projects_screen.dart';
import '../goals/goals_screen.dart';
import '../notes/notes_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _weekDays;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _weekDays = _getCurrentWeek();
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

  void _showQuickTaskDialog(BuildContext context) {
    final controller = TextEditingController();
    final notificationController = context.read<NotificationController>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: BrainTheme.accentPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.flash_on,
                size: 22,
                color: BrainTheme.accentPurple,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Captura rápida',
              style: TextStyle(
                color: BrainTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: BrainTheme.textPrimary),
          decoration: InputDecoration(
            hintText: '¿Qué tienes en mente?',
            hintStyle: TextStyle(color: BrainTheme.textTertiary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BrainTheme.borderDark),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: BrainTheme.borderDark),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: BrainTheme.accentPurple,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: BrainTheme.surfaceDark,
          ),
          onSubmitted: (value) {
            _submitTask(
                value, dialogContext, controller, notificationController);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: BrainTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          FilledButton(
            onPressed: () {
              _submitTask(controller.text, dialogContext, controller,
                  notificationController);
            },
            style: FilledButton.styleFrom(
              backgroundColor: BrainTheme.accentPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Capturar',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTask(
    String text,
    BuildContext dialogContext,
    TextEditingController controller,
    NotificationController notificationController,
  ) async {
    if (text.trim().isEmpty) {
      notificationController.showWarning('Por favor, escribe una tarea');
      return;
    }

    try {
      await context.read<TasksProvider>().addTask(title: text.trim());
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
    } catch (e) {
      notificationController.showError('Error: ${e.toString()}');
    }
  }

  String _generateAdvisorText({
    required TasksProvider tasks,
    required ProjectsProvider projects,
    required GoalsProvider goals,
    required NotesProvider notes,
  }) {
    final activeTasks = tasks.tasks.where((t) => t.isActive).length;
    final overdue = tasks.overdueTasks.length;
    final urgent = tasks.urgentTasks.length;
    final focusTask =
        tasks.focusTasks.isNotEmpty ? tasks.focusTasks.first : null;
    final activeProjects = projects.activeProjects.length;

    if (overdue > 0) {
      return 'Atención: Tienes $overdue ${overdue == 1 ? "tarea vencida" : "tareas vencidas"}. Te recomendamos reprogramar sus fechas límites hoy para mantener tu claridad mental. ⚠️';
    } else if (urgent > 0) {
      return '¡Hoy tienes $urgent ${urgent == 1 ? "tarea urgente" : "tareas urgentes"}! Te sugerimos enfocar tu energía a primera hora en completarlas. Puedes iniciar el Modo Foco para concentrarte. ⚡';
    } else if (focusTask != null) {
      return 'Tu mente está lista. Tu tarea de enfoque actual es "${focusTask.title}". Inicia una sesión de Modo Foco de 25 minutos para lograr tu máximo rendimiento. ⏱️';
    } else if (activeTasks == 0) {
      return '¡Increíble! No tienes tareas pendientes. Tu mente está completamente despejada. Excelente momento para capturar nuevas notas creativas o planificar un gran proyecto. ✨';
    } else {
      return 'Todo fluye según lo planeado. Tienes $activeTasks tareas activas y $activeProjects proyectos en marcha. Recuerda tomar descansos regulares para mantener tu rendimiento. 💡';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer5<TasksProvider, ProjectsProvider, NotesProvider,
        GoalsProvider, DashboardProvider>(
      builder: (context, tasks, projects, notes, goals, dashboard, _) {
        final today = DateTime.now();
        final alerts = dashboard.alerts;

        // Calculo de productividad del dia (hoy)
        final todayTasks = tasks.tasks.where((t) {
          final d = t.dueDate;
          return d != null &&
              d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
        }).toList();

        final completedToday =
            todayTasks.where((t) => t.status == TaskStatus.completed).length;
        final totalToday = todayTasks.length;
        final todayProgress =
            totalToday == 0 ? 0.0 : (completedToday / totalToday);

        // Filtrar tareas del dia seleccionado en el calendario
        final selectedDateTasks = tasks.tasks.where((t) {
          final d = t.dueDate;
          return d != null && _isSameDay(d, _selectedDate);
        }).toList();

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

        return SingleChildScrollView(
          padding: ResponsiveHelper.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER: INTELLIGENT GREETING & RADIAL PROGRESS RING
              _buildMindGreetingHeader(
                  context, todayProgress, completedToday, totalToday),

              const SizedBox(height: 24),

              // 2. CALENDAR WEEK RIBBON (INTERACTIVE)
              _buildCalendarWeekRibbon(tasks),

              const SizedBox(height: 24),

              // 3. SMART ATASCOS / QUICK HUB CAROUSEL
              _buildQuickActionsHub(context),

              const SizedBox(height: 24),

              // 4. INTELLIGENT SGI ADVISOR
              _buildSgiAdvisorCard(tasks, projects, goals, notes, alerts),

              const SizedBox(height: 32),

              // 5. PREMIUM REDESIGNED STATS GRID
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

              const SizedBox(height: 32),

              // 6. DAILY AGENDA / CHECKLIST FOR SELECTED DATE
              _buildDailyAgendaChecklist(selectedDateTasks, tasks, context),

              // Focus tasks section if any
              if (tasks.focusTasks.isNotEmpty) ...[
                const SizedBox(height: 32),
                _SectionHeader(
                  title: 'Modo foco',
                  icon: Icons.center_focus_strong,
                  color: BrainTheme.accentOrange,
                  count: tasks.focusTasks.length,
                  actionLabel: 'Abrir',
                  onAction: () => Navigator.pushNamed(context, '/focus'),
                ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                const SizedBox(height: 12),
                ...tasks.focusTasks.take(3).map(
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

              // Overdue section if any
              if (tasks.overdueTasks.isNotEmpty) ...[
                const SizedBox(height: 32),
                _SectionHeader(
                  title: 'Vencidas',
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
        );
      },
    );
  }

  // WIDGET: Mind Greeting Header
  Widget _buildMindGreetingHeader(
    BuildContext context,
    double todayProgress,
    int completedToday,
    int totalToday,
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
      child: Row(
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
                const SizedBox(height: 8),
                Text(
                  'Tu mapa mental operativo e inteligente.',
                  style: TextStyle(
                    fontSize: 13,
                    color: BrainTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Circular Progress Radial
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: BrainTheme.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: todayProgress,
                  strokeWidth: 6,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: BrainTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '$completedToday/$totalToday',
                      style: TextStyle(
                        fontSize: 9,
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
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, end: 0, curve: Curves.easeOut);
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
                        'Hoy',
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

  // WIDGET: Quick Actions Hub
  Widget _buildQuickActionsHub(BuildContext context) {
    final actions = [
      (
        title: 'Capturar',
        icon: Icons.flash_on,
        color: BrainTheme.accentPurple,
        onTap: () => _showQuickTaskDialog(context)
      ),
      (
        title: 'Nueva Nota',
        icon: Icons.sticky_note_2_outlined,
        color: BrainTheme.accentCyan,
        onTap: () => Navigator.pushNamed(context, '/note')
      ),
      (
        title: 'Nuevo Proyecto',
        icon: Icons.folder_open_outlined,
        color: BrainTheme.accentGreen,
        onTap: () => Navigator.pushNamed(context, '/project')
      ),
      (
        title: 'Modo Foco',
        icon: Icons.center_focus_strong,
        color: BrainTheme.accentOrange,
        onTap: () => Navigator.pushNamed(context, '/focus')
      ),
      (
        title: 'Objetivo',
        icon: Icons.track_changes_outlined,
        color: BrainTheme.accentPink,
        onTap: () => Navigator.pushNamed(context, '/goal')
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bolt_outlined, color: BrainTheme.accentOrange, size: 18),
            SizedBox(width: 8),
            Text(
              'Atajos Rápidos',
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
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final action = actions[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: action.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: BrainTheme.cardDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: action.color.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: action.color.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(action.icon,
                                size: 14, color: action.color),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            action.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: BrainTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOut);
  }

  // WIDGET: Sgi Advisor Card
  Widget _buildSgiAdvisorCard(
    TasksProvider tasks,
    ProjectsProvider projects,
    GoalsProvider goals,
    NotesProvider notes,
    List<SmartAlert> alerts,
  ) {
    final alertWidget = alerts.isNotEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...alerts.take(2).map((alert) {
                final severityColor = switch (alert.severity) {
                  SmartAlertSeverity.info => BrainTheme.accentBlue,
                  SmartAlertSeverity.warning => BrainTheme.accentOrange,
                  SmartAlertSeverity.danger => BrainTheme.accentRed,
                };
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: severityColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 8, color: severityColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alert.title + ': ' + alert.message,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: BrainTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          )
        : null;

    final advisorText = _generateAdvisorText(
      tasks: tasks,
      projects: projects,
      goals: goals,
      notes: notes,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: BrainTheme.accentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.psychology,
                    size: 20, color: BrainTheme.accentPurple),
              ),
              const SizedBox(width: 12),
              Text(
                'Inteligencia SGI',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.3,
                  color: BrainTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advisorText,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: BrainTheme.textSecondary,
            ),
          ),
          if (alertWidget != null) ...[
            const SizedBox(height: 12),
            Divider(color: BrainTheme.borderDark),
            const SizedBox(height: 8),
            alertWidget,
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 550.ms)
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
              'Métricas Generales',
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
              title: 'Tareas',
              value: '$activeTasksCount',
              icon: Icons.checklist_rounded,
              color: BrainTheme.accentBlue,
              subtitle: 'pendientes',
              progress: tasksProgressVal,
              progressLabel: 'Completado: ${(tasksProgressVal * 100).toInt()}%',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      elevation: 0,
                      backgroundColor:
                          BrainTheme.primaryDark.withValues(alpha: 0.95),
                      title: const Text('Tareas'),
                    ),
                    body: const TasksScreen(),
                  ),
                ),
              ),
            ),
            _PremiumStatsCard(
              title: 'Proyectos',
              value: '$activeProjectsCount',
              icon: Icons.folder_open_outlined,
              color: BrainTheme.accentGreen,
              subtitle: 'activos',
              progress: projectsProgressVal,
              progressLabel:
                  'Finalizados: ${projects.completedProjects.length}/${projects.projects.length}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      elevation: 0,
                      backgroundColor:
                          BrainTheme.primaryDark.withValues(alpha: 0.95),
                      title: const Text('Proyectos'),
                    ),
                    body: const ProjectsScreen(),
                  ),
                ),
              ),
            ),
            _PremiumStatsCard(
              title: 'Objetivos',
              value: '$activeGoalsCount',
              icon: Icons.track_changes_outlined,
              color: BrainTheme.accentPurple,
              subtitle: 'vigentes',
              progress: averageGoalProgress,
              progressLabel:
                  'Progreso medio: ${(averageGoalProgress * 100).toInt()}%',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      elevation: 0,
                      backgroundColor:
                          BrainTheme.primaryDark.withValues(alpha: 0.95),
                      title: const Text('Objetivos'),
                    ),
                    body: const GoalsScreen(),
                  ),
                ),
              ),
            ),
            _PremiumStatsCard(
              title: 'Notas',
              value: '$totalNotesCount',
              icon: Icons.sticky_note_2_outlined,
              color: BrainTheme.accentCyan,
              subtitle: 'recientes',
              progress: notes.notes.isEmpty ? 0.0 : 1.0,
              progressLabel: 'En $notesNotebooksCount cuadernos',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(
                      elevation: 0,
                      backgroundColor:
                          BrainTheme.primaryDark.withValues(alpha: 0.95),
                      title: const Text('Notas'),
                    ),
                    body: const NotesScreen(),
                  ),
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

  // WIDGET: Daily Agenda / Checklist
  Widget _buildDailyAgendaChecklist(
    List<Task> selectedDateTasks,
    TasksProvider tasksProvider,
    BuildContext context,
  ) {
    final dateString = _isSameDay(_selectedDate, DateTime.now())
        ? 'Hoy'
        : '${_getDayNameAbbr(_selectedDate)} ${_selectedDate.day}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.playlist_add_check_rounded,
                color: BrainTheme.accentBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              'Agenda para $dateString',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: BrainTheme.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Text(
              '${selectedDateTasks.where((t) => t.status == TaskStatus.completed).length}/${selectedDateTasks.length}',
              style: TextStyle(
                fontSize: 12,
                color: BrainTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (selectedDateTasks.isEmpty)
          Container(
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
                Icon(
                  Icons.calendar_today_outlined,
                  size: 32,
                  color: BrainTheme.textTertiary.withValues(alpha: 0.3),
                ),
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
                  onPressed: () {
                    Navigator.pushNamed(context, '/task');
                  },
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text('Programar Tarea'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        BrainTheme.accentBlue.withValues(alpha: 0.15),
                    foregroundColor: BrainTheme.accentBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    textStyle: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.bold),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOut)
        else
          Column(
            children: selectedDateTasks.map((task) {
              return TaskCard(
                task: task,
                onTap: () => Navigator.pushNamed(
                  context,
                  '/task',
                  arguments: task.id,
                ),
                onToggle: () => tasksProvider.toggleTaskStatus(task.id),
              );
            }).toList(),
          ),
      ],
    );
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
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    this.count,
    this.actionLabel,
    this.onAction,
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
        const Spacer(),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: color,
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}
