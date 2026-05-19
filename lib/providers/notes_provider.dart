import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/result.dart';
import '../models/note.dart';
import '../services/interfaces/storage_service_interface.dart';
import '../utils/debouncer.dart';
import '../utils/haptic_helper.dart';
import '../utils/notification_service_v2.dart';

class NotesProvider extends ChangeNotifier {
  final IStorageService _storage;
  List<Note> _notes = [];
  final _uuid = const Uuid();
  bool _isLoaded = false;
  int _displayCount = 50;
  static const int _pageSize = 50;
  final _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

  int _lastFilteredCount = 0;

  bool get hasMore => _displayCount < _lastFilteredCount;

  void loadMore() {
    if (!hasMore) return;
    _displayCount = (_displayCount + _pageSize).clamp(0, _notes.length);
    notifyListeners();
  }

  void resetPagination() {
    _displayCount = _pageSize;
    _lastFilteredCount = 0;
  }

  NotesProvider({required IStorageService storage}) : _storage = storage;

  List<Note> _pinnedNotes = [];
  List<Note> _unpinnedNotes = [];
  List<Note> _recentNotes = [];
  List<String> _notebooks = ['General'];
  Map<String, int> _cachedNotebookCounts = {};
  Map<String, int> _cachedTagCounts = {};

  List<Note> get notes => _notes;
  bool get isLoaded => _isLoaded;

  List<Note> get pinnedNotes => _pinnedNotes;
  List<Note> get unpinnedNotes => _unpinnedNotes;
  List<Note> get recentNotes => _recentNotes;
  List<String> get notebooks => _notebooks;
  Map<String, int> get notebookCounts => _cachedNotebookCounts;
  Map<String, int> get tagCounts => _cachedTagCounts;

  Future<void> loadNotes() async {
    _notes = await _storage.loadNotes();
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

    _cachedNotebookCounts = {};
    for (final n in _notes) {
      _cachedNotebookCounts[n.notebook] =
          (_cachedNotebookCounts[n.notebook] ?? 0) + 1;
    }

    _cachedTagCounts = {};
    for (final n in _notes) {
      for (final tag in n.tags) {
        _cachedTagCounts[tag] = (_cachedTagCounts[tag] ?? 0) + 1;
      }
    }
  }

  void _notifyAndScheduleSave() {
    _updateComputedLists();
    notifyListeners();
    _saveDebouncer.call(() => _storage.saveNotes(_notes));
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

  Future<Result<Note>> addNote({
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
      HapticHelper.light();
      showSuccessNotification('Nota creada: ${note.title}');
      return Result.success(note);
    } catch (e, s) {
      final error = AppException(
        message: 'Error al crear nota',
        code: 'ADD_NOTE',
        stackTrace: s,
      );
      error.log();
      showErrorNotification(error.message);
      return Result.failure(error);
    }
  }

  Future<void> updateNote(Note note) async {
    try {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) {
        _notes[index] = note;
        _notifyAndScheduleSave();
      }
    } catch (e, s) {
      AppException(message: 'Error al actualizar nota', code: 'UPDATE_NOTE', stackTrace: s).log();
      showErrorNotification('Error al actualizar nota');
    }
  }

