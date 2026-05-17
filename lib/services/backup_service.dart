import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../models/goal.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../models/task.dart';

class BrainBackupImport {
  final List<Task> tasks;
  final List<Project> projects;
  final List<Note> notes;
  final List<Goal> goals;

  const BrainBackupImport({
    required this.tasks,
    required this.projects,
    required this.notes,
    required this.goals,
  });
}

class BackupService {
  static Map<String, dynamic> buildPayload({
    required List<Task> tasks,
    required List<Project> projects,
    required List<Note> notes,
    required List<Goal> goals,
  }) {
    return {
      'schemaVersion': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'second_brain',
      'tasks': tasks.map((t) => t.toJson()).toList(),
      'projects': projects.map((p) => p.toJson()).toList(),
      'notes': notes.map((n) => n.toJson()).toList(),
      'goals': goals.map((g) => g.toJson()).toList(),
    };
  }

  static Future<File> exportToJson({
    required List<Task> tasks,
    required List<Project> projects,
    required List<Note> notes,
    required List<Goal> goals,
  }) async {
    // Realizamos la construcción del payload y la codificación JSON en un Isolate
    final jsonString = await Isolate.run(() {
      final payload = buildPayload(
        tasks: tasks,
        projects: projects,
        notes: notes,
        goals: goals,
      );
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(payload);
    });

    final directory = await _preferredExportDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${directory.path}/second_brain_backup_$timestamp.json');
    
    return file.writeAsString(jsonString, flush: true);
  }

  static Future<BrainBackupImport?> pickAndReadImport() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      allowMultiple: false,
    );

    final path = result?.files.single.path;
    if (path == null) return null;

    final content = await File(path).readAsString();
    
    // El procesamiento de decode y mapeo de objetos puede ser pesado, lo movemos a un Isolate
    return await Isolate.run(() {
      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        throw const FormatException('El archivo no contiene una copia valida.');
      }

      final json = Map<String, dynamic>.from(decoded);
      return BrainBackupImport(
        tasks: _decodeList(json['tasks'], Task.fromJson),
        projects: _decodeList(json['projects'], Project.fromJson),
        notes: _decodeList(json['notes'], Note.fromJson),
        goals: _decodeList(json['goals'], Goal.fromJson),
      );
    });
  }

  static List<T> _decodeList<T>(
    Object? value,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    if (value is! List) return [];
    return value
        .whereType<Map>()
        .map((item) => fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<Directory> _preferredExportDirectory() async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads != null) return downloads;
    } catch (_) {
      // Android may restrict direct downloads access on some API levels.
    }
    return getApplicationDocumentsDirectory();
  }
}
