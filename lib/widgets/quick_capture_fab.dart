import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/haptic_helper.dart';

class QuickCaptureFAB extends StatefulWidget {
  final Function(String type) onCapture;

  const QuickCaptureFAB({super.key, required this.onCapture});

  @override
  State<QuickCaptureFAB> createState() => _QuickCaptureFABState();
}

class _QuickCaptureFABState extends State<QuickCaptureFAB> {
  bool _isOpen = false;

  void _toggle() {
    HapticHelper.light();
    setState(() => _isOpen = !_isOpen);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isOpen) ...[
            _MiniFAB(
              icon: Icons.note_add_outlined,
              label: AppLocalizations.of(context).note,
              color: BrainTheme.accentGreen,
              onTap: () {
                HapticHelper.medium();
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
                HapticHelper.medium();
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
                HapticHelper.medium();
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
                HapticHelper.medium();
                _toggle();
                widget.onCapture('goal');
              },
            ),
            const SizedBox(height: 14),
          ],
          Semantics(
            label: AppLocalizations.of(context).quickCapture,
            button: true,
            child: FloatingActionButton(
              onPressed: _toggle,
              backgroundColor: BrainTheme.accentPurple.withValues(alpha: 0.9),
              elevation: 4,
              child: AnimatedRotation(
                turns: _isOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.add, size: 24),
              ),
            ),
          ),
        ],
      ),
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
    return Semantics(
      label: label,
      button: true,
      child: Row(
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
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onPressed: onTap,
            child: Icon(icon, size: 18),
          ),
        ],
      )
          .animate()
          .fade(duration: 200.ms)
          .slideX(begin: 0.5, end: 0, curve: Curves.easeOut),
    );
  }
}
