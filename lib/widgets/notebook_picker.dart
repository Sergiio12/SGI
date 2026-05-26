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
                      onPressed: () async {
                        final newName = await showModalBottomSheet<String>(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (_) => _CreateNotebookSheet(
                            provider: provider,
                          ),
                        );
                        if (newName != null && context.mounted) {
                          Navigator.pop(context, newName);
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(AppLocalizations.of(context).newNotebook),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BrainTheme.accentOf(context),
                        side: BorderSide(color: BrainTheme.accentOf(context).withValues(alpha: 0.3)),
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
          ? BrainTheme.accentOf(context).withValues(alpha: 0.1)
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
                color: BrainTheme.accentOf(context), size: 20)
            : null,
        onTap: onTap,
      ),
    );
  }
}

class _CreateNotebookSheet extends StatefulWidget {
  final NotesProvider provider;

  const _CreateNotebookSheet({required this.provider});

  @override
  State<_CreateNotebookSheet> createState() => _CreateNotebookSheetState();
}

class _CreateNotebookSheetState extends State<_CreateNotebookSheet> {
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: BrainTheme.borderDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context).newNotebook,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              onSubmitted: (_) => _create(),
            ),
            const SizedBox(height: 20),
            Text(
              'Color',
              style: TextStyle(
                color: BrainTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: NotebookInfo.palette.map((hex) {
                final color = NotebookInfo.colorFromHex(hex);
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.transparent,
                        width: isSelected ? 3 : 0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 20, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _create,
                style: FilledButton.styleFrom(
                  backgroundColor: BrainTheme.accentOf(context),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Crear',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: BrainTheme.accentOf(context).computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    await widget.provider.createNotebook(name, color: _selectedColor);
    if (!context.mounted) return;
    Navigator.pop(context, name);
  }
}
