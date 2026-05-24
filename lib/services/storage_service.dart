import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/goal.dart';
import '../models/notebook_info.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/tag.dart';
import 'interfaces/storage_service_interface.dart';

class HiveStorageService implements IStorageService {
  static const String _boxName = 'second_brain_store';
  static const String _schemaVersionKey = 'schema_version';
  static const int _currentSchemaVersion = 2;

  static const String _tasksKey = 'brain_tasks';
  static const String _projectsKey = 'brain_projects';
  static const String _notesKey = 'brain_notes';
  static const String _goalsKey = 'brain_goals';
  static const String _trashTasksKey = 'brain_trash_tasks';
  static const String _trashProjectsKey = 'brain_trash_projects';
  static const String _trashNotesKey = 'brain_trash_notes';
  static const String _trashGoalsKey = 'brain_trash_goals';
  static const String _tagsKey = 'brain_tags';
  static const String _notebookNamesKey = 'brain_notebook_names';
  static const String _dailyIntentionsKey = 'brain_daily_intentions';
  static const String _dailyPlansKey = 'brain_daily_plans';
  static const String _dailyTimeBlocksKey = 'brain_daily_time_blocks';
  static const String _archivedTasksKey = 'brain_archived_tasks';

  Box<String>? _box;

  List<Task>? _cachedTasks;
  List<Project>? _cachedProjects;
  List<Note>? _cachedNotes;
  List<Goal>? _cachedGoals;
  List<Task>? _cachedTrashTasks;
  List<Project>? _cachedTrashProjects;
  List<Note>? _cachedTrashNotes;
  List<Goal>? _cachedTrashGoals;
  List<Tag>? _cachedTags;

  VoidCallback? onTrashChanged;

