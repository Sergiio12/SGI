import 'dart:async';

import 'package:flutter/material.dart';

import '../services/cloud/sync_service.dart';
import '../services/interfaces/storage_service_interface.dart';

enum SyncStatus { disconnected, syncing, synced, error }

class SyncProvider extends ChangeNotifier {
  final SyncService _syncService;
  final IStorageService _storage;
  SyncStatus _status = SyncStatus.disconnected;
  DateTime? _lastSync;
  StreamSubscription<bool>? _connectionSubscription;

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

  Future<void> triggerSync() async {
    if (!_syncService.isAvailable) {
      _status = SyncStatus.error;
      notifyListeners();
      return;
    }

    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final tasks = await _storage.loadTasks();
      await _syncService.uploadTasks(tasks);
      final cloudTasks = await _syncService.downloadTasks();
      if (cloudTasks.isNotEmpty) await _storage.saveTasks(cloudTasks);

      final projects = await _storage.loadProjects();
      await _syncService.uploadProjects(projects);
      final cloudProjects = await _syncService.downloadProjects();
      if (cloudProjects.isNotEmpty) await _storage.saveProjects(cloudProjects);

      final notes = await _storage.loadNotes();
      await _syncService.uploadNotes(notes);
      final cloudNotes = await _syncService.downloadNotes();
      if (cloudNotes.isNotEmpty) await _storage.saveNotes(cloudNotes);

      final goals = await _storage.loadGoals();
      await _syncService.uploadGoals(goals);
      final cloudGoals = await _syncService.downloadGoals();
      if (cloudGoals.isNotEmpty) await _storage.saveGoals(cloudGoals);

      _lastSync = DateTime.now();
      _status = SyncStatus.synced;
    } catch (e) {
      _status = SyncStatus.error;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    super.dispose();
  }
}
