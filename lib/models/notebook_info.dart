import 'package:flutter/material.dart';

class NotebookInfo {
  final String name;
  final String colorHex;

  const NotebookInfo({required this.name, required this.colorHex});

  Color get color => colorFromHex(colorHex);

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': colorHex,
      };

  factory NotebookInfo.fromJson(dynamic json) {
    if (json is String) {
      return NotebookInfo(
        name: json,
        colorHex: defaultColorHex(json),
      );
    }
    final map = json as Map<String, dynamic>;
    final name = map['name'] as String? ?? '';
    final colorHex = map['color'] as String? ?? defaultColorHex(name);
    return NotebookInfo(name: name, colorHex: colorHex);
  }

  static const List<String> palette = [
    '9D4EDD',
    '3B82F6',
    '10B981',
    'F59E0B',
    'EF4444',
    'EC4899',
    '06B6D4',
    'FBBF24',
  ];

  static String defaultColorHex(String name) {
    final seed = name.runes.fold<int>(0, (sum, char) => sum + char);
    return palette[seed % palette.length];
  }

  static Color colorFromHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    final value = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    return Color(int.parse(value, radix: 16));
  }
}
