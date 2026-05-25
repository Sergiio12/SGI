import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../config/theme.dart';
import '../../models/note.dart';
import '../../providers/notes_provider.dart';
import '../../utils/debouncer.dart';
import '../../widgets/note_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_card.dart';
import '../../widgets/notebook_picker.dart';
import '../../utils/notification_service_v2.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  String? _filterNotebook;
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
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      context.read<NotesProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
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
      _showTopNotification(
        '${ids.length} ${AppLocalizations.of(context).notesDeleted}',
        actionLabel: AppLocalizations.of(context).undo,
        onAction: () {
          for (final id in ids) {
            provider.restoreNote(id);
          }
        },
      );
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
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mover a cuaderno',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: BrainTheme.textPrimary)),
              const SizedBox(height: 12),
              ...notebooks.map((nb) => ListTile(
                    leading: Icon(Icons.folder_outlined,
                        color: BrainTheme.textSecondary),
                    title: Text(nb,
                        style: TextStyle(color: BrainTheme.textPrimary)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      for (final id in _selectedNoteIds) {
                        final note = provider.getNoteById(id);
                        if (note != null) {
                          await provider.updateNote(
                              note.copyWith(notebook: nb));
                        }
                      }
                      _exitSelectionMode();
                    },
                  )),
            ],
          ),
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
              label: Text('Anclar',
                  style: TextStyle(color: BrainTheme.textPrimary)),
            ),
            TextButton.icon(
              onPressed: _showMoveSelectedDialog,
              icon: const Icon(Icons.drive_file_move_outlined, size: 18),
              label: Text('Mover',
                  style: TextStyle(color: BrainTheme.textPrimary)),
            ),
            TextButton.icon(
              onPressed: _deleteSelected,
              icon: Icon(Icons.delete_outline,
                  size: 18, color: BrainTheme.accentRed),
              label: Text('Eliminar',
                  style: TextStyle(color: BrainTheme.accentRed)),
            ),
            TextButton.icon(
              onPressed: _exitSelectionMode,
              icon: const Icon(Icons.close, size: 18),
              label: Text('Cancelar',
                  style: TextStyle(color: BrainTheme.textPrimary)),
            ),
          ],
        ),
      ),
    );
  }

  void _showTopNotification(String message,
      {String? actionLabel, VoidCallback? onAction}) {
    showSuccessNotification(
      message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  void _copyNoteContent(Note note) {
    final text = '${note.title}\n\n${note.content}';
    Clipboard.setData(ClipboardData(text: text));
    _showTopNotification('Contenido copiado al portapapeles');
  }

  void _shareNote(Note note) {
    final text = '${note.title}\n\n${note.content}';
    Clipboard.setData(ClipboardData(text: text));
    _showTopNotification('Contenido copiado para compartir');
  }

  void _showMoveSingleDialog(
      BuildContext context, NotesProvider provider, Note note) {
    final notebooks = provider.notebooks;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).moveToNotebook,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: BrainTheme.textPrimary)),
              const SizedBox(height: 12),
              ...notebooks.map((nb) => ListTile(
                    leading: Icon(Icons.folder_outlined,
                        color: BrainTheme.textSecondary),
                    title: Text(nb,
                        style: TextStyle(color: BrainTheme.textPrimary)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await provider.updateNote(
                          note.copyWith(notebook: nb));
                      if (mounted) {
                        _showTopNotification('Nota movida a "$nb"');
                      }
                    },
                  )),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteNoteWithUndo(
      BuildContext context, NotesProvider provider, Note note) {
    final noteId = note.id;
    provider.deleteNote(noteId);
    _showTopNotification(
      AppLocalizations.of(context).notesUndoDeleted(note.title),
      actionLabel: AppLocalizations.of(context).undo,
      onAction: () => provider.restoreNote(noteId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();
    if (!provider.isLoaded) {
      return const SkeletonGrid();
    }

    final notes = _getFilteredNotes(provider);
    final pinned = notes.where((n) => n.isPinned).toList();
    final unpinned = notes.where((n) => !n.isPinned).toList();
    final sortedNotes = [...pinned, ...unpinned];
    final total = provider.notes.length;
    final pinnedCount = provider.pinnedNotes.length;
    final notebooksCount = provider.notebooks.length;

    return Column(
      children: [
        _buildSearchBar(),
        _buildStatsBar(total, pinnedCount, notebooksCount),
        _buildFilterRow(provider.notebooks),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => provider.loadNotes(),
            child: sortedNotes.isEmpty
                ? _buildEmptyState()
                : _buildNotesList(sortedNotes, provider),
          ),
        ),
        if (_selectionMode) _buildSelectionToolbar(),
      ],
    );
  }

  List<Note> _getFilteredNotes(NotesProvider provider) {
    return provider.filteredNotes(
      notebook: _filterNotebook,
      searchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
      sortBy: _sortOption,
    );
  }

  Widget _buildEmptyState() {
    return EmptyState(
      emoji: _searchQuery.isNotEmpty ? '\u{1F50D}' : '\u{1F4DD}',
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

  Widget _buildStatsBar(int total, int pinned, int notebooks) {
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
  }

  Widget _buildFilterRow(List<String> notebooks) {
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
  }

  Widget _buildNotebookDropdown(List<String> notebooks) {
    final label = _filterNotebook ?? AppLocalizations.of(context).allNotebooks;
    final notebookColor = _filterNotebook != null
        ? context.read<NotesProvider>().getNotebookColor(_filterNotebook!)
        : null;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final selected = await showNotebookPickerModal(
          context,
          selectedNotebook: _filterNotebook,
          allowAll: true,
        );
        if (!mounted) return;
        setState(() => _filterNotebook = selected);
      },
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: BrainTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BrainTheme.borderDark),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: notebookColor?.withValues(alpha: 0.2) ?? BrainTheme.surfaceDark,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder,
                size: 16,
                color: notebookColor ?? BrainTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: BrainTheme.textPrimary, fontSize: 13),
              ),
            ),
            Icon(Icons.expand_more, color: BrainTheme.textSecondary, size: 20),
          ],
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
        tooltip: _isGridView
            ? AppLocalizations.of(context).listView
            : AppLocalizations.of(context).gridView,
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
              child: Icon(Icons.access_time,
                  size: 18, color: BrainTheme.textSecondary),
            ),
            DropdownMenuItem(
              value: SortOption.createdAt,
              child: Icon(Icons.add_circle_outline,
                  size: 18, color: BrainTheme.textSecondary),
            ),
            DropdownMenuItem(
              value: SortOption.title,
              child: Icon(Icons.sort_by_alpha,
                  size: 18, color: BrainTheme.textSecondary),
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

  Widget _buildNotesList(List<Note> notes, NotesProvider provider) {
    if (_isGridView) {
      return MasonryGridView.count(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        itemCount: notes.length,
        itemBuilder: (context, index) {
          final note = notes[index];
          return _buildNoteCard(note, provider);
        },
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildNoteCard(note, provider),
        );
      },
    );
  }

  Widget _buildNoteCard(Note note, NotesProvider provider) {
    return NoteCard(
      note: note,
      searchQuery: _searchQuery,
      isSelected: _selectedNoteIds.contains(note.id),
      onSelect: _selectionMode ? (v) => _toggleSelection(note.id) : null,
      onTap: _selectionMode
          ? () => _toggleSelection(note.id)
          : () => Navigator.pushNamed(context, '/note', arguments: note.id),
      onDelete: _selectionMode
          ? null
          : () => _deleteNoteWithUndo(context, provider, note),
      onTogglePin: _selectionMode ? null : () => provider.togglePin(note.id),
      onCopyContent: _selectionMode ? null : () => _copyNoteContent(note),
      onShare: _selectionMode ? null : () => _shareNote(note),
      onMoveToNotebook: _selectionMode
          ? null
          : () => _showMoveSingleDialog(context, provider, note),
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
