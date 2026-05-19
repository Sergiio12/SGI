import 'package:flutter/material.dart';
import '../../../config/theme.dart';

Future<String?> showEmojiPickerModal(BuildContext context, String currentEmoji) {
  return showModalBottomSheet<String>(
    context: context,
    useSafeArea: true,
    builder: (ctx) => _EmojiPickerContent(currentEmoji: currentEmoji),
  );
}

class _EmojiPickerContent extends StatelessWidget {
  final String currentEmoji;

  const _EmojiPickerContent({required this.currentEmoji});

  static const _noteEmojis = [
    '📝', '💡', '🎯', '📗', '🗂️', '📌', '💻', '🗒️',
    '✍️', '📎', '🧠', '📓', '✏️', '📖', '🪄', '📚',
    '⭐', '🔥', '✅', '🚀', '💪', '🎨', '📊', '🔬',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Elegir Emoji',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _noteEmojis.map((e) {
              final isSelected = e == currentEmoji;
              return GestureDetector(
                onTap: () => Navigator.pop(context, e),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? BrainTheme.accentPurple.withValues(alpha: 0.2)
                        : BrainTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? BrainTheme.accentPurple
                          : BrainTheme.borderDark,
                    ),
                  ),
                  child: Center(
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
