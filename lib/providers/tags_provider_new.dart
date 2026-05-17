import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/tag.dart';
import '../services/storage_service.dart';
import '../utils/notification_service_v2.dart';

class TagsProvider extends ChangeNotifier {
  late Map<TagType, List<Tag>> _tagsByType;
  final _uuid = const Uuid();
  bool _isLoaded = false;

  TagsProvider() {
    _tagsByType = {
      TagType.note: [],
      TagType.task: [],
      TagType.project: [],
      TagType.goal: [],
    };
  }

  bool get isLoaded => _isLoaded;

  List<Tag> getTags(TagType type) => List<Tag>.from(_tagsByType[type] ?? []);

  List<Tag> get allTags => _tagsByType.values.expand((tags) => tags).toList();

  Future<void> loadTags() async {
    final loadedTags = await StorageService.loadTags();
    if (loadedTags.isEmpty) {
      _tagsByType[TagType.note] = Tag.defaultTagsForType(TagType.note);
      _tagsByType[TagType.task] = Tag.defaultTagsForType(TagType.task);
      _tagsByType[TagType.project] = Tag.defaultTagsForType(TagType.project);
      _tagsByType[TagType.goal] = Tag.defaultTagsForType(TagType.goal);
    } else {
      _tagsByType = {
        TagType.note:
            loadedTags.where((tag) => tag.type == TagType.note).toList(),
        TagType.task:
            loadedTags.where((tag) => tag.type == TagType.task).toList(),
        TagType.project:
            loadedTags.where((tag) => tag.type == TagType.project).toList(),
        TagType.goal:
            loadedTags.where((tag) => tag.type == TagType.goal).toList(),
      };
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<Tag> addTag(
      {required String name,
      required int colorValue,
      required TagType type}) async {
    final tag = Tag(
      id: _uuid.v4(),
      name: name,
      color: Color(colorValue),
      type: type,
    );
    final tags = _tagsByType[type] ?? [];
    tags.add(tag);
    _tagsByType[type] = tags;
    await StorageService.saveTags(allTags);
    notifyListeners();
    showSuccessNotification('Etiqueta creada');
    return tag;
  }

  Future<void> updateTag(Tag tag) async {
    final tags = _tagsByType[tag.type] ?? [];
    final idx = tags.indexWhere((t) => t.id == tag.id);
    if (idx != -1) {
      tags[idx] = tag;
      _tagsByType[tag.type] = tags;
      await StorageService.saveTags(allTags);
      notifyListeners();
      showSuccessNotification('Etiqueta actualizada');
    }
  }

  Future<void> deleteTag(String id, TagType type) async {
    final tags = _tagsByType[type] ?? [];
    tags.removeWhere((t) => t.id == id);
    _tagsByType[type] = tags;
    await StorageService.saveTags(allTags);
    notifyListeners();
    showSuccessNotification('Etiqueta eliminada');
  }

  Tag? getById(String id, TagType type) {
    try {
      return _tagsByType[type]?.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
