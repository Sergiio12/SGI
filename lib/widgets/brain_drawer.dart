import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../providers/goals_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/projects_provider.dart';
import '../providers/tasks_provider.dart';
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
                      gradient: const LinearGradient(
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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SGI',
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
            const Divider(color: BrainTheme.borderDark),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Consumer4<TasksProvider, ProjectsProvider, NotesProvider,
                  GoalsProvider>(
                builder: (context, tasks, projects, notes, goals, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatBadge(
                        count: tasks.totalTasks,
                        label: 'Tareas',
                        color: BrainTheme.accentOrange,
                      ),
                      _StatBadge(
                        count: projects.projects.length,
                        label: 'Proyectos',
                        color: BrainTheme.accentBlue,
                      ),
                      _StatBadge(
                        count: goals.goals.length,
                        label: 'Objetivos',
                        color: BrainTheme.accentPurple,
                      ),
                      _StatBadge(
                        count: notes.notes.length,
                        label: 'Notas',
                        color: BrainTheme.accentGreen,
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: BrainTheme.borderDark),
            _DrawerItem(
              icon: Icons.search_rounded,
              label: 'Busqueda global',
              onTap: () => _open(context, '/search'),
            ),
            const Divider(
                color: BrainTheme.borderDark, indent: 16, endIndent: 16),
            const _DrawerSectionLabel('VISTAS'),
            _DrawerItem(
              icon: Icons.center_focus_strong,
              label: 'Modo foco',
              badge: Consumer<TasksProvider>(
                builder: (_, tasks, __) {
                  return tasks.focusTasks.isNotEmpty
                      ? _CountBadge(count: tasks.focusTasks.length)
                      : const SizedBox.shrink();
                },
              ),
              onTap: () => _open(context, '/focus'),
            ),
            _DrawerItem(
              icon: Icons.today_rounded,
              label: 'Hoy',
              badge: Consumer<TasksProvider>(
                builder: (_, tasks, __) {
                  return tasks.todayTasks.isNotEmpty
                      ? _CountBadge(count: tasks.todayTasks.length)
                      : const SizedBox.shrink();
                },
              ),
              onTap: () => _open(context, '/calendar'),
            ),
            _DrawerItem(
              icon: Icons.warning_amber_rounded,
              label: 'Vencidas',
              badge: Consumer<TasksProvider>(
                builder: (_, tasks, __) {
                  return tasks.overdueTasks.isNotEmpty
                      ? _CountBadge(
                          count: tasks.overdueTasks.length,
                          color: BrainTheme.accentRed,
                        )
                      : const SizedBox.shrink();
                },
              ),
              onTap: () => _open(context, '/calendar'),
            ),
            _DrawerItem(
              icon: Icons.calendar_month_outlined,
              label: 'Calendario',
              onTap: () => _open(context, '/calendar'),
            ),
            _DrawerItem(
              icon: Icons.analytics_outlined,
              label: 'Progreso',
              onTap: () => _open(context, '/progress'),
            ),
            const Spacer(),
            const Divider(color: BrainTheme.borderDark),
            _DrawerItem(
              icon: Icons.cloud_done_outlined,
              label: 'Datos y respaldo',
              onTap: () => _open(context, '/data'),
            ),
            _DrawerItem(
              icon: Icons.delete_outline_rounded,
              label: 'Papelera',
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
              label: 'Ajustes',
              onTap: () => _open(context, '/settings'),
            ),
            _DrawerItem(
              icon: Icons.info_outline_rounded,
              label: 'Acerca de',
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'SGI',
                  applicationVersion: '1.0.0',
                  applicationIcon: const Icon(Icons.psychology, size: 48),
                );
              },
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

class _DrawerSectionLabel extends StatelessWidget {
  final String text;

  const _DrawerSectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: BrainTheme.textTertiary,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
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
        style: const TextStyle(fontSize: 14, color: BrainTheme.textPrimary),
      ),
      trailing: badge,
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatBadge({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: BrainTheme.textTertiary),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final Color color;

  const _CountBadge({
    required this.count,
    this.color = BrainTheme.accentPurple,
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
