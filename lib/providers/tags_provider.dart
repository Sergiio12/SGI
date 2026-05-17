import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/tag.dart';
import '../services/storage_service.dart';
import '../utils/notification_service_v2.dart';

class TagsProvider extends ChangeNotifier {
  List<Tag> _tags = [];
  final _uuid = const Uuid();
  bool _isLoaded = false;

  List<Tag> get tags => _tags;
  bool get isLoaded => _isLoaded;

  List<Tag> getTags(TagType type) =>
      _tags.where((tag) => tag.type == type).toList();

  Future<void> loadTags() async {
    _tags = await StorageService.loadTags();
    if (_tags.isEmpty) {
      _tags = [
        ...Tag.defaultTagsForType(TagType.note),
        ...Tag.defaultTagsForType(TagType.task),
        ...Tag.defaultTagsForType(TagType.project),
        ...Tag.defaultTagsForType(TagType.goal),
      ];
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<Tag> addTag(
      {required String name,
      required int colorValue,
      TagType type = TagType.note}) async {
    final tag =
        Tag(id: _uuid.v4(), name: name, color: Color(colorValue), type: type);
    _tags.add(tag);
    await StorageService.saveTags(_tags);
    notifyListeners();
    showSuccessNotification('Etiqueta creada');
    return tag;
  }

  Future<void> updateTag(Tag tag) async {
    final idx = _tags.indexWhere((t) => t.id == tag.id);
    if (idx != -1) {
      _tags[idx] = tag;
      await StorageService.saveTags(_tags);
      notifyListeners();
      showSuccessNotification('Etiqueta actualizada');
    }
  }

  Future<void> deleteTag(String id) async {
    _tags.removeWhere((t) => t.id == id);
    await StorageService.saveTags(_tags);
    notifyListeners();
    showSuccessNotification('Etiqueta eliminada');
  }

  Tag? getById(String id) {
    try {
      return _tags.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
