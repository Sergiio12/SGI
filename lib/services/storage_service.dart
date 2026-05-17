import 'dart:convert';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/goal.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../models/task.dart';

List<Map<String, dynamic>> _decodeJsonList(String jsonData) {
  final decoded = jsonDecode(jsonData);
  if (decoded is! List) return [];
  return decoded
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

String _encodeJsonList(List<Map<String, dynamic>> items) {
  return jsonEncode(items);
}

class StorageService {
  static const String _boxName = 'second_brain_store';
  static const String _tasksKey = 'brain_tasks';
  static const String _projectsKey = 'brain_projects';
  static const String _notesKey = 'brain_notes';
  static const String _goalsKey = 'brain_goals';

  static Box<String>? _box;

  // Sistema de caché en memoria para accesos instantáneos sin E/S de disco
  static List<Task>? _cachedTasks;
  static List<Project>? _cachedProjects;
  static List<Note>? _cachedNotes;
  static List<Goal>? _cachedGoals;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<String>(_boxName);
    await _migrateSharedPreferences();
  }

  static Box<String> get _store {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('StorageService.init() must be called before use.');
    }
    return box;
  }

  static Future<void> _migrateSharedPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in [_tasksKey, _projectsKey, _notesKey, _goalsKey]) {
      if (!_store.containsKey(key)) {
        final legacyValue = prefs.getString(key);
        if (legacyValue != null) await _store.put(key, legacyValue);
      }
    }
  }


  static Future<List<T>> _loadList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final data = _store.get(key);
    if (data == null || data.isEmpty) return [];

    try {
      // Usamos Isolate.run para decodificar y mapear en un hilo separado
      return await Isolate.run(() {
        final decoded = _decodeJsonList(data);
        return decoded.map((item) => fromJson(item)).toList();
      });
    } catch (e) {
      debugPrint('Error loading list $key: $e');
      return [];
    }
  }

  static Future<void> _saveList(
    String key,
    List<Map<String, dynamic>> items,
  ) async {
    // La codificación JSON puede ser costosa para listas grandes
    final encoded = await Isolate.run(() => _encodeJsonList(items));
    await _store.put(key, encoded);
  }

  static Future<List<Task>> loadTasks() async {
    final cached = _cachedTasks;
    if (cached != null) {
      return List<Task>.from(cached);
    }
    final loaded = await _loadList(_tasksKey, Task.fromJson);
    _cachedTasks = loaded;
    return List<Task>.from(loaded);
  }

  static Future<void> saveTasks(List<Task> tasks) async {
    _cachedTasks = List<Task>.from(tasks);
    await _saveList(_tasksKey, tasks.map((t) => t.toJson()).toList());
  }

  static Future<List<Project>> loadProjects() async {
    final cached = _cachedProjects;
    if (cached != null) {
      return List<Project>.from(cached);
    }
    final loaded = await _loadList(_projectsKey, Project.fromJson);
    _cachedProjects = loaded;
    return List<Project>.from(loaded);
  }

  static Future<void> saveProjects(List<Project> projects) async {
    _cachedProjects = List<Project>.from(projects);
    await _saveList(_projectsKey, projects.map((p) => p.toJson()).toList());
  }

  static Future<List<Note>> loadNotes() async {
    final cached = _cachedNotes;
    if (cached != null) {
      return List<Note>.from(cached);
    }
    final loaded = await _loadList(_notesKey, Note.fromJson);
    _cachedNotes = loaded;
    return List<Note>.from(loaded);
  }

  static Future<void> saveNotes(List<Note> notes) async {
    _cachedNotes = List<Note>.from(notes);
    await _saveList(_notesKey, notes.map((n) => n.toJson()).toList());
  }

  static Future<List<Goal>> loadGoals() async {
    final cached = _cachedGoals;
    if (cached != null) {
      return List<Goal>.from(cached);
    }
    final loaded = await _loadList(_goalsKey, Goal.fromJson);
    _cachedGoals = loaded;
    return List<Goal>.from(loaded);
  }

  static Future<void> saveGoals(List<Goal> goals) async {
    _cachedGoals = List<Goal>.from(goals);
    await _saveList(_goalsKey, goals.map((g) => g.toJson()).toList());
  }

  static Future<void> clearAll() async {
    _cachedTasks = null;
    _cachedProjects = null;
    _cachedNotes = null;
    _cachedGoals = null;
    await _store.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
