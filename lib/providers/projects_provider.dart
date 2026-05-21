import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../core/result.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/interfaces/storage_service_interface.dart';
import '../utils/debouncer.dart';
import '../utils/haptic_helper.dart';
import '../utils/notification_service_v2.dart';

class ProjectsProvider extends ChangeNotifier {
  final IStorageService _storage;
  List<Project> _projects = [];
  final _uuid = const Uuid();
  bool _isLoaded = false;
  final _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

  ProjectsProvider({required IStorageService storage}) : _storage = storage;

  List<Project>? __activeProjects;
  List<Project>? __pausedProjects;
  List<Project>? __completedProjects;
  List<Project>? __abandonedProjects;

  List<Project> get projects => _projects;
  bool get isLoaded => _isLoaded;

  List<Project> get activeProjects =>
      __activeProjects ??= _projects.where((p) => p.status == ProjectStatus.active).toList();
  List<Project> get pausedProjects =>
      __pausedProjects ??= _projects.where((p) => p.status == ProjectStatus.paused).toList();
  List<Project> get completedProjects =>
      __completedProjects ??= _projects.where((p) => p.status == ProjectStatus.completed).toList();
  List<Project> get abandonedProjects =>
      __abandonedProjects ??= _projects.where((p) => p.status == ProjectStatus.abandoned).toList();

  List<Project> getProjectsByGoal(String goalId) =>
      _projects.where((p) => p.goalId == goalId).toList();

  Project? getProjectById(String id) {
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadProjects() async {
    _projects = await _storage.loadProjects();
    _markDirty();
    _isLoaded = true;
    notifyListeners();
  }

  void _markDirty() {
    __activeProjects = null;
    __pausedProjects = null;
    __completedProjects = null;
    __abandonedProjects = null;
  }

  void _notifyAndScheduleSave() {
    _markDirty();
    notifyListeners();
    _saveDebouncer.call(() => _storage.saveProjects(_projects));
  }

  Future<Result<Project>> addProject({
    required String title,
    String description = '',
    String emoji = '📁',
    int colorValue = 0xFF2196F3,
    ProjectStatus status = ProjectStatus.active,
    DateTime? startDate,
    DateTime? deadline,
    TaskPriority priority = TaskPriority.medium,
    String objective = '',
    String? goalId,
    List<String> tags = const [],
  }) async {
    try {
      final now = DateTime.now();
      final project = Project(
        id: _uuid.v4(),
        title: title,
        description: description,
        emoji: emoji,
        colorValue: colorValue,
        status: status,
        startDate: startDate ?? now,
        deadline: deadline,
        priority: priority,
        objective: objective,
        goalId: goalId,
        tags: tags,
        createdAt: now,
        updatedAt: now,
      );
      _projects.add(project);
      _notifyAndScheduleSave();
      HapticHelper.light();
      showSuccessNotification('Proyecto creado: ${project.title}');
      return Result.success(project);
    } catch (e, s) {
      final error = AppException(
        message: 'Error al crear proyecto',
        code: 'ADD_PROJECT',
        stackTrace: s,
      );
      error.log();
      showErrorNotification(error.message);
      return Result.failure(error);
    }
  }

  Future<void> updateProject(Project project) async {
    try {
      final index = _projects.indexWhere((p) => p.id == project.id);
      if (index != -1) {
        _projects[index] = project;
        _notifyAndScheduleSave();
        showSuccessNotification('Proyecto actualizado');
      }
    } catch (e, s) {
      AppException(message: 'Error al actualizar proyecto', code: 'UPDATE_PROJECT', stackTrace: s).log();
      showErrorNotification('Error al actualizar proyecto');
    }
  }

  Future<void> addTaskToProject(String projectId, String taskId) async {
    try {
      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        final project = _projects[index];
        if (!project.taskIds.contains(taskId)) {
          _projects[index] = project.copyWith(
            taskIds: [...project.taskIds, taskId],
          );
          _notifyAndScheduleSave();
        }
      }
    } catch (e, s) {
      AppException(message: 'Error al agregar tarea al proyecto', code: 'ADD_TASK_TO_PROJECT', stackTrace: s).log();
      showErrorNotification('Error al agregar tarea al proyecto');
    }
  }

  Future<void> addNoteToProject(String projectId, String noteId) async {
    try {
      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        final project = _projects[index];
        if (!project.noteIds.contains(noteId)) {
          _projects[index] = project.copyWith(
            noteIds: [...project.noteIds, noteId],
          );
          _notifyAndScheduleSave();
        }
      }
    } catch (e, s) {
      AppException(message: 'Error al agregar nota al proyecto', code: 'ADD_NOTE_TO_PROJECT', stackTrace: s).log();
      showErrorNotification('Error al agregar nota al proyecto');
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      final index = _projects.indexWhere((p) => p.id == projectId);
      if (index == -1) return;
      final project = _projects.removeAt(index);
      final trash = await _storage.loadTrashProjects();
      trash.add(project);
      await _storage.saveTrashProjects(trash);
      _notifyAndScheduleSave();
      HapticHelper.medium();
      showSuccessNotification('Proyecto movido a la papelera');
    } catch (e, s) {
      AppException(message: 'Error al eliminar proyecto', code: 'DELETE_PROJECT', stackTrace: s).log();
      showErrorNotification('Error al eliminar proyecto');
    }
  }

  Future<void> restoreProject(String projectId) async {
    try {
      final trash = await _storage.loadTrashProjects();
      final index = trash.indexWhere((p) => p.id == projectId);
      if (index != -1) {
        final project = trash.removeAt(index);
        _projects.add(project);
        await _storage.saveTrashProjects(trash);
        _notifyAndScheduleSave();
        HapticHelper.light();
        showSuccessNotification('Proyecto restaurado');
      }
    } catch (e, s) {
      AppException(message: 'Error al restaurar proyecto', code: 'RESTORE_PROJECT', stackTrace: s).log();
      showErrorNotification('Error al restaurar proyecto');
    }
  }

  Future<void> permanentDeleteProject(String projectId) async {
    try {
      final trash = await _storage.loadTrashProjects();
      trash.removeWhere((p) => p.id == projectId);
      await _storage.saveTrashProjects(trash);
      showSuccessNotification('Proyecto eliminado permanentemente');
    } catch (e, s) {
      AppException(message: 'Error al eliminar proyecto permanentemente', code: 'PERM_DELETE_PROJECT', stackTrace: s).log();
      showErrorNotification('Error al eliminar proyecto');
    }
  }

  Future<void> replaceAll(List<Project> projects) async {
    _projects = projects;
    _notifyAndScheduleSave();
  }

  @override
  void dispose() {
    _saveDebouncer.dispose();
    super.dispose();
  }
}
