import 'package:flutter/material.dart';

class TagColorPicker extends StatelessWidget {
  final int selectedColorValue;
  final ValueChanged<int> onColorChanged;

  const TagColorPicker({
    super.key,
    required this.selectedColorValue,
    required this.onColorChanged,
  });

  static const List<int> colorPalette = [
    0xFFEF4444,
    0xFFF97316,
    0xFFF59E0B,
    0xFFEAB308,
    0xFF84CC16,
    0xFF22C55E,
    0xFF10B981,
    0xFF14B8A6,
    0xFF06B6D4,
    0xFF0EA5E9,
    0xFF3B82F6,
    0xFF6366F1,
    0xFF8B5CF6,
    0xFF9D4EDD,
    0xFFA855F7,
    0xFFD946EF,
    0xFFEC4899,
    0xFFF43F5E,
    0xFF78716C,
    0xFFA8A29E,
    0xFF6B7280,
    0xFF4B5563,
    0xFF1C1917,
    0xFF18181B,
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: colorPalette.map((colorValue) {
        final color = Color(colorValue);
        final isSelected = colorValue == selectedColorValue;
        return GestureDetector(
          onTap: () => onColorChanged(colorValue),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: isSelected ? 3 : 0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : [],
            ),
            child: isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
