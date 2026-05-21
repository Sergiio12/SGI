import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../l10n/app_localizations.dart';
import '../providers/trash_provider.dart';

class BrainDrawer extends StatelessWidget {
  const BrainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: BrainTheme.surfaceDark,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          BrainTheme.accentPurple,
                          BrainTheme.accentBlue
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.psychology, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).appTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: BrainTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Tu espacio personal',
                        style: TextStyle(
                          fontSize: 12,
                          color: BrainTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Divider(color: BrainTheme.borderDark),
            _DrawerItem(
              icon: Icons.delete_outline_rounded,
              label: AppLocalizations.of(context).trash,
              badge: Consumer<TrashProvider>(
                builder: (_, trash, __) {
                  return trash.totalItems > 0
                      ? _CountBadge(
                          count: trash.totalItems,
                          color: BrainTheme.accentRed,
                        )
                      : const SizedBox.shrink();
                },
              ),
              onTap: () => _open(context, '/trash'),
            ),
            _DrawerItem(
              icon: Icons.settings_outlined,
              label: AppLocalizations.of(context).settings,
              onTap: () => _open(context, '/settings'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? badge;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22, color: BrainTheme.textSecondary),
      title: Text(
        label,
        style: TextStyle(fontSize: 14, color: BrainTheme.textPrimary),
      ),
      trailing: badge,
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  _CountBadge({
    required this.count,
    this.color = const Color(0xFF9D4EDD),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
