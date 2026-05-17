import 'brain_item.dart';

enum GoalHorizon { monthly, quarterly, yearly }

class Goal extends BrainItem {
  final String title;
  final String description;
  final GoalHorizon horizon;
  final List<String> projectIds;
  final String metricLabel;
  final double targetValue;
  final double currentValue;
  final int colorValue;

  Goal({
    required super.id,
    required this.title,
    this.description = '',
    this.horizon = GoalHorizon.quarterly,
    this.projectIds = const [],
    this.metricLabel = 'Progreso',
    this.targetValue = 100,
    this.currentValue = 0,
    this.colorValue = 0xFF8B5CF6,
    super.tags = const [],
    required super.createdAt,
    required super.updatedAt,
  });

  double get progress {
    if (targetValue <= 0) return 0;
    return (currentValue / targetValue).clamp(0, 1).toDouble();
  }

  Goal copyWith({
    String? title,
    String? description,
    GoalHorizon? horizon,
    List<String>? projectIds,
    String? metricLabel,
    double? targetValue,
    double? currentValue,
    int? colorValue,
    List<String>? tags,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      horizon: horizon ?? this.horizon,
      projectIds: projectIds ?? this.projectIds,
      metricLabel: metricLabel ?? this.metricLabel,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      colorValue: colorValue ?? this.colorValue,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'horizon': horizon.name,
        'projectIds': projectIds,
        'metricLabel': metricLabel,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'colorValue': colorValue,
        'tags': tags,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'],
        title: json['title'],
        description: json['description'] ?? '',
        horizon: _horizonFromJson(json['horizon']),
        projectIds: List<String>.from(json['projectIds'] ?? []),
        metricLabel: json['metricLabel'] ?? 'Progreso',
        targetValue: _doubleFromJson(json['targetValue'], fallback: 100),
        currentValue: _doubleFromJson(json['currentValue'], fallback: 0),
        colorValue: json['colorValue'] ?? 0xFF8B5CF6,
        tags: List<String>.from(json['tags'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );
}

GoalHorizon _horizonFromJson(Object? value) {
  if (value is String) {
    for (final horizon in GoalHorizon.values) {
      if (horizon.name == value) return horizon;
    }
  }

  if (value is int && value >= 0 && value < GoalHorizon.values.length) {
    return GoalHorizon.values[value];
  }

  return GoalHorizon.quarterly;
}

double _doubleFromJson(Object? value, {required double fallback}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}
