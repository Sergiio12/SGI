import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/goal.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../models/task.dart';
import 'backup_service.dart';
import 'interfaces/storage_service_interface.dart';

class PersistentBackupService {
  static const String _backupFileName = 'sgi_auto_backup.json';

  /// Intenta restaurar datos desde copias de seguridad persistentes.
  ///
  /// Busca en:
  /// 1. Directorio de documentos (restaurado por Android Auto Backup)
  /// 2. Directorio de Descargas (persiste tras desinstalación)
  ///
  /// Retorna `true` si se restauraron datos, `false` en caso contrario.
  static Future<bool> tryRestore(IStorageService storage) async {
    try {
      final tasks = await storage.loadTasks();
      final projects = await storage.loadProjects();
      final notes = await storage.loadNotes();
      final goals = await storage.loadGoals();

      if (tasks.isNotEmpty ||
          projects.isNotEmpty ||
          notes.isNotEmpty ||
          goals.isNotEmpty) {
        return false;
      }

      final backupFile = await _findBackupFile();
      if (backupFile == null) return false;

      final content = await backupFile.readAsString();
      final decoded = jsonDecode(content);
      if (decoded is! Map) return false;

      final data = Map<String, dynamic>.from(decoded);

      if (data['tasks'] is List) {
        final restored = (data['tasks'] as List)
            .whereType<Map>()
            .map((e) => Task.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (restored.isNotEmpty) await storage.saveTasks(restored);
      }

      if (data['projects'] is List) {
        final restored = (data['projects'] as List)
            .whereType<Map>()
            .map((e) => Project.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (restored.isNotEmpty) await storage.saveProjects(restored);
      }

      if (data['notes'] is List) {
        final restored = (data['notes'] as List)
            .whereType<Map>()
            .map((e) => Note.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (restored.isNotEmpty) await storage.saveNotes(restored);
      }

      if (data['goals'] is List) {
        final restored = (data['goals'] as List)
            .whereType<Map>()
            .map((e) => Goal.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (restored.isNotEmpty) await storage.saveGoals(restored);
      }

      return true;
    } catch (e) {
      debugPrint('PersistentBackup: restore error: $e');
      return false;
    }
  }

  static Future<File?> _findBackupFile() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final docFile = File('${docDir.path}/$_backupFileName');
      if (await docFile.exists()) return docFile;
    } catch (_) {}

    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final dlFile = File('${downloadsDir.path}/$_backupFileName');
        if (await dlFile.exists()) return dlFile;
      }
    } catch (_) {}

    return null;
  }

  /// Guarda un snapshot completo de los datos en ubicaciones persistentes.
  static Future<void> saveSnapshot({
    required List<Task> tasks,
    required List<Project> projects,
    required List<Note> notes,
    required List<Goal> goals,
  }) async {
    final payload = BackupService.buildPayload(
      tasks: tasks,
      projects: projects,
      notes: notes,
      goals: goals,
    );

    final jsonString = jsonEncode(payload);

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final docFile = File('${docDir.path}/$_backupFileName');
      await docFile.writeAsString(jsonString, flush: true);
    } catch (e) {
      debugPrint('PersistentBackup: snapshot to docs failed: $e');
    }

    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        final dlFile = File('${downloadsDir.path}/$_backupFileName');
        await dlFile.writeAsString(jsonString, flush: true);
      }
    } catch (_) {}
  }
}
