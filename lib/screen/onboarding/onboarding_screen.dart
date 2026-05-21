import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/theme.dart';

const _onboardingKey = 'onboarding_completed_v2';
const _kThemeMode = 'theme_mode';
const _kAccentColor = 'accent_color';
const _kUserName = 'user_name';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  static Future<bool> isNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_onboardingKey) ?? false);
  }

  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _bgController;
  int _currentPage = 0;

  final _nameController = TextEditingController();
  String _themeMode = 'dark';
  int _selectedAccent = 0;

  final _accentColors = [
    BrainTheme.accentPurple,
    BrainTheme.accentBlue,
    BrainTheme.accentGreen,
    BrainTheme.accentOrange,
    BrainTheme.accentRed,
    BrainTheme.accentPink,
    BrainTheme.accentCyan,
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1);
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: 400.ms,
        curve: Curves.easeOutCubic,
      );
    } else {
      _complete();
    }
  }

  Future<void> _complete() async {
    final prefs = await SharedPreferences.getInstance();
    final brightness = _themeMode == 'light'
        ? Brightness.light
        : _themeMode == 'system'
            ? WidgetsBinding.instance.platformDispatcher.platformBrightness
            : Brightness.dark;

    await prefs.setString(_kThemeMode, _themeMode);
    await prefs.setInt(
        _kAccentColor, _accentColors[_selectedAccent].toARGB32());
    if (_nameController.text.trim().isNotEmpty) {
      await prefs.setString(_kUserName, _nameController.text.trim());
    }
    await OnboardingScreen.markCompleted();

    BrainTheme.updateBrightness(brightness);
    BrainTheme.updateAccentColor(_accentColors[_selectedAccent]);
    widget.onComplete();
  }

  List<_OnboardingPage> get _pages => [
        _OnboardingPage(
          icon: Icons.psychology_rounded,
          title: 'Tu Segundo Cerebro',
          subtitle:
              'Organiza tus ideas, tareas, proyectos y metas en un solo lugar. Conéctalo todo y nunca pierdas el foco.',
          gradientColors: [
            BrainTheme.accentPurple,
            BrainTheme.accentBlue,
          ],
          particleColor: BrainTheme.accentPurple,
        ),
        _OnboardingPage(
          icon: Icons.checklist_rounded,
          title: 'Tareas Inteligentes',
          subtitle:
              'Crea tareas con prioridades, subtareas, fechas límite y recordatorios. Organízalas por proyecto y estado.',
          gradientColors: [
            BrainTheme.accentBlue,
            BrainTheme.accentCyan,
          ],
          particleColor: BrainTheme.accentBlue,
        ),
        _OnboardingPage(
          icon: Icons.track_changes_rounded,
          title: 'Metas y Proyectos',
          subtitle:
              'Define objetivos medibles con horizontes mensuales, trimestrales o anuales. Vincula proyectos y sigue tu progreso.',
          gradientColors: [
            BrainTheme.accentGreen,
            BrainTheme.accentCyan,
          ],
          particleColor: BrainTheme.accentGreen,
        ),
        _OnboardingPage(
          icon: Icons.sticky_note_2_rounded,
          title: 'Notas con Poder',
          subtitle:
              'Captura conocimientos con libretas, adjuntos, emojis y etiquetas. Búsqueda instantánea en todo tu contenido.',
          gradientColors: [
            BrainTheme.accentOrange,
            BrainTheme.accentPurple,
          ],
          particleColor: BrainTheme.accentOrange,
        ),
        _OnboardingPage(
          icon: Icons.palette_outlined,
          title: 'Personaliza tu Experiencia',
          subtitle: '',
          isLast: true,
          gradientColors: [
            BrainTheme.accentPurple,
            BrainTheme.accentPink,
          ],
          particleColor: BrainTheme.accentPurple,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return Positioned.fill(
                child: CustomPaint(
                  painter: _OnboardingBgPainter(
                    phase: _bgController.value,
                    accent: _accentColors[_selectedAccent],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) =>
                        _buildPage(_pages[index], index),
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SGI',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: -0.5,
            ),
          ),
          if (_currentPage < _pages.length - 1)
            GestureDetector(
              onTap: _complete,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Text(
                  'Saltar',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page, int index) {
    if (page.isLast) {
      return _buildLastPage(page);
    }
    return _buildStandardPage(page, index);
  }

  Widget _buildStandardPage(_OnboardingPage page, int index) {
    final isVisible = _currentPage == index;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          AnimatedContainer(
            duration: 600.ms,
            curve: Curves.easeOutBack,
            width: isVisible ? 140 : 100,
            height: isVisible ? 140 : 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: page.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: page.gradientColors[0].withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              page.icon,
              size: isVisible ? 60 : 44,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),
          AnimatedOpacity(
            opacity: isVisible ? 1 : 0,
            duration: 400.ms,
            child: AnimatedSlide(
              offset: isVisible ? Offset.zero : const Offset(0, 0.2),
              duration: 400.ms,
              curve: Curves.easeOut,
              child: Column(
                children: [
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    page.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }

  Widget _buildLastPage(_OnboardingPage page) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            AnimatedContainer(
              duration: 600.ms,
              curve: Curves.easeOutBack,
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: page.gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: page.gradientColors[0].withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.palette_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              'Personaliza tu Experiencia',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 36),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cómo te llamas?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tu nombre',
                      hintStyle: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    autofocus: true,
                  ),
                  const Divider(
                    color: Colors.white24,
                    height: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Color de acento',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_accentColors.length, (i) {
                      final isSelected = i == _selectedAccent;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedAccent = i),
                        child: AnimatedContainer(
                          duration: 250.ms,
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _accentColors[i],
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2.5)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _accentColors[i]
                                          .withValues(alpha: 0.5),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tema',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ThemeOption(
                        label: 'Claro',
                        icon: Icons.light_mode_outlined,
                        isSelected: _themeMode == 'light',
                        accentColor: _accentColors[_selectedAccent],
                        onTap: () => setState(() => _themeMode = 'light'),
                      ),
                      const SizedBox(width: 8),
                      _ThemeOption(
                        label: 'Oscuro',
                        icon: Icons.dark_mode_outlined,
                        isSelected: _themeMode == 'dark',
                        accentColor: _accentColors[_selectedAccent],
                        onTap: () => setState(() => _themeMode = 'dark'),
                      ),
                      const SizedBox(width: 8),
                      _ThemeOption(
                        label: 'Sistema',
                        icon: Icons.settings_brightness_outlined,
                        isSelected: _themeMode == 'system',
                        accentColor: _accentColors[_selectedAccent],
                        onTap: () => setState(() => _themeMode = 'system'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 32 : 8,
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: isActive
                      ? LinearGradient(
                          colors: [
                            _accentColors[_selectedAccent],
                            _accentColors[_selectedAccent]
                                .withValues(alpha: 0.5),
                          ],
                        )
                      : null,
                  color: isActive ? null : Colors.white.withValues(alpha: 0.15),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _nextPage,
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentColors[_selectedAccent],
                    _accentColors[_selectedAccent].withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                        _accentColors[_selectedAccent].withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _currentPage == _pages.length - 1 ? 'Comenzar' : 'Continuar',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? accentColor.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.08),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isSelected
                    ? accentColor
                    : Colors.white.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? accentColor
                      : Colors.white.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color particleColor;
  final bool isLast;

  _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.particleColor,
    this.isLast = false,
  });
}

class _OnboardingBgPainter extends CustomPainter {
  final double phase;
  final Color accent;

  _OnboardingBgPainter({required this.phase, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    for (int i = 0; i < 6; i++) {
      final angle = (i / 6) * 2 * pi + phase * 2 * pi;
      final x = size.width / 2 +
          cos(angle) * size.width * 0.35 +
          sin(phase * 2 * pi + i) * 30;
      final y = size.height / 2 +
          sin(angle) * size.height * 0.2 +
          cos(phase * 2 * pi + i * 1.5) * 20;

      paint.color = accent.withValues(
        alpha: 0.06 + 0.03 * sin(phase * 2 * pi + i * 1.2),
      );
      canvas.drawCircle(Offset(x, y), 80 + 20 * sin(phase * 2 * pi + i), paint);
    }
  }

  @override
  bool shouldRepaint(_OnboardingBgPainter old) => old.phase != phase;
}
