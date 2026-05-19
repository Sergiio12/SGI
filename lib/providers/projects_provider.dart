import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/project.dart';
import '../models/task.dart';
import '../services/interfaces/storage_service_interface.dart';
import '../utils/debouncer.dart';
import '../utils/notification_service_v2.dart';

class ProjectsProvider extends ChangeNotifier {
  final IStorageService _storage;
  List<Project> _projects = [];
  final _uuid = const Uuid();
  bool _isLoaded = false;
  final _saveDebouncer = Debouncer(delay: const Duration(milliseconds: 500));

  ProjectsProvider({required IStorageService storage}) : _storage = storage;

  List<Project> _activeProjects = [];
  List<Project> _pausedProjects = [];
  List<Project> _completedProjects = [];
  List<Project> _abandonedProjects = [];

  List<Project> get projects => _projects;
  bool get isLoaded => _isLoaded;

  List<Project> get activeProjects => _activeProjects;
  List<Project> get pausedProjects => _pausedProjects;
  List<Project> get completedProjects => _completedProjects;
  List<Project> get abandonedProjects => _abandonedProjects;

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
    _updateComputedLists();
    _isLoaded = true;
    notifyListeners();
  }

  void _updateComputedLists() {
    _activeProjects =
        _projects.where((p) => p.status == ProjectStatus.active).toList();
    _pausedProjects =
        _projects.where((p) => p.status == ProjectStatus.paused).toList();
    _completedProjects =
        _projects.where((p) => p.status == ProjectStatus.completed).toList();
    _abandonedProjects =
        _projects.where((p) => p.status == ProjectStatus.abandoned).toList();
  }

  void _notifyAndScheduleSave() {
    _updateComputedLists();
    notifyListeners();
    _saveDebouncer.call(() => _storage.saveProjects(_projects));
  }

  Future<Project> addProject({
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
      showSuccessNotification('Proyecto creado: ${project.title}');
      return project;
    } catch (e) {
      showErrorNotification('Error al crear proyecto');
      rethrow;
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
    } catch (e) {
      showErrorNotification('Error al actualizar proyecto');
      rethrow;
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
    } catch (e) {
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
    } catch (e) {
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
      showSuccessNotification('Proyecto movido a la papelera');
    } catch (e) {
      showErrorNotification('Error al eliminar proyecto');
      rethrow;
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
        showSuccessNotification('Proyecto restaurado');
      }
    } catch (e) {
      showErrorNotification('Error al restaurar proyecto');
      rethrow;
    }
  }

  Future<void> permanentDeleteProject(String projectId) async {
    try {
      final trash = await _storage.loadTrashProjects();
      trash.removeWhere((p) => p.id == projectId);
      await _storage.saveTrashProjects(trash);
      showSuccessNotification('Proyecto eliminado permanentemente');
    } catch (e) {
      showErrorNotification('Error al eliminar proyecto');
      rethrow;
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
