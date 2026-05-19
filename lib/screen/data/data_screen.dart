import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:second_brain/l10n/app_localizations.dart';
import '../../config/theme.dart';
import '../../providers/goals_provider.dart';
import '../../providers/trash_provider.dart';
import '../../utils/notification_service_v2.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/search_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../services/backup_service.dart';
import '../../services/notification_service.dart';
import '../../services/interfaces/storage_service_interface.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.dataManagement)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActionCard(
            icon: Icons.file_download_outlined,
            title: AppLocalizations.of(context)!.exportData,
            subtitle:
                'Guarda tareas, proyectos, objetivos, notas y relaciones en un archivo local.',
            buttonLabel: AppLocalizations.of(context)!.exportData,
            isBusy: _isBusy,
            onPressed: _export,
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.restore_outlined,
            title: AppLocalizations.of(context)!.importData,
            subtitle:
                'Importa una copia JSON exportada previamente. Sustituye los datos actuales.',
            buttonLabel: AppLocalizations.of(context)!.restore,
            isBusy: _isBusy,
            onPressed: _restore,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: BrainTheme.accentBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cloud_sync_outlined,
                      color: BrainTheme.accentBlue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Firebase opcional',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: BrainTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'La base local es la fuente principal. Firebase queda preparado como capa secundaria de respaldo y sincronizacion futura.',
                          style: TextStyle(
                            fontSize: 13,
                            color: BrainTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ActionCard(
            icon: Icons.delete_forever_outlined,
            title: AppLocalizations.of(context)!.clearAllData,
            subtitle:
                'BORRA TODAS las tareas, proyectos, notas y configuraciones. Esta accion NO se puede deshacer.',
            buttonLabel: AppLocalizations.of(context)!.clearAllData,
            isBusy: _isBusy,
            isDestructive: true,
            onPressed: _deleteAll,
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _isBusy = true);
    try {
      final storage = context.read<IStorageService>();
      final file = await BackupService.exportToJson(
        tasks: context.read<TasksProvider>().tasks,
        projects: context.read<ProjectsProvider>().projects,
        notes: context.read<NotesProvider>().notes,
        goals: context.read<GoalsProvider>().goals,
        trashTasks: await storage.loadTrashTasks(),
        trashProjects: await storage.loadTrashProjects(),
        trashNotes: await storage.loadTrashNotes(),
        trashGoals: await storage.loadTrashGoals(),
      );
      if (!mounted) return;
      showSuccessNotification('Exportado en ${file.path}');
    } catch (error) {
      if (!mounted) return;
      showErrorNotification('No se pudo exportar: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _restore() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.restore),
        content: const Text(
          'Esta accion sustituira los datos actuales por los del archivo seleccionado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final tasksProvider = context.read<TasksProvider>();
    final projectsProvider = context.read<ProjectsProvider>();
    final notesProvider = context.read<NotesProvider>();
    final goalsProvider = context.read<GoalsProvider>();
    final trashProvider = context.read<TrashProvider>();
    setState(() => _isBusy = true);
    try {
      final backup = await BackupService.pickAndReadImport();
      if (backup == null) return;

      final storage = context.read<IStorageService>();
      await Future.wait([
        tasksProvider.replaceAll(backup.tasks),
        projectsProvider.replaceAll(backup.projects),
        notesProvider.replaceAll(backup.notes),
        goalsProvider.replaceAll(backup.goals),
        storage.saveTrashTasks(backup.trashTasks),
        storage.saveTrashProjects(backup.trashProjects),
        storage.saveTrashNotes(backup.trashNotes),
        storage.saveTrashGoals(backup.trashGoals),
      ]);

      await trashProvider.reload();

      if (!mounted) return;
      showSuccessNotification('Datos restaurados');
    } catch (error) {
      if (!mounted) return;
      showErrorNotification('No se pudo restaurar: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.clearAllData),
        content: const Text(
          'Esta accion borrara permanentemente todas tus tareas, proyectos, objetivos y notas. No podras recuperarlos a menos que tengas un respaldo JSON.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: BrainTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(dialogContext)!.permanentlyDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      // 1. Clear storage (Hive and SharedPreferences)
      await context.read<IStorageService>().clearAll();

      // 2. Clear notifications
      await NotificationService.cancelAll();

      // 3. Clear memory (Providers)
      if (mounted) {
        context.read<TasksProvider>().replaceAll([]);
        context.read<ProjectsProvider>().replaceAll([]);
        context.read<NotesProvider>().replaceAll([]);
        context.read<GoalsProvider>().replaceAll([]);
        context.read<TrashProvider>().emptyAll();
        context.read<SearchProvider>().clear();
      }

      if (!mounted) return;
      showSuccessNotification('Todos los datos han sido eliminados');
    } catch (error) {
      if (!mounted) return;
      showErrorNotification('Error al eliminar datos: $error');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool isBusy;
  final bool isDestructive;
  final VoidCallback onPressed;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.isBusy,
    this.isDestructive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (isDestructive
                            ? BrainTheme.accentRed
                            : BrainTheme.accentPurple)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon,
                      color: isDestructive
                          ? BrainTheme.accentRed
                          : BrainTheme.accentPurple),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: BrainTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: BrainTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: isBusy ? null : onPressed,
              style: isDestructive
                  ? FilledButton.styleFrom(
                      backgroundColor:
                          BrainTheme.accentRed.withValues(alpha: 0.8),
                      foregroundColor: Colors.white,
                    )
                  : null,
              icon: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(icon),
              label: Text(buttonLabel),
            ),
          ],
        ),
      ),
    );
  }
}
