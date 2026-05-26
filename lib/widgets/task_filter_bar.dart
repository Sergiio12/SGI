import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../models/task.dart';

class TaskFilterBar extends StatelessWidget {
  final String searchQuery;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleFilters;
  final int activeFilterCount;

  const TaskFilterBar({
    required this.searchQuery,
    required this.searchController,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onToggleFilters,
    required this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).searchTasks,
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: onClearSearch,
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
                filled: true,
                fillColor: BrainTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: BrainTheme.borderDark),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: BrainTheme.borderDark),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          _ActionButton(
            icon: Icons.filter_list,
            isActive: activeFilterCount > 0,
            activeColor: BrainTheme.statusColor(TaskStatus.inProgress),
            activeFilterCount: activeFilterCount,
            onTap: onToggleFilters,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final int activeFilterCount;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.activeFilterCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.12)
              : BrainTheme.cardDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.3)
                : BrainTheme.borderDark,
            width: 1,
          ),
        ),
        child: Badge(
          isLabelVisible: activeFilterCount > 0,
          label: Text('$activeFilterCount',
              style:
                  const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? activeColor : BrainTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
