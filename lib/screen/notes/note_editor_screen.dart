import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/note.dart';
import '../../utils/notification_service_v2.dart';
import '../../models/tag.dart';
import '../../providers/notes_provider.dart';
import '../../providers/projects_provider.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _notebookController = TextEditingController(text: 'General');

  NoteType _type = NoteType.freeform;
  String _emoji = '📝';
  String? _projectId;
  List<String> _selectedTags = [];
  bool _isPinned = false;

  bool get _isEditing => widget.noteId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final note = context.read<NotesProvider>().getNoteById(widget.noteId!);
        if (note != null) {
          setState(() {
            _titleController.text = note.title;
            _contentController.text = note.content;
            _notebookController.text = note.notebook;
            _type = note.type;
            _emoji = note.emoji;
            _projectId = note.projectId;
            _selectedTags = List.from(note.tags);
            _isPinned = note.isPinned;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _notebookController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty) {
      showWarningNotification('El título es obligatorio');
      return;
    }

    final provider = context.read<NotesProvider>();

    if (_isEditing) {
      final note = provider.getNoteById(widget.noteId!);
      if (note != null) {
        await provider.updateNote(note.copyWith(
          title: _titleController.text,
          content: _contentController.text,
          type: _type,
          notebook: _notebookController.text.trim().isEmpty
              ? 'General'
              : _notebookController.text.trim(),
          emoji: _emoji,
          projectId: _projectId,
          tags: _selectedTags,
          isPinned: _isPinned,
        ));
      }
    } else {
      await provider.addNote(
        title: _titleController.text,
        content: _contentController.text,
        type: _type,
        notebook: _notebookController.text.trim().isEmpty
            ? 'General'
            : _notebookController.text.trim(),
        emoji: _emoji,
        projectId: _projectId,
        tags: _selectedTags,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Nota' : 'Nueva Nota'),
        actions: [
          // Pin
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? BrainTheme.accentOrange : null,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          if (_isEditing)
            IconButton(
              icon:
                  Icon(Icons.delete_outline, color: BrainTheme.accentRed),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: BrainTheme.cardDark,
                    title: Text('Eliminar nota', style: TextStyle(color: BrainTheme.textPrimary)),
                    content: Text('Se moverá a la papelera. ¿Deseas continuar?', style: TextStyle(color: BrainTheme.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: FilledButton.styleFrom(backgroundColor: BrainTheme.accentRed, foregroundColor: Colors.white),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await context.read<NotesProvider>().deleteNote(widget.noteId!);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
          TextButton(
            onPressed: _save,
            child: const Text('Guardar',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Note type selector
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: NoteType.values.map((type) {
                  final isSelected = _type == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _type = type),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
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
                          _typeLabel(type),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? BrainTheme.accentPurple
                                : BrainTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Emoji + Title
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showEmojiPicker,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: BrainTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: BrainTheme.borderDark),
                      ),
                      child: Center(
                        child:
                            Text(_emoji, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Título de la nota...',
                        border: InputBorder.none,
                        filled: false,
                      ),
                      autofocus: !_isEditing,
                    ),
                  ),
                ],
              ),
            ),

            // Project selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<ProjectsProvider>(
                builder: (context, projects, _) {
                  return Row(
                    children: [
                      Icon(Icons.folder_outlined,
                          size: 18, color: BrainTheme.textTertiary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButton<String?>(
                          value: _projectId,
                          isExpanded: true,
                          dropdownColor: BrainTheme.cardDark,
                          underline: const SizedBox.shrink(),
                          hint: const Text('Sin proyecto'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Sin proyecto'),
                            ),
                            ...projects.projects.map((p) => DropdownMenuItem(
                                  value: p.id,
                                  child: Text('${p.emoji} ${p.title}'),
                                )),
                          ],
                          onChanged: (v) => setState(() => _projectId = v),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.menu_book_outlined,
                      size: 18, color: BrainTheme.textTertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _notebookController,
                      decoration: const InputDecoration(
                        labelText: 'Cuaderno',
                        hintText: 'General',
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tags
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Tag.defaultTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag.id);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedTags.remove(tag.id);
                        } else {
                          _selectedTags.add(tag.id);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? tag.color.withValues(alpha: 0.2)
                            : BrainTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? tag.color : BrainTheme.borderDark,
                        ),
                      ),
                      child: Text(
                        tag.name,
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              isSelected ? tag.color : BrainTheme.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            Divider(color: BrainTheme.borderDark),

            // Content editor
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _contentController,
                style: TextStyle(
                  fontSize: 15,
                  color: BrainTheme.textPrimary,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: _getHintForType(_type),
                  border: InputBorder.none,
                  filled: false,
                ),
                maxLines: null,
                minLines: 15,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(NoteType type) {
    switch (type) {
      case NoteType.freeform:
        return '📝 Libre';
      case NoteType.checklist:
        return '✓ Checklist';
      case NoteType.journal:
        return '📔 Diario';
      case NoteType.reference:
        return '📎 Referencia';
      case NoteType.meetingNotes:
        return '💡 Reunion';
    }
  }

  String _getHintForType(NoteType type) {
    switch (type) {
      case NoteType.freeform:
        return 'Escribe tus pensamientos...';
      case NoteType.checklist:
        return '- [ ] Elemento 1\n- [ ] Elemento 2\n- [x] Completado';
      case NoteType.journal:
        return 'Hoy me siento...\n\nLogros del día:\n\nReflexiones:';
      case NoteType.reference:
        return 'Fuente:\n\nPuntos clave:\n\nNotas:';
      case NoteType.meetingNotes:
        return 'Participantes:\n\nAgenda:\n\nDecisiones:\n\nSiguientes pasos:';
    }
  }

  void _showEmojiPicker() {
    final noteEmojis = [
      '📝',
      '💡',
      '🎯',
      '📗',
      '🗂️',
      '📌',
      '💻',
      '🗒️',
      '✍️',
      '📎',
      '🧠',
      '📓',
      '✏️',
      '📖',
      '🪄',
      '📚',
    ];

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Elegir Emoji',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: noteEmojis.map((e) {
                return GestureDetector(
                  onTap: () {
                    setState(() => _emoji = e);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: BrainTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: e == _emoji
                            ? BrainTheme.accentPurple
                            : BrainTheme.borderDark,
                      ),
                    ),
                    child: Center(
                      child: Text(e, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
