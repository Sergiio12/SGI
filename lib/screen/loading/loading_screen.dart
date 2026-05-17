import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';

import '../../providers/goals_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/trash_provider.dart';

import '../../services/notification_service.dart';
import '../../services/storage_service.dart';

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

  String _statusText = 'Inicializando sistema';

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

      _steps.addAll([
        _InitStep(
          progress: 0.12,
          label: 'Inicializando almacenamiento seguro',
          action: () async {
            await StorageService.init();
          },
        ),
        _InitStep(
          progress: 0.28,
          label: 'Cargando tareas prioritarias',
          action: () async {
            await tasksProvider.loadTasks();
          },
        ),
        _InitStep(
          progress: 0.45,
          label: 'Reconstruyendo proyectos',
          action: () async {
            await projectsProvider.loadProjects();
          },
        ),
        _InitStep(
          progress: 0.64,
          label: 'Preparando entorno visual',
          action: () async {
            await Future.delayed(
              const Duration(milliseconds: 350),
            );
          },
        ),
        _InitStep(
          progress: 0.82,
          label: 'Optimizando experiencia',
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
        'Sincronizando sesión',
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
        'Todo listo',
      );

      await Future.delayed(
        const Duration(milliseconds: 450),
      );

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.home,
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
      await Future.wait([
        notesProvider.loadNotes(),
        goalsProvider.loadGoals(),
        context.read<TrashProvider>().loadTrash(),
        NotificationService.init(),
      ]);

      await NotificationService.rescheduleAll(
        tasksProvider.tasks,
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
            child: _GlowOrb(
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
            child: _GlowOrb(
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
                              'Inicializando',
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
                    child: Center(
                      child: SizedBox(
                        width: 240,
                        height: 240,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Órbita exterior con partícula brillante que viaja
                            RotationTransition(
                              turns: _orbitalController,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 230,
                                    height: 230,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.04,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Partícula brillante en órbita
                                  Positioned(
                                    top: 0,
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: BrainTheme.accentBlue,
                                        boxShadow: [
                                          BoxShadow(
                                            color: BrainTheme.accentBlue,
                                            blurRadius: 6,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Órbita media con partícula girando en sentido inverso
                            RotationTransition(
                              turns: Tween<double>(
                                begin: 0,
                                end: -1,
                              ).animate(
                                CurvedAnimation(
                                  parent: _orbitalController,
                                  curve: Curves.linear,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 180,
                                    height: 180,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: BrainTheme.accentPurple.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Partícula brillante en órbita interna
                                  Positioned(
                                    bottom: 0,
                                    child: Container(
                                      width: 5,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: BrainTheme.accentPurple,
                                        boxShadow: [
                                          BoxShadow(
                                            color: BrainTheme.accentPurple,
                                            blurRadius: 5,
                                            spreadRadius: 1.5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // CARD CENTRAL - Glassmorphism con halo reactivo dinámico
                            ClipRRect(
                              borderRadius: BorderRadius.circular(34),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  width: 118,
                                  height: 118,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(34),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white.withValues(
                                          alpha: 0.07,
                                        ),
                                        Colors.white.withValues(
                                          alpha: 0.02,
                                        ),
                                      ],
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color.lerp(
                                          BrainTheme.accentPurple,
                                          BrainTheme.accentBlue,
                                          _displayProgress.clamp(0.0, 1.0),
                                        )!.withValues(alpha: 0.22),
                                        blurRadius: 40 + (10 * _displayProgress),
                                        spreadRadius: 1 + _displayProgress,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/app_icon.png',
                                  ),
                                ),
                              ),
                            )
                                .animate(
                                  onPlay: (controller) => controller.repeat(
                                    reverse: true,
                                  ),
                                )
                                .scale(
                                  begin: const Offset(1, 1),
                                  end: const Offset(
                                    1.03,
                                    1.03,
                                  ),
                                  duration: 2000.ms,
                                  curve: Curves.easeInOut,
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // =========================================
                  // FOOTER
                  // =========================================

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Estado
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: Text(
                          _statusText,
                          key: ValueKey(_statusText),
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Barra
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(
                              alpha: 0.06,
                            ),
                          ),
                          child: Stack(
                            children: [
                              FractionallySizedBox(
                                widthFactor: _displayProgress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        BrainTheme.accentPurple,
                                        BrainTheme.accentBlue,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            BrainTheme.accentPurple.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Info inferior
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(_displayProgress * 100).toInt()}%',
                            style: GoogleFonts.inter(
                              color: BrainTheme.accentPurple,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            _estimatedTime(),
                            style: GoogleFonts.inter(
                              color: Colors.white.withValues(
                                alpha: 0.35,
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          'Creado por Sergio Asensio',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(
                              alpha: 0.25,
                            ),
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  )
                      .animate()
                      .fadeIn(
                        delay: 300.ms,
                        duration: 700.ms,
                      )
                      .slideY(
                        begin: 0.15,
                        end: 0,
                        curve: Curves.easeOutCubic,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _estimatedTime() {
    final remaining = max(0, ((1 - _displayProgress) * 3).ceil());

    if (remaining <= 1) {
      return 'Casi listo';
    }

    return '~${remaining}s';
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

// ===========================================================
// GLOW
// ===========================================================

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
