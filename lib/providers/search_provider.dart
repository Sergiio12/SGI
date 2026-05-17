import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../models/task.dart';

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String type;
  final String emoji;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.emoji,
  });
}

class SearchProvider extends ChangeNotifier {
  String _query = '';
  List<SearchResult> _results = [];
  Timer? _debounceTimer;

  String get query => _query;
  List<SearchResult> get results => _results;

  void search({
    required String query,
    required List<Task> tasks,
    required List<Project> projects,
    required List<Note> notes,
    required List<Goal> goals,
  }) {
    _query = query;
    if (query.isEmpty) {
      _debounceTimer?.cancel();
      _results = [];
      notifyListeners();
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      _results = await Isolate.run(() => _performSearchSync(
            query: query,
            tasks: tasks,
            projects: projects,
            notes: notes,
            goals: goals,
          ));
      notifyListeners();
    });
  }

  static List<SearchResult> _performSearchSync({
    required String query,
    required List<Task> tasks,
    required List<Project> projects,
    required List<Note> notes,
    required List<Goal> goals,
  }) {
    final lower = query.toLowerCase();
    final results = <SearchResult>[];

    for (final task in tasks) {
      if (task.title.toLowerCase().contains(lower) ||
          task.description.toLowerCase().contains(lower) ||
          task.tags.any((t) => t.toLowerCase().contains(lower))) {
        results.add(SearchResult(
          id: task.id,
          title: task.title,
          subtitle: 'Tarea · ${task.status.name}',
          type: 'task',
          emoji: '✓',
        ));
      }
    }

    for (final project in projects) {
      if (project.title.toLowerCase().contains(lower) ||
          project.description.toLowerCase().contains(lower) ||
          project.objective.toLowerCase().contains(lower) ||
          project.tags.any((t) => t.toLowerCase().contains(lower))) {
        results.add(SearchResult(
          id: project.id,
          title: project.title,
          subtitle: 'Proyecto · ${project.status.name}',
          type: 'project',
          emoji: project.emoji,
        ));
      }
    }

    for (final note in notes) {
      if (note.title.toLowerCase().contains(lower) ||
          note.content.toLowerCase().contains(lower) ||
          note.notebook.toLowerCase().contains(lower) ||
          note.tags.any((t) => t.toLowerCase().contains(lower))) {
        results.add(SearchResult(
          id: note.id,
          title: note.title,
          subtitle: 'Nota · ${note.notebook}',
          type: 'note',
          emoji: note.emoji,
        ));
      }
    }

    for (final goal in goals) {
      if (goal.title.toLowerCase().contains(lower) ||
          goal.description.toLowerCase().contains(lower) ||
          goal.metricLabel.toLowerCase().contains(lower) ||
          goal.tags.any((t) => t.toLowerCase().contains(lower))) {
        results.add(SearchResult(
          id: goal.id,
          title: goal.title,
          subtitle: 'Objetivo · ${goal.horizon.name}',
          type: 'goal',
          emoji: '◎',
        ));
      }
    }

    return results;
  }

  void clear() {
    _debounceTimer?.cancel();
    _query = '';
    _results = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
