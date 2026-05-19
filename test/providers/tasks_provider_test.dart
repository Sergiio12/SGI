import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/models/task.dart';
import 'package:second_brain/providers/tasks_provider.dart';

import '../helpers/mock_storage_service.dart';

void main() {
  late MockStorageService storage;
  late TasksProvider provider;

  setUp(() async {
    storage = MockStorageService();
    provider = TasksProvider(storage: storage);
    await provider.loadTasks();
  });

  group('TasksProvider - CRUD', () {
    test('loadTasks loads empty list by default', () {
      expect(provider.tasks, isEmpty);
      expect(provider.isLoaded, isTrue);
    });

    test('addTask creates and returns a task', () async {
      final task = await provider.addTask(title: 'Test task');
      expect(task.title, 'Test task');
      expect(provider.tasks.length, 1);
      expect(provider.todoTasks.length, 1);
    });

    test('addTask with all fields', () async {
      final now = DateTime.now();
      final dueDate = now.add(const Duration(days: 1));
      final task = await provider.addTask(
        title: 'Full task',
        description: 'Description',
        priority: TaskPriority.high,
        dueDate: dueDate,
        estimatedHours: 2.5,
        projectId: 'proj-1',
        tags: ['urgent'],
      );
      expect(task.title, 'Full task');
      expect(task.description, 'Description');
      expect(task.priority, TaskPriority.high);
      expect(task.dueDate, dueDate);
      expect(task.projectId, 'proj-1');
      expect(task.tags, ['urgent']);
    });

    test('updateTask modifies task in list', () async {
      final task = await provider.addTask(title: 'Original');
      final updated = task.copyWith(title: 'Updated');
      await provider.updateTask(updated);
      expect(provider.getTaskById(task.id)?.title, 'Updated');
    });

    test('updateTask does nothing for non-existent task', () async {
      final now = DateTime.now();
      final task = Task(
        id: 'nonexistent',
        title: 'Ghost',
        createdAt: now,
        updatedAt: now,
      );
      await provider.updateTask(task);
      expect(provider.tasks, isEmpty);
    });

    test('getTaskById returns null for missing id', () {
      expect(provider.getTaskById('missing'), isNull);
    });
  });

  group('TasksProvider - Status Management', () {
    test('toggleTaskStatus toggles between pending and completed', () async {
      final task = await provider.addTask(title: 'Toggle me');
      expect(task.status, TaskStatus.pending);

      await provider.toggleTaskStatus(task.id);
      expect(provider.getTaskById(task.id)?.status, TaskStatus.completed);

      await provider.toggleTaskStatus(task.id);
      expect(provider.getTaskById(task.id)?.status, TaskStatus.pending);
    });

    test('moveTaskToStatus changes status', () async {
      final task = await provider.addTask(title: 'Move me');
      await provider.moveTaskToStatus(task.id, TaskStatus.inProgress);
      expect(provider.getTaskById(task.id)?.status, TaskStatus.inProgress);
    });

    test('moveTaskToStatus same status does nothing', () async {
      final task = await provider.addTask(title: 'Stay');
      await provider.moveTaskToStatus(task.id, TaskStatus.pending);
      expect(provider.getTaskById(task.id)?.status, TaskStatus.pending);
    });
  });

  group('TasksProvider - Subtasks', () {
    test('addSubtask adds a subtask to a task', () async {
      final task = await provider.addTask(title: 'With subtasks');
      await provider.addSubtask(task.id, 'Step 1');
      final updated = provider.getTaskById(task.id)!;
      expect(updated.subtasks.length, 1);
      expect(updated.subtasks.first.title, 'Step 1');
      expect(updated.subtasks.first.isDone, isFalse);
    });

    test('toggleSubtask toggles subtask completion', () async {
      final task = await provider.addTask(title: 'Subtasks');
      await provider.addSubtask(task.id, 'Step 1');
      final subtaskId = provider.getTaskById(task.id)!.subtasks.first.id;

      await provider.toggleSubtask(task.id, subtaskId);
      expect(
        provider.getTaskById(task.id)!.subtasks.first.isDone,
        isTrue,
      );

      await provider.toggleSubtask(task.id, subtaskId);
      expect(
        provider.getTaskById(task.id)!.subtasks.first.isDone,
        isFalse,
      );
    });
  });

  group('TasksProvider - Computed Lists', () {
    test('todoTasks returns pending tasks only', () async {
      await provider.addTask(title: 'Pending 1');
      await provider.addTask(title: 'Pending 2');
      final inProgress = await provider.addTask(title: 'In Progress');
      await provider.moveTaskToStatus(inProgress.id, TaskStatus.inProgress);

      expect(provider.todoTasks.length, 2);
      expect(provider.inProgressTasks.length, 1);
    });

    test('doneTasks returns completed tasks', () async {
      final task = await provider.addTask(title: 'Will complete');
      await provider.toggleTaskStatus(task.id);
      expect(provider.doneTasks.length, 1);
    });

    test('overdueTasks returns tasks past due', () async {
      final pastDate = DateTime.now().subtract(const Duration(days: 2));
      await provider.addTask(
        title: 'Overdue',
        dueDate: pastDate,
      );
      expect(provider.overdueTasks.length, 1);
    });

    test('todayTasks returns tasks due today', () async {
      final today = DateTime.now();
      await provider.addTask(title: 'Due today', dueDate: today);
      await provider.addTask(
        title: 'Due tomorrow',
        dueDate: today.add(const Duration(days: 1)),
      );
      expect(provider.todayTasks.length, 1);
    });
  });

  group('TasksProvider - Trash Lifecycle', () {
    test('deleteTask moves task to trash', () async {
      final task = await provider.addTask(title: 'Delete me');
      await provider.deleteTask(task.id);
      expect(provider.tasks, isEmpty);
      expect(storage.trashTasks.length, 1);
      expect(storage.trashTasks.first.title, 'Delete me');
    });

    test('restoreTask retrieves task from trash', () async {
      final task = await provider.addTask(title: 'Restore me');
      await provider.deleteTask(task.id);
      await provider.restoreTask(task.id);
      expect(provider.tasks.length, 1);
      expect(storage.trashTasks, isEmpty);
    });

    test('permanentDeleteTask removes from trash', () async {
      final task = await provider.addTask(title: 'Delete forever');
      await provider.deleteTask(task.id);
      await provider.permanentDeleteTask(task.id);
      expect(storage.trashTasks, isEmpty);
    });
  });

  group('TasksProvider - Aggregates', () {
    test('totalTasks returns correct count', () async {
      await provider.addTask(title: 'A');
      await provider.addTask(title: 'B');
      await provider.addTask(title: 'C');
      expect(provider.totalTasks, 3);
    });

    test('completionRate returns ratio', () async {
      expect(provider.completionRate, 0);
      await provider.addTask(title: 'A');
      await provider.addTask(title: 'B');
      await provider.addTask(title: 'C');
      await provider.toggleTaskStatus(
        provider.tasks.first.id,
      );
      expect(provider.completionRate, 1 / 3);
    });
  });
}
