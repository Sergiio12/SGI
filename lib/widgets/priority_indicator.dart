import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/task.dart';

class PriorityIndicator extends StatelessWidget {
  final TaskPriority priority;
  final bool showLabel;

  const PriorityIndicator({
    super.key,
    required this.priority,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BrainTheme.priorityColor(priority.index),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            _label,
            style: TextStyle(
              fontSize: 12,
              color: BrainTheme.priorityColor(priority.index),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  String get _label {
    switch (priority) {
      case TaskPriority.low:
        return 'Baja';
      case TaskPriority.medium:
        return 'Media';
      case TaskPriority.high:
        return 'Alta';
      case TaskPriority.urgent:
        return 'Urgente';
    }
  }
}
