import 'dart:async';

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
  final double relevance;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.emoji,
    this.relevance = 1.0,
  });
}

class SearchProvider extends ChangeNotifier {
  String _query = '';
  List<SearchResult> _results = [];
  Timer? _debounceTimer;

  Map<String, List<SearchResult>> _invertedIndex = {};
  List<SearchResult> _allItems = [];

  String get query => _query;
  List<SearchResult> get results => _results;

  static final _tokenPattern = RegExp(r"[a-zA-ZáéíóúüñÁÉÍÓÚÜÑ0-9]+");

  List<String> _tokenize(String text) {
    return _tokenPattern
        .allMatches(text.toLowerCase())
        .map((m) => m.group(0)!)
        .toList();
  }

  void _rebuildIndex({
    required List<Task> tasks,
    required List<Project> projects,
    required List<Note> notes,
    required List<Goal> goals,
  }) {
    _allItems = [];
    _invertedIndex = {};

    void addToIndex(String word, SearchResult result) {
      _invertedIndex.putIfAbsent(word, () => []).add(result);
    }

    for (final task in tasks) {
      final result = SearchResult(
        id: task.id,
        title: task.title,
        subtitle: 'Tarea · ${task.status.name}',
        type: 'task',
        emoji: '✓',
      );
      _allItems.add(result);
      for (final word in _tokenize('${task.title} ${task.description} ${task.tags.join(' ')}')) {
        addToIndex(word, result);
      }
    }

    for (final project in projects) {
      final result = SearchResult(
        id: project.id,
        title: project.title,
        subtitle: 'Proyecto · ${project.status.name}',
        type: 'project',
        emoji: project.emoji,
      );
      _allItems.add(result);
      for (final word in _tokenize('${project.title} ${project.description} ${project.objective} ${project.tags.join(' ')}')) {
        addToIndex(word, result);
      }
    }

    for (final note in notes) {
      final result = SearchResult(
        id: note.id,
        title: note.title,
        subtitle: 'Nota · ${note.notebook}',
        type: 'note',
        emoji: note.emoji,
      );
      _allItems.add(result);
      for (final word in _tokenize('${note.title} ${note.content} ${note.notebook} ${note.tags.join(' ')}')) {
        addToIndex(word, result);
      }
    }

    for (final goal in goals) {
      final result = SearchResult(
        id: goal.id,
        title: goal.title,
        subtitle: 'Objetivo · ${goal.horizon.name}',
        type: 'goal',
        emoji: '◎',
      );
      _allItems.add(result);
      for (final word in _tokenize('${goal.title} ${goal.description} ${goal.metricLabel} ${goal.tags.join(' ')}')) {
        addToIndex(word, result);
      }
    }
  }

  void rebuildIndex({
    required List<Task> tasks,
    required List<Project> projects,
    required List<Note> notes,
    required List<Goal> goals,
  }) {
    _rebuildIndex(tasks: tasks, projects: projects, notes: notes, goals: goals);
    if (_query.isNotEmpty) {
      _results = _searchO1(_query);
      notifyListeners();
    }
  }

  List<SearchResult> _searchO1(String query) {
    if (_invertedIndex.isEmpty) return [];

    final words = _tokenize(query);
    if (words.isEmpty) return [];

    final scored = <String, double>{};

    for (final word in words) {
      final hits = _invertedIndex[word];
      if (hits == null) continue;
      for (final hit in hits) {
        scored[hit.id] = (scored[hit.id] ?? 0) + 1.0;
      }
    }

    final threshold = words.length * 0.5;
    final matchingIds = scored.entries
        .where((e) => e.value >= threshold)
        .map((e) => e.key)
        .toSet();

    return _allItems
        .where((item) => matchingIds.contains(item.id))
        .map((item) {
          final score = scored[item.id] ?? 1.0;
          return SearchResult(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            type: item.type,
            emoji: item.emoji,
            relevance: score / words.length,
          );
        })
        .toList()
      ..sort((a, b) => b.relevance.compareTo(a.relevance));
  }

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

    if (_invertedIndex.isEmpty) {
      _rebuildIndex(tasks: tasks, projects: projects, notes: notes, goals: goals);
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      _results = _searchO1(query);
      notifyListeners();
    });
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
