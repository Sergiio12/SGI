import 'package:flutter/foundation.dart';

import '../../models/goal.dart';
import '../../models/note.dart';
import '../../models/project.dart';
import '../../models/tag.dart';
import '../../models/task.dart';
import '../interfaces/storage_service_interface.dart';
import 'sync_service.dart';

class LocalFirstStorageService implements IStorageService {
  final IStorageService _local;
  final SyncService _cloud;

  LocalFirstStorageService(this._local, this._cloud);

  @override
  VoidCallback? onTrashChanged;

  Future<void> _syncFromCloud() async {
    try {
      final tasks = await _cloud.downloadTasks();
      await _local.saveTasks(tasks);
      final projects = await _cloud.downloadProjects();
      await _local.saveProjects(projects);
      final notes = await _cloud.downloadNotes();
      await _local.saveNotes(notes);
      final goals = await _cloud.downloadGoals();
      await _local.saveGoals(goals);
    } catch (_) {}
  }

  @override
  Future<void> init() async {
    await _local.init();
    if (_cloud.isAvailable) {
      await _syncFromCloud();
    }
  }

  @override
  Future<List<Task>> loadTasks() async {
    final tasks = await _local.loadTasks();
    if (_cloud.isAvailable) {
      _syncFromCloud();
    }
    return tasks;
  }

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    await _local.saveTasks(tasks);
    if (_cloud.isAvailable) {
      _cloud.uploadTasks(tasks);
    }
  }

  @override
  Future<List<Project>> loadProjects() async {
    final projects = await _local.loadProjects();
    if (_cloud.isAvailable) {
      _syncFromCloud();
    }
    return projects;
  }

  @override
  Future<void> saveProjects(List<Project> projects) async {
    await _local.saveProjects(projects);
    if (_cloud.isAvailable) {
      _cloud.uploadProjects(projects);
    }
  }

  @override
  Future<List<Note>> loadNotes() async {
    final notes = await _local.loadNotes();
    if (_cloud.isAvailable) {
      _syncFromCloud();
    }
    return notes;
  }

  @override
  Future<void> saveNotes(List<Note> notes) async {
    await _local.saveNotes(notes);
    if (_cloud.isAvailable) {
      _cloud.uploadNotes(notes);
    }
  }

  @override
  Future<List<String>> loadNotebookNames() =>
      _local.loadNotebookNames();

  @override
  Future<void> saveNotebookNames(List<String> names) =>
      _local.saveNotebookNames(names);

  @override
  Future<List<Goal>> loadGoals() async {
    final goals = await _local.loadGoals();
    if (_cloud.isAvailable) {
      _syncFromCloud();
    }
    return goals;
  }

  @override
  Future<void> saveGoals(List<Goal> goals) async {
    await _local.saveGoals(goals);
    if (_cloud.isAvailable) {
      _cloud.uploadGoals(goals);
    }
  }

  @override
  Future<List<Tag>> loadTags() => _local.loadTags();

  @override
  Future<void> saveTags(List<Tag> tags) => _local.saveTags(tags);

  @override
  Future<List<Task>> loadTrashTasks() => _local.loadTrashTasks();

  @override
  Future<void> saveTrashTasks(List<Task> tasks) async {
    await _local.saveTrashTasks(tasks);
    onTrashChanged?.call();
  }

  @override
  Future<List<Project>> loadTrashProjects() => _local.loadTrashProjects();

  @override
  Future<void> saveTrashProjects(List<Project> projects) async {
    await _local.saveTrashProjects(projects);
    onTrashChanged?.call();
  }

  @override
  Future<List<Note>> loadTrashNotes() => _local.loadTrashNotes();

  @override
  Future<void> saveTrashNotes(List<Note> notes) async {
    await _local.saveTrashNotes(notes);
    onTrashChanged?.call();
  }

  @override
  Future<List<Goal>> loadTrashGoals() => _local.loadTrashGoals();

  @override
  Future<void> saveTrashGoals(List<Goal> goals) async {
    await _local.saveTrashGoals(goals);
    onTrashChanged?.call();
  }

  @override
  Future<Map<String, String>> loadDailyIntentions() =>
      _local.loadDailyIntentions();

  @override
  Future<void> saveDailyIntentions(Map<String, String> intentions) =>
      _local.saveDailyIntentions(intentions);

  @override
  Future<Map<String, List<String>>> loadDailyPlans() =>
      _local.loadDailyPlans();

  @override
  Future<void> saveDailyPlans(Map<String, List<String>> plans) =>
      _local.saveDailyPlans(plans);

  @override
  Future<Map<String, String>> loadDailyTimeBlocks() =>
      _local.loadDailyTimeBlocks();

  @override
  Future<void> saveDailyTimeBlocks(Map<String, String> blocks) =>
      _local.saveDailyTimeBlocks(blocks);

  @override
  Future<void> clearAll() async {
    await _local.clearAll();
    if (_cloud.isAvailable) {
      await _cloud.deleteAll();
    }
  }
}
