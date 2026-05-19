import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/models/note.dart';
import 'package:second_brain/providers/notes_provider.dart';

import '../helpers/mock_storage_service.dart';

void main() {
  late MockStorageService storage;
  late NotesProvider provider;

  setUp(() async {
    storage = MockStorageService();
    provider = NotesProvider(storage: storage);
    await provider.loadNotes();
  });

  group('NotesProvider - CRUD', () {
    test('loadNotes loads empty list by default', () {
      expect(provider.notes, isEmpty);
      expect(provider.isLoaded, isTrue);
      expect(provider.notebooks, ['General']);
    });

    test('addNote creates a note', () async {
      final note = await provider.addNote(title: 'Test Note');
      expect(note.title, 'Test Note');
      expect(provider.notes.length, 1);
    });

    test('addNote with all fields', () async {
      final note = await provider.addNote(
        title: 'Full Note',
        content: 'Some content',
        type: NoteType.journal,
        notebook: 'Work',
        emoji: '📕',
        isPinned: true,
        tags: ['important'],
      );
      expect(note.content, 'Some content');
      expect(note.type, NoteType.journal);
      expect(note.notebook, 'Work');
      expect(note.isPinned, isTrue);
      expect(note.emoji, '📕');
      expect(note.tags, ['important']);
    });

    test('updateNote modifies note', () async {
      final note = await provider.addNote(title: 'Original');
      final updated = note.copyWith(title: 'Updated');
      await provider.updateNote(updated);
      expect(provider.getNoteById(note.id)?.title, 'Updated');
    });

    test('getNoteById returns null for missing id', () {
      expect(provider.getNoteById('missing'), isNull);
    });

    test('togglePin flips pinned status', () async {
      final note = await provider.addNote(title: 'Pin me');
      expect(note.isPinned, isFalse);

      await provider.togglePin(note.id);
      expect(provider.getNoteById(note.id)?.isPinned, isTrue);

      await provider.togglePin(note.id);
      expect(provider.getNoteById(note.id)?.isPinned, isFalse);
    });
  });

  group('NotesProvider - Notebook management', () {
    test('notebooks are derived from notes', () async {
      await provider.addNote(title: 'A', notebook: 'Work');
      await provider.addNote(title: 'B', notebook: 'Personal');
      await provider.addNote(title: 'C', notebook: 'Work');
      expect(provider.notebooks, containsAll(['Work', 'Personal']));
      expect(provider.notebookCounts['Work'], 2);
      expect(provider.notebookCounts['Personal'], 1);
    });

    test('renameNotebook renames all notes in notebook', () async {
      await provider.addNote(title: 'A', notebook: 'Old');
      await provider.addNote(title: 'B', notebook: 'Old');
      await provider.renameNotebook('Old', 'New');
      for (final note in provider.notes) {
        expect(note.notebook, 'New');
      }
    });

    test('deleteNotebook moves notes to General', () async {
      await provider.addNote(title: 'A', notebook: 'Custom');
      await provider.deleteNotebook('Custom');
      expect(provider.notes.first.notebook, 'General');
    });
  });

  group('NotesProvider - Computed lists', () {
    test('pinnedNotes and unpinnedNotes are correct', () async {
      await provider.addNote(title: 'A', isPinned: true);
      await provider.addNote(title: 'B');
      await provider.addNote(title: 'C', isPinned: true);
      expect(provider.pinnedNotes.length, 2);
      expect(provider.unpinnedNotes.length, 1);
    });

    test('recentNotes returns top 10 by updatedAt', () async {
      for (var i = 0; i < 15; i++) {
        await provider.addNote(title: 'Note $i');
      }
      expect(provider.recentNotes.length, 10);
    });
  });

  group('NotesProvider - Search and filter', () {
    test('search finds by title', () async {
      await provider.addNote(title: 'Meeting notes');
      await provider.addNote(title: 'Random thought');
      expect(provider.search('meeting').length, 1);
    });

    test('search finds by content', () async {
      await provider.addNote(title: 'A', content: 'flutter tutorial');
      expect(provider.search('tutorial').length, 1);
    });

    test('filteredNotes applies multiple filters', () async {
      await provider.addNote(
        title: 'Work note',
        notebook: 'Work',
        type: NoteType.reference,
        tags: ['important'],
      );
      await provider.addNote(title: 'Personal', notebook: 'Personal');

      final result = provider.filteredNotes(
        notebook: 'Work',
        type: NoteType.reference,
      );
      expect(result.length, 1);
    });

    test('getNotesByProject filters correctly', () async {
      await provider.addNote(title: 'A', projectId: 'p1');
      await provider.addNote(title: 'B', projectId: 'p1');
      await provider.addNote(title: 'C');
      expect(provider.getNotesByProject('p1').length, 2);
    });
  });

  group('NotesProvider - Trash Lifecycle', () {
    test('deleteNote moves to trash', () async {
      final note = await provider.addNote(title: 'Delete me');
      await provider.deleteNote(note.id);
      expect(provider.notes, isEmpty);
    });

    test('restoreNote retrieves from trash', () async {
      final note = await provider.addNote(title: 'Restore me');
      await provider.deleteNote(note.id);
      await provider.restoreNote(note.id);
      expect(provider.notes.length, 1);
    });

    test('permanentDeleteNote removes from trash', () async {
      final note = await provider.addNote(title: 'Forever');
      await provider.deleteNote(note.id);
      await provider.permanentDeleteNote(note.id);
    });
  });
}
