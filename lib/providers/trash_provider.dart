import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/interfaces/storage_service_interface.dart';
import '../utils/notification_service_v2.dart';

enum TrashItemType { task, project, note, goal }

class TrashBundle {
  final TrashItemType type;
  final Task? task;
  final Project? project;
  final Note? note;
  final Goal? goal;
  final DateTime deletedAt;

  TrashBundle({
    required this.type,
    this.task,
    this.project,
    this.note,
    this.goal,
    required this.deletedAt,
  });

  String get id {
    switch (type) {
      case TrashItemType.task:
        return task!.id;
      case TrashItemType.project:
        return project!.id;
      case TrashItemType.note:
        return note!.id;
      case TrashItemType.goal:
        return goal!.id;
    }
  }

  String get title {
    switch (type) {
      case TrashItemType.task:
        return task!.title;
      case TrashItemType.project:
        return project!.title;
      case TrashItemType.note:
        return note!.title;
      case TrashItemType.goal:
        return goal!.title;
    }
  }

  IconData get icon {
    switch (type) {
      case TrashItemType.task:
        return Icons.checklist_rounded;
      case TrashItemType.project:
        return Icons.folder_open_outlined;
      case TrashItemType.note:
        return Icons.sticky_note_2_outlined;
      case TrashItemType.goal:
        return Icons.track_changes_outlined;
    }
  }

  Color get color {
    switch (type) {
      case TrashItemType.task:
        return Colors.orange;
      case TrashItemType.project:
        return Colors.blue;
      case TrashItemType.note:
        return Colors.green;
      case TrashItemType.goal:
        return Colors.purple;
    }
  }
}

class TrashProvider extends ChangeNotifier {
  final IStorageService _storage;
  List<TrashBundle> _items = [];
  bool _isLoaded = false;

  TrashProvider({required IStorageService storage}) : _storage = storage;

  List<TrashBundle> get items => _items;
  bool get isLoaded => _isLoaded;
  int get totalItems => _items.length;

  List<TrashBundle> get sortedItems {
    final sorted = [..._items];
    sorted.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return sorted;
  }

  Future<void> loadTrash() async {
    final tasks = await _storage.loadTrashTasks();
    final projects = await _storage.loadTrashProjects();
    final notes = await _storage.loadTrashNotes();
    final goals = await _storage.loadTrashGoals();

    _items = [
      ...tasks.map((t) => TrashBundle(
            type: TrashItemType.task,
            task: t,
            deletedAt: t.updatedAt,
          )),
      ...projects.map((p) => TrashBundle(
            type: TrashItemType.project,
            project: p,
            deletedAt: p.updatedAt,
          )),
      ...notes.map((n) => TrashBundle(
            type: TrashItemType.note,
            note: n,
            deletedAt: n.updatedAt,
          )),
      ...goals.map((g) => TrashBundle(
            type: TrashItemType.goal,
            goal: g,
            deletedAt: g.updatedAt,
          )),
    ];

    _isLoaded = true;
    notifyListeners();
  }

  void _onTrashChanged() {
    loadTrash();
  }

  void register() {
    _storage.onTrashChanged = _onTrashChanged;
  }

  void unregister() {
    if (_storage.onTrashChanged == _onTrashChanged) {
      _storage.onTrashChanged = null;
    }
  }

  Future<void> reload() async {
    await loadTrash();
  }

  Future<void> emptyAll() async {
    await _storage.saveTrashTasks([]);
    await _storage.saveTrashProjects([]);
    await _storage.saveTrashNotes([]);
    await _storage.saveTrashGoals([]);
    _items = [];
    notifyListeners();
    showSuccessNotification('Papelera vaciada');
  }
}
