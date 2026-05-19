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
      final result = await provider.addProject(title: 'Test Project');
      expect(result.isSuccess, isTrue);
      final project = result.unwrap();
      expect(project.title, 'Test Project');
      expect(provider.projects.length, 1);
    });

    test('addProject with all fields', () async {
      final deadline = DateTime.now().add(const Duration(days: 30));
      final result = await provider.addProject(
        title: 'Full Project',
        description: 'A detailed project',
        emoji: '🚀',
        colorValue: 0xFF00FF00,
        deadline: deadline,
        priority: TaskPriority.high,
        objective: 'Launch MVP',
        goalId: 'goal-1',
        tags: ['tech'],
      );
      expect(result.isSuccess, isTrue);
      final project = result.unwrap();
      expect(project.description, 'A detailed project');
      expect(project.emoji, '🚀');
      expect(project.deadline, deadline);
      expect(project.priority, TaskPriority.high);
      expect(project.objective, 'Launch MVP');
      expect(project.goalId, 'goal-1');
      expect(project.tags, ['tech']);
    });

    test('updateProject modifies project', () async {
      final result = await provider.addProject(title: 'Original');
      final project = result.unwrap();
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
        title: 'Completed',
        status: ProjectStatus.completed,
      );
      expect(provider.activeProjects.length, 1);
      expect(provider.pausedProjects.length, 1);
      expect(provider.completedProjects.length, 1);
    });
  });

  group('ProjectsProvider - Trash Lifecycle', () {
    test('deleteProject moves to trash', () async {
      final result = await provider.addProject(title: 'Delete me');
      final project = result.unwrap();
      await provider.deleteProject(project.id);
      expect(provider.projects, isEmpty);
    });

    test('restoreProject retrieves from trash', () async {
      final result = await provider.addProject(title: 'Restore me');
      final project = result.unwrap();
      await provider.deleteProject(project.id);
      await provider.restoreProject(project.id);
      expect(provider.projects.length, 1);
    });

    test('permanentDeleteProject removes from trash', () async {
      final result = await provider.addProject(title: 'Forever');
      final project = result.unwrap();
      await provider.deleteProject(project.id);
      await provider.permanentDeleteProject(project.id);
    });
  });
}
