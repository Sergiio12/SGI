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
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
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
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _newTagController = TextEditingController();
  bool _showNewTagInput = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.currentTagIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                Text(l10n.tags,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add, color: BrainTheme.accentPurple),
                      tooltip: l10n.createNewTag,
                      onPressed: () => setState(() => _showNewTagInput = true),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context, _selectedIds),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '${l10n.search}...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: BrainTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: BrainTheme.borderDark),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<TagsProvider>(
                builder: (context, tagsProv, _) {
                  final allTags = tagsProv.getTags(TagType.note);
                  final filtered = _searchQuery.isEmpty
                      ? allTags
                      : allTags.where((t) =>
                          t.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                  if (allTags.isEmpty && !_showNewTagInput) {
                    return Center(
                      child: Text(l10n.noTags,
                          style: TextStyle(color: BrainTheme.textTertiary)),
                    );
                  }

                  return ListView(
                    controller: widget.scrollController,
                    children: [
                      if (_showNewTagInput) _buildNewTagInput(l10n, tagsProv),
                      if (_showNewTagInput && filtered.isNotEmpty)
                        const Divider(height: 24),
                      if (filtered.isEmpty && _searchQuery.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(l10n.noResults,
                                style: TextStyle(color: BrainTheme.textTertiary)),
                          ),
                        ),
                      ...filtered.map((t) {
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
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(context, _selectedIds),
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(l10n.accept, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                style: FilledButton.styleFrom(
                  backgroundColor: BrainTheme.accentPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                  shadowColor: BrainTheme.accentPurple.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewTagInput(AppLocalizations l10n, TagsProvider tagsProv) {
    return Card(
      color: BrainTheme.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.createNewTag,
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: BrainTheme.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: _newTagController,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.tagName,
                isDense: true,
                filled: true,
                fillColor: BrainTheme.cardDark,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: BrainTheme.borderDark),
                ),
              ),
              onSubmitted: (_) => _createTag(tagsProv, l10n),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showNewTagInput = false;
                      _newTagController.clear();
                    });
                  },
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _createTag(tagsProv, l10n),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.createTags),
                  style: FilledButton.styleFrom(
                    backgroundColor: BrainTheme.accentGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createTag(TagsProvider tagsProv, AppLocalizations l10n) {
    final name = _newTagController.text.trim();
    if (name.isEmpty) return;
    tagsProv.addTag(
      name: name,
      colorValue: BrainTheme.accentPurple.toARGB32(),
    );
    _newTagController.clear();
    setState(() {
      _showNewTagInput = false;
    });
  }
}
