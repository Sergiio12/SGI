import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:second_brain/l10n/app_localizations.dart';

import '../../config/theme.dart';
import '../../models/note.dart';
import '../../models/tag.dart';
import '../../utils/notification_service_v2.dart';
import '../../providers/notes_provider.dart';
import '../../providers/tags_provider.dart';
import '../../widgets/tag_color_picker.dart';

class NoteEditorScreen extends StatefulWidget {
  final String? noteId;

  const NoteEditorScreen({super.key, this.noteId});

  @override
  State<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends State<NoteEditorScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  NoteType _type = NoteType.freeform;
  String _emoji = '📝';
  String? _projectId;
  List<String> _selectedTagIds = [];
  bool _isPinned = false;
  List<NoteAttachment> _attachments = [];
  String _notebook = 'General';
  bool _isUploading = false;
  String? _uploadError;

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
            _notebook = note.notebook;
            _type = note.type;
            _emoji = note.emoji;
            _projectId = note.projectId;
            _selectedTagIds = List.from(note.tags);
            _isPinned = note.isPinned;
            _attachments = List.from(note.attachments);
          });
        }
      });
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
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      showWarningNotification('El título es obligatorio');
      return;
    }

    final provider = context.read<NotesProvider>();
    final notebook = _notebook.trim().isEmpty ? 'General' : _notebook.trim();

    if (_isEditing) {
      final note = provider.getNoteById(widget.noteId!);
      if (note != null) {
        await provider.updateNote(note.copyWith(
          title: _titleController.text.trim(),
          content: _contentController.text,
          attachments: _attachments,
          type: _type,
          notebook: notebook,
          emoji: _emoji,
          projectId: _projectId,
          tags: _selectedTagIds,
          isPinned: _isPinned,
        ));
      }
    } else {
      await provider.addNote(
        title: _titleController.text.trim(),
        content: _contentController.text,
        attachments: _attachments,
        type: _type,
        notebook: notebook,
        emoji: _emoji,
        projectId: _projectId,
        tags: _selectedTagIds,
        isPinned: _isPinned,
      );
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickFiles() async {
    try {
      setState(() {
        _isUploading = true;
        _uploadError = null;
      });

      final result = await fp.FilePicker.pickFiles(allowMultiple: true);
      if (result == null) {
        setState(() => _isUploading = false);
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final uploadDir = Directory('${appDir.path}/note_attachments');
      if (!await uploadDir.exists()) {
        await uploadDir.create(recursive: true);
      }

      final uuid = const Uuid();
      int successCount = 0;
      int failCount = 0;

      for (final file in result.files) {
        try {
          if (file.path == null) {
            failCount++;
            continue;
          }
          final src = File(file.path!);
          if (!await src.exists()) {
            failCount++;
            continue;
          }
          final destFileName = '${uuid.v4()}_${file.name}';
          final dest = File('${uploadDir.path}/$destFileName');
          await src.copy(dest.path);

          setState(() {
            _attachments.add(NoteAttachment(
              id: uuid.v4(),
              fileName: file.name,
              path: dest.path,
              size: file.size,
            ));
          });
          successCount++;
        } catch (e) {
          failCount++;
        }
      }

      setState(() => _isUploading = false);

      if (!mounted) return;
      if (failCount > 0 && successCount > 0) {
        showWarningNotification(
            '$successCount archivo(s) subido(s), $failCount fallaron');
      } else if (failCount > 0) {
        setState(() => _uploadError = 'Error al subir $failCount archivo(s)');
        showErrorNotification('Error al subir archivos');
      } else if (successCount > 0) {
        showSuccessNotification('$successCount archivo(s) adjuntado(s)');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadError = 'Error inesperado al seleccionar archivos';
      });
      showErrorNotification('Error al seleccionar archivos');
    }
  }

  Future<void> _openAttachment(NoteAttachment attachment) async {
    try {
      final file = File(attachment.path);
      if (!await file.exists()) {
        showErrorNotification('El archivo ya no existe en esta ubicación');
        return;
      }
      if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', attachment.path]);
      } else if (Platform.isAndroid || Platform.isIOS) {
        showWarningNotification('Abre el archivo desde: ${attachment.path}');
      } else if (Platform.isMacOS) {
        await Process.run('open', [attachment.path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [attachment.path]);
      }
    } catch (e) {
      showErrorNotification('No se pudo abrir el archivo');
    }
  }

  IconData _fileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam;
      case 'mp3':
      case 'wav':
      case 'aac':
        return Icons.audiotrack;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.folder_zip;
      case 'txt':
        return Icons.article;
      default:
        return Icons.attach_file;
    }
  }

  Color _fileColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Colors.redAccent;
      case 'doc':
      case 'docx':
        return Colors.blueAccent;
      case 'xls':
      case 'xlsx':
        return Colors.greenAccent;
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'webp':
        return Colors.cyanAccent;
      default:
        return BrainTheme.accentPurple;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showTagPicker() {
    showModalBottomSheet(
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
            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppLocalizations.of(context).tags,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Toca para asignar etiquetas a esta nota',
                        style: TextStyle(
                            color: BrainTheme.textTertiary, fontSize: 13)),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Consumer<TagsProvider>(
                          builder: (context, tagsProv, _) {
                        final noteTags = tagsProv.getTags(TagType.note);
                        if (noteTags.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Sin etiquetas',
                                    style: TextStyle(
                                        color: BrainTheme.textTertiary)),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _showManageTagsModal();
                                  },
                                  child: const Text('Crear etiquetas'),
                                ),
                              ],
                            ),
                          );
                        }
                        return ListView(
                          controller: scrollController,
                          children: noteTags.map((t) {
                            final isSelected = _selectedTagIds.contains(t.id);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 6),
                              color: isSelected
                                  ? t.color.withValues(alpha: 0.1)
                                  : BrainTheme.surfaceDark,
                              child: ListTile(
                                leading: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: t.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(t.name,
                                    style: TextStyle(
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal)),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle,
                                        color: t.color, size: 22)
                                    : Icon(Icons.circle_outlined,
                                        color: BrainTheme.textTertiary,
                                        size: 22),
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      _selectedTagIds.remove(t.id);
                                    } else {
                                      _selectedTagIds.add(t.id);
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
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showManageTagsModal();
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Gestionar etiquetas'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNotebookPicker() {
    final provider = context.read<NotesProvider>();
    final notebooks = provider.notebooks;
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
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
                    Text(AppLocalizations.of(context).notebook,
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'Nuevo cuaderno...',
                    prefixIcon: const Icon(Icons.add, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      setState(() => _notebook = value.trim());
                      Navigator.pop(ctx);
                    }
                  },
                ),
                const SizedBox(height: 12),
                if (notebooks.isNotEmpty)
                  SizedBox(
                    height: notebooks.length * 56.0,
                    child: ListView(
                      children: notebooks
                          .map((nb) => ListTile(
                                leading: Icon(
                                  _notebook == nb
                                      ? Icons.folder
                                      : Icons.folder_outlined,
                                  color: _notebook == nb
                                      ? BrainTheme.accentPurple
                                      : BrainTheme.textSecondary,
                                ),
                                title: Text(nb,
                                    style: TextStyle(
                                        fontWeight: _notebook == nb
                                            ? FontWeight.w600
                                            : FontWeight.normal)),
                                trailing: _notebook == nb
                                    ? Icon(Icons.check,
                                        color: BrainTheme.accentPurple)
                                    : null,
                                onTap: () {
                                  setState(() => _notebook = nb);
                                  Navigator.pop(ctx);
                                },
                              ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showManageTagsModal() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (ctx) {
          final nameCtrl = TextEditingController();
          int newTagColorValue = BrainTheme.accentPurple.toARGB32();
          return StatefulBuilder(builder: (mctx, setModalState) {
            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: Container(
                height: 520,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Gestionar etiquetas',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(child:
                        Consumer<TagsProvider>(builder: (context, prov, _) {
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
                                    child: const Icon(Icons.delete,
                                        color: Colors.white),
                                  ),
                                  onDismissed: (_) => prov.deleteTag(t.id),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                        backgroundColor: t.color, radius: 14),
                                    title: Text(t.name),
                                    trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                              icon: const Icon(Icons.edit,
                                                  size: 20),
                                              onPressed: () {
                                                int editColorValue =
                                                    t.color.toARGB32();
                                                final editNameCtrl =
                                                    TextEditingController(
                                                        text: t.name);
                                                showDialog(
                                                    context: context,
                                                    builder: (dctx) =>
                                                        StatefulBuilder(
                                                            builder: (dState,
                                                                    setDialogState) =>
                                                                AlertDialog(
                                                                  title: const Text(
                                                                      'Editar etiqueta'),
                                                                  content:
                                                                      SingleChildScrollView(
                                                                          child: Column(
                                                                              mainAxisSize: MainAxisSize.min,
                                                                              children: [
                                                                        TextField(
                                                                            controller:
                                                                                editNameCtrl,
                                                                            decoration:
                                                                                const InputDecoration(hintText: 'Nombre')),
                                                                        const SizedBox(
                                                                            height:
                                                                                16),
                                                                        TagColorPicker(
                                                                          selectedColorValue:
                                                                              editColorValue,
                                                                          onColorChanged: (v) =>
                                                                              setDialogState(() => editColorValue = v),
                                                                        ),
                                                                      ])),
                                                                  actions: [
                                                                    TextButton(
                                                                        onPressed: () =>
                                                                            Navigator.pop(
                                                                                dctx),
                                                                        child: Text(
                                                                            AppLocalizations.of(dState).cancel)),
                                                                    FilledButton(
                                                                        onPressed:
                                                                            () async {
                                                                          await prov.updateTag(t.copyWith(
                                                                              name: editNameCtrl.text,
                                                                              color: Color(editColorValue)));
                                                                          Navigator.pop(
                                                                              dctx);
                                                                        },
                                                                        child: Text(
                                                                            AppLocalizations.of(dState).save))
                                                                  ],
                                                                )));
                                              }),
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 20),
                                              onPressed: () =>
                                                  prov.deleteTag(t.id)),
                                        ]),
                                  ),
                                ))
                            .toList(),
                      );
                    })),
                    const Divider(),
                    const Text('Crear nueva etiqueta',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(
                                hintText: 'Nombre',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TagColorPicker(
                      selectedColorValue: newTagColorValue,
                      onColorChanged: (v) =>
                          setModalState(() => newTagColorValue = v),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: () async {
                            if (nameCtrl.text.trim().isEmpty) return;
                            await context.read<TagsProvider>().addTag(
                                name: nameCtrl.text.trim(),
                                colorValue: newTagColorValue);
                            nameCtrl.clear();
                            setModalState(() => newTagColorValue =
                                BrainTheme.accentPurple.toARGB32());
                          },
                          child: const Text('Crear etiqueta')),
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? AppLocalizations.of(context).editNote
            : AppLocalizations.of(context).createNote),
        actions: [
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.delete_outline, color: BrainTheme.accentRed),
              tooltip: AppLocalizations.of(context).delete,
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(
                        '${AppLocalizations.of(ctx).delete} ${AppLocalizations.of(ctx).note}'),
                    content: const Text('Se moverá a la papelera.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(AppLocalizations.of(ctx).cancel)),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                              backgroundColor: BrainTheme.accentRed,
                              foregroundColor: Colors.white),
                          child: Text(AppLocalizations.of(ctx).delete)),
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
          FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(AppLocalizations.of(context).save,
                  style: TextStyle(fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 8),
            _buildEmojiAndTitle(),
            const SizedBox(height: 12),
            _buildMetadataRow(),
            const SizedBox(height: 12),
            _buildTagsSection(),
            const Divider(height: 24),
            _buildContentEditor(),
            const Divider(height: 24),
            _buildAttachmentsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SizedBox(
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
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                    fontWeight: isSelected ? FontWeight.w600 : null,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmojiAndTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                child: Text(_emoji, style: const TextStyle(fontSize: 24)),
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
    );
  }

  Widget _buildMetadataRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _MetadataChip(
              icon: Icons.folder_outlined,
              label: _notebook,
              onTap: _showNotebookPicker,
            ),
          ),
          const SizedBox(width: 8),
          _MetadataChip(
            icon: _isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            label: _isPinned ? 'Anclado' : 'Anclar',
            active: _isPinned,
            activeColor: BrainTheme.accentOrange,
            onTap: () => setState(() => _isPinned = !_isPinned),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    return Consumer<TagsProvider>(builder: (context, tagsProv, _) {
      final selectedTags = _selectedTagIds
          .map((id) => tagsProv.getById(id))
          .whereType<Tag>()
          .toList();

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(AppLocalizations.of(context).tags,
                    style: TextStyle(
                        color: BrainTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const Spacer(),
                TextButton(
                  onPressed: _showTagPicker,
                  child: Text(
                    selectedTags.isEmpty ? 'Añadir' : 'Editar',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            if (selectedTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedTags
                    .map((tag) => GestureDetector(
                          onTap: () =>
                              setState(() => _selectedTagIds.remove(tag.id)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: tag.color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: tag.color),
                            ),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Text(tag.name,
                                  style: TextStyle(
                                      color: tag.color, fontSize: 12)),
                              const SizedBox(width: 6),
                              Icon(Icons.close, size: 14, color: tag.color),
                            ]),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildContentEditor() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
        minLines: 12,
        keyboardType: TextInputType.multiline,
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(AppLocalizations.of(context).attachments,
                  style: TextStyle(
                      color: BrainTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text('(${_attachments.length})',
                    style: TextStyle(
                        color: BrainTheme.textTertiary, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (_attachments.isNotEmpty)
            ..._attachments.map((a) => _AttachmentTile(
                  attachment: a,
                  icon: _fileIcon(a.fileName),
                  iconColor: _fileColor(a.fileName),
                  formattedSize: _formatFileSize(a.size),
                  onOpen: () => _openAttachment(a),
                  onRemove: () => setState(
                      () => _attachments.removeWhere((x) => x.id == a.id)),
                )),
          const SizedBox(height: 12),
          if (_uploadError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_uploadError!,
                  style: TextStyle(
                      color: BrainTheme.accentRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
          OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickFiles,
            icon: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file, size: 18),
            label: Text(_isUploading ? 'Subiendo...' : 'Adjuntar archivo'),
          ),
        ],
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
      '⭐',
      '🔥',
      '✅',
      '🚀',
      '💪',
      '🎨',
      '📊',
      '🔬',
    ];

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Elegir Emoji',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
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
                      color: e == _emoji
                          ? BrainTheme.accentPurple.withValues(alpha: 0.2)
                          : BrainTheme.surfaceDark,
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

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final Color? activeColor;

  const _MetadataChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? (activeColor ?? BrainTheme.accentPurple)
        : BrainTheme.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (activeColor ?? BrainTheme.accentPurple).withValues(alpha: 0.1)
              : BrainTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? (activeColor ?? BrainTheme.accentPurple)
                    .withValues(alpha: 0.3)
                : BrainTheme.borderDark,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12, color: color, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final NoteAttachment attachment;
  final IconData icon;
  final Color iconColor;
  final String formattedSize;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  const _AttachmentTile({
    required this.attachment,
    required this.icon,
    required this.iconColor,
    required this.formattedSize,
    required this.onOpen,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: BrainTheme.surfaceDark,
      child: ListTile(
        dense: true,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          attachment.fileName,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(formattedSize,
            style: TextStyle(fontSize: 11, color: BrainTheme.textTertiary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: 'Abrir archivo',
              onPressed: onOpen,
            ),
            IconButton(
              icon: Icon(Icons.close, size: 18, color: BrainTheme.accentRed),
              tooltip: 'Quitar',
              onPressed: onRemove,
            ),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}
