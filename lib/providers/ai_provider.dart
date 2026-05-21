import 'dart:async';

import 'package:flutter/material.dart';

import '../models/project.dart';
import '../models/tag.dart';
import '../models/task.dart';
import '../services/local_ai_service.dart';
import 'settings_provider.dart';

class AiSuggestion {
  final TaskPriority? suggestedPriority;
  final double? suggestedHours;
  final List<String> suggestedTags;
  final String? suggestedProjectId;
  final String? dailyIntention;

  const AiSuggestion({
    this.suggestedPriority,
    this.suggestedHours,
    this.suggestedTags = const [],
    this.suggestedProjectId,
    this.dailyIntention,
  });

  bool get isEmpty =>
      suggestedPriority == null &&
      suggestedHours == null &&
      suggestedTags.isEmpty &&
      suggestedProjectId == null &&
      dailyIntention == null;
}

class AiProvider extends ChangeNotifier {
  final LocalAiService _ai = LocalAiService();
  final SettingsProvider _settings;

  AiProvider({required SettingsProvider settings}) : _settings = settings;

  bool get _enabled => _settings.aiSuggestionsEnabled;

  AiSuggestion _taskSuggestion = const AiSuggestion();
  AiSuggestion _dailyIntention = const AiSuggestion();
  bool _isAnalyzing = false;
  Timer? _debounceTimer;

  AiSuggestion get taskSuggestion => _taskSuggestion;
  AiSuggestion get dailyIntention => _dailyIntention;
  bool get isAnalyzing => _isAnalyzing;

  void suggestForTask({
    required String title,
    required String description,
    required List<Tag> tags,
    required List<Project> projects,
  }) {
    if (!_enabled || title.trim().isEmpty) {
      if (_taskSuggestion.isEmpty) return;
      _taskSuggestion = const AiSuggestion();
      notifyListeners();
      return;
    }

    _debounceTimer?.cancel();
    _isAnalyzing = true;
    notifyListeners();

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final priority = _ai.suggestPriority(title, description);
      final hours = _ai.suggestEstimatedHours(title, description);
      final tagList = _ai.suggestTags(title, description, tags);
      final projectId = _ai.suggestProject(title, projects);

      _taskSuggestion = AiSuggestion(
        suggestedPriority: priority,
        suggestedHours: hours,
        suggestedTags: tagList,
        suggestedProjectId: projectId,
      );
      _isAnalyzing = false;
      notifyListeners();
    });
  }

  void generateDailyIntention(List<Task> todayTasks) {
    if (!_enabled) {
      _dailyIntention = const AiSuggestion();
      notifyListeners();
      return;
    }

    final intention = _ai.generateDailyIntention(todayTasks);
    _dailyIntention = AiSuggestion(dailyIntention: intention);
    notifyListeners();
  }

  void clearTaskSuggestions() {
    _debounceTimer?.cancel();
    _taskSuggestion = const AiSuggestion();
    _isAnalyzing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
