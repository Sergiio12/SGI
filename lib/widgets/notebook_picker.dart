import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';

import '../config/theme.dart';
import '../models/notebook_info.dart';
import '../providers/notes_provider.dart';

Future<String?> showNotebookPickerModal(
  BuildContext context, {
  String? selectedNotebook,
  bool allowAll = false,
}) {
  final provider = context.read<NotesProvider>();
  final notebooks = provider.notebooks;
  final searchController = TextEditingController();

  return showModalBottomSheet<String?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (context, setSheetState) {
        final query = searchController.text.toLowerCase();
        final filtered = query.isEmpty
            ? notebooks
            : notebooks
                .where((nb) => nb.toLowerCase().contains(query))
                .toList();

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).selectNotebook,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: searchController,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).searchNotebook,
                    prefixIcon: Icon(Icons.search,
                        size: 20, color: BrainTheme.textTertiary),
                    suffixIcon: searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear,
                                size: 18, color: BrainTheme.textSecondary),
                            onPressed: () {
                              searchController.clear();
                              setSheetState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: BrainTheme.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty && query.isNotEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context).noResults,
                            style: TextStyle(
                                color: BrainTheme.textTertiary, fontSize: 13),
                          ),
                        )
                      : ListView(
                          children: [
                            if (allowAll)
                              _NotebookTile(
                                label:
                                    AppLocalizations.of(context).allNotebooks,
                                icon: Icons.folder,
                                iconColor: BrainTheme.accentBlue,
                                isSelected: selectedNotebook == null,
                                onTap: () => Navigator.pop(ctx, null),
                              ),
                            ...filtered.map((nb) {
                              final color =
                                  provider.getNotebookColor(nb);
                              return _NotebookTile(
                                label: nb,
                                color: color,
                                isSelected: selectedNotebook == nb,
                                onTap: () => Navigator.pop(ctx, nb),
                              );
                            }),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SafeArea(
                    top: false,
                    child: OutlinedButton.icon(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) =>
                            _CreateNotebookDialog(provider: provider),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(AppLocalizations.of(context).newNotebook),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BrainTheme.accentPurple,
                        side: BorderSide(color: BrainTheme.accentPurple.withValues(alpha: 0.3)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    },
  );
}

class _NotebookTile extends StatelessWidget {
  final String label;
  final Color? color;
  final IconData? icon;
  final Color? iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _NotebookTile({
    required this.label,
    this.color,
    this.icon,
    this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      color: isSelected
          ? BrainTheme.accentPurple.withValues(alpha: 0.1)
          : BrainTheme.surfaceDark,
      child: ListTile(
        dense: true,
        leading: icon != null
            ? Icon(icon, size: 20, color: iconColor ?? BrainTheme.textSecondary)
            : Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: color?.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.folder, size: 16, color: color),
              ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle,
                color: BrainTheme.accentPurple, size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _CreateNotebookDialog extends StatefulWidget {
  final NotesProvider provider;

  const _CreateNotebookDialog({required this.provider});

  @override
  State<_CreateNotebookDialog> createState() => _CreateNotebookDialogState();
}

class _CreateNotebookDialogState extends State<_CreateNotebookDialog> {
  final _nameController = TextEditingController();
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = NotebookInfo.colorFromHex(NotebookInfo.palette.first);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: BrainTheme.cardDark,
      title: Text(
        AppLocalizations.of(context).newNotebook,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nombre',
                filled: true,
                fillColor: BrainTheme.surfaceDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 16),
            Text(
              'Color',
              style: TextStyle(
                color: BrainTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: NotebookInfo.palette.map((hex) {
                final color = NotebookInfo.colorFromHex(hex);
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        width: isSelected ? 3 : 1,
                        color: isSelected
                            ? BrainTheme.surfaceDark
                            : BrainTheme.borderDark,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context).cancel),
        ),
        FilledButton(
          onPressed: _create,
          style: FilledButton.styleFrom(
            backgroundColor: BrainTheme.accentPurple,
          ),
          child: const Text('Crear'),
        ),
      ],
    );
  }

  void _create() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.provider.createNotebook(name, color: _selectedColor);
    Navigator.pop(context);
  }
}
