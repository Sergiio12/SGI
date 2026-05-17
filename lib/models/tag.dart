import 'package:flutter/material.dart';

enum TagType { note, task, project, goal }

class Tag {
  final String id;
  final String name;
  final Color color;
  final TagType type;

  const Tag({
    required this.id,
    required this.name,
    this.color = Colors.blue,
    required this.type,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'type': type.toString(),
      };

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'],
        name: json['name'],
        color: Color(json['color']),
        type: _parseTagType(json['type'] ?? 'TagType.note'),
      );

  static TagType _parseTagType(String str) {
    switch (str) {
      case 'TagType.note':
        return TagType.note;
      case 'TagType.task':
        return TagType.task;
      case 'TagType.project':
        return TagType.project;
      case 'TagType.goal':
        return TagType.goal;
      default:
        return TagType.note;
    }
  }

  Tag copyWith({String? name, Color? color, TagType? type}) => Tag(
        id: id,
        name: name ?? this.name,
        color: color ?? this.color,
        type: type ?? this.type,
      );

  static List<Tag> defaultTagsForType(TagType type) {
    switch (type) {
      case TagType.note:
        return [
          const Tag(
              id: 'research',
              name: '🔍 Investigación',
              color: Colors.blue,
              type: TagType.note),
          const Tag(
              id: 'personal',
              name: '🏠 Personal',
              color: Colors.green,
              type: TagType.note),
          const Tag(
              id: 'ideas',
              name: '💡 Ideas',
              color: Colors.amber,
              type: TagType.note),
          const Tag(
              id: 'important',
              name: '⭐ Importante',
              color: Colors.orange,
              type: TagType.note),
        ];
      case TagType.task:
        return [
          const Tag(
              id: 'urgent',
              name: '🔥 Urgente',
              color: Colors.red,
              type: TagType.task),
          const Tag(
              id: 'blocked',
              name: '🚫 Bloqueado',
              color: Colors.grey,
              type: TagType.task),
          const Tag(
              id: 'inprogress',
              name: '⚙️ En progreso',
              color: Colors.blue,
              type: TagType.task),
          const Tag(
              id: 'review',
              name: '👁️ Revisar',
              color: Colors.purple,
              type: TagType.task),
        ];
      case TagType.project:
        return [
          const Tag(
              id: 'active',
              name: '✅ Activo',
              color: Colors.green,
              type: TagType.project),
          const Tag(
              id: 'onhold',
              name: '⏸️ En espera',
              color: Colors.amber,
              type: TagType.project),
          const Tag(
              id: 'completed',
              name: '🎉 Completado',
              color: Colors.teal,
              type: TagType.project),
          const Tag(
              id: 'archived',
              name: '📦 Archivado',
              color: Colors.grey,
              type: TagType.project),
        ];
      case TagType.goal:
        return [
          const Tag(
              id: 'shortterm',
              name: '🎯 Corto plazo',
              color: Colors.blue,
              type: TagType.goal),
          const Tag(
              id: 'longterm',
              name: '🏔️ Largo plazo',
              color: Colors.purple,
              type: TagType.goal),
          const Tag(
              id: 'health',
              name: '💪 Salud',
              color: Colors.red,
              type: TagType.goal),
          const Tag(
              id: 'learning',
              name: '📚 Aprendizaje',
              color: Colors.orange,
              type: TagType.goal),
        ];
    }
  }
}
