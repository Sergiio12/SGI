import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/result.dart';
import '../models/notebook_info.dart';
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

  List<Note>? __pinnedNotes;
  List<Note>? __unpinnedNotes;
  List<Note>? __recentNotes;
  List<String>? __notebooks;
  Map<String, int>? __notebookCounts;
  final List<NotebookInfo> _notebookInfos = [];

  List<Note> get notes => _notes;
  bool get isLoaded => _isLoaded;

  List<Note> get pinnedNotes =>
      __pinnedNotes ??= _notes.where((n) => n.isPinned).toList();
  List<Note> get unpinnedNotes =>
      __unpinnedNotes ??= _notes.where((n) => !n.isPinned).toList();
  List<Note> get recentNotes {
    if (__recentNotes != null) return __recentNotes!;
    final sorted = [..._notes]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    __recentNotes = sorted.take(10).toList();
    return __recentNotes!;
  }

  List<String> get notebooks {
    if (__notebooks != null) return __notebooks!;
    final derived = _notes.map((n) => n.notebook).toSet();
    final merged = {
      ...derived,
      ..._notebookInfos.map((info) => info.name).toSet()
    }.toList()
      ..sort();
    __notebooks = merged.isEmpty ? ['General'] : merged;
    return __notebooks!;
  }

  NotebookInfo getNotebookInfo(String notebook) {
    return _notebookInfos.firstWhere(
      (info) => info.name == notebook,
      orElse: () => NotebookInfo(
        name: notebook,
        colorHex: NotebookInfo.defaultColorHex(notebook),
      ),
    );
  }

  Color getNotebookColor(String notebook) => getNotebookInfo(notebook).color;

  Map<String, int> get notebookCounts {
    if (__notebookCounts != null) return __notebookCounts!;
    __notebookCounts = <String, int>{};
    for (final n in _notes) {
      __notebookCounts![n.notebook] = (__notebookCounts![n.notebook] ?? 0) + 1;
    }
    return __notebookCounts!;
  }

  Future<void> loadNotes() async {
    _notes = await _storage.loadNotes();
    final savedNotebooks = await _storage.loadNotebooks();
    _notebookInfos
      ..clear()
      ..addAll(savedNotebooks);
    _markDirty();
    _isLoaded = true;
    notifyListeners();
  }

  void _markDirty() {
    __pinnedNotes = null;
    __unpinnedNotes = null;
    __recentNotes = null;
    __notebooks = null;
    __notebookCounts = null;
  }

  void _notifyAndScheduleSave() {
    _markDirty();
    notifyListeners();
    _saveDebouncer.call(() async {
      await _storage.saveNotes(_notes);
      await _storage.saveNotebooks(_notebookInfos);
    });
  }

  List<Note> getNotesByProject(String projectId) =>
      _notes.where((n) => n.projectId == projectId).toList();

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
    String notebook = 'General',
    String? projectId,
    String emoji = '\u{1F4DD}',
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
        notebook: notebook,
        projectId: projectId,
        emoji: emoji,
        isPinned: isPinned,
        createdAt: now,
        updatedAt: now,
      );
      _notes.add(note);
      _notifyAndScheduleSave();
      HapticHelper.light();
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
      AppException(
              message: 'Error al actualizar nota',
              code: 'UPDATE_NOTE',
              stackTrace: s)
          .log();
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
      }
    } catch (e, s) {
      AppException(
              message: 'Error al cambiar anclaje de nota',
              code: 'TOGGLE_PIN',
              stackTrace: s)
          .log();
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
    } catch (e, s) {
      AppException(
              message: 'Error al eliminar nota',
              code: 'DELETE_NOTE',
              stackTrace: s)
          .log();
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
      }
    } catch (e, s) {
      AppException(
              message: 'Error al restaurar nota',
              code: 'RESTORE_NOTE',
              stackTrace: s)
          .log();
      showErrorNotification('Error al restaurar nota');
    }
  }

  Future<void> permanentDeleteNote(String noteId) async {
    try {
      final trash = await _storage.loadTrashNotes();
      trash.removeWhere((n) => n.id == noteId);
      await _storage.saveTrashNotes(trash);
    } catch (e, s) {
      AppException(
              message: 'Error al eliminar nota permanentemente',
              code: 'PERM_DELETE_NOTE',
              stackTrace: s)
          .log();
      showErrorNotification('Error al eliminar nota');
    }
  }

  Future<void> renameNotebook(String oldName, String newName) async {
    final trimmedNew = newName.trim();
    if (oldName == trimmedNew || trimmedNew.isEmpty) return;
    try {
      for (var i = 0; i < _notes.length; i++) {
        if (_notes[i].notebook == oldName) {
          _notes[i] = _notes[i].copyWith(notebook: trimmedNew);
        }
      }
      final infoIndex =
          _notebookInfos.indexWhere((info) => info.name == oldName);
      if (infoIndex != -1) {
        _notebookInfos[infoIndex] = NotebookInfo(
          name: trimmedNew,
          colorHex: _notebookInfos[infoIndex].colorHex,
        );
      }
      _notifyAndScheduleSave();
    } catch (e, s) {
      AppException(
              message: 'Error al renombrar cuaderno',
              code: 'RENAME_NOTEBOOK',
              stackTrace: s)
          .log();
    }
  }

  Future<void> deleteNotebook(String name) async {
    try {
      for (var i = 0; i < _notes.length; i++) {
        if (_notes[i].notebook == name) {
          _notes[i] = _notes[i].copyWith(notebook: 'General');
        }
      }
      _notebookInfos.removeWhere((info) => info.name == name);
      _notifyAndScheduleSave();
    } catch (e, s) {
      AppException(
              message: 'Error al eliminar cuaderno',
              code: 'DELETE_NOTEBOOK',
              stackTrace: s)
          .log();
    }
  }

  Future<void> createNotebook(String name, {Color? color}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || notebooks.contains(trimmed)) return;
    _notebookInfos.add(NotebookInfo(
      name: trimmed,
      colorHex: color != null
          ? color.toARGB32().toRadixString(16).substring(2).toUpperCase()
          : NotebookInfo.defaultColorHex(trimmed),
    ));
    _markDirty();
    notifyListeners();
    await _storage.saveNotebooks(_notebookInfos);
  }

  Future<void> setNotebookColor(String name, Color color) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final index = _notebookInfos.indexWhere((info) => info.name == trimmed);
    final colorHex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    if (index != -1) {
      _notebookInfos[index] = NotebookInfo(name: trimmed, colorHex: colorHex);
    } else {
      _notebookInfos.add(NotebookInfo(name: trimmed, colorHex: colorHex));
    }
    _markDirty();
    notifyListeners();
    await _storage.saveNotebooks(_notebookInfos);
  }

  Future<void> replaceAll(List<Note> notes) async {
    _notes = notes;
    _notifyAndScheduleSave();
  }

  bool _matchesQuery(Note note, String query) {
    final lower = query.toLowerCase();
    return note.title.toLowerCase().contains(lower) ||
        note.content.toLowerCase().contains(lower) ||
        note.notebook.toLowerCase().contains(lower);
  }

  List<Note> filteredNotes({
    String? notebook,
    String? searchQuery,
    String? projectId,
    SortOption sortBy = SortOption.updatedAt,
  }) {
    var result = _notes;

    if (projectId != null) {
      result = result.where((n) => n.projectId == projectId).toList();
    }
    if (notebook != null) {
      result = result.where((n) => n.notebook == notebook).toList();
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
