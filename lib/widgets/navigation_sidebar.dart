import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/tasks_provider.dart';
import '../providers/trash_provider.dart';
import '../models/task.dart';
import '../utils/haptic_helper.dart';

class NavigationSidebar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onItemSelected;

  const NavigationSidebar({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
  });

  @override
  State<NavigationSidebar> createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends State<NavigationSidebar> {
  bool _mainSectionExpanded = true;
  bool _planningSectionExpanded = true;

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

    final planningItems = [
      _PlanningItemData(Icons.today_rounded, l10n.todayView, '/today'),
      _PlanningItemData(Icons.calendar_month_outlined, l10n.calendar, '/calendar'),
      _PlanningItemData(Icons.center_focus_strong_outlined, l10n.focusMode, '/focus'),
      _PlanningItemData(Icons.bar_chart_outlined, l10n.statistics, '/stats'),
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
          _buildHeader(l10n),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSection(
                  title: l10n.sectionMainMenu,
                  isExpanded: _mainSectionExpanded,
                  onToggle: () => setState(() => _mainSectionExpanded = !_mainSectionExpanded),
                  children: primaryItems.map((item) {
                    final active = widget.currentIndex == item.index;
                    return _SidebarNavItem(
                      icon: item.icon,
                      label: item.label,
                      isActive: active,
                      onTap: () {
                        HapticHelper.selection();
                        widget.onItemSelected(item.index);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 4),
                _buildSection(
                  title: l10n.sectionPlanning,
                  isExpanded: _planningSectionExpanded,
                  onToggle: () => setState(() => _planningSectionExpanded = !_planningSectionExpanded),
                  children: planningItems.map((item) {
                    return _SidebarNavItem(
                      icon: item.icon,
                      label: item.label,
                      onTap: () {
                        HapticHelper.selection();
                        Navigator.pushNamed(context, item.route);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          _buildQuickStats(tasks),
          const SizedBox(height: 6),
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
            onTap: () {
              HapticHelper.selection();
              Navigator.pushNamed(context, '/trash');
            },
          ),
          _SidebarNavItem(
            icon: Icons.settings_outlined,
            label: l10n.settings,
            onTap: () {
              HapticHelper.selection();
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: BrainTheme.borderDark.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Tooltip(
        message: 'Second Brain v1.0',
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
                    'v1.0.1',
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
    );
  }

  Widget _buildSection({
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 4),
            child: Row(
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: BrainTheme.textTertiary.withValues(alpha: 0.6),
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: BrainTheme.textTertiary.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: Column(children: children),
          secondChild: const SizedBox.shrink(),
          crossFadeState: isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildQuickStats(TasksProvider tasks) {
    return Container(
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
                tooltip: 'Pendientes',
              ),
              _StatDot(
                color: BrainTheme.statusColor(TaskStatus.inProgress),
                label: '${tasks.inProgressTasks.length}',
                tooltip: 'En progreso',
              ),
              _StatDot(
                color: BrainTheme.statusColor(TaskStatus.inReview),
                label: '${tasks.inReviewTasks.length}',
                tooltip: 'En revisión',
              ),
              _StatDot(
                color: BrainTheme.statusColor(TaskStatus.completed),
                label: '${tasks.doneTasks.length}',
                tooltip: 'Completadas',
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: tasks.completionRate,
              backgroundColor: BrainTheme.borderDark.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation(
                BrainTheme.accentGreen,
              ),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItemData {
  final IconData icon;
  final String label;
  final int index;
  const _SidebarItemData(this.icon, this.label, this.index);
}

class _PlanningItemData {
  final IconData icon;
  final String label;
  final String route;
  const _PlanningItemData(this.icon, this.label, this.route);
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
    return Semantics(
      label: label,
      button: true,
      selected: isActive,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? BrainTheme.accentPurple.withValues(alpha: 0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  if (isActive)
                    Container(
                      width: 3,
                      height: 18,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: BrainTheme.accentPurple,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    )
                  else
                    const SizedBox(width: 11),
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
      ),
    );
  }
}

class _StatDot extends StatelessWidget {
  final Color color;
  final String label;
  final String tooltip;

  const _StatDot({
    required this.color,
    required this.label,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Row(
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
      ),
    );
  }
}
