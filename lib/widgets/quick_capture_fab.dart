import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';

class QuickCaptureFAB extends StatefulWidget {
  final Function(String type) onCapture;

  const QuickCaptureFAB({super.key, required this.onCapture});

  @override
  State<QuickCaptureFAB> createState() => _QuickCaptureFABState();
}

class _QuickCaptureFABState extends State<QuickCaptureFAB>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini FABs
        ScaleTransition(
          scale: _animation,
          alignment: Alignment.bottomRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _MiniFAB(
                icon: Icons.note_add_outlined,
                label: AppLocalizations.of(context).note,
                color: BrainTheme.accentGreen,
                onTap: () {
                  _toggle();
                  widget.onCapture('note');
                },
              ),
              const SizedBox(height: 10),
              _MiniFAB(
                icon: Icons.add_task,
                label: AppLocalizations.of(context).task,
                color: BrainTheme.accentBlue,
                onTap: () {
                  _toggle();
                  widget.onCapture('task');
                },
              ),
              const SizedBox(height: 10),
              _MiniFAB(
                icon: Icons.create_new_folder_outlined,
                label: AppLocalizations.of(context).project,
                color: BrainTheme.accentOrange,
                onTap: () {
                  _toggle();
                  widget.onCapture('project');
                },
              ),
              const SizedBox(height: 10),
              _MiniFAB(
                icon: Icons.track_changes_outlined,
                label: AppLocalizations.of(context).goal,
                color: BrainTheme.accentPurple,
                onTap: () {
                  _toggle();
                  widget.onCapture('goal');
                },
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),

        // Main FAB
        Semantics(
          label: AppLocalizations.of(context).quickCapture,
          button: true,
          child: FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: BrainTheme.accentPurple,
            child: AnimatedRotation(
              turns: _isOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 250),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniFAB extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniFAB({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: BrainTheme.surfaceDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: BrainTheme.glowShadow,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: BrainTheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton.small(
          heroTag: label,
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onPressed: onTap,
          child: Icon(icon, size: 20),
        ),
      ],
    )
        .animate()
        .fade(duration: 200.ms)
        .slideX(begin: 0.5, end: 0, curve: Curves.easeOut);
  }
}
