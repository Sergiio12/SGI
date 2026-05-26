import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';

import '../config/theme.dart';
import '../models/goal.dart';
import '../models/tag.dart';
import '../providers/tags_provider.dart';

class GoalCard extends StatelessWidget {
  final Goal goal;
  final int projectCount;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const GoalCard({
    super.key,
    required this.goal,
    required this.projectCount,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(goal.colorValue);

    return Slidable(
      endActionPane: onDelete != null
          ? ActionPane(
              motion: const BehindMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => onDelete?.call(),
                  backgroundColor: BrainTheme.accentRed,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline_rounded,
                  label: AppLocalizations.of(context).delete,
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            )
          : null,
      child: Semantics(
        label:
            '${goal.title}, ${(goal.progress * 100).toInt()}% ${AppLocalizations.of(context).goal}',
        child: Card(
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
            onLongPress: () => _showQuickActions(context),
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
                        child: Icon(
                          Icons.track_changes_rounded,
                          color: color,
                          size: 24,
                        ),
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
                            Row(
                              children: [
                                _buildBadge(
                                  _horizonLabel(context, goal.horizon),
                                  BrainTheme.surfaceDark,
                                  BrainTheme.textTertiary,
                                ),
                                if (goal.progress >= 1) ...[
                                  const SizedBox(width: 6),
                                  _buildBadge(
                                    AppLocalizations.of(context)
                                        .statusCompleted,
                                    BrainTheme.accentGreen
                                        .withValues(alpha: 0.15),
                                    BrainTheme.accentGreen,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: BrainTheme.cardDark,
                        surfaceTintColor: Colors.transparent,
                        icon: Icon(Icons.more_horiz,
                            color: BrainTheme.textTertiary),
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              Navigator.pushNamed(context, '/goal',
                                  arguments: goal.id);
                            case 'delete':
                              onDelete?.call();
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined,
                                    size: 18, color: BrainTheme.textSecondary),
                                const SizedBox(width: 10),
                                Text(AppLocalizations.of(context).editGoal,
                                    style: TextStyle(
                                        color: BrainTheme.textPrimary)),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: BrainTheme.accentRed),
                                const SizedBox(width: 10),
                                Text(AppLocalizations.of(context).delete,
                                    style:
                                        TextStyle(color: BrainTheme.accentRed)),
                              ],
                            ),
                          ),
                        ],
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
                        height: 1.4,
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
                      if (tags.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: tags
                            .map((tag) => Container(
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
                                ))
                            .toList(),
                      );
                    }),
                  ],
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: goal.progress),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: BrainTheme.borderDark,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
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
                      const SizedBox(width: 8),
                      Icon(Icons.folder_outlined,
                          size: 14, color: BrainTheme.textTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '$projectCount',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: BrainTheme.textTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.access_time,
                          size: 14, color: BrainTheme.textTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          _timeAgo(context, goal.updatedAt),
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: BrainTheme.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }

  Widget _buildBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: BrainTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BrainTheme.textTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                goal.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: BrainTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(goal.progress * 100).round()}% ${AppLocalizations.of(context).goalProgressCompleted}',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(goal.colorValue),
                ),
              ),
              const SizedBox(height: 8),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: goal.progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: BrainTheme.borderDark,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(Color(goal.colorValue)),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading:
                    Icon(Icons.edit_outlined, color: BrainTheme.textSecondary),
                title: Text(AppLocalizations.of(context).editGoal,
                    style: TextStyle(color: BrainTheme.textPrimary)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.pushNamed(context, '/goal', arguments: goal.id);
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.delete_outline, color: BrainTheme.accentRed),
                title: Text(AppLocalizations.of(context).delete,
                    style: TextStyle(color: BrainTheme.accentRed)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete?.call();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _horizonLabel(BuildContext context, GoalHorizon horizon) {
    final l10n = AppLocalizations.of(context);
    switch (horizon) {
      case GoalHorizon.monthly:
        return l10n.goalMonthly;
      case GoalHorizon.quarterly:
        return l10n.goalQuarterly;
      case GoalHorizon.yearly:
        return l10n.goalYearly;
    }
  }

  String _compact(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _timeAgo(BuildContext context, DateTime date) {
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 7) {
      return '${diff.inDays ~/ 7}sem';
    }
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return l10n.justNow;
  }
}
