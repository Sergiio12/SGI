import 'dart:isolate';
import '../models/project.dart';
import '../models/task.dart';

enum SmartAlertSeverity { info, warning, danger }

class SmartAlert {
  final String title;
  final String message;
  final SmartAlertSeverity severity;

  const SmartAlert({
    required this.title,
    required this.message,
    required this.severity,
  });
}

class SmartAlertsService {
  static Future<List<SmartAlert>> buildAlerts({
    required List<Task> tasks,
    required List<Project> projects,
  }) async {
    // Si no hay datos, evitamos el overhead del Isolate
    if (tasks.isEmpty && projects.isEmpty) return [];

    return await Isolate.run(() => _buildAlertsInternal(
          tasks: tasks,
          projects: projects,
        ));
  }

  static List<SmartAlert> _buildAlertsInternal({
    required List<Task> tasks,
    required List<Project> projects,
  }) {
    final now = DateTime.now();
    final alerts = <SmartAlert>[];

    final dueSoon = tasks.where((task) {
      final dueDate = task.dueDate;
      if (dueDate == null || !task.isActive) return false;
      final remaining = dueDate.difference(now);
      return remaining.inHours >= 0 && remaining.inHours <= 24;
    }).length;
    if (dueSoon > 0) {
      alerts.add(SmartAlert(
        title: 'Deadlines cercanos',
        message: '$dueSoon tareas vencen en las próximas 24 horas.',
        severity: SmartAlertSeverity.warning,
      ));
    }

    final urgentNotStarted = tasks.where((task) {
      return task.priority == TaskPriority.urgent &&
          task.status == TaskStatus.pending;
    }).length;
    if (urgentNotStarted > 0) {
      alerts.add(SmartAlert(
        title: 'Urgentes sin iniciar',
        message: '$urgentNotStarted tareas urgentes siguen en pendiente.',
        severity: SmartAlertSeverity.danger,
      ));
    }

    final inactiveImportant = tasks.where((task) {
      if (!task.isActive) return false;
      if (task.priority.index < TaskPriority.high.index) return false;
      final activity = task.lastActivityAt ?? task.updatedAt;
      return now.difference(activity).inDays >= 3;
    }).length;
    if (inactiveImportant > 0) {
      alerts.add(SmartAlert(
        title: 'Baja actividad',
        message:
            '$inactiveImportant tareas importantes llevan 3 días sin avance.',
        severity: SmartAlertSeverity.warning,
      ));
    }

    final delayedProjects = projects.where((project) {
      final deadline = project.deadline;
      if (deadline == null) return false;
      return deadline.isBefore(now) &&
          project.status != ProjectStatus.completed &&
          project.status != ProjectStatus.abandoned;
    }).length;
    if (delayedProjects > 0) {
      alerts.add(SmartAlert(
        title: 'Proyectos retrasados',
        message: '$delayedProjects proyectos han superado su fecha estimada.',
        severity: SmartAlertSeverity.danger,
      ));
    }

    return alerts.take(4).toList();
  }
}
