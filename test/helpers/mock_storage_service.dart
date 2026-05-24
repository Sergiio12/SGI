import 'package:flutter/material.dart';
import 'package:second_brain/models/goal.dart';
import 'package:second_brain/models/notebook_info.dart';
import 'package:second_brain/models/note.dart';
import 'package:second_brain/models/project.dart';
import 'package:second_brain/models/tag.dart';
import 'package:second_brain/models/task.dart';
import 'package:second_brain/services/interfaces/storage_service_interface.dart';

class MockStorageService implements IStorageService {
  List<Task> _tasks = [];
  List<Project> _projects = [];
  List<Note> _notes = [];
  List<Goal> _goals = [];
  List<Tag> _tags = [];
  List<Task> _trashTasks = [];
  List<Project> _trashProjects = [];
  List<Note> _trashNotes = [];
  List<Goal> _trashGoals = [];
  List<NotebookInfo> _notebookInfos = [];
  Map<String, String> _dailyIntentions = {};
  Map<String, List<String>> _dailyPlans = {};
  Map<String, String> _dailyTimeBlocks = {};

  List<Task> get savedTasks => _tasks;
  List<Task> get trashTasks => _trashTasks;

  VoidCallback? onTrashChanged;

  @override
  Future<void> init() async {}

  @override
  Future<List<Task>> loadTasks() async => _tasks;

  @override
  Future<void> saveTasks(List<Task> tasks) async {
    _tasks = List<Task>.from(tasks);
  }

  @override
  Future<List<Project>> loadProjects() async => _projects;

  @override
  Future<void> saveProjects(List<Project> projects) async {
    _projects = List<Project>.from(projects);
  }

  @override
  Future<List<Note>> loadNotes() async => _notes;

  @override
  Future<void> saveNotes(List<Note> notes) async {
    _notes = List<Note>.from(notes);
  }

  @override
  Future<List<Goal>> loadGoals() async => _goals;

  @override
  Future<void> saveGoals(List<Goal> goals) async {
    _goals = List<Goal>.from(goals);
  }

  @override
  Future<List<Tag>> loadTags() async => _tags;

  @override
  Future<void> saveTags(List<Tag> tags) async {
    _tags = List<Tag>.from(tags);
  }

  @override
  Future<List<Task>> loadTrashTasks() async => _trashTasks;

  @override
  Future<void> saveTrashTasks(List<Task> tasks) async {
    _trashTasks = List<Task>.from(tasks);
    onTrashChanged?.call();
  }

  @override
  Future<List<Project>> loadTrashProjects() async => _trashProjects;

  @override
  Future<void> saveTrashProjects(List<Project> projects) async {
    _trashProjects = List<Project>.from(projects);
    onTrashChanged?.call();
  }

  @override
  Future<List<Note>> loadTrashNotes() async => _trashNotes;

  @override
  Future<void> saveTrashNotes(List<Note> notes) async {
    _trashNotes = List<Note>.from(notes);
    onTrashChanged?.call();
  }

  @override
  Future<List<Goal>> loadTrashGoals() async => _trashGoals;

  @override
  Future<void> saveTrashGoals(List<Goal> goals) async {
    _trashGoals = List<Goal>.from(goals);
    onTrashChanged?.call();
  }

  @override
  Future<List<NotebookInfo>> loadNotebooks() async => _notebookInfos;

  @override
  Future<void> saveNotebooks(List<NotebookInfo> notebooks) async {
    _notebookInfos = List<NotebookInfo>.from(notebooks);
  }

  @override
  Future<Map<String, String>> loadDailyIntentions() async => _dailyIntentions;

  @override
  Future<void> saveDailyIntentions(Map<String, String> intentions) async {
    _dailyIntentions = Map<String, String>.from(intentions);
  }

  @override
  Future<Map<String, List<String>>> loadDailyPlans() async => _dailyPlans;

  @override
  Future<void> saveDailyPlans(Map<String, List<String>> plans) async {
    _dailyPlans = plans.map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  @override
  Future<Map<String, String>> loadDailyTimeBlocks() async => _dailyTimeBlocks;

  @override
  Future<void> saveDailyTimeBlocks(Map<String, String> blocks) async {
    _dailyTimeBlocks = Map<String, String>.from(blocks);
  }

  @override
  Future<void> clearAll() async {
    _tasks = [];
    _projects = [];
    _notes = [];
    _goals = [];
    _tags = [];
    _trashTasks = [];
    _trashProjects = [];
    _trashNotes = [];
    _trashGoals = [];
    _notebookInfos = [];
    _dailyIntentions = {};
    _dailyPlans = {};
    _dailyTimeBlocks = {};
  }
}