  @override
  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    await _migrateSharedPreferences();
    await _runSchemaMigrations();
  }

  Future<void> _runSchemaMigrations() async {
    final prefs = await SharedPreferences.getInstance();
    final storedVersion = prefs.getInt(_schemaVersionKey) ?? 1;

    if (storedVersion < _currentSchemaVersion) {
      for (int v = storedVersion; v < _currentSchemaVersion; v++) {
        await _migrate(v, v + 1);
      }
      await prefs.setInt(_schemaVersionKey, _currentSchemaVersion);
    }
  }

  Future<void> _migrate(int fromVersion, int toVersion) async {
    if (fromVersion == 1 && toVersion == 2) {
      await _migrateV1toV2();
    }
  }

  Future<void> _migrateV1toV2() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in [_tasksKey, _projectsKey, _notesKey, _goalsKey]) {
      final raw = _store.get(key);
      if (raw == null || raw.isEmpty) continue;

      try {
        final decoded = await Isolate.run(() {
          final list = jsonDecode(raw);
          if (list is! List) return raw;
          final updated = list.map((item) {
            if (item is! Map) return item;
            final map = Map<String, dynamic>.from(item);

            if (!map.containsKey('version')) {
              map['version'] = 2;
            }

            if (key == _tasksKey && map['status'] is String) {
              final legacyStatus = map['status'] as String;
              if (legacyStatus == 'done') map['status'] = 'completed';
              if (legacyStatus == 'todo') map['status'] = 'pending';
            }

            if (key == _projectsKey && map['status'] is String) {
              final legacyStatus = map['status'] as String;
              if (legacyStatus == 'planning') map['status'] = 'active';
              if (legacyStatus == 'finished') map['status'] = 'completed';
            }

            return map;
          }).toList();
          return jsonEncode(updated);
        });
        await _store.put(key, decoded);
      } catch (e) {
        debugPrint('Migration V1->V2 error for $key: $e');
      }
    }

    final locale = prefs.getString('language_code');
    if (locale == null) {
      await prefs.setString('language_code', 'es');
    }
  }

  Box<String> get _store {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('HiveStorageService.init() must be called before use.');
    }
    return box;
  }

  Future<void> _migrateSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [_tasksKey, _projectsKey, _notesKey, _goalsKey]) {
      if (!_store.containsKey(key)) {
        final legacyValue = prefs.getString(key);
        if (legacyValue != null) await _store.put(key, legacyValue);
      }
    }
  }

  Future<List<T>> _loadList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final data = _store.get(key);
    if (data == null || data.isEmpty) return [];

    try {
      final decodedList = await Isolate.run(() {
        final decoded = jsonDecode(data);
        if (decoded is! List) return <Map<String, dynamic>>[];
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
      return decodedList.map((item) => fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error loading list $key: $e');
      return [];
    }
  }

  Future<void> _saveList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    final encoded = await Isolate.run(() => jsonEncode(items));
    await _store.put(key, encoded);
  }

  @override
  Future<List<Task>> loadTasks() async {
    final cached = _cachedTasks;
    if (cached != null) return List<Task>.from(cached);
    final loaded = await _loadList(_tasksKey, Task.fromJson);
    _cachedTasks = loaded;
    return List<Task>.from(loaded);
  }

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    _cachedTasks = List<Task>.from(tasks);
    await _saveList(_tasksKey, tasks.map((t) => t.toJson()).toList());
  }

  Future<List<Task>> loadArchivedTasks() async =>
      _loadList(_archivedTasksKey, Task.fromJson);

  Future<void> saveArchivedTasks(List<Task> tasks) async =>
      _saveList(_archivedTasksKey, tasks.map((t) => t.toJson()).toList());

  @override
  Future<List<Project>> loadProjects() async {
    final cached = _cachedProjects;
    if (cached != null) return List<Project>.from(cached);
    final loaded = await _loadList(_projectsKey, Project.fromJson);
    _cachedProjects = loaded;
    return List<Project>.from(loaded);
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    _cachedProjects = List<Project>.from(projects);
    await _saveList(_projectsKey, projects.map((p) => p.toJson()).toList());
  }

  @override
  Future<List<Note>> loadNotes() async {
    final cached = _cachedNotes;
    if (cached != null) return List<Note>.from(cached);
    final loaded = await _loadList(_notesKey, Note.fromJson);
    _cachedNotes = loaded;
    return List<Note>.from(loaded);
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    _cachedNotes = List<Note>.from(notes);
    await _saveList(_notesKey, notes.map((n) => n.toJson()).toList());
  }

  @override
  Future<List<NotebookInfo>> loadNotebooks() async {
    final raw = _box!.get(_notebookNamesKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((item) => NotebookInfo.fromJson(item)).toList();
  }

  @override
  Future<void> saveNotebooks(List<NotebookInfo> notebooks) async {
    await _box!.put(_notebookNamesKey,
        jsonEncode(notebooks.map((notebook) => notebook.toJson()).toList()));
  }

  @override
  Future<Map<String, String>> loadDailyIntentions() async {
    final raw = _box!.get(_dailyIntentionsKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as String));
  }

  @override
  Future<void> saveDailyIntentions(Map<String, String> intentions) async {
    await _box!.put(_dailyIntentionsKey, jsonEncode(intentions));
  }

  @override
  Future<Map<String, List<String>>> loadDailyPlans() async {
    final raw = _box!.get(_dailyPlansKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as List).cast<String>()));
  }

  @override
  Future<void> saveDailyPlans(Map<String, List<String>> plans) async {
    await _box!.put(_dailyPlansKey, jsonEncode(plans));
  }

  @override
  Future<Map<String, String>> loadDailyTimeBlocks() async {
    final raw = _box!.get(_dailyTimeBlocksKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, v as String));
  }

  @override
  Future<void> saveDailyTimeBlocks(Map<String, String> blocks) async {
    await _box!.put(_dailyTimeBlocksKey, jsonEncode(blocks));
  }

  @override
  Future<List<Goal>> loadGoals() async {
    final cached = _cachedGoals;
    if (cached != null) return List<Goal>.from(cached);
    final loaded = await _loadList(_goalsKey, Goal.fromJson);
    _cachedGoals = loaded;
    return List<Goal>.from(loaded);
  }

  @override
  Future<List<Tag>> loadTags() async {
    final cached = _cachedTags;
    if (cached != null) return List<Tag>.from(cached);
    final loaded = await _loadList(_tagsKey, Tag.fromJson);
    _cachedTags = loaded;
    return List<Tag>.from(loaded);
  }

  @override
  Future<void> saveTags(List<Tag> tags) async {
    _cachedTags = List<Tag>.from(tags);
    await _saveList(_tagsKey, tags.map((t) => t.toJson()).toList());
  }

  @override
  Future<void> saveGoals(List<Goal> goals) async {
    _cachedGoals = List<Goal>.from(goals);
    await _saveList(_goalsKey, goals.map((g) => g.toJson()).toList());
  }

  @override
  Future<List<Task>> loadTrashTasks() async {
    final cached = _cachedTrashTasks;
    if (cached != null) return List<Task>.from(cached);
    final loaded = await _loadList(_trashTasksKey, Task.fromJson);
    _cachedTrashTasks = loaded;
    return List<Task>.from(loaded);
  }

  @override
  Future<void> saveTrashTasks(List<Task> tasks) async {
    _cachedTrashTasks = List<Task>.from(tasks);
    await _saveList(_trashTasksKey, tasks.map((t) => t.toJson()).toList());
    onTrashChanged?.call();
  }

  @override
  Future<List<Project>> loadTrashProjects() async {
    final cached = _cachedTrashProjects;
    if (cached != null) return List<Project>.from(cached);
    final loaded = await _loadList(_trashProjectsKey, Project.fromJson);
    _cachedTrashProjects = loaded;
    return List<Project>.from(loaded);
  }

  @override
  Future<void> saveTrashProjects(List<Project> projects) async {
    _cachedTrashProjects = List<Project>.from(projects);
    await _saveList(
        _trashProjectsKey, projects.map((p) => p.toJson()).toList());
    onTrashChanged?.call();
  }

  @override
  Future<List<Note>> loadTrashNotes() async {
    final cached = _cachedTrashNotes;
    if (cached != null) return List<Note>.from(cached);
    final loaded = await _loadList(_trashNotesKey, Note.fromJson);
    _cachedTrashNotes = loaded;
    return List<Note>.from(loaded);
  }

  @override
  Future<void> saveTrashNotes(List<Note> notes) async {
    _cachedTrashNotes = List<Note>.from(notes);
    await _saveList(_trashNotesKey, notes.map((n) => n.toJson()).toList());
    onTrashChanged?.call();
  }

  @override
  Future<List<Goal>> loadTrashGoals() async {
    final cached = _cachedTrashGoals;
    if (cached != null) return List<Goal>.from(cached);
    final loaded = await _loadList(_trashGoalsKey, Goal.fromJson);
    _cachedTrashGoals = loaded;
    return List<Goal>.from(loaded);
  }

  @override
  Future<void> saveTrashGoals(List<Goal> goals) async {
    _cachedTrashGoals = List<Goal>.from(goals);
    await _saveList(_trashGoalsKey, goals.map((g) => g.toJson()).toList());
    onTrashChanged?.call();
  }

  @override
  Future<void> clearAll() async {
    _cachedTasks = null;
    _cachedProjects = null;
    _cachedNotes = null;
    _cachedGoals = null;
    _cachedTrashTasks = null;
    _cachedTrashProjects = null;
    _cachedTrashNotes = null;
    _cachedTrashGoals = null;
    await _store.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
