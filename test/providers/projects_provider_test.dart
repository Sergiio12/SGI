import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/models/project.dart';
import 'package:second_brain/models/task.dart';
import 'package:second_brain/providers/projects_provider.dart';

import '../helpers/mock_storage_service.dart';

void main() {
  late MockStorageService storage;
  late ProjectsProvider provider;

  setUp(() async {
    storage = MockStorageService();
    provider = ProjectsProvider(storage: storage);
    await provider.loadProjects();
  });

  group('ProjectsProvider - CRUD', () {
    test('loadProjects loads empty list by default', () {
      expect(provider.projects, isEmpty);
      expect(provider.isLoaded, isTrue);
    });

    test('addProject creates a project', () async {
      final project = await provider.addProject(title: 'Test Project');
      expect(project.title, 'Test Project');
      expect(provider.projects.length, 1);
      expect(provider.activeProjects.length, 1);
    });

    test('addProject with all fields', () async {
      final project = await provider.addProject(
        title: 'Full Project',
        description: 'A description',
        emoji: '🚀',
        colorValue: 0xFFFF0000,
        deadline: DateTime(2026, 12, 31),
        priority: TaskPriority.high,
        objective: 'Launch it',
      );
      expect(project.title, 'Full Project');
      expect(project.description, 'A description');
      expect(project.emoji, '🚀');
      expect(project.deadline, DateTime(2026, 12, 31));
      expect(project.priority, TaskPriority.high);
      expect(project.objective, 'Launch it');
    });

    test('updateProject modifies project', () async {
      final project = await provider.addProject(title: 'Original');
      final updated = project.copyWith(title: 'Updated');
      await provider.updateProject(updated);
      expect(provider.getProjectById(project.id)?.title, 'Updated');
    });

    test('getProjectById returns null for missing id', () {
      expect(provider.getProjectById('missing'), isNull);
    });

    test('getProjectsByGoal filters correctly', () async {
      await provider.addProject(title: 'Goal A', goalId: 'g1');
      await provider.addProject(title: 'Goal B', goalId: 'g1');
      await provider.addProject(title: 'Other', goalId: 'g2');
      expect(provider.getProjectsByGoal('g1').length, 2);
      expect(provider.getProjectsByGoal('g2').length, 1);
    });
  });

  group('ProjectsProvider - Status management', () {
    test('projects are grouped by status', () async {
      await provider.addProject(title: 'Active 1');
      await provider.addProject(
        title: 'Paused',
        status: ProjectStatus.paused,
      );
      await provider.addProject(
        title: 'Done',
        status: ProjectStatus.completed,
      );

      expect(provider.activeProjects.length, 1);
      expect(provider.pausedProjects.length, 1);
      expect(provider.completedProjects.length, 1);
    });
  });

  group('ProjectsProvider - Trash Lifecycle', () {
    test('deleteProject moves to trash', () async {
      final project = await provider.addProject(title: 'Delete me');
      await provider.deleteProject(project.id);
      expect(provider.projects, isEmpty);
      expect(storage.trashTasks, isEmpty); // projects go to trash projects
    });

    test('restoreProject retrieves from trash', () async {
      final project = await provider.addProject(title: 'Restore me');
      await provider.deleteProject(project.id);
      await provider.restoreProject(project.id);
      expect(provider.projects.length, 1);
    });

    test('permanentDeleteProject removes from trash', () async {
      final project = await provider.addProject(title: 'Forever');
      await provider.deleteProject(project.id);
      await provider.permanentDeleteProject(project.id);
    });
  });
}
