import 'package:flutter_test/flutter_test.dart';
import 'package:second_brain/models/tag.dart';
import 'package:second_brain/providers/tags_provider.dart';

import '../helpers/mock_storage_service.dart';

void main() {
  late MockStorageService storage;
  late TagsProvider provider;

  setUp(() async {
    storage = MockStorageService();
    provider = TagsProvider(storage: storage);
    await provider.loadTags();
  });

  group('TagsProvider - CRUD', () {
    test('loadTags seeds default tags when empty', () {
      expect(provider.tags, isNotEmpty);
      expect(provider.isLoaded, isTrue);
    });

    test('addTag creates a tag', () async {
      final oldCount = provider.tags.length;
      final tag = await provider.addTag(
        name: 'Custom',
        colorValue: 0xFF0000FF,
        type: TagType.task,
      );
      expect(tag.name, 'Custom');
      expect(provider.tags.length, oldCount + 1);
    });

    test('updateTag modifies tag', () async {
      final tag = provider.tags.first;
      final updated = tag.copyWith(name: 'Updated Name');
      await provider.updateTag(updated);
      expect(provider.getById(tag.id)?.name, 'Updated Name');
    });

    test('deleteTag removes tag', () async {
      final tag = await provider.addTag(
        name: 'Delete me',
        colorValue: 0xFFFF0000,
        type: TagType.note,
      );
      await provider.deleteTag(tag.id);
      expect(provider.getById(tag.id), isNull);
    });
  });

  group('TagsProvider - Filtering', () {
    test('getTags filters by type', () {
      final noteTags = provider.getTags(TagType.note);
      expect(noteTags, isNotEmpty);
      for (final tag in noteTags) {
        expect(tag.type, TagType.note);
      }
    });
  });
}
