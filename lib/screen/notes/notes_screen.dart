import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../config/theme.dart';
import '../../models/note.dart';
import '../../models/tag.dart';
import '../../providers/notes_provider.dart';
import '../../providers/tags_provider.dart';
import '../../widgets/note_card.dart';
import '../../widgets/empty_state.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  NoteType? _filterType;
  String? _filterNotebook;
  Set<String> _filterTagIds = {};
  bool _isGridView = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTagFilter(String tagId) {
    setState(() {
      if (_filterTagIds.contains(tagId)) {
        _filterTagIds.remove(tagId);
      } else {
        _filterTagIds.add(tagId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        _buildStatsBar(),
        _buildNotebookFilter(),
        _buildTagFilter(),
        _buildTypeAndViewFilter(),
        const SizedBox(height: 8),
        Expanded(child: _buildNotesList()),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Buscar notas...',
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
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Consumer<NotesProvider>(builder: (context, provider, _) {
      final total = provider.notes.length;
      final pinned = provider.pinnedNotes.length;
      final notebooks = provider.notebooks.length;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            _StatChip(
              icon: Icons.sticky_note_2_outlined,
              label: '$total notas',
            ),
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.push_pin_outlined,
              label: '$pinned ancladas',
              color: BrainTheme.accentOrange,
            ),
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.folder_outlined,
              label: '$notebooks cuadernos',
              color: BrainTheme.accentBlue,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildNotebookFilter() {
    return Consumer<NotesProvider>(builder: (context, provider, _) {
      final notebooks = provider.notebooks;
      return SizedBox(
        height: 38,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _NotebookChip(
              label: 'Todas',
              isSelected: _filterNotebook == null,
              count: provider.notes.length,
              onTap: () => setState(() => _filterNotebook = null),
            ),
            ...notebooks.map((nb) {
              final count = provider.notebookCounts[nb] ?? 0;
              return _NotebookChip(
                label: nb,
                isSelected: _filterNotebook == nb,
                count: count,
                onTap: () =>
                    setState(() => _filterNotebook = _filterNotebook == nb ? null : nb),
              );
            }),
          ],
        ),
      );
    });
  }

  Widget _buildTagFilter() {
    return Consumer<TagsProvider>(builder: (context, tagsProv, _) {
      final noteTags = tagsProv.getTags(TagType.note);
      final usedTagIds =
          context.read<NotesProvider>().tagCounts.keys.toSet();
      final activeTags = noteTags.where((t) => usedTagIds.contains(t.id)).toList();

      if (activeTags.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: activeTags.map((tag) {
              final isSelected = _filterTagIds.contains(tag.id);
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => _toggleTagFilter(tag.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tag.color.withValues(alpha: 0.2)
                          : BrainTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? tag.color
                            : BrainTheme.borderDark,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: tag.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tag.name,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected
                                ? tag.color
                                : BrainTheme.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildTypeAndViewFilter() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'Todas',
            isSelected: _filterType == null,
            onTap: () => setState(() => _filterType = null),
          ),
          _FilterChip(
            label: '📝 Libres',
            isSelected: _filterType == NoteType.freeform,
            onTap: () => setState(() => _filterType = NoteType.freeform),
          ),
          _FilterChip(
            label: '✓ Checklist',
            isSelected: _filterType == NoteType.checklist,
            onTap: () => setState(() => _filterType = NoteType.checklist),
          ),
          _FilterChip(
            label: '📔 Diario',
            isSelected: _filterType == NoteType.journal,
            onTap: () => setState(() => _filterType = NoteType.journal),
          ),
          _FilterChip(
            label: '📎 Referencia',
            isSelected: _filterType == NoteType.reference,
            onTap: () => setState(() => _filterType = NoteType.reference),
          ),
          _FilterChip(
            label: '💡 Reunion',
            isSelected: _filterType == NoteType.meetingNotes,
            onTap: () => setState(() => _filterType = NoteType.meetingNotes),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: BrainTheme.textSecondary,
              size: 20,
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesList() {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        var notes = provider.filteredNotes(
          type: _filterType,
          notebook: _filterNotebook,
          tags: _filterTagIds.isNotEmpty ? _filterTagIds.toList() : null,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        );

        final pinned = notes.where((n) => n.isPinned).toList();
        final unpinned = notes.where((n) => !n.isPinned).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        notes = [...pinned, ...unpinned];

        if (notes.isEmpty) {
          return EmptyState(
            emoji: _searchQuery.isNotEmpty ? '🔍' : '📝',
            title: _searchQuery.isNotEmpty
                ? 'Sin resultados'
                : 'Sin notas',
            subtitle: _searchQuery.isNotEmpty
                ? 'No hay notas que coincidan con "$_searchQuery"'
                : 'Captura tus ideas, referencias y pensamientos',
            actionLabel: _searchQuery.isNotEmpty ? null : 'Nueva Nota',
            onAction: _searchQuery.isNotEmpty
                ? null
                : () => Navigator.pushNamed(context, '/note'),
          );
        }

        if (_isGridView) {
          return MasonryGridView.count(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              return NoteCard(
                note: notes[index],
                onTap: () => Navigator.pushNamed(
                  context,
                  '/note',
                  arguments: notes[index].id,
                ),
                onLongPress: () => provider.togglePin(notes[index].id),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NoteCard(
                note: notes[index],
                onTap: () => Navigator.pushNamed(
                  context,
                  '/note',
                  arguments: notes[index].id,
                ),
                onLongPress: () => provider.togglePin(notes[index].id),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? BrainTheme.accentPurple.withValues(alpha: 0.2)
                : BrainTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? BrainTheme.accentPurple
                  : BrainTheme.borderDark,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? BrainTheme.accentPurple
                  : BrainTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _StatChip({
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? BrainTheme.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BrainTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: c,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const _NotebookChip({
    required this.label,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? BrainTheme.accentBlue.withValues(alpha: 0.15)
                : BrainTheme.surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? BrainTheme.accentBlue
                  : BrainTheme.borderDark,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_outlined,
                size: 13,
                color: isSelected
                    ? BrainTheme.accentBlue
                    : BrainTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? BrainTheme.accentBlue
                      : BrainTheme.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : null,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected
                      ? BrainTheme.accentBlue.withValues(alpha: 0.2)
                      : BrainTheme.borderDark.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? BrainTheme.accentBlue
                        : BrainTheme.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
