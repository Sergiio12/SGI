import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/tag.dart';
import '../../../providers/tags_provider.dart';

Future<Set<String>> showTagPickerModal(
  BuildContext context,
  Set<String> currentTagIds,
) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return _TagPickerBody(
            scrollController: scrollController,
            currentTagIds: currentTagIds,
          );
        },
      );
    },
  ).then((v) => v ?? currentTagIds);
}

class _TagPickerBody extends StatefulWidget {
  final ScrollController scrollController;
  final Set<String> currentTagIds;

  const _TagPickerBody({
    required this.scrollController,
    required this.currentTagIds,
  });

  @override
  State<_TagPickerBody> createState() => _TagPickerBodyState();
}

class _TagPickerBodyState extends State<_TagPickerBody> {
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.currentTagIds);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context).tags,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context, _selectedIds),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Toca para asignar etiquetas a esta nota',
                style: TextStyle(color: BrainTheme.textTertiary, fontSize: 13)),
            const SizedBox(height: 16),
            Expanded(
              child: Consumer<TagsProvider>(builder: (context, tagsProv, _) {
                final noteTags = tagsProv.getTags(TagType.note);
                if (noteTags.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Sin etiquetas',
                            style: TextStyle(color: BrainTheme.textTertiary)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, _selectedIds);
                          },
                          child: const Text('Crear etiquetas'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView(
                  controller: widget.scrollController,
                  children: noteTags.map((t) {
                    final isSelected = _selectedIds.contains(t.id);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      color: isSelected
                          ? t.color.withValues(alpha: 0.1)
                          : BrainTheme.surfaceDark,
                      child: ListTile(
                        leading: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: t.color, shape: BoxShape.circle),
                        ),
                        title: Text(t.name,
                            style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: t.color, size: 22)
                            : Icon(Icons.circle_outlined,
                                color: BrainTheme.textTertiary, size: 22),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIds.remove(t.id);
                            } else {
                              _selectedIds.add(t.id);
                            }
                          });
                        },
                      ),
                    );
                  }).toList(),
                );
              }),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _selectedIds),
                child: const Text('Aceptar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
