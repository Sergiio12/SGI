import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/tag.dart';
import '../../../providers/tags_provider.dart';
import '../../tag_color_picker.dart';

Future<void> showTagManagerModal(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _TagManagerBody(),
  );
}

class _TagManagerBody extends StatefulWidget {
  @override
  State<_TagManagerBody> createState() => _TagManagerBodyState();
}

class _TagManagerBodyState extends State<_TagManagerBody> {
  final _nameController = TextEditingController();
  int _newTagColorValue = BrainTheme.accentPurple.toARGB32();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: 520,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Gestionar etiquetas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<TagsProvider>(builder: (context, prov, _) {
                final noteTags = prov.getTags(TagType.note);
                if (noteTags.isEmpty) {
                  return Center(
                    child: Text('Crea tu primera etiqueta',
                        style: TextStyle(color: BrainTheme.textTertiary)),
                  );
                }
                return ListView(
                  children: noteTags
                      .map((t) => Dismissible(
                            key: ValueKey(t.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: BrainTheme.accentRed,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => prov.deleteTag(t.id),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: t.color, radius: 14),
                              title: Text(t.name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                      icon: const Icon(Icons.edit, size: 20),
                                      onPressed: () => _editTag(context, prov, t)),
                                  IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 20),
                                      onPressed: () => prov.deleteTag(t.id)),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                );
              }),
            ),
            const Divider(),
            const Text('Crear nueva etiqueta',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Nombre',
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                )),
            const SizedBox(height: 12),
            TagColorPicker(
              selectedColorValue: _newTagColorValue,
              onColorChanged: (v) => setState(() => _newTagColorValue = v),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: () async {
                    if (_nameController.text.trim().isEmpty) return;
                    await context.read<TagsProvider>().addTag(
                        name: _nameController.text.trim(),
                        colorValue: _newTagColorValue);
                    _nameController.clear();
                  },
                  child: const Text('Crear etiqueta')),
            ),
          ],
        ),
      ),
    );
  }

  void _editTag(BuildContext context, TagsProvider prov, Tag tag) {
    int editColorValue = tag.color.toARGB32();
    final editNameCtrl = TextEditingController(text: tag.name);
    showDialog(
      context: context,
      builder: (dctx) => StatefulBuilder(
        builder: (dState, setDialogState) => AlertDialog(
          title: const Text('Editar etiqueta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: editNameCtrl,
                    decoration: const InputDecoration(hintText: 'Nombre')),
                const SizedBox(height: 16),
                TagColorPicker(
                  selectedColorValue: editColorValue,
                  onColorChanged: (v) => setDialogState(() => editColorValue = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dctx),
                child: Text(AppLocalizations.of(dState).cancel)),
            FilledButton(
                onPressed: () async {
                  await prov.updateTag(tag.copyWith(
                      name: editNameCtrl.text, color: Color(editColorValue)));
                  Navigator.pop(dctx);
                },
                child: Text(AppLocalizations.of(dState).save)),
          ],
        ),
      ),
    );
  }
}
