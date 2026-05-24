import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

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

class _PomodoroTimerState extends State<PomodoroTimer> {
  PomodoroState _state = PomodoroState.idle;
  int _secondsRemaining = 25 * 60;
  int _totalSeconds = 25 * 60;
  int _completedSessions = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _state = PomodoroState.working;
    _totalSeconds = widget.workMinutes * 60;
    _secondsRemaining = _totalSeconds;
    _tick();
  }

  void _tick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        _onTimerComplete();
        return;
      }
      setState(() => _secondsRemaining--);
    });
  }

  void _onTimerComplete() {
    if (_state == PomodoroState.working) {
      _completedSessions++;
      widget.onSessionComplete?.call();
      final isLongBreak = _completedSessions % widget.sessionsUntilLongBreak == 0;
      final breakMinutes = isLongBreak ? widget.longBreakMinutes : widget.breakMinutes;
      setState(() {
        _state = PomodoroState.breakTime;
        _totalSeconds = breakMinutes * 60;
        _secondsRemaining = _totalSeconds;
      });
      _tick();
    } else {
      setState(() => _state = PomodoroState.idle);
    }
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _state = PomodoroState.paused);
  }

  void _resume() {
    setState(() => _state = PomodoroState.working);
    _tick();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _state = PomodoroState.idle;
      _secondsRemaining = widget.workMinutes * 60;
      _totalSeconds = widget.workMinutes * 60;
    });
  }

  void _skipBreak() {
    _timer?.cancel();
    setState(() => _state = PomodoroState.idle);
  }

  String get _formattedTime {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _progress => _totalSeconds > 0 ? _secondsRemaining / _totalSeconds : 0;

  String get _stateLabel {
    switch (_state) {
      case PomodoroState.idle:
        return 'Preparado';
      case PomodoroState.working:
        return 'Enfoque';
      case PomodoroState.breakTime:
        final isLong = _totalSeconds == widget.longBreakMinutes * 60;
        return isLong ? 'Descanso largo' : 'Descanso';
      case PomodoroState.paused:
        return 'Pausado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWorking = _state == PomodoroState.working;
    final accentColor = isWorking ? BrainTheme.accentPurple : BrainTheme.accentGreen;

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
              Text(
                _stateLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor,
                ),
              ),
              const Spacer(),
              Text(
                '${_completedSessions} sesiones',
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
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 6,
                    backgroundColor: BrainTheme.borderDark.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation(accentColor),
                    strokeCap: StrokeCap.round,
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
                    Text(
                      _state == PomodoroState.working ? 'trabajo' : 'descanso',
                      style: TextStyle(fontSize: 12, color: BrainTheme.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildControls(),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildControls() {
    switch (_state) {
      case PomodoroState.idle:
        return [
          _ControlButton(
            icon: Icons.play_arrow_rounded,
            label: 'Comenzar',
            color: BrainTheme.accentGreen,
            onTap: _startTimer,
          ),
        ];
      case PomodoroState.working:
      case PomodoroState.breakTime:
        return [
          _ControlButton(
            icon: Icons.pause_rounded,
            label: 'Pausar',
            color: BrainTheme.accentOrange,
            onTap: _pause,
          ),
          const SizedBox(width: 12),
          _ControlButton(
            icon: Icons.stop_rounded,
            label: 'Detener',
            color: BrainTheme.accentRed,
            onTap: _reset,
          ),
          if (_state == PomodoroState.breakTime) ...[
            const SizedBox(width: 12),
            _ControlButton(
              icon: Icons.skip_next_rounded,
              label: 'Saltar',
              color: BrainTheme.accentBlue,
              onTap: _skipBreak,
            ),
          ],
        ];
      case PomodoroState.paused:
        return [
          _ControlButton(
            icon: Icons.play_arrow_rounded,
            label: 'Reanudar',
            color: BrainTheme.accentGreen,
            onTap: _resume,
          ),
          const SizedBox(width: 12),
          _ControlButton(
            icon: Icons.stop_rounded,
            label: 'Detener',
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
