import 'brain_item.dart';
import 'recurrence_rule.dart';

enum TaskPriority { low, medium, high, urgent }

enum TaskStatus { pending, inProgress, inReview, completed, cancelled }

class Task extends BrainItem {
  final String title;
  final String description;
  final TaskPriority priority;
  final TaskStatus status;
  final DateTime? dueDate;
  final double estimatedHours;
  final double? actualHours;
  final int? reminderMinutesBefore;
  final DateTime? lastActivityAt;
  final String? projectId;
  final List<SubTask> subtasks;
  final List<String> linkedNoteIds;
  final RecurrenceRule? recurrence;
  final String? sourceTaskId;
  final String? calendarEventId;

  Task({
    required super.id,
    required this.title,
    this.description = '',
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.pending,
    this.dueDate,
    this.estimatedHours = 1,
    this.actualHours,
    this.reminderMinutesBefore,
    this.lastActivityAt,
    this.projectId,
    this.subtasks = const [],
    this.linkedNoteIds = const [],
    this.recurrence,
    this.sourceTaskId,
    this.calendarEventId,
    super.tags = const [],
    required super.createdAt,
    required super.updatedAt,
  });

  double get progress {
    if (subtasks.isEmpty) return status == TaskStatus.completed ? 1.0 : 0.0;
    final completed = subtasks.where((s) => s.isDone).length;
    return completed / subtasks.length;
  }

  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != TaskStatus.completed &&
      status != TaskStatus.cancelled;

  bool get isActive =>
      status != TaskStatus.completed && status != TaskStatus.cancelled;

  Task copyWith({
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    double? estimatedHours,
    double? actualHours,
    int? reminderMinutesBefore,
    DateTime? lastActivityAt,
    String? projectId,
    List<SubTask>? subtasks,
    List<String>? linkedNoteIds,
    List<String>? tags,
    RecurrenceRule? recurrence,
    String? sourceTaskId,
    String? calendarEventId,
    bool clearDueDate = false,
    bool clearActualHours = false,
    bool clearReminder = false,
    bool clearLastActivity = false,
    bool clearProjectId = false,
    bool clearRecurrence = false,
    bool clearSourceTaskId = false,
    bool clearCalendarEventId = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: clearActualHours ? null : (actualHours ?? this.actualHours),
      reminderMinutesBefore: clearReminder
          ? null
          : (reminderMinutesBefore ?? this.reminderMinutesBefore),
      lastActivityAt:
          clearLastActivity ? null : (lastActivityAt ?? this.lastActivityAt),
      projectId: clearProjectId ? null : (projectId ?? this.projectId),
      subtasks: subtasks ?? this.subtasks,
      linkedNoteIds: linkedNoteIds ?? this.linkedNoteIds,
      tags: tags ?? this.tags,
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      sourceTaskId:
          clearSourceTaskId ? null : (sourceTaskId ?? this.sourceTaskId),
      calendarEventId: clearCalendarEventId
          ? null
          : (calendarEventId ?? this.calendarEventId),
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority.name,
        'status': status.name,
        'dueDate': dueDate?.toIso8601String(),
        'estimatedHours': estimatedHours,
        'actualHours': actualHours,
        'reminderMinutesBefore': reminderMinutesBefore,
        'lastActivityAt': lastActivityAt?.toIso8601String(),
        'projectId': projectId,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'linkedNoteIds': linkedNoteIds,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        if (recurrence != null) 'recurrence': recurrence!.toJson(),
        if (sourceTaskId != null) 'sourceTaskId': sourceTaskId,
        if (calendarEventId != null) 'calendarEventId': calendarEventId,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        priority: _priorityFromJson(json['priority']),
        status: _statusFromJson(json['status']),
        dueDate:
            json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
        estimatedHours: _doubleFromJson(json['estimatedHours'], fallback: 1),
        actualHours: _nullableDoubleFromJson(json['actualHours']),
        reminderMinutesBefore: json['reminderMinutesBefore'],
        lastActivityAt: json['lastActivityAt'] != null
            ? DateTime.parse(json['lastActivityAt'])
            : null,
        projectId: json['projectId'],
        subtasks: (json['subtasks'] as List<dynamic>?)
                ?.map((s) => SubTask.fromJson(s))
                .toList() ??
            [],
        linkedNoteIds: List<String>.from(json['linkedNoteIds'] ?? []),
        tags: List<String>.from(json['tags'] ?? []),
        recurrence: json['recurrence'] != null
            ? RecurrenceRule.fromJson(json['recurrence'])
            : null,
        sourceTaskId: json['sourceTaskId'],
        calendarEventId: json['calendarEventId'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
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

TaskStatus _statusFromJson(Object? value) {
  if (value is String) {
    switch (value) {
      case 'todo':
      case 'pending':
        return TaskStatus.pending;
      case 'inProgress':
        return TaskStatus.inProgress;
      case 'inReview':
        return TaskStatus.inReview;
      case 'done':
      case 'completed':
        return TaskStatus.completed;
      case 'archived':
      case 'cancelled':
        return TaskStatus.cancelled;
    }
  }

  if (value is int) {
    switch (value) {
      case 0:
        return TaskStatus.pending;
      case 1:
        return TaskStatus.inProgress;
      case 2:
        return TaskStatus.completed;
      case 3:
        return TaskStatus.cancelled;
    }
  }

  return TaskStatus.pending;
}

double _doubleFromJson(Object? value, {required double fallback}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

double? _nullableDoubleFromJson(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

class SubTask {
  final String id;
  final String title;
  final bool isDone;

  const SubTask({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  SubTask copyWith({String? title, bool? isDone}) => SubTask(
        id: id,
        title: title ?? this.title,
        isDone: isDone ?? this.isDone,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        id: json['id'],
        title: json['title'],
        isDone: json['isDone'] ?? false,
      );
}
