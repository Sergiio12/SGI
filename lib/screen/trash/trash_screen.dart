import 'package:flutter/material.dart';
import 'package:second_brain/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/goals_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/tasks_provider.dart';
import '../../providers/trash_provider.dart';
import '../../widgets/empty_state.dart';

class TrashScreen extends StatelessWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.trash),
        actions: [
          Consumer<TrashProvider>(
            builder: (context, trash, _) {
              if (trash.totalItems == 0) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: AppLocalizations.of(context)!.emptyTrash,
                onPressed: () => _confirmEmptyTrash(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<TrashProvider>(
        builder: (context, trash, _) {
          if (!trash.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          if (trash.totalItems == 0) {
            return EmptyState(
              emoji: '🗑️',
              title: AppLocalizations.of(context)!.emptyState,
              subtitle: AppLocalizations.of(context)!.emptyStateDescription,
            );
          }

          final items = trash.sortedItems;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final bundle = items[index];
              return _TrashItemCard(
                bundle: bundle,
                onRestore: () => _restoreItem(context, bundle),
                onPermanentDelete: () =>
                    _permanentDeleteItem(context, bundle),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmEmptyTrash(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Text(
          AppLocalizations.of(context)!.emptyTrash,
          style: TextStyle(color: BrainTheme.textPrimary),
        ),
        content: Text(
          AppLocalizations.of(context)!.permanentlyDelete,
          style: TextStyle(color: BrainTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: BrainTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.emptyTrash),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<TrashProvider>().emptyAll();
    }
  }

  Future<void> _restoreItem(BuildContext context, TrashBundle bundle) async {
    switch (bundle.type) {
      case TrashItemType.task:
        await context.read<TasksProvider>().restoreTask(bundle.id);
        break;
      case TrashItemType.project:
        await context.read<ProjectsProvider>().restoreProject(bundle.id);
        break;
      case TrashItemType.note:
        await context.read<NotesProvider>().restoreNote(bundle.id);
        break;
      case TrashItemType.goal:
        await context.read<GoalsProvider>().restoreGoal(bundle.id);
        break;
    }
    if (context.mounted) {
      await context.read<TrashProvider>().reload();
    }
  }

  Future<void> _permanentDeleteItem(
      BuildContext context, TrashBundle bundle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BrainTheme.cardDark,
        title: Text(
          AppLocalizations.of(context)!.permanentlyDelete,
          style: TextStyle(color: BrainTheme.textPrimary),
        ),
        content: Text(
          '${AppLocalizations.of(context)!.permanentlyDelete}: "${bundle.title}"',
          style: TextStyle(color: BrainTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: BrainTheme.accentRed,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      switch (bundle.type) {
        case TrashItemType.task:
          await context
              .read<TasksProvider>()
              .permanentDeleteTask(bundle.id);
          break;
        case TrashItemType.project:
          await context
              .read<ProjectsProvider>()
              .permanentDeleteProject(bundle.id);
          break;
        case TrashItemType.note:
          await context
              .read<NotesProvider>()
              .permanentDeleteNote(bundle.id);
          break;
        case TrashItemType.goal:
          await context
              .read<GoalsProvider>()
              .permanentDeleteGoal(bundle.id);
          break;
      }
      if (context.mounted) {
        await context.read<TrashProvider>().reload();
      }
    }
  }
}

class _TrashItemCard extends StatelessWidget {
  final TrashBundle bundle;
  final VoidCallback onRestore;
  final VoidCallback onPermanentDelete;

  _TrashItemCard({
    required this.bundle,
    required this.onRestore,
    required this.onPermanentDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: bundle.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(bundle.icon, color: bundle.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bundle.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: BrainTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _typeLabel(context),
                    style: TextStyle(
                      fontSize: 11,
                      color: BrainTheme.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.restore_outlined, size: 20),
              tooltip: AppLocalizations.of(context)!.restore,
              color: BrainTheme.accentGreen,
              onPressed: onRestore,
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever_outlined, size: 20),
              tooltip: AppLocalizations.of(context)!.permanentlyDelete,
              color: BrainTheme.accentRed.withValues(alpha: 0.7),
              onPressed: onPermanentDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(BuildContext context) {
    switch (bundle.type) {
      case TrashItemType.task:
        return AppLocalizations.of(context)!.task;
      case TrashItemType.project:
        return AppLocalizations.of(context)!.project;
      case TrashItemType.note:
        return AppLocalizations.of(context)!.note;
      case TrashItemType.goal:
        return AppLocalizations.of(context)!.goal;
    }
  }
}
