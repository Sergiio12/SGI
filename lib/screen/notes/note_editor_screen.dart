import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/note.dart';
import '../../utils/notification_service_v2.dart';
import '../../providers/notes_provider.dart';
import '../../providers/tags_provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
  List<NoteAttachment> _attachments = [];

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
            _attachments = List.from(note.attachments);
          });
        }
      });
      // ensure tags loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final tagsProv = context.read<TagsProvider>();
        if (!tagsProv.isLoaded) tagsProv.loadTags();
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
          attachments: _attachments,
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
        attachments: _attachments,
        type: _type,
        notebook: _notebookController.text.trim().isEmpty
            ? 'General'
            : _notebookController.text.trim(),
        emoji: _emoji,
        projectId: _projectId,
        tags: _selectedTags,
        isPinned: _isPinned,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  void _showTagPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: 480,
            padding: const EdgeInsets.all(16),
            child: Consumer<TagsProvider>(builder: (context, tagsProv, _) {
              final tags = tagsProv.tags;
              return Column(
                children: [
                  const Text('Seleccionar etiquetas',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: tags.map((t) {
                        final isSelected = _selectedTags.contains(t.id);
                        return CheckboxListTile(
                          title: Text(t.name),
                          value: isSelected,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              if (!_selectedTags.contains(t.id))
                                _selectedTags.add(t.id);
                            } else {
                              _selectedTags.remove(t.id);
                            }
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Listo'))
                ],
              );
            }),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Nota' : 'Nueva Nota'),
        actions: [
          IconButton(
            icon: Icon(
              _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              color: _isPinned ? BrainTheme.accentOrange : null,
            ),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: BrainTheme.accentRed),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: BrainTheme.cardDark,
                    title: Text('Eliminar nota',
                        style: TextStyle(color: BrainTheme.textPrimary)),
                    content: Text('Se moverá a la papelera. ¿Deseas continuar?',
                        style: TextStyle(color: BrainTheme.textSecondary)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                              backgroundColor: BrainTheme.accentRed,
                              foregroundColor: Colors.white),
                          child: const Text('Eliminar')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await context
                      .read<NotesProvider>()
                      .deleteNote(widget.noteId!);
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
          TextButton(
              onPressed: _save,
              child: const Text('Guardar',
                  style: TextStyle(fontWeight: FontWeight.w600))),
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

            // Tags moved up to be more visible (below title)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Consumer<TagsProvider>(builder: (context, tagsProv, _) {
                final selected = tagsProv.tags
                    .where((t) => _selectedTags.contains(t.id))
                    .toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selected.isEmpty
                          ? [
                              Text('Sin etiquetas',
                                  style:
                                      TextStyle(color: BrainTheme.textTertiary))
                            ]
                          : selected
                              .map((tag) => GestureDetector(
                                    onTap: () => setState(
                                        () => _selectedTags.remove(tag.id)),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color:
                                            tag.color.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: tag.color),
                                      ),
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(tag.name,
                                                style: TextStyle(
                                                    color: tag.color)),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.close, size: 14)
                                          ]),
                                    ),
                                  ))
                              .toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      TextButton.icon(
                          onPressed: () => _showTagPicker(),
                          icon: const Icon(Icons.add),
                          label: const Text('Editar etiquetas')),
                      const SizedBox(width: 8),
                      TextButton.icon(
                          onPressed: () => _showManageTagsModal(),
                          icon: const Icon(Icons.edit),
                          label: const Text('Gestionar etiquetas')),
                    ])
                  ],
                );
              }),
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

            // Attachments
            if (_attachments.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Adjuntos',
                        style: TextStyle(
                            color: BrainTheme.textSecondary,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    ..._attachments.map((a) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.attach_file),
                          title: Text(a.fileName,
                              style: TextStyle(color: BrainTheme.textPrimary)),
                          subtitle: Text(
                              '${(a.size / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(color: BrainTheme.textTertiary)),
                          trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() => _attachments
                                  .removeWhere((x) => x.id == a.id))),
                        )),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilledButton.icon(
                    onPressed: _pickFiles,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Adjuntar archivo'),
                    style: FilledButton.styleFrom(
                        backgroundColor: BrainTheme.surfaceDark,
                        foregroundColor: BrainTheme.textPrimary),
                  ),
                ],
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

  void _showManageTagsModal() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          final nameCtrl = TextEditingController();
          int colorValue = BrainTheme.accentPurple.value;
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: 420,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Gestionar etiquetas',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Expanded(child:
                      Consumer<TagsProvider>(builder: (context, prov, _) {
                    return ListView(
                      children: prov.tags
                          .map((t) => ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: t.color, radius: 16),
                                title: Text(t.name),
                                trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            nameCtrl.text = t.name;
                                            showDialog(
                                                context: context,
                                                builder: (dctx) => AlertDialog(
                                                      title: const Text(
                                                          'Editar etiqueta'),
                                                      content: TextField(
                                                          controller: nameCtrl,
                                                          decoration:
                                                              const InputDecoration(
                                                                  hintText:
                                                                      'Nombre')),
                                                      actions: [
                                                        TextButton(
                                                            onPressed: () =>
                                                                Navigator.pop(
                                                                    dctx),
                                                            child: const Text(
                                                                'Cancelar')),
                                                        FilledButton(
                                                            onPressed:
                                                                () async {
                                                              await prov.updateTag(
                                                                  t.copyWith(
                                                                      name: nameCtrl
                                                                          .text));
                                                              Navigator.pop(
                                                                  dctx);
                                                              Navigator.pop(
                                                                  ctx);
                                                            },
                                                            child: const Text(
                                                                'Guardar'))
                                                      ],
                                                    ));
                                          }),
                                      IconButton(
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          onPressed: () =>
                                              prov.deleteTag(t.id)),
                                    ]),
                              ))
                          .toList(),
                    );
                  })),
                  const Divider(),
                  TextField(
                      controller: nameCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Nueva etiqueta')),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                          child: FilledButton(
                              onPressed: () async {
                                if (nameCtrl.text.trim().isEmpty) return;
                                await context.read<TagsProvider>().addTag(
                                    name: nameCtrl.text.trim(),
                                    colorValue: colorValue);
                                nameCtrl.clear();
                              },
                              child: const Text('Crear')))
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _pickFiles() async {
    final result = await fp.FilePicker.pickFiles(allowMultiple: true);
    if (result == null) return;
    final appDir = await getApplicationDocumentsDirectory();
    final uuid = const Uuid();
    for (final file in result.files) {
      try {
        if (file.path == null) continue;
        final src = File(file.path!);
        final destFileName = '${uuid.v4()}_${file.name}';
        final dest = File('${appDir.path}/$destFileName');
        await src.copy(dest.path);
        setState(() {
          _attachments.add(NoteAttachment(
            id: uuid.v4(),
            fileName: file.name,
            path: dest.path,
            size: file.size,
          ));
        });
      } catch (e) {
        // ignore copy errors silently
      }
    }
  }
}
