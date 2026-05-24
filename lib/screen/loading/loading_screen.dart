import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';

import '../../providers/daily_planner_provider.dart';
import '../../providers/goals_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/trash_provider.dart';
import '../home_screen.dart';

import '../../services/notification_service.dart';
import '../../services/persistent_backup_service.dart';
import '../../services/interfaces/storage_service_interface.dart';

import '../../widgets/loading_animation.dart';
import '../../widgets/loading_glow_orb.dart';
import '../../widgets/loading_progress_footer.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen>
    with SingleTickerProviderStateMixin {
  // =========================================================
  // PROGRESO REAL
  // =========================================================

  double _targetProgress = 0;
  double _displayProgress = 0;

  String _statusText = '';

  late final AnimationController _orbitalController;

  Timer? _progressTimer;

  final List<_InitStep> _steps = [];

  @override
  void initState() {
    super.initState();

    _orbitalController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });

    _startSmoothProgressAnimation();
  }

  @override
  void dispose() {
    _orbitalController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  // =========================================================
  // ANIMACIÓN SUAVE DE PROGRESO
  // =========================================================

  void _startSmoothProgressAnimation() {
    _progressTimer = Timer.periodic(
      const Duration(milliseconds: 16),
      (_) {
        if (!mounted) return;

        setState(() {
          _displayProgress += (_targetProgress - _displayProgress) * 0.08;
        });
      },
    );
  }

  void _updateProgress(
    double value,
    String status,
  ) {
    _targetProgress = value;

    if (mounted) {
      setState(() {
        _statusText = status;
      });
    }
  }

  // =========================================================
  // INICIALIZACIÓN
  // =========================================================

  Future<void> _initialize() async {
    final stopwatch = Stopwatch()..start();

    try {
      final tasksProvider = context.read<TasksProvider>();
      final projectsProvider = context.read<ProjectsProvider>();
      final notesProvider = context.read<NotesProvider>();
      final goalsProvider = context.read<GoalsProvider>();

      final l10n = AppLocalizations.of(context);
      _steps.addAll([
        _InitStep(
          progress: 0.12,
          label: l10n.loadingInitStorage,
          action: () async {
            await context.read<IStorageService>().init();
          },
        ),
        _InitStep(
          progress: 0.20,
          label: l10n.loadingRestore,
          action: () async {
            await PersistentBackupService.tryRestore(
              context.read<IStorageService>(),
            );
          },
        ),
        _InitStep(
          progress: 0.28,
          label: l10n.loadingTasks,
          action: () async {
            await tasksProvider.loadTasks();
          },
        ),
        _InitStep(
          progress: 0.45,
          label: l10n.loadingProjects,
          action: () async {
            await projectsProvider.loadProjects();
          },
        ),
        _InitStep(
          progress: 0.64,
          label: l10n.loadingVisual,
          action: () async {
            await Future.delayed(
              const Duration(milliseconds: 350),
            );
          },
        ),
        _InitStep(
          progress: 0.82,
          label: l10n.loadingReady,
          action: () async {
            await Future.delayed(
              const Duration(milliseconds: 250),
            );
          },
        ),
      ]);

      for (final step in _steps) {
        _updateProgress(
          step.progress,
          step.label,
        );

        await step.action();
      }

      // =====================================================
      // CARGA EN BACKGROUND
      // =====================================================

      unawaited(
        _loadSecondaryData(
          notesProvider,
          goalsProvider,
          tasksProvider,
        ),
      );

      // =====================================================
      // FINAL
      // =====================================================

      _updateProgress(
        0.92,
        l10n.loadingSession,
      );

      // Tiempo visual mínimo
      final elapsed = stopwatch.elapsedMilliseconds;

      if (elapsed < 2200) {
        await Future.delayed(
          Duration(milliseconds: 2200 - elapsed),
        );
      }

      _updateProgress(
        1.0,
        l10n.loadingReady,
      );

      await Future.delayed(
        const Duration(milliseconds: 450),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          transitionsBuilder: (_, animation, __, child) {
            return Stack(
              children: [
                FadeTransition(
                  opacity: Tween<double>(begin: 1, end: 0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0, 0.4, curve: Curves.easeOut),
                    ),
                  ),
                  child: const SizedBox(),
                ),
                FadeTransition(
                  opacity: Tween<double>(begin: 0, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: const Interval(0.2, 1, curve: Curves.easeOut),
                    ),
                  ),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 1.05, end: 1).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: const Interval(0.2, 1, curve: Curves.easeOutCubic),
                      ),
                    ),
                    child: child,
                  ),
                ),
              ],
            );
          },
        ),
      );
    } catch (e) {
      _updateProgress(
        1,
        'Error durante la inicialización',
      );

      debugPrint(e.toString());
    }
  }

  Future<void> _loadSecondaryData(
    NotesProvider notesProvider,
    GoalsProvider goalsProvider,
    TasksProvider tasksProvider,
  ) async {
    try {
      final settings = context.read<SettingsProvider>();
      NotificationService.configure(
        notificationsEnabled: settings.notificationsEnabled,
        remind24h: settings.remind24h,
        remind1h: settings.remind1h,
        defaultReminderMinutes: settings.defaultReminderMinutes,
        quietHoursEnabled: settings.quietHoursEnabled,
        quietStartHour: settings.quietStartHour,
        quietStartMinute: settings.quietStartMinute,
        quietEndHour: settings.quietEndHour,
        quietEndMinute: settings.quietEndMinute,
      );

      await Future.wait([
        notesProvider.loadNotes(),
        goalsProvider.loadGoals(),
        context.read<TrashProvider>().loadTrash(),
      ]);

      await NotificationService.rescheduleAll(
        tasksProvider.tasks,
      );

      await context.read<DailyPlannerProvider>().load();

      unawaited(
        PersistentBackupService.saveSnapshot(
          tasks: tasksProvider.tasks,
          projects: context.read<ProjectsProvider>().projects,
          notes: notesProvider.notes,
          goals: goalsProvider.goals,
        ),
      );
    } catch (_) {}
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          // =================================================
          // BACKGROUND
          // =================================================

          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF111827),
                    Color(0xFF09090B),
                  ],
                ),
              ),
            ),
          ),

          // Glow superior animado
          Positioned(
            top: -180,
            left: -120,
            child: LoadingGlowOrb(
              size: 320,
              color: BrainTheme.accentPurple.withValues(
                alpha: 0.16,
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.15, 1.15),
                  duration: 8.seconds,
                  curve: Curves.easeInOut,
                )
                .fade(
                  begin: 0.7,
                  end: 1.0,
                  duration: 8.seconds,
                  curve: Curves.easeInOut,
                ),
          ),

          // Glow inferior animado
          Positioned(
            bottom: -220,
            right: -180,
            child: LoadingGlowOrb(
              size: 420,
              color: BrainTheme.accentBlue.withValues(
                alpha: 0.12,
              ),
            )
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.12, 1.12),
                  duration: 10.seconds,
                  curve: Curves.easeInOut,
                )
                .fade(
                  begin: 0.6,
                  end: 1.0,
                  duration: 10.seconds,
                  curve: Curves.easeInOut,
                ),
          ),

          // =================================================
          // CONTENIDO
          // =================================================

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 28,
              ),
              child: Column(
                children: [
                  // =========================================
                  // HEADER
                  // =========================================

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(
                            alpha: 0.04,
                          ),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: 0.06,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: BrainTheme.accentPurple,
                                borderRadius: BorderRadius.circular(
                                  100,
                                ),
                              ),
                            )
                                .animate(
                                  onPlay: (controller) => controller.repeat(
                                    reverse: true,
                                  ),
                                )
                                .fade(
                                  begin: 0.35,
                                  end: 1,
                                  duration: 1200.ms,
                                ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context).loadingInit,
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'v1.0.1-beta',
                        style: GoogleFonts.inter(
                          color: Colors.white.withValues(
                            alpha: 0.3,
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  // =========================================
                  // CENTRO
                  // =========================================

                  Expanded(
                    child: LoadingAnimation(
                      controller: _orbitalController,
                      progress: _displayProgress,
                    ),
                  ),

                  // =========================================
                  // FOOTER
                  // =========================================

                  LoadingProgressFooter(
                    progress: _displayProgress,
                    statusText: _statusText,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ===========================================================
// STEP MODEL
// ===========================================================

class _InitStep {
  final double progress;
  final String label;
  final Future<void> Function() action;

  _InitStep({
    required this.progress,
    required this.label,
    required this.action,
  });
}
