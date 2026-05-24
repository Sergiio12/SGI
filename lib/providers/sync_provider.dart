import 'dart:async';

import 'package:flutter/material.dart';

import '../models/goal.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../services/cloud/sync_service.dart';
import '../services/interfaces/storage_service_interface.dart';

enum SyncStatus { disconnected, syncing, synced, error }

class SyncConflict {
  final String id;
  final String title;
  final String type;
  final DateTime localUpdatedAt;
  final DateTime cloudUpdatedAt;

  const SyncConflict({
    required this.id,
    required this.title,
    required this.type,
    required this.localUpdatedAt,
    required this.cloudUpdatedAt,
  });
}

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;
  final IStorageService _storage;
  SyncStatus _status = SyncStatus.disconnected;
  DateTime? _lastSync;
  StreamSubscription<bool>? _connectionSubscription;
  List<SyncConflict> _conflicts = [];
  String? _lastError;

  SyncProvider({
    required SyncService syncService,
    required IStorageService storage,
  })  : _syncService = syncService,
        _storage = storage {
    _connectionSubscription = _syncService.connectionState.listen((connected) {
      if (!connected) {
        _status = SyncStatus.disconnected;
      } else if (_status == SyncStatus.disconnected) {
        _status = SyncStatus.synced;
      }
      notifyListeners();
    });
  }

  SyncStatus get status => _status;
  DateTime? get lastSync => _lastSync;
  bool get isAvailable => _syncService.isAvailable;
  List<SyncConflict> get conflicts => _conflicts;
  bool get hasConflicts => _conflicts.isNotEmpty;
  String? get lastError => _lastError;

  String get statusLabel {
    switch (_status) {
      case SyncStatus.disconnected:
        return 'Sin conexión';
      case SyncStatus.syncing:
        return 'Sincronizando...';
      case SyncStatus.synced:
        return 'Sincronizado';
      case SyncStatus.error:
        return 'Error de sincronización';
    }
  }

  void _detectConflicts<T>({
    required List<T> localItems,
    required List<T> cloudItems,
    required String Function(T) getId,
    required String Function(T) getTitle,
    required String type,
    required DateTime Function(T) getUpdatedAt,
  }) {
    final cloudMap = {for (final item in cloudItems) getId(item): item};
    for (final local in localItems) {
      final localId = getId(local);
      final cloud = cloudMap[localId];
      if (cloud != null) {
        final localTime = getUpdatedAt(local);
        final cloudTime = getUpdatedAt(cloud);
        final diff = localTime.difference(cloudTime).inSeconds.abs();
        if (diff > 5 && localTime.isBefore(cloudTime) == false) {
          _conflicts.add(SyncConflict(
            id: localId,
            title: getTitle(local),
            type: type,
            localUpdatedAt: localTime,
            cloudUpdatedAt: cloudTime,
          ));
        }
      }
    }
  }

  Future<void> triggerSync() async {
    if (!_syncService.isAvailable) {
      _status = SyncStatus.error;
      _lastError = 'Servicio de sincronización no disponible';
      notifyListeners();
      return;
    }

    _status = SyncStatus.syncing;
    _conflicts = [];
    _lastError = null;
    notifyListeners();

    try {
      final localTasks = await _storage.loadTasks();
      await _syncService.uploadTasks(localTasks);
      final cloudTasks = await _syncService.downloadTasks();

      final localProjects = await _storage.loadProjects();
      await _syncService.uploadProjects(localProjects);
      final cloudProjects = await _syncService.downloadProjects();

      final localNotes = await _storage.loadNotes();
      await _syncService.uploadNotes(localNotes);
      final cloudNotes = await _syncService.downloadNotes();

      final localGoals = await _storage.loadGoals();
      await _syncService.uploadGoals(localGoals);
      final cloudGoals = await _syncService.downloadGoals();

      _detectConflicts(
        localItems: localTasks,
        cloudItems: cloudTasks,
        getId: (Task t) => t.id,
        getTitle: (Task t) => t.title,
        type: 'task',
        getUpdatedAt: (Task t) => t.updatedAt,
      );
      _detectConflicts(
        localItems: localProjects,
        cloudItems: cloudProjects,
        getId: (Project p) => p.id,
        getTitle: (Project p) => p.title,
        type: 'project',
        getUpdatedAt: (Project p) => p.updatedAt,
      );
      _detectConflicts(
        localItems: localNotes,
        cloudItems: cloudNotes,
        getId: (Note n) => n.id,
        getTitle: (Note n) => n.title,
        type: 'note',
        getUpdatedAt: (Note n) => n.updatedAt,
      );
      _detectConflicts(
        localItems: localGoals,
        cloudItems: cloudGoals,
        getId: (Goal g) => g.id,
        getTitle: (Goal g) => g.title,
        type: 'goal',
        getUpdatedAt: (Goal g) => g.updatedAt,
      );

      if (!hasConflicts) {
        if (cloudTasks.isNotEmpty) await _storage.saveTasks(cloudTasks);
        if (cloudProjects.isNotEmpty) await _storage.saveProjects(cloudProjects);
        if (cloudNotes.isNotEmpty) await _storage.saveNotes(cloudNotes);
        if (cloudGoals.isNotEmpty) await _storage.saveGoals(cloudGoals);
      }

      _lastSync = DateTime.now();
      _status = hasConflicts ? SyncStatus.synced : SyncStatus.synced;
    } catch (e) {
      _status = SyncStatus.error;
      _lastError = e.toString();
    }

    notifyListeners();
  }

  Future<void> resolveConflictKeepLocal(String id, String type) async {
    _conflicts.removeWhere((c) => c.id == id && c.type == type);
    if (!hasConflicts) {
      await _reapplyCloud();
    }
    notifyListeners();
  }

  Future<void> resolveConflictKeepCloud(String id, String type) async {
    _conflicts.removeWhere((c) => c.id == id && c.type == type);
    if (!hasConflicts) {
      await _reapplyCloud();
    }
    notifyListeners();
  }

  Future<void> resolveAllConflictsKeepLocal() async {
    _conflicts.clear();
    notifyListeners();
  }

  Future<void> resolveAllConflictsKeepCloud() async {
    _conflicts.clear();
    await _reapplyCloud();
    notifyListeners();
  }

  Future<void> _reapplyCloud() async {
    try {
      final cloudTasks = await _syncService.downloadTasks();
      if (cloudTasks.isNotEmpty) await _storage.saveTasks(cloudTasks);
      final cloudProjects = await _syncService.downloadProjects();
      if (cloudProjects.isNotEmpty) await _storage.saveProjects(cloudProjects);
      final cloudNotes = await _syncService.downloadNotes();
      if (cloudNotes.isNotEmpty) await _storage.saveNotes(cloudNotes);
      final cloudGoals = await _syncService.downloadGoals();
      if (cloudGoals.isNotEmpty) await _storage.saveGoals(cloudGoals);
    } catch (_) {}
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
