import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../../config/theme.dart';
import '../../models/note.dart';
import '../../providers/notes_provider.dart';
import '../../widgets/note_card.dart';
import '../../widgets/empty_state.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  NoteType? _filterType;
  bool _isGridView = true;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: TextField(
            controller: _searchController,
            onChanged: (v) =>
                setState(() => _searchQuery = v.toLowerCase()),
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
        ),
        // Filter bar
        SizedBox(
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
                onTap: () =>
                    setState(() => _filterType = NoteType.meetingNotes),
              ),
              const SizedBox(width: 8),
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
        ),
        const SizedBox(height: 8),

        // Notes
        Expanded(
          child: Consumer<NotesProvider>(
            builder: (context, provider, _) {
              var notes = _filterType != null
                  ? provider.getNotesByType(_filterType!)
                  : provider.notes;

              if (_searchQuery.isNotEmpty) {
                notes = notes
                    .where((n) =>
                        n.title.toLowerCase().contains(_searchQuery) ||
                        n.content.toLowerCase().contains(_searchQuery) ||
                        n.notebook.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              // Sort: pinned first, then by date
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
                  actionLabel:
                      _searchQuery.isNotEmpty ? null : 'Nueva Nota',
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
          ),
        ),
      ],
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
              color:
                  isSelected ? BrainTheme.accentPurple : BrainTheme.borderDark,
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
