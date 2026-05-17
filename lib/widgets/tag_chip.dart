import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/tag.dart';

class TagChip extends StatelessWidget {
  final Tag tag;
  final bool selected;
  final VoidCallback? onTap;

  const TagChip({
    super.key,
    required this.tag,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? tag.color.withValues(alpha: 0.2)
              : BrainTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? tag.color : BrainTheme.borderDark,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          tag.name,
          style: TextStyle(
            fontSize: 12,
            color: selected ? tag.color : BrainTheme.textSecondary,
            fontWeight: selected ? FontWeight.w600 : null,
          ),
        ),
      ),
    );
  }
}
