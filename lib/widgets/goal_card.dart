import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/goal.dart';
import '../models/tag.dart';
import '../providers/tags_provider.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final int projectCount;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.goal,
    required this.projectCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(goal.colorValue);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      color: BrainTheme.cardDark,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(Icons.track_changes_rounded, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                            color: BrainTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: BrainTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _horizonLabel(goal.horizon),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: BrainTheme.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${(goal.progress * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (goal.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  goal.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: BrainTheme.textSecondary,
                  ),
                ),
              ],
              if (goal.tags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Consumer<TagsProvider>(builder: (context, tp, _) {
                  final tags = goal.tags
                      .map((id) => tp.getById(id))
                      .whereType<Tag>()
                      .take(3)
                      .toList();
                  if (tags.isEmpty) return const SizedBox.shrink();
                  return Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tag.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: tag.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                  );
                }),
              ],
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: goal.progress,
                  minHeight: 8,
                  backgroundColor: BrainTheme.borderDark,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.analytics_outlined,
                      size: 14, color: BrainTheme.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${goal.metricLabel}: ${_compact(goal.currentValue)} / ${_compact(goal.targetValue)}',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: BrainTheme.textTertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.folder_outlined,
                      size: 14, color: BrainTheme.textTertiary),
                  const SizedBox(width: 4),
                  Text(
                    '$projectCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: BrainTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  String _horizonLabel(GoalHorizon horizon) {
    switch (horizon) {
      case GoalHorizon.monthly:
        return 'Mensual';
      case GoalHorizon.quarterly:
        return 'Trimestral';
      case GoalHorizon.yearly:
        return 'Anual';
    }
  }

  String _compact(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}
