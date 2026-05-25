import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../config/theme.dart';

class LoadingProgressFooter extends StatelessWidget {
  final double progress;
  final String statusText;
  final String? estimatedTime;

  const LoadingProgressFooter({
    super.key,
    required this.progress,
    required this.statusText,
    this.estimatedTime,
  });

  String get _displayEstimatedTime {
    if (estimatedTime != null) return estimatedTime!;

    final remaining = max(0, ((1 - progress) * 3).ceil());

    if (remaining <= 1) {
      return 'Casi listo';
    }

    return '~${remaining}s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            statusText,
            key: ValueKey(statusText),
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BrainTheme.accentOf(context),
                          BrainTheme.accentBlue,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: BrainTheme.accentOf(context).withValues(alpha: 0.4),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.inter(
                color: BrainTheme.accentOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              _displayEstimatedTime,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.35),
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
              color: Colors.white.withValues(alpha: 0.25),
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
        );
  }
}
