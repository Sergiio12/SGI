import 'package:intl/intl.dart';

class TimeBlock {
  final String id;
  final String taskId;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isCompleted;

  const TimeBlock({
    required this.id,
    required this.taskId,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.isCompleted = false,
  });

  String get startLabel {
    final dt = DateTime(2000, 1, 1, startHour, startMinute);
    return DateFormat('HH:mm').format(dt);
  }

  String get endLabel {
    final dt = DateTime(2000, 1, 1, endHour, endMinute);
    return DateFormat('HH:mm').format(dt);
  }

  int get durationMinutes =>
      (endHour * 60 + endMinute) - (startHour * 60 + startMinute);

  TimeBlock copyWith({
    String? id,
    String? taskId,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? isCompleted,
  }) =>
      TimeBlock(
        id: id ?? this.id,
        taskId: taskId ?? this.taskId,
        startHour: startHour ?? this.startHour,
        startMinute: startMinute ?? this.startMinute,
        endHour: endHour ?? this.endHour,
        endMinute: endMinute ?? this.endMinute,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'isCompleted': isCompleted,
      };

  factory TimeBlock.fromJson(Map<String, dynamic> json) => TimeBlock(
        id: json['id'] as String,
        taskId: json['taskId'] as String,
        startHour: json['startHour'] as int,
        startMinute: json['startMinute'] as int,
        endHour: json['endHour'] as int,
        endMinute: json['endMinute'] as int,
        isCompleted: json['isCompleted'] as bool? ?? false,
      );
}
