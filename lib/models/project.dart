import 'brain_item.dart';
import 'task.dart';

enum ProjectStatus { active, paused, completed, abandoned }

class Project extends BrainItem {
  final String title;
  final String description;
  final String emoji;
  final int colorValue;
  final ProjectStatus status;
  final DateTime startDate;
  final DateTime? deadline;
  final TaskPriority priority;
  final String objective;
  final String? goalId;
  final List<String> taskIds;
  final List<String> noteIds;
  final List<String> areas; // Areas de responsabilidad (metodo PARA)

  Project({
    required super.id,
    required this.title,
    this.description = '',
    this.emoji = '📁',
    this.colorValue = 0xFF2196F3,
    this.status = ProjectStatus.active,
    DateTime? startDate,
    this.deadline,
    this.priority = TaskPriority.medium,
    this.objective = '',
    this.goalId,
    this.taskIds = const [],
    this.noteIds = const [],
    this.areas = const [],
    super.tags = const [],
    required super.createdAt,
    required super.updatedAt,
  }) : startDate = startDate ?? createdAt;

  Project copyWith({
    String? title,
    String? description,
    String? emoji,
    int? colorValue,
    ProjectStatus? status,
    DateTime? startDate,
    DateTime? deadline,
    TaskPriority? priority,
    String? objective,
    String? goalId,
    List<String>? taskIds,
    List<String>? noteIds,
    List<String>? areas,
    List<String>? tags,
    bool clearGoalId = false,
    bool clearDeadline = false,
  }) {
    return Project(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      colorValue: colorValue ?? this.colorValue,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      priority: priority ?? this.priority,
      objective: objective ?? this.objective,
      goalId: clearGoalId ? null : (goalId ?? this.goalId),
      taskIds: taskIds ?? this.taskIds,
      noteIds: noteIds ?? this.noteIds,
      areas: areas ?? this.areas,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  static double taskProgress(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    final done = tasks.where((t) => t.status == TaskStatus.completed).length;
    return done / tasks.length;
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'emoji': emoji,
        'colorValue': colorValue,
        'status': status.name,
        'startDate': startDate.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'priority': priority.name,
        'objective': objective,
        'goalId': goalId,
        'taskIds': taskIds,
        'noteIds': noteIds,
        'areas': areas,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt']);

    return Project(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      emoji: json['emoji'] ?? '📁',
      colorValue: json['colorValue'] ?? 0xFF2196F3,
      status: _statusFromJson(json['status']),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : createdAt,
      deadline:
          json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      priority: _priorityFromJson(json['priority']),
      objective: json['objective'] ?? '',
      goalId: json['goalId'],
      taskIds: List<String>.from(json['taskIds'] ?? []),
      noteIds: List<String>.from(json['noteIds'] ?? []),
      areas: List<String>.from(json['areas'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: createdAt,
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

ProjectStatus _statusFromJson(Object? value) {
  if (value is String) {
    switch (value) {
      case 'planning':
      case 'active':
        return ProjectStatus.active;
      case 'onHold':
      case 'paused':
        return ProjectStatus.paused;
      case 'completed':
        return ProjectStatus.completed;
      case 'archived':
      case 'abandoned':
        return ProjectStatus.abandoned;
    }
  }

  if (value is int) {
    switch (value) {
      case 0:
      case 1:
        return ProjectStatus.active;
      case 2:
        return ProjectStatus.paused;
      case 3:
        return ProjectStatus.completed;
      case 4:
        return ProjectStatus.abandoned;
    }
  }

  return ProjectStatus.active;
}

TaskPriority _priorityFromJson(Object? value) {
  if (value is String) {
    for (final priority in TaskPriority.values) {
      if (priority.name == value) return priority;
    }
  }

  if (value is int && value >= 0 && value < TaskPriority.values.length) {
    return TaskPriority.values[value];
  }

  return TaskPriority.medium;
}
