import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/tasks_provider.dart';
import '../providers/trash_provider.dart';
import '../models/task.dart';

class NavigationSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const NavigationSidebar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tasks = context.watch<TasksProvider>();
    final trash = context.watch<TrashProvider>();

    final primaryItems = [
      _SidebarItemData(Icons.dashboard_outlined, l10n.navDashboard, 0),
      _SidebarItemData(Icons.checklist_rounded, l10n.navTasks, 1),
      _SidebarItemData(Icons.folder_open_outlined, l10n.navProjects, 2),
      _SidebarItemData(Icons.track_changes_outlined, l10n.navGoals, 3),
      _SidebarItemData(Icons.sticky_note_2_outlined, l10n.navNotes, 4),
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: BrainTheme.surfaceDark,
        border: Border(
          right: BorderSide(
            color: BrainTheme.borderDark.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // ── Branding ──
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: BrainTheme.borderDark.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [BrainTheme.accentPurple, BrainTheme.accentBlue],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.appTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BrainTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      'Tu espacio personal',
                      style: TextStyle(
                        fontSize: 10,
                        color: BrainTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Primary Nav ──
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
            child: _SectionLabel(label: 'Menú principal'),
          ),
          ...primaryItems.map((item) {
            final active = currentIndex == item.index;
            return _SidebarNavItem(
              icon: item.icon,
              label: item.label,
              isActive: active,
              onTap: () => onItemSelected(item.index),
            );
          }),

          const SizedBox(height: 8),

          // ── Secondary Nav ──
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: _SectionLabel(label: 'Planificación'),
          ),
          _SidebarNavItem(
            icon: Icons.today_rounded,
            label: l10n.todayView,
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/today'),
          ),
          _SidebarNavItem(
            icon: Icons.calendar_month_outlined,
            label: l10n.calendar,
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/calendar'),
          ),
          _SidebarNavItem(
            icon: Icons.center_focus_strong_outlined,
            label: l10n.focusMode,
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/focus'),
          ),
          _SidebarNavItem(
            icon: Icons.bar_chart_outlined,
            label: l10n.statistics,
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/stats'),
          ),

          const Spacer(),

          // ── Quick Stats ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: BrainTheme.cardDark.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatDot(
                      color: BrainTheme.statusColor(TaskStatus.pending),
                      label: '${tasks.todoTasks.length}',
                    ),
                    _StatDot(
                      color: BrainTheme.statusColor(TaskStatus.inProgress),
                      label: '${tasks.inProgressTasks.length}',
                    ),
                    _StatDot(
                      color: BrainTheme.statusColor(TaskStatus.inReview),
                      label: '${tasks.inReviewTasks.length}',
                    ),
                    _StatDot(
                      color: BrainTheme.statusColor(TaskStatus.completed),
                      label: '${tasks.doneTasks.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Bottom Actions ──
          _SidebarNavItem(
            icon: Icons.delete_outline_rounded,
            label: l10n.trash,
            trailing: trash.totalItems > 0
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: BrainTheme.accentRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${trash.totalItems}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: BrainTheme.accentRed,
                      ),
                    ),
                  )
                : null,
            onTap: () => Navigator.pushNamed(context, '/trash'),
          ),
          _SidebarNavItem(
            icon: Icons.settings_outlined,
            label: l10n.settings,
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Data classes ──────────────────────────────────────────────────

class _SidebarItemData {
  final IconData icon;
  final String label;
  final int index;
  const _SidebarItemData(this.icon, this.label, this.index);
}

// ─── Widgets ───────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: BrainTheme.textTertiary.withValues(alpha: 0.6),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? BrainTheme.accentPurple.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(
                      color: BrainTheme.accentPurple.withValues(alpha: 0.2),
                      width: 0.5,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? BrainTheme.accentPurple
                      : BrainTheme.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? BrainTheme.accentPurple
                          : BrainTheme.textPrimary,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  final Color color;
  final String label;
  const _StatDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: BrainTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
