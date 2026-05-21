import 'dart:async';

import '../../models/goal.dart';
import '../../models/note.dart';
import '../../models/project.dart';
import '../../models/task.dart';

abstract class SyncService {
  Future<void> init();
  Future<void> uploadTasks(List<Task> tasks);
  Future<List<Task>> downloadTasks();
  Future<void> uploadProjects(List<Project> projects);
  Future<List<Project>> downloadProjects();
  Future<void> uploadNotes(List<Note> notes);
  Future<List<Note>> downloadNotes();
  Future<void> uploadGoals(List<Goal> goals);
  Future<List<Goal>> downloadGoals();
  Future<void> deleteAll();
  bool get isAvailable;
  Stream<bool> get connectionState;
}
