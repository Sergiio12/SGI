import 'package:flutter/material.dart';

import '../../models/goal.dart';
import '../../models/note.dart';
import '../../models/notebook_info.dart';
import '../../models/project.dart';
import '../../models/tag.dart';
import '../../models/task.dart';

abstract class IStorageService {
  Future<void> init();
  VoidCallback? onTrashChanged;

  Future<List<Task>> loadTasks();
  Future<void> saveTasks(List<Task> tasks);
  Future<List<Project>> loadProjects();
  Future<void> saveProjects(List<Project> projects);
  Future<List<Note>> loadNotes();
  Future<void> saveNotes(List<Note> notes);
  Future<List<NotebookInfo>> loadNotebooks();
  Future<void> saveNotebooks(List<NotebookInfo> notebooks);
  Future<List<Goal>> loadGoals();
  Future<void> saveGoals(List<Goal> goals);
  Future<List<Tag>> loadTags();
  Future<void> saveTags(List<Tag> tags);

  Future<List<Task>> loadTrashTasks();
  Future<void> saveTrashTasks(List<Task> tasks);
  Future<List<Project>> loadTrashProjects();
  Future<void> saveTrashProjects(List<Project> projects);
  Future<List<Note>> loadTrashNotes();
  Future<void> saveTrashNotes(List<Note> notes);
  Future<List<Goal>> loadTrashGoals();
  Future<void> saveTrashGoals(List<Goal> goals);

  Future<Map<String, String>> loadDailyIntentions();
  Future<void> saveDailyIntentions(Map<String, String> intentions);
  Future<Map<String, List<String>>> loadDailyPlans();
  Future<void> saveDailyPlans(Map<String, List<String>> plans);
  Future<Map<String, String>> loadDailyTimeBlocks();
  Future<void> saveDailyTimeBlocks(Map<String, String> blocks);

  Future<void> clearAll();
}
