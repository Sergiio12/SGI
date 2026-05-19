import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/note.dart';
import '../services/storage_service.dart';
import '../utils/debouncer.dart';
import '../utils/notification_service_v2.dart';

class NotesProvider extends ChangeNotifier {
  List<Note> _notes = [];
  final _uuid = const Uuid();
  bool _isLoaded = false;
  final _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

  List<Note> _pinnedNotes = [];
  List<Note> _unpinnedNotes = [];
  List<Note> _recentNotes = [];
  List<String> _notebooks = ['General'];

  List<Note> get notes => _notes;
  bool get isLoaded => _isLoaded;

  List<Note> get pinnedNotes => _pinnedNotes;
  List<Note> get unpinnedNotes => _unpinnedNotes;
  List<Note> get recentNotes => _recentNotes;
  List<String> get notebooks => _notebooks;

  Map<String, int> get notebookCounts {
    final counts = <String, int>{};
    for (final n in _notes) {
      counts[n.notebook] = (counts[n.notebook] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, int> get tagCounts {
    final counts = <String, int>{};
    for (final n in _notes) {
      for (final tag in n.tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  Future<void> loadNotes() async {
    _notes = await StorageService.loadNotes();
    _updateComputedLists();
    _isLoaded = true;
    notifyListeners();
  }

  void _updateComputedLists() {
    _pinnedNotes = _notes.where((n) => n.isPinned).toList();
    _unpinnedNotes = _notes.where((n) => !n.isPinned).toList();

    final sorted = [..._notes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    _recentNotes = sorted.take(10).toList();

    final values = _notes.map((n) => n.notebook).toSet().toList()..sort();
    _notebooks = values.isEmpty ? ['General'] : values;
  }

  void _notifyAndScheduleSave() {
    _updateComputedLists();
    notifyListeners();
    _saveDebouncer.call(() => StorageService.saveNotes(_notes));
  }

  List<Note> getNotesByProject(String projectId) =>
      _notes.where((n) => n.projectId == projectId).toList();

  List<Note> getNotesByTag(String tag) =>
      _notes.where((n) => n.tags.contains(tag)).toList();

  List<Note> getNotesByTags(List<String> tags) => _notes
      .where((n) => tags.any((t) => n.tags.contains(t)))
      .toList();

  List<Note> getNotesByType(NoteType type) =>
      _notes.where((n) => n.type == type).toList();

  List<Note> getNotesByNotebook(String notebook) =>
      _notes.where((n) => n.notebook == notebook).toList();

  Note? getNoteById(String id) {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Note> addNote({
    required String title,
    String content = '',
    NoteType type = NoteType.freeform,
    String notebook = 'General',
    String? projectId,
    String emoji = '\u{1F4DD}',
    List<String> tags = const [],
    List<NoteAttachment> attachments = const [],
    bool isPinned = false,
  }) async {
    try {
      final now = DateTime.now();
      final note = Note(
        id: _uuid.v4(),
        title: title,
        content: content,
        attachments: attachments,
        type: type,
        notebook: notebook,
        projectId: projectId,
        emoji: emoji,
        tags: tags,
        isPinned: isPinned,
        createdAt: now,
        updatedAt: now,
      );
      _notes.add(note);
      _notifyAndScheduleSave();
      showSuccessNotification('Nota creada: ${note.title}');
      return note;
    } catch (e) {
      showErrorNotification('Error al crear nota');
      rethrow;
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        _notifyAndScheduleSave();
      }
    } catch (e) {
      showErrorNotification('Error al actualizar nota');
      rethrow;
    }
  }

  Future<void> togglePin(String noteId) async {
    try {
      final index = _notes.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        final note = _notes[index];
        _notes[index] = note.copyWith(isPinned: !note.isPinned);
        _notifyAndScheduleSave();
        showSuccessNotification(
            note.isPinned ? 'Nota desanclada' : 'Nota anclada');
      }
    } catch (e) {
      showErrorNotification('Error al cambiar anclaje de nota');
      rethrow;
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      final index = _notes.indexWhere((n) => n.id == noteId);
      if (index == -1) return;
      final note = _notes.removeAt(index);
      final trash = await StorageService.loadTrashNotes();
      trash.add(note);
      await StorageService.saveTrashNotes(trash);
      _notifyAndScheduleSave();
      showSuccessNotification('Nota movida a la papelera');
    } catch (e) {
      showErrorNotification('Error al eliminar nota');
      rethrow;
    }
  }

  Future<void> restoreNote(String noteId) async {
    try {
      final trash = await StorageService.loadTrashNotes();
      final index = trash.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        final note = trash.removeAt(index);
        _notes.add(note);
        await StorageService.saveTrashNotes(trash);
        _notifyAndScheduleSave();
        showSuccessNotification('Nota restaurada');
      }
    } catch (e) {
      showErrorNotification('Error al restaurar nota');
      rethrow;
    }
  }

  Future<void> permanentDeleteNote(String noteId) async {
    try {
      final trash = await StorageService.loadTrashNotes();
      trash.removeWhere((n) => n.id == noteId);
      await StorageService.saveTrashNotes(trash);
      showSuccessNotification('Nota eliminada permanentemente');
    } catch (e) {
      showErrorNotification('Error al eliminar nota');
      rethrow;
    }
  }

  Future<void> renameNotebook(String oldName, String newName) async {
    if (oldName == newName || newName.trim().isEmpty) return;
    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].notebook == oldName) {
        _notes[i] = _notes[i].copyWith(notebook: newName.trim());
      }
    }
    _notifyAndScheduleSave();
    showSuccessNotification('Cuaderno renombrado');
  }

  Future<void> deleteNotebook(String name) async {
    for (var i = 0; i < _notes.length; i++) {
      if (_notes[i].notebook == name) {
        _notes[i] = _notes[i].copyWith(notebook: 'General');
      }
    }
    _notifyAndScheduleSave();
    showSuccessNotification('Cuaderno eliminado, notas movidas a General');
  }

  Future<void> replaceAll(List<Note> notes) async {
    _notes = notes;
    _notifyAndScheduleSave();
  }

  List<Note> search(String query) {
    if (query.isEmpty) return [];
    final lower = query.toLowerCase();
    return _notes.where((n) {
      return n.title.toLowerCase().contains(lower) ||
          n.content.toLowerCase().contains(lower) ||
          n.notebook.toLowerCase().contains(lower) ||
          n.tags.any((t) => t.toLowerCase().contains(lower));
    }).toList();
  }

  List<Note> filteredNotes({
    NoteType? type,
    String? notebook,
    List<String>? tags,
    String? searchQuery,
    String? projectId,
  }) {
    var result = _notes;

    if (projectId != null) {
      result = result.where((n) => n.projectId == projectId).toList();
    }
    if (type != null) {
      result = result.where((n) => n.type == type).toList();
    }
    if (notebook != null) {
      result = result.where((n) => n.notebook == notebook).toList();
    }
    if (tags != null && tags.isNotEmpty) {
      result = result.where((n) => tags.any((t) => n.tags.contains(t))).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final lower = searchQuery.toLowerCase();
      result = result.where((n) {
        return n.title.toLowerCase().contains(lower) ||
            n.content.toLowerCase().contains(lower) ||
            n.notebook.toLowerCase().contains(lower) ||
            n.tags.any((t) => t.toLowerCase().contains(lower));
      }).toList();
    }

    return result;
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }
}
