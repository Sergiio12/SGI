import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../models/goal.dart';
import '../../models/note.dart';
import '../../models/project.dart';
import '../../models/task.dart';
import 'sync_service.dart';

class FirebaseSyncService implements SyncService {
  FirebaseFirestore? _firestore;
  auth.User? _user;
  bool _available = false;
  final _connectionController = StreamController<bool>.broadcast();

  @override
  bool get isAvailable => _available;

  @override
  Stream<bool> get connectionState => _connectionController.stream;

  @override
  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _firestore = FirebaseFirestore.instance;

      final authInstance = auth.FirebaseAuth.instance;
      _user = authInstance.currentUser;
      if (_user == null) {
        final credential = await authInstance.signInAnonymously();
        _user = credential.user;
      }

      _available = true;
      _connectionController.add(true);

      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      _available = false;
      _connectionController.add(false);
      debugPrint('FirebaseSyncService: No se pudo inicializar Firebase: $e');
    }
  }

  String? get _uid => _user?.uid;

  @override
  Future<void> uploadTasks(List<Task> tasks) async {
    if (!_available || _uid == null) return;
    final batch = _firestore!.batch();
    for (final task in tasks) {
      final doc = _firestore!.collection('tasks').doc(task.id);
      batch.set(doc, {
        ...task.toJson(),
        'lastModified': DateTime.now().toIso8601String(),
        'userId': _uid,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<List<Task>> downloadTasks() async {
    if (!_available || _uid == null) return [];
    try {
      final snapshot = await _firestore!
          .collection('tasks')
          .where('userId', isEqualTo: _uid)
          .get();
      return snapshot.docs
          .map((doc) => Task.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error descargando tareas: $e');
      return [];
    }
  }

  @override
  Future<void> uploadProjects(List<Project> projects) async {
    if (!_available || _uid == null) return;
    final batch = _firestore!.batch();
    for (final project in projects) {
      final doc = _firestore!.collection('projects').doc(project.id);
      batch.set(doc, {
        ...project.toJson(),
        'lastModified': DateTime.now().toIso8601String(),
        'userId': _uid,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<List<Project>> downloadProjects() async {
    if (!_available || _uid == null) return [];
    try {
      final snapshot = await _firestore!
          .collection('projects')
          .where('userId', isEqualTo: _uid)
          .get();
      return snapshot.docs
          .map((doc) => Project.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error descargando proyectos: $e');
      return [];
    }
  }

  @override
  Future<void> uploadNotes(List<Note> notes) async {
    if (!_available || _uid == null) return;
    final batch = _firestore!.batch();
    for (final note in notes) {
      final doc = _firestore!.collection('notes').doc(note.id);
      batch.set(doc, {
        ...note.toJson(),
        'lastModified': DateTime.now().toIso8601String(),
        'userId': _uid,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<List<Note>> downloadNotes() async {
    if (!_available || _uid == null) return [];
    try {
      final snapshot = await _firestore!
          .collection('notes')
          .where('userId', isEqualTo: _uid)
          .get();
      return snapshot.docs
          .map((doc) => Note.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error descargando notas: $e');
      return [];
    }
  }

  @override
  Future<void> uploadGoals(List<Goal> goals) async {
    if (!_available || _uid == null) return;
    final batch = _firestore!.batch();
    for (final goal in goals) {
      final doc = _firestore!.collection('goals').doc(goal.id);
      batch.set(doc, {
        ...goal.toJson(),
        'lastModified': DateTime.now().toIso8601String(),
        'userId': _uid,
      }, SetOptions(merge: true));
    }
    await batch.commit();
  }

  @override
  Future<List<Goal>> downloadGoals() async {
    if (!_available || _uid == null) return [];
    try {
      final snapshot = await _firestore!
          .collection('goals')
          .where('userId', isEqualTo: _uid)
          .get();
      return snapshot.docs
          .map((doc) => Goal.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      debugPrint('FirebaseSyncService: Error descargando objetivos: $e');
      return [];
    }
  }

  @override
  Future<void> deleteAll() async {
    if (!_available || _uid == null) return;
    for (final collection in ['tasks', 'projects', 'notes', 'goals']) {
      final snapshot = await _firestore!
          .collection(collection)
          .where('userId', isEqualTo: _uid)
          .get();
      final batch = _firestore!.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  void dispose() {
    _connectionController.close();
  }
}
