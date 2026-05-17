import 'package:flutter/material.dart';

class Tag {
  final String id;
  final String name;
  final Color color;

  const Tag({
    required this.id,
    required this.name,
    this.color = Colors.blue,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
      };

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: json['id'],
        name: json['name'],
        color: Color(json['color']),
      );

  static List<Tag> defaultTags = [
    const Tag(id: 'work', name: '💼 Trabajo', color: Colors.blue),
    const Tag(id: 'personal', name: '🏠 Personal', color: Colors.green),
    const Tag(id: 'ideas', name: '💡 Ideas', color: Colors.amber),
    const Tag(id: 'learning', name: '📚 Aprendizaje', color: Colors.purple),
    const Tag(id: 'health', name: '🏃 Salud', color: Colors.red),
    const Tag(id: 'finance', name: '💰 Finanzas', color: Colors.teal),
    const Tag(id: 'creative', name: '🎨 Creativo', color: Colors.orange),
    const Tag(id: 'urgent', name: '🔥 Urgente', color: Colors.redAccent),
  ];
}
