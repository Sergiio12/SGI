import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../config/theme.dart';
import '../../models/note.dart';
import '../../models/tag.dart';
import '../../providers/notes_provider.dart';
import '../../providers/tags_provider.dart';
import '../../utils/debouncer.dart';
import '../../widgets/note_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_card.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String? _filterNotebook;
  Set<String> _filterTagIds = {};
  bool _isGridView = true;
  SortOption _sortOption = SortOption.updatedAt;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _searchDebouncer = Debouncer(delay: const Duration(milliseconds: 300));

  bool _selectionMode = false;
  final Set<String> _selectedNoteIds = {};
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
        context.read<NotesProvider>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _exitSelectionMode() {
    setState(() {
      _selectionMode = false;
      _selectedNoteIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedNoteIds.contains(id)) {
        _selectedNoteIds.remove(id);
        if (_selectedNoteIds.isEmpty) _selectionMode = false;
      } else {
        _selectedNoteIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final provider = context.read<NotesProvider>();
    final ids = List<String>.from(_selectedNoteIds);
    for (final id in ids) {
      await provider.deleteNote(id);
    }
    _exitSelectionMode();
    if (mounted) {
      _showBottomSnackBar('${ids.length} ${AppLocalizations.of(context).notesDeleted}');
    }
  }

  Future<void> _pinSelected() async {
    final provider = context.read<NotesProvider>();
    for (final id in _selectedNoteIds) {
      final note = provider.getNoteById(id);
      if (note != null && !note.isPinned) {
        await provider.togglePin(id);
      }
    }
    _exitSelectionMode();
  }

  void _showMoveSelectedDialog() {
    final provider = context.read<NotesProvider>();
    final notebooks = provider.notebooks;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mover a cuaderno',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...notebooks.map((nb) => ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(nb),
                  onTap: () async {
                    Navigator.pop(ctx);
                    for (final id in _selectedNoteIds) {
                      final note = provider.getNoteById(id);
                      if (note != null) {
                        await provider.updateNote(note.copyWith(notebook: nb));
                      }
                    }
                    _exitSelectionMode();
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: BrainTheme.cardDark,
        border: Border(top: BorderSide(color: BrainTheme.borderDark)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: _pinSelected,
              icon: const Icon(Icons.push_pin_outlined, size: 18),
              label: const Text('Anclar'),
            ),
            TextButton.icon(
              onPressed: _showMoveSelectedDialog,
              icon: const Icon(Icons.drive_file_move_outlined, size: 18),
              label: const Text('Mover'),
            ),
            TextButton.icon(
              onPressed: _deleteSelected,
              icon: Icon(Icons.delete_outline, size: 18, color: BrainTheme.accentRed),
              label: Text('Eliminar', style: TextStyle(color: BrainTheme.accentRed)),
            ),
            TextButton.icon(
              onPressed: _exitSelectionMode,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancelar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBottomSnackBar(String message, {String? actionLabel, VoidCallback? onAction}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final paddingBottom = MediaQuery.of(context).padding.bottom;
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(bottom: paddingBottom, left: 0, right: 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: const RoundedRectangleBorder(),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(label: actionLabel, textColor: BrainTheme.accentPurple, onPressed: onAction)
          : null,
    ));
  }

  void _copyNoteContent(Note note) {
    final text = '${note.title}\n\n${note.content}';
    Clipboard.setData(ClipboardData(text: text));
    _showBottomSnackBar('Contenido copiado al portapapeles');
  }

  void _shareNote(Note note) {
    final text = '${note.title}\n\n${note.content}';
    Clipboard.setData(ClipboardData(text: text));
    _showBottomSnackBar('Contenido copiado para compartir');
  }

  void _showMoveSingleDialog(BuildContext context, NotesProvider provider, Note note) {
    final notebooks = provider.notebooks;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).moveToNotebook,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...notebooks.map((nb) => ListTile(
                  leading: Icon(Icons.folder_outlined, color: BrainTheme.textSecondary),
                  title: Text(nb),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await provider.updateNote(note.copyWith(notebook: nb));
                    if (mounted) {
                      _showBottomSnackBar('Nota movida a "$nb"');
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  void _deleteNoteWithUndo(BuildContext context, NotesProvider provider, Note note) {
    final noteId = note.id;
    provider.deleteNote(noteId);
    _showBottomSnackBar(
      AppLocalizations.of(context).notesUndoDeleted(note.title),
      actionLabel: AppLocalizations.of(context).undo,
      onAction: () => provider.restoreNote(noteId),
    );
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
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) return const SkeletonGrid();
        return Column(
          children: [
            _buildSearchBar(),
            _buildStatsBar(),
            _buildFilterRow(),
            _buildTagFilter(),
            const SizedBox(height: 8),
            Expanded(child: _buildNotesList()),
            if (_selectionMode) _buildSelectionToolbar(),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => _searchDebouncer.call(() {
          if (mounted) setState(() => _searchQuery = v.toLowerCase());
        }),
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).searchInNotes,
          hintStyle: TextStyle(color: BrainTheme.textTertiary),
          prefixIcon:
              Icon(Icons.search, size: 20, color: BrainTheme.textTertiary),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear,
                      size: 18, color: BrainTheme.textSecondary),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
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
              label: '$total ${AppLocalizations.of(context).notes}',
            ),
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.push_pin_outlined,
              label: '$pinned ${AppLocalizations.of(context).pinned}',
              color: BrainTheme.accentOrange,
            ),
            const SizedBox(width: 12),
            _StatChip(
              icon: Icons.folder_outlined,
              label: '$notebooks ${AppLocalizations.of(context).notebooksLabel}',
              color: BrainTheme.accentBlue,
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterRow() {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        final notebooks = provider.notebooks;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Expanded(child: _buildNotebookDropdown(notebooks)),
              const SizedBox(width: 8),
              _buildSortDropdown(),
              const SizedBox(width: 8),
              _buildViewToggle(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotebookDropdown(List<String> notebooks) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: BrainTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BrainTheme.borderDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _filterNotebook,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(Icons.folder_outlined,
                  size: 16, color: BrainTheme.textSecondary),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).allNotebooks,
                style: TextStyle(color: BrainTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
          items: [
            DropdownMenuItem<String?>(
              value: null,
              child: Text(
                AppLocalizations.of(context).allNotebooks,
                style: TextStyle(color: BrainTheme.textPrimary, fontSize: 13),
              ),
            ),
            ...notebooks.map((nb) => DropdownMenuItem<String?>(
                  value: nb,
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined,
                          size: 14, color: BrainTheme.accentBlue),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          nb,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: BrainTheme.textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          onChanged: (String? value) => setState(() => _filterNotebook = value),
          dropdownColor: BrainTheme.cardDark,
          icon: Icon(Icons.expand_more,
              color: BrainTheme.textSecondary, size: 20),
          style: TextStyle(color: BrainTheme.textPrimary, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _isGridView
            ? BrainTheme.accentPurple.withValues(alpha: 0.1)
            : BrainTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isGridView
              ? BrainTheme.accentPurple.withValues(alpha: 0.3)
              : BrainTheme.borderDark,
        ),
      ),
      child: IconButton(
        icon: Icon(
          _isGridView ? Icons.grid_view_rounded : Icons.view_list_rounded,
          color:
              _isGridView ? BrainTheme.accentPurple : BrainTheme.textSecondary,
          size: 20,
        ),
        onPressed: () => setState(() => _isGridView = !_isGridView),
        tooltip: _isGridView ? AppLocalizations.of(context).listView : AppLocalizations.of(context).gridView,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: BrainTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BrainTheme.borderDark),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<SortOption>(
          value: _sortOption,
          isDense: true,
          items: [
            DropdownMenuItem(
              value: SortOption.updatedAt,
              child: Icon(Icons.access_time, size: 18, color: BrainTheme.textSecondary),
            ),
            DropdownMenuItem(
              value: SortOption.createdAt,
              child: Icon(Icons.add_circle_outline, size: 18, color: BrainTheme.textSecondary),
            ),
            DropdownMenuItem(
              value: SortOption.title,
              child: Icon(Icons.sort_by_alpha, size: 18, color: BrainTheme.textSecondary),
            ),
          ],
          onChanged: (SortOption? value) {
            if (value != null) setState(() => _sortOption = value);
          },
          dropdownColor: BrainTheme.cardDark,
          icon: const SizedBox.shrink(),
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildTagFilter() {
    return Consumer<TagsProvider>(builder: (context, tagsProv, _) {
      final noteTags = tagsProv.getTags(TagType.note);
      final usedTagIds = context.read<NotesProvider>().tagCounts.keys.toSet();
      final activeTags =
          noteTags.where((t) => usedTagIds.contains(t.id)).toList();

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? tag.color.withValues(alpha: 0.2)
                          : BrainTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? tag.color : BrainTheme.borderDark,
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
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
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

  Widget _buildNotesList() {
    return Consumer<NotesProvider>(
      builder: (context, provider, _) {
        var notes = provider.filteredNotes(
          notebook: _filterNotebook,
          tags: _filterTagIds.isNotEmpty ? _filterTagIds.toList() : null,
          searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
          sortBy: _sortOption,
        );

        final pinned = notes.where((n) => n.isPinned).toList();
        final unpinned = notes.where((n) => !n.isPinned).toList();
        notes = [...pinned, ...unpinned];

        if (notes.isEmpty) {
          return EmptyState(
            emoji: _searchQuery.isNotEmpty ? '🔍' : '📝',
            title: _searchQuery.isNotEmpty
                ? AppLocalizations.of(context).noResults
                : AppLocalizations.of(context).emptyNotes,
            subtitle: _searchQuery.isNotEmpty
                ? 'No hay notas que coincidan con "$_searchQuery"'
                : AppLocalizations.of(context).emptyNotesSubtitle,
            actionLabel: _searchQuery.isNotEmpty
                ? null
                : AppLocalizations.of(context).createNote,
            onAction: _searchQuery.isNotEmpty
                ? null
                : () => Navigator.pushNamed(context, '/note'),
          );
        }

        if (_isGridView) {
          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification &&
                  notification.metrics.pixels >= notification.metrics.maxScrollExtent - 300) {
                provider.loadMore();
              }
              return false;
            },
            child: MasonryGridView.count(
            key: ValueKey('notes_grid_${notes.length}_${pinned.length}'),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return NoteCard(
                note: note,
                searchQuery: _searchQuery,
                isSelected: _selectedNoteIds.contains(note.id),
                onSelect: _selectionMode ? (v) => _toggleSelection(note.id) : null,
                onTap: _selectionMode
                    ? () => _toggleSelection(note.id)
                    : () => Navigator.pushNamed(context, '/note', arguments: note.id),
                onDelete: _selectionMode ? null : () => _deleteNoteWithUndo(context, provider, note),
                onTogglePin: _selectionMode ? null : () => provider.togglePin(note.id),
                onCopyContent: _selectionMode ? null : () => _copyNoteContent(note),
                onShare: _selectionMode ? null : () => _shareNote(note),
                onMoveToNotebook: _selectionMode ? null : () => _showMoveSingleDialog(context, provider, note),
              );
            },
          ),
        );
        }

        return ListView.builder(
          key: ValueKey('notes_list_${notes.length}_${pinned.length}'),
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: notes.length,
          itemBuilder: (context, index) {
            final note = notes[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NoteCard(
                note: note,
                searchQuery: _searchQuery,
                isSelected: _selectedNoteIds.contains(note.id),
                onSelect: _selectionMode ? (v) => _toggleSelection(note.id) : null,
                onTap: _selectionMode
                    ? () => _toggleSelection(note.id)
                    : () => Navigator.pushNamed(context, '/note', arguments: note.id),
                onDelete: _selectionMode ? null : () => _deleteNoteWithUndo(context, provider, note),
                onTogglePin: _selectionMode ? null : () => provider.togglePin(note.id),
                onCopyContent: _selectionMode ? null : () => _copyNoteContent(note),
                onShare: _selectionMode ? null : () => _shareNote(note),
                onMoveToNotebook: _selectionMode ? null : () => _showMoveSingleDialog(context, provider, note),
              ),
            );
          },
        );
      },
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