  Future<void> togglePin(String noteId) async {
    try {
      final index = _notes.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        final note = _notes[index];
        final newPinned = !note.isPinned;
        _notes[index] = note.copyWith(isPinned: newPinned);
        _notifyAndScheduleSave();
        HapticHelper.selection();
        showSuccessNotification(newPinned ? 'Nota anclada' : 'Nota desanclada');
      }
    } catch (e, s) {
      AppException(message: 'Error al cambiar anclaje de nota', code: 'TOGGLE_PIN', stackTrace: s).log();
      showErrorNotification('Error al cambiar anclaje de nota');
    }
  }

  Future<void> deleteNote(String noteId) async {
    try {
      final index = _notes.indexWhere((n) => n.id == noteId);
      if (index == -1) return;
      final note = _notes.removeAt(index);
      final trash = await _storage.loadTrashNotes();
      trash.add(note);
      await _storage.saveTrashNotes(trash);
      _notifyAndScheduleSave();
      HapticHelper.medium();
      showSuccessNotification('Nota movida a la papelera');
    } catch (e, s) {
      AppException(message: 'Error al eliminar nota', code: 'DELETE_NOTE', stackTrace: s).log();
      showErrorNotification('Error al eliminar nota');
    }
  }

  Future<void> restoreNote(String noteId) async {
    try {
      final trash = await _storage.loadTrashNotes();
      final index = trash.indexWhere((n) => n.id == noteId);
      if (index != -1) {
        final note = trash.removeAt(index);
        _notes.add(note);
        await _storage.saveTrashNotes(trash);
        _notifyAndScheduleSave();
        HapticHelper.light();
        showSuccessNotification('Nota restaurada');
      }
    } catch (e, s) {
      AppException(message: 'Error al restaurar nota', code: 'RESTORE_NOTE', stackTrace: s).log();
      showErrorNotification('Error al restaurar nota');
    }
  }

  Future<void> permanentDeleteNote(String noteId) async {
    try {
      final trash = await _storage.loadTrashNotes();
      trash.removeWhere((n) => n.id == noteId);
      await _storage.saveTrashNotes(trash);
      showSuccessNotification('Nota eliminada permanentemente');
    } catch (e, s) {
      AppException(message: 'Error al eliminar nota permanentemente', code: 'PERM_DELETE_NOTE', stackTrace: s).log();
      showErrorNotification('Error al eliminar nota');
    }
  }

  Future<void> renameNotebook(String oldName, String newName) async {
    if (oldName == newName || newName.trim().isEmpty) return;
    try {
      for (var i = 0; i < _notes.length; i++) {
        if (_notes[i].notebook == oldName) {
          _notes[i] = _notes[i].copyWith(notebook: newName.trim());
        }
      }
      _notifyAndScheduleSave();
      showSuccessNotification('Cuaderno renombrado');
    } catch (e, s) {
      AppException(message: 'Error al renombrar cuaderno', code: 'RENAME_NOTEBOOK', stackTrace: s).log();
    }
  }

  Future<void> deleteNotebook(String name) async {
    try {
      for (var i = 0; i < _notes.length; i++) {
        if (_notes[i].notebook == name) {
          _notes[i] = _notes[i].copyWith(notebook: 'General');
        }
      }
      _notifyAndScheduleSave();
      showSuccessNotification('Cuaderno eliminado, notas movidas a General');
    } catch (e, s) {
      AppException(message: 'Error al eliminar cuaderno', code: 'DELETE_NOTEBOOK', stackTrace: s).log();
    }
  }

  Future<void> replaceAll(List<Note> notes) async {
    _notes = notes;
    _notifyAndScheduleSave();
  }

  bool _matchesQuery(Note note, String query) {
    final lower = query.toLowerCase();
    return note.title.toLowerCase().contains(lower) ||
        note.content.toLowerCase().contains(lower) ||
        note.notebook.toLowerCase().contains(lower) ||
        note.tags.any((t) => t.toLowerCase().contains(lower));
  }

  List<Note> search(String query) {
    if (query.isEmpty) return [];
    return _notes.where((n) => _matchesQuery(n, query)).toList();
  }

  List<Note> filteredNotes({
    NoteType? type,
    String? notebook,
    List<String>? tags,
    String? searchQuery,
    String? projectId,
    SortOption sortBy = SortOption.updatedAt,
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
      result = result.where((n) => _matchesQuery(n, searchQuery)).toList();
    }

    _lastFilteredCount = result.length;

    switch (sortBy) {
      case SortOption.updatedAt:
        result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      case SortOption.createdAt:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.title:
        result.sort((a, b) => a.title.compareTo(b.title));
    }

    return result.take(_displayCount).toList();
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }
}
