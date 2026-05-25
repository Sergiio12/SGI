import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/haptic_helper.dart';

enum PomodoroState { idle, working, breakTime, paused }

class PomodoroTimer extends StatefulWidget {
  final int workMinutes;
  final int breakMinutes;
  final int longBreakMinutes;
  final int sessionsUntilLongBreak;
  final VoidCallback? onSessionComplete;

  const PomodoroTimer({
    super.key,
    this.workMinutes = 25,
    this.breakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsUntilLongBreak = 4,
    this.onSessionComplete,
  });

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> with WidgetsBindingObserver {
  PomodoroState _state = PomodoroState.idle;
  int _secondsRemaining = 25 * 60;
  int _totalSeconds = 25 * 60;
  int _completedSessions = 0;
  Timer? _timer;
  DateTime? _sessionStart;
  int _elapsedBeforePause = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _state == PomodoroState.working) {
      _pause();
    }
  }

  void _startTimer() {
    _state = PomodoroState.working;
    _totalSeconds = widget.workMinutes * 60;
    _secondsRemaining = _totalSeconds;
    _elapsedBeforePause = 0;
    _sessionStart = DateTime.now();
    _tick();
  }

  void _tick() {
    _timer?.cancel();
    _sessionStart = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionStart == null) return;
      final elapsed = DateTime.now().difference(_sessionStart!).inSeconds + _elapsedBeforePause;
      final remaining = _totalSeconds - elapsed;
      if (remaining <= 0) {
        timer.cancel();
        _onTimerComplete();
        return;
      }
      setState(() => _secondsRemaining = remaining);
    });
  }

  void _onTimerComplete() {
    HapticHelper.heavy();
    HapticHelper.heavy();
    if (_state == PomodoroState.working) {
      _completedSessions++;
      widget.onSessionComplete?.call();
      final isLongBreak = _completedSessions % widget.sessionsUntilLongBreak == 0;
      final breakMinutes = isLongBreak ? widget.longBreakMinutes : widget.breakMinutes;
      setState(() {
        _state = PomodoroState.breakTime;
        _totalSeconds = breakMinutes * 60;
        _secondsRemaining = _totalSeconds;
        _elapsedBeforePause = 0;
      });
      _tick();
    } else {
      setState(() => _state = PomodoroState.idle);
    }
  }

  void _pause() {
    _timer?.cancel();
    _elapsedBeforePause = _totalSeconds - _secondsRemaining;
    _sessionStart = null;
    setState(() => _state = PomodoroState.paused);
  }

  void _resume() {
    setState(() => _state = PomodoroState.working);
    _tick();
  }

  void _reset() {
    _timer?.cancel();
    _sessionStart = null;
    _elapsedBeforePause = 0;
    setState(() {
      _state = PomodoroState.idle;
      _secondsRemaining = widget.workMinutes * 60;
      _totalSeconds = widget.workMinutes * 60;
    });
  }

  void _skipBreak() {
    _timer?.cancel();
    _sessionStart = null;
    _elapsedBeforePause = 0;
    HapticHelper.medium();
    setState(() => _state = PomodoroState.idle);
  }

  String get _formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress => _totalSeconds > 0 ? _secondsRemaining / _totalSeconds : 0;

  String _getStateLabel(AppLocalizations l10n) {
    switch (_state) {
      case PomodoroState.idle:
        return l10n.pomodoroIdle;
      case PomodoroState.working:
        return l10n.pomodoroWork;
      case PomodoroState.breakTime:
        final isLong = _totalSeconds == widget.longBreakMinutes * 60;
        return isLong ? l10n.pomodoroLongBreak : l10n.pomodoroBreak;
      case PomodoroState.paused:
        return l10n.pomodoroPaused;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isWorking = _state == PomodoroState.working;
    final accentColor = isWorking ? BrainTheme.accentOf(context) : BrainTheme.accentGreen;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: BrainTheme.borderDark.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.timer_rounded, size: 18, color: accentColor),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
                child: Text(_getStateLabel(l10n)),
              ),
              const Spacer(),
              Text(
                '${_completedSessions} ${l10n.pomodoroSessions}',
                style: TextStyle(fontSize: 12, color: BrainTheme.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, value, _) => SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      backgroundColor: BrainTheme.borderDark.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation(accentColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formattedTime,
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w700,
                        color: BrainTheme.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(fontSize: 12, color: BrainTheme.textTertiary),
                      child: Text(
                        isWorking ? l10n.pomodoroWorkLabel : l10n.pomodoroBreakLabel,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildControls(l10n),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildControls(AppLocalizations l10n) {
    switch (_state) {
      case PomodoroState.idle:
        return [
          _ControlButton(
            icon: Icons.play_arrow_rounded,
            label: l10n.pomodoroStart,
            color: BrainTheme.accentGreen,
            onTap: _startTimer,
          ),
        ];
      case PomodoroState.working:
      case PomodoroState.breakTime:
        return [
          _ControlButton(
            icon: Icons.pause_rounded,
            label: l10n.pomodoroPause,
            color: BrainTheme.accentOrange,
            onTap: _pause,
          ),
          const SizedBox(width: 12),
          _ControlButton(
            icon: Icons.stop_rounded,
            label: l10n.pomodoroStop,
            color: BrainTheme.accentRed,
            onTap: _reset,
          ),
          if (_state == PomodoroState.breakTime) ...[
            const SizedBox(width: 12),
            _ControlButton(
              icon: Icons.skip_next_rounded,
              label: l10n.pomodoroSkip,
              color: BrainTheme.accentBlue,
              onTap: _skipBreak,
            ),
          ],
        ];
      case PomodoroState.paused:
        return [
          _ControlButton(
            icon: Icons.play_arrow_rounded,
            label: l10n.pomodoroResume,
            color: BrainTheme.accentGreen,
            onTap: _resume,
          ),
          const SizedBox(width: 12),
          _ControlButton(
            icon: Icons.stop_rounded,
            label: l10n.pomodoroStop,
            color: BrainTheme.accentRed,
            onTap: _reset,
          ),
        ];
    }
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
